#!/usr/bin/env bash

# 部署脚本
# source config.sh
. config.sh

# source docker.sh
. docker.sh

# source minio/minio.sh, minio function
. minio/minio.sh

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

# 部署基础组件
function deployBase() {
    echo "docker network create --driver=bridge --subnet=${DOCKER_SUBNET} br0"
    docker network create --driver=bridge --subnet=${DOCKER_SUBNET} br0

    # 创建基础组件，这些是没有依赖的服务
    echo "create base component."
    dockerComposeUp postgresql
    dockerComposeUp redis

    # 等他们启动
    sleep 20

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
}

# 打印关键信息
function printConf() {
    echo "###############################################################################################"
    echo "###############################################################################################"
    echo "###############################################################################################"
    echo "Keycloak Admin UI: https://${KEYCLOAK_DOMAIN_NAME}"
    echo "Admin User: ${KEYCLOAK_ADMIN}"
    echo "Admin Password: ${KEYCLOAK_ADMIN_PASSWORD}"
    echo ""
    echo "Default User for Outline:"
    echo "Username: ${ADMIN_EMAIL}"
    echo "Password: ${KEYCLOAK_ADMIN_PASSWORD} (same as admin password)"
    echo ""
    echo "Outline URL: https://${OUTLINE_DOMAIN_NAME}"
    echo "###############################################################################################"
    echo "###############################################################################################"
    echo "###############################################################################################"
}

# 部署方法，部署基本组件 + outline服务
function deployService() {
    # 部署基础服务
    echo "deploy base"
    deployBase

    # 生成 keycloak realm 配置文件
    echo "Generate keycloak realm config file..."
    envsubst < "keycloak/realm-config.json.template" > "keycloak/realm-config.json"

    # 部署 keycloak
    echo "deploy keycloak"
    dockerComposeUp keycloak
    
    # 部署 outline服务
    echo "deploy outline"
    dockerComposeUp outline

    # 等待 outline 和 keycloak 启动完成
    sleep 30

    # 最后部署 https-portal，因为它依赖前面的服务
    echo "deploy https-portal"
    dockerComposeUp https-portal

    # 判断是否创建 minio bucket
    if [ "$MINIO_ENABLED" = "true" ]; then
        echo "minio enabled, create default bucket and accessKey."
        # 创建 minio的 bucket
        createMinioBucketAndAK
    else
        echo "minio disabled, do not create default bucket and accessKey."
    fi

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

main "$@"
