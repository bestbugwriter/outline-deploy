#!/usr/bin/env bash

# 配置文件，使用时， source 本文件
# 随机字符串
function randomString() {
    STRING_LEN=$1
    strings /dev/urandom |tr -dc A-Za-z0-9 | head -c ${STRING_LEN}
}

# 随机16位字符串
function randomString16() {
    randomString 16
}

# docker的子网网段，我们创建的几个容器都在一个网段
export DOCKER_SUBNET=172.16.0.0/24

# 个人域名，需要用的几个域名都要做对应的 dns解析，要能解析到我们服务器的IP
export ROOT_DOMAIN_NAME=bdms.fun

# 个人邮箱
export ADMIN_EMAIL=yywfqq@live.com



################
# postgresql 配置
export POSTGRES_IP=172.16.0.11
export POSTGRES_DATA_DIR=./data
# postgres 超级管理员账号
export POSTGRES_USER=postgres
export POSTGRES_PASSWORD=$(randomString16)

# outline 数据库账号
export OUTLINE_DB_USER=outline
export OUTLINE_DB_PASSWORD=$(randomString16)
export OUTLINE_DB_NAME=outline




################
## redis 相关配置
export REDIS_IP=172.16.0.20
# 密码随机
export REDIS_PASSWORD=$(randomString16)
export REDIS_DATA_DIR=./data
export REDIS_LOG_DIR=./logs


################
## minio 配置，这个可以用 阿里云oss、腾讯云cos等 s3兼容的对象存储替代
export MINIO_ENABLED=false
export MINIO_IP=172.16.0.30
export MINIO_PORT=9001
export MINIO_S3_PORT=9000
export MINIO_ROOT_USER=admin
export MINIO_ROOT_PASSWORD=$(randomString16)
export MINIO_DATA_DIR=./data

# minio的 控制台域名，这个可以登录、管理
export MINIO_DOMAIN_NAME=minio.${ROOT_DOMAIN_NAME}

# minio s3的域名，用于s3上传，登录不行
export MINIO_S3API_DOMAIN_NAME=minio-s3.${ROOT_DOMAIN_NAME}

# minio 创建的 accessKey 和 secretKey， 使用随机字符串，注意长度要求
# mc: <ERROR> Unable to add a new service account. The access key is invalid. (access key length should be between 3 and 20).
export MINIO_ADMIN_AK=$(randomString 16)
# mc: <ERROR> Unable to add a new service account. The secret key is invalid. (secret key length should be between 8 and 40).
export MINIO_ADMIN_SK=$(randomString 32)

# minio 自动创建的 bucket，用于 outline存储
export OUTLINE_MINIO_BUCKET=outline


################
## https-portal a fully automated SSL/TLS reverse proxy
export HTTPS_PORTAL_IP=172.16.0.40
export HTTPS_PORTAL_DATA_DIR=./data



################
## outline 的配置
export OUTLINE_IP=172.16.0.60
export OUTLINE_PORT=3000
export OUTLINE_DATA_DIR=./data

# outline 配置模板， 和 生存的配置文件， 模板文件中的 变量会用环境变量替换，写入到 outline.env 中
export OUTLINE_ENV_FILE_TEMPLATE=outline.env.template
# outline 容器启动时的 环境变量配置文件
export OUTLINE_ENV_FILE=outline.env

# outline 用的 key和 密钥  SECRET_KEY，UTILS_SECRET
export OUTLINE_SECRET_KEY=$(openssl rand -hex 32)
export OUTLINE_UTILS_SECRET=$(openssl rand -hex 32)
# outline的域名
export OUTLINE_DOMAIN_NAME=doc.${ROOT_DOMAIN_NAME}

# outline 的 url， 我们用https的
export OUTLINE_ROOT_URL=https://${OUTLINE_DOMAIN_NAME}

## 下面这些是 对象存储的配置， 这里用的是自己搭建的 minio，如果想用 阿里云oss、腾讯云cos，只要改下面的配置就行
export OUTLINE_S3_ACCESS_KEY_ID=${MINIO_ADMIN_AK}
export OUTLINE_S3_SECRET_ACCESS_KEY=${MINIO_ADMIN_SK}
# aliyun可以填 oss-cn-hangzhou
export OUTLINE_S3_REGION=cn
export OUTLINE_S3_UPLOAD_BUCKET_URL=https://${MINIO_S3API_DOMAIN_NAME}
# outline 用到的 S3 bucket
export OUTLINE_S3_UPLOAD_BUCKET_NAME=${OUTLINE_MINIO_BUCKET}


################
## drawio 配置
export DRAWIO_ENABLED=false
export DRAWIO_IP=172.16.0.70
export DRAWIO_PORT=8080
export DRAWIO_DOMAIN_NAME=drawio.${ROOT_DOMAIN_NAME}


################
## drist 配置
export GRIST_ENABLED=false
export GRIST_IP=172.16.0.80
export GRIST_PORT=8484
export GRIST_DATA_DIR=./persist
export GRIST_DOMAIN_NAME=drist.${ROOT_DOMAIN_NAME}
export GRIST_DEFAULT_EMAIL=${ADMIN_EMAIL}


################
## MailHog 配置
export MAILHOG_IP=172.16.0.90


################
## Ory Kratos (Identity Management)
export KRATOS_IP=172.16.0.51
export KRATOS_DOMAIN_NAME=login.${ROOT_DOMAIN_NAME}

# Kratos database credentials
export KRATOS_DB_USER=kratos
export KRATOS_DB_PASSWORD=$(randomString16)
export KRATOS_DB_NAME=kratos

# Kratos secrets
export KRATOS_SECRET_COOKIE=$(randomString 32)
export KRATOS_SECRET_CIPHER=$(randomString 32)


################
## Ory Hydra (OAuth2 & OpenID Connect Provider)
export HYDRA_IP=172.16.0.52
export HYDRA_DOMAIN_NAME=auth.${ROOT_DOMAIN_NAME}

# Hydra database credentials
export HYDRA_DB_USER=hydra
export HYDRA_DB_PASSWORD=$(randomString16)
export HYDRA_DB_NAME=hydra

# Hydra system secret
export HYDRA_SYSTEM_SECRET=$(randomString 32)

# Hydra client for Outline
export HYDRA_CLIENT_ID=outline-client
export HYDRA_CLIENT_SECRET=$(randomString 32)
