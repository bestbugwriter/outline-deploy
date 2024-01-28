#!/usr/bin/env bash

# 修改 账号名称和密码
function changeAccount() {

    # 获取 npm的 token
    echo "get npm token use ${NPM_ADMIN_USER_DEFAULT} ${NPM_ADMIN_PASSWORD_DEFAULT}"
    NPM_TOKEN=$(getNPMToken ${NPM_ADMIN_USER_DEFAULT} ${NPM_ADMIN_PASSWORD_DEFAULT})

    # 修改账号名称
    echo "renameAccount ${NPM_TOKEN} ${NPM_ADMIN_USER}"
    renameAccount ${NPM_TOKEN} ${NPM_ADMIN_USER}

    # 修改账号密码
    echo "changePassword ${NPM_TOKEN} ${NPM_ADMIN_PASSWORD_DEFAULT} ${NPM_ADMIN_PASSWORD}"
    changePassword ${NPM_TOKEN} ${NPM_ADMIN_PASSWORD_DEFAULT} ${NPM_ADMIN_PASSWORD}
}

# 修改账号名称
function renameAccount() {
    NPM_TOKEN=$1
    NPM_ADMIN_USER=$2
    result1=$(curl -X PUT "http://${NPM_IP}:81/api/users/1" -H "Authorization: Bearer ${NPM_TOKEN}" -H 'Content-Type: application/json; charset=UTF-8' \
       --data-raw "{\"name\":\"Administrator\",\"nickname\":\"Admin\",\"email\":\"${NPM_ADMIN_USER}\",\"roles\":[\"admin\"],\"is_disabled\":false}")
    echo $result1
}

# 修改账号密码
function changePassword() {
    NPM_TOKEN=$1
    OLD_PASSWORD=$2
    NEW_PASSWORD=$3
    result2=$(curl -X PUT "http://${NPM_IP}:81/api/users/1/auth" -H "Authorization: Bearer ${NPM_TOKEN}" -H 'Content-Type: application/json; charset=UTF-8' \
       --data-raw "{\"type\":\"password\",\"current\":\"${OLD_PASSWORD}\",\"secret\":\"${NEW_PASSWORD}\"}")
    echo $result2
}

# 获取 npm的 token http://${NPM_IP}:81/api/tokens
function getNPMToken() {
    NPM_USER=$1
    NPM_PASSWORD=$2

    result=$(curl -X POST "http://${NPM_IP}:81/api/tokens" -H 'Content-Type: application/json; charset=UTF-8' --data-raw "{\"identity\":\"${NPM_USER}\",\"secret\":\"${NPM_PASSWORD}\"}")

    # 使用awk提取client_id
    # 最后的 print$(i+2) 取第二个key，print$(i+1) 是 :, print$(i) 是 token
    # {"token":"eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJhcGkiLCJhdHRycyI6eyJpZCI6MX0sInNjb3BlIjpbInVzZXIiXSwiZXhwaXJlc0luIjoiMWQiLCJqdGkiOiJUbTNHcWF5aENyWEVvOGJIIiwiaWF0IjoxNzA2MzI1NjEyLCJleHAiOjE3MDY0MTIwMTJ9.IcFmqulz4cD8BJI64TRLykg42CMSUjIi3NEfSFCp1lqMxxX0KiDuDNRKgshU773nsErITm8cLj4f8a1ZAZGeFjP9X_Rf-rdThfyzLfJVvJo_pwN6E57XzBkOW-hyCNqTbMhDuX9rxE0AbJ5cBotnlZcLA8UfBthC265wTQJjkYmOZ-y8UfEE0iZu0UQ5G-JCxPrLS7O_VY3oWEF0GmkY_ch9nV9MQgZ9MH2LL1SjQzoRSxsK0-XlsnV4SbWiOuzpLMoNPxW0jdYDIBDnorIjIaqflYbwJ1owPDf9suhZlXVeRWSzHYIBcxxmZUtqZzCz49Sv5q48CmAfP22kpP14eQ","expires":"2024-01-28T03:20:12.656Z"}
    echo "${result}" | awk -F\" '{for(i=1;i<=NF;i++) if ($i=="token") print$(i+2)}'
}

# 增加需要的代理 host
function addProxyHosts() {

    # 获取 npm的 token
    echo "get npm token user ${NPM_ADMIN_USER}"
    NPM_TOKEN=$(getNPMToken ${NPM_ADMIN_USER} ${NPM_ADMIN_PASSWORD})

    # 增加 gitea的代理域名D
    echo "addProxyHost ${NPM_TOKEN} ${GITEA_DOMAIN_NAME} ${GITEA_IP} ${GITEA_PORT}"
    addProxyHost ${NPM_TOKEN} ${GITEA_DOMAIN_NAME} ${GITEA_IP} ${GITEA_PORT}

    if [ "$MINIO_ENABLED" = "true" ]; then
       # 增加 minio s3地址的代理域名
        echo "minio enabled, addProxyHost ${NPM_TOKEN} ${MINIO_S3API_DOMAIN_NAME} ${MINIO_IP} ${MINIO_S3_PORT}"
        addProxyHost ${NPM_TOKEN} ${MINIO_S3API_DOMAIN_NAME} ${MINIO_IP} ${MINIO_S3_PORT}
    else
        echo "minio disabled, do not add proxy hosts."
    fi

    # 增加 outline的代理域名
    echo "addProxyHost ${NPM_TOKEN} ${OUTLINE_DOMAIN_NAME} ${OUTLINE_IP} ${OUTLINE_PORT}"
    addProxyHost ${NPM_TOKEN} ${OUTLINE_DOMAIN_NAME} ${OUTLINE_IP} ${OUTLINE_PORT}

    # drawio开关
    if [ "$DRAWIO_ENABLED" = "true" ]; then
        # 增加 drawio的代理域名
        echo "drawio enabled, addProxyHost ${NPM_TOKEN} ${DRAWIO_DOMAIN_NAME} ${DRAWIO_IP} ${DRAWIO_PORT}"
        addProxyHost ${NPM_TOKEN} ${DRAWIO_DOMAIN_NAME} ${DRAWIO_IP} ${DRAWIO_PORT}
    else
        echo "drawio disabled, do not add proxy hosts."
    fi
}

# 增加代理 host
function addProxyHost() {
    NPM_TOKEN=$1
    PROXY_DOMAIN_NAME=$2
    PROXY_IP=$3
    PROXY_PORT=$4
    curl -X POST "http://${NPM_IP}:81/api/nginx/proxy-hosts" -H "Authorization: Bearer ${NPM_TOKEN}" -H 'Content-Type: application/json; charset=UTF-8' \
      --data-raw "{\"domain_names\":[\"${PROXY_DOMAIN_NAME}\"],\"forward_scheme\":\"http\",\"forward_host\":\"${PROXY_IP}\",\"forward_port\":${PROXY_PORT},\"caching_enabled\":true,\"allow_websocket_upgrade\":true,\"access_list_id\":\"0\",\"certificate_id\":\"new\",\"ssl_forced\":true,\"http2_support\":true,\"hsts_enabled\":true,\"hsts_subdomains\":true,\"meta\":{\"letsencrypt_email\":\"yywfqq@live.com\",\"letsencrypt_agree\":true,\"dns_challenge\":false},\"advanced_config\":\"\",\"locations\":[],\"block_exploits\":false}"
}