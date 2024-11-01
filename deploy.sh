#!/usr/bin/env bash

# 部署脚本
# source config.sh
. config.sh

# source docker.sh
. docker.sh

# source gitea/gitea.sh, gitea function
. gitea/gitea.sh

# source minio/minio.sh, minio function
. minio/minio.sh

# source nginxproxymanager/npm.sh
. nginxproxymanager/npm.sh

# docker compose 启动
function dockerComposeUp() {
    echo "docker compose create $1"
    pushd $1 || exit
    docker compose up -d
    popd || exit
}

# docker compose 重启
function dockerComposeRestart() {
    echo "docker compose create $1"
    pushd $1 || exit
    docker compose down
    docker compose up -d
    popd || exit
}

# 创建 nginx proxy manager 的数据库
function createDbNPM() {
    execMySQL "create database ${MYSQL_NPM_DB}"
    execMySQL "grant all privileges on ${MYSQL_NPM_DB}.* to '${MYSQL_USER}'@'%'"
}

# 在 MySQL的 docker容器中执行sql
function execMySQL() {
    echo "docker exec -it mysql mysql -e '$1'"
    docker exec -it mysql mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "$1"
}

# 部署基础组件
function deployBase() {
    echo "docker network create --driver=bridge --subnet=${DOCKER_SUBNET} br0"
    docker network create --driver=bridge --subnet=${DOCKER_SUBNET} br0

    # 创建基础组件，这些是没有依赖的服务
    echo "create base component."
    dockerComposeUp mysql
    dockerComposeUp postgresql
    dockerComposeUp redis

    # minio 开关
    if [ "$MINIO_ENABLED" = "true" ]; then
        echo "minio enabled, create minio container."
        dockerComposeUp minio
    else
        echo "minio disabled, do not create minio container."
    fi

    # drawio开关
    if [ "$DRAWIO_ENABLED" = "true" ]; then
        echo "drawio enabled, create drawio container."
        dockerComposeUp drawio
    else
        echo "drawio disabled, do not create drawio container."
    fi

    # grist开关
    if [ "$GRIST_ENABLED" = "true" ]; then
        echo "grist enabled, create grist container."
        dockerComposeUp grist
    else
        echo "grist disabled, do not create grist container."
    fi

    # 创建 gitea的服务，依赖 MySQL
    echo "create gitea service."
    dockerComposeUp gitea

    # 创建 nginx proxy manager 的 MySQL数据库， 创建 nginx proxy manager的服务，依赖MySQL
    echo "create nginx proxy manager database and service."
    createDbNPM
    dockerComposeUp nginxproxymanager

    # 创建 gitea的 管理员账号
    echo "create gitea admin user: ${GITEA_ADMIN_USER}."
    createGiteaAdmin "${GITEA_ADMIN_USER}" "${GITEA_ADMIN_PASSWORD}" "${GITEA_ADMIN_EMAIL}"

    # 创建 gitea的 应用，给 outline做oidc认证服务
    echo "create gitea app: ${GITEA_APP_NAME}."
    createGiteaApp "${GITEA_ADMIN_USER}" "${GITEA_ADMIN_PASSWORD}" "${GITEA_APP_NAME}" "${OUTLINE_ROOT_URL}/auth/oidc.callback"

    # 判断是否创建 minio bucket
    if [ "$MINIO_ENABLED" = "true" ]; then
        echo "minio enabled, create default bucket and accessKey."
        # 创建 minio的 bucket
        createMinioBucketAndAK
    else
        echo "minio disabled, do not create default bucket and accessKey."
    fi
}

# 打印关键信息
function printConf() {
    echo "###############################################################################################"
    echo "###############################################################################################"
    echo "###############################################################################################"
    echo "nginxproxymanager  http://${ROOT_DOMAIN_NAME}:81, user ${NPM_ADMIN_USER}, password ${NPM_ADMIN_PASSWORD}"
    echo "minio-s3           https://${MINIO_S3API_DOMAIN_NAME} -> http://${MINIO_IP}:${MINIO_S3_PORT}"
    echo "gitea              https://${GITEA_DOMAIN_NAME} -> http://${GITEA_IP}:${GITEA_PORT}, user ${GITEA_ADMIN_USER}, password ${GITEA_ADMIN_PASSWORD}"
    echo "outline            https://${OUTLINE_DOMAIN_NAME} -> http://${OUTLINE_IP}:${OUTLINE_PORT}"
    echo "drawio             https://${DRAWIO_DOMAIN_NAME} -> http://${DRAWIO_IP}:${DRAWIO_PORT}"
    echo "grist              https://${GRIST_DOMAIN_NAME} -> http://${GRIST_IP}:${GRIST_PORT}"
    echo "###############################################################################################"
    echo "###############################################################################################"
    echo "###############################################################################################"
}

# 部署方法，部署基本组件 + outline服务
# 创建 nginxproxymanager 配置
function deployService() {
    env > deploy.env

    # 部署基础服务
    echo "deploy base"
    deployBase

    # 生成 outline 环境配置文件, 在 outline目录下
    envsubst < "./outline/${OUTLINE_ENV_FILE_TEMPLATE}" > "./outline/${OUTLINE_ENV_FILE}"

    # 部署 outline服务
    echo "deploy outline"
    dockerComposeUp outline

    # 这里等一下 nginxproxymanager service 不一定启动完成，20241031-这个时间还是不够，会导致后面的改密码 改名字 add host都失败，需要增加一个单独的补救命令
    # npm登录502，可能是因为启动下载IP-ranges.json超时，导致启动卡住，pr还没合，可以通过修改容器中的 /app/index.js 
    sleep 60
    # nginxproxymanager需要首次登录时修改 账号和密码
    echo "nginxproxymanager change account"
    changeAccount

    # nginxproxymanager 增加代理服务
    echo "nginxproxymanager add proxy hosts"
    addProxyHosts

    # 输出环境变量到本地文件
    echo "save env to deploy.conf"
    env > deploy.conf

    # 打印关键配置
    printConf
}

# 主方法
function main() {
    # 如果没有传入参数，或者传入的第一个参数是"help"，则显示帮助信息
    if [ -z "$1" ] || [ "$1" == "help" ]; then
        echo "用法： $0 [方法1|方法2] [参数...]"
        exit 1
    fi

    # 根据传入的参数名来决定执行哪个方法
    if [ "$1" == "service" ]; then
        echo "deploy service."
        deployService
    elif [ "$1" == "all" ]; then
        echo "deploy docker"
        installDocker
        echo "deploy service."
        deployService
    elif [ "$1" == "restart" ]; then
        echo "restart $2"
        dockerComposeRestart $2
    elif [ "$1" == "docker" ]; then
        echo "deploy docker"
        installDocker
    else
        echo "unknown args： $1"
        echo "args like: docker/service/all/restart"
        exit 1
    fi
}

main $@