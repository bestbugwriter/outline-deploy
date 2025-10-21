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
    echo "Hydra (OIDC Issuer): https://${AUTH_DOMAIN_NAME}"
    echo "Hydra Login/Consent App: https://${AUTH_UI_DOMAIN_NAME}"
    echo "Kratos Self-Service UI: https://${KRATOS_UI_DOMAIN_NAME}"
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

    # 生成 Kratos 配置文件
    echo "Generate kratos config file..."
    envsubst < "kratos/kratos.yml.template" > "kratos/kratos.yml"

    # 部署 Kratos (身份服务)
    echo "deploy kratos"
    dockerComposeUp kratos

    # 部署 Hydra (OIDC) 及其 Login/Consent 应用
    echo "deploy hydra"
    dockerComposeUp hydra

    # 等待 Hydra 启动完成，后续需要创建 OAuth2 Client
    echo "Waiting for Hydra to start..."
    sleep 60

    # 创建 Outline 的 OAuth2 Client（若已存在则忽略错误）
    echo "Create Hydra OAuth2 client for Outline"
    docker exec hydra hydra create oauth2-client --endpoint http://localhost:4445 \
      --id "${HYDRA_CLIENT_ID}" \
      --secret "${HYDRA_CLIENT_SECRET}" \
      --name "Outline" \
      --grant-type "authorization_code,refresh_token" \
      --response-type "code" \
      --scope "openid,profile,email,offline_access" \
      --redirect-uri "https://${OUTLINE_DOMAIN_NAME}/auth/oidc.callback" \
      --token-endpoint-auth-method "client_secret_basic" >/dev/null 2>&1 || \
    docker exec hydra hydra clients create --endpoint http://localhost:4445 \
      --id "${HYDRA_CLIENT_ID}" \
      --secret "${HYDRA_CLIENT_SECRET}" \
      --name "Outline" \
      --grant-types "authorization_code,refresh_token" \
      --response-types "code" \
      --scope "openid,profile,email,offline_access" \
      --redirect-uris "https://${OUTLINE_DOMAIN_NAME}/auth/oidc.callback" \
      --token-endpoint-auth-method "client_secret_basic" >/dev/null 2>&1 || true

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
