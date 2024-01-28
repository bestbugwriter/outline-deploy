#!/usr/bin/env bash

# 创建 gitea的 admin 账号
function createGiteaAdmin() {
    # 管理员账号，名称不能是 "admin"
    GITEA_ADMIN_USER=$1
    # 管理员密码
    GITEA_ADMIN_PASSWORD=$2
    # 管理员邮箱
    GITEA_ADMIN_EMAIL=$3

    # 通过 docker 容器中的 gitea命令创建 管理员用户
    # Gitea is not supposed to be run as root. Sorry. If you need to use privileged TCP ports please instead use setcap and the `cap_net_bind_service` permission
    echo "create gitea admin user ${GITEA_ADMIN_USER}."
    docker exec -it gitea su  -c "gitea admin user create --username ${GITEA_ADMIN_USER} --password ${GITEA_ADMIN_PASSWORD} --email ${GITEA_ADMIN_EMAIL} --admin" git
    echo "check gitea user."
    docker exec -it gitea su -c "gitea admin user list" git
}

# 创建 gitea的 app
function createGiteaApp() {
    # 管理员账号
    GITEA_ADMIN_USER=$1
    # 管理员密码
    GITEA_ADMIN_PASSWORD=$2
    # gitea的 应用名称
    GITEA_APP_NAME=$3
    # gitea oidc的 回调地址 ${OUTLINE_ROOT_URL}/auth/oidc.callback
    GITEA_APP_CALLBACK_URL=$4

    # 使用 http的 basic 认证
    BASIC_AUTH=$(echo -n ${GITEA_ADMIN_USER}:${GITEA_ADMIN_PASSWORD} | base64)

    # 通过 http接口创建 oidc应用， gitea的命令行没有这个功能
    echo "create gitea app ${GITEA_APP_NAME}, user: ${GITEA_ADMIN_USER}, CALLBACK_URL: ${GITEA_APP_CALLBACK_URL}"
    result=$(curl -X POST http://${GITEA_IP}:${GITEA_PORT}/api/v1/user/applications/oauth2 \
    -H 'accept: application/json' -H 'Content-Type: application/json' -H "Authorization: Basic ${BASIC_AUTH}" \
    -d "{\"confidential_client\": true,\"name\": \"${GITEA_APP_NAME}\",\"redirect_uris\": [\"${GITEA_APP_CALLBACK_URL}\"]}")

    echo "result: ${result}"

    # 使用awk提取client_id
    # 最后的 print$(i+2) 取第二个key，print$(i+1) 是 :, print$(i) 是 client_id
    client_id=$(echo "${result}" | awk -F\" '{for(i=1;i<=NF;i++) if ($i=="client_id") print$(i+2)}')
    # 使用awk提取client_secret
    client_secret=$(echo "${result}" | awk -F\" '{for(i=1;i<=NF;i++) if ($i=="client_secret") print$(i+2)}')
    # 输出结果
    echo "Extracted Client ID: $client_id"
    echo "Extracted Client Secret: $client_secret"

    # 导出关键信息 export APP ID and SECRET
    export GITEA_APP_CLI_ID=$client_id
    export GITEA_APP_CLI_SECRET=$client_secret
}