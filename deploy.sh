#!/usr/bin/env bash

# 如果存在 deploy.conf 文件，则加载它以重用之前的配置（特别是密码）
if [ -f "deploy.conf" ]; then
    echo "Found deploy.conf, loading existing configuration..."
    # 我们需要导出变量，以便后续的脚本可以使用
    set -a
    source deploy.conf
    set +a
fi

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

# 创建 Hydra 客户端
function createHydraClientForOutline() {
    echo "Creating Hydra client for Outline..."
    # 等待 Hydra 启动
    sleep 10
    docker run --rm --network br0 \
        oryd/hydra:v2.2.0 oauth2 client create \
        --endpoint "http://${HYDRA_IP}:4445" \
        --id "${HYDRA_CLIENT_ID}" \
        --secret "${HYDRA_CLIENT_SECRET}" \
        --grant-types "authorization_code,refresh_token,client_credentials" \
        --response-types "code,id_token" \
        --scope "openid profile email offline_access" \
        --callbacks "${OUTLINE_ROOT_URL}/auth/oidc.callback" \
        --name "Outline"
    echo "Hydra client for Outline created."
}

# 部署基础组件
function deployBase() {
    # 检查 br0 网络是否存在，不存在则创建
    if [ -z "$(docker network ls -q -f name=^br0$)" ]; then
        echo "Network br0 not found, creating docker network: br0 with subnet ${DOCKER_SUBNET}"
        docker network create --driver=bridge --subnet=${DOCKER_SUBNET} br0
    else
        echo "Network br0 already exists, skipping creation."
    fi

    # 创建基础组件，这些是没有依赖的服务
    echo "create base component."
    dockerComposeUp postgresql
    dockerComposeUp redis
    dockerComposeUp kratos
    dockerComposeUp hydra

    # 等他们启动
    sleep 20

    # 创建 Hydra 客户端
    createHydraClientForOutline

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
    echo "Kratos Admin UI: https://${KRATOS_DOMAIN_NAME}/admin"
    echo "Kratos Public UI: https://${KRATOS_DOMAIN_NAME}/"
    echo "Hydra Admin UI: https://${HYDRA_DOMAIN_NAME}/admin"
    echo "Hydra Public UI: https://${HYDRA_DOMAIN_NAME}/"
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

    
        # 生成 outline 环境配置文件, 在 outline目录下
        echo "Generate outline config file..."
        envsubst < "outline/outline.env.template" > "outline/outline.env"
    
        # 部署 outline服务
        echo "deploy outline"
        dockerComposeUp outline
    
        # 等待 outline 启动完成
        echo "Waiting for Outline to start..."
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
