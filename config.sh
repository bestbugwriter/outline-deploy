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
# mysql 配置
export MYSQL_IP=172.16.0.10
# mysql root密码
export MYSQL_ROOT_PASSWORD=$(randomString16)
export MYSQL_DATA_DIR=./data

# 使用到的两个 db，一个给 gitea用，一个给 nginx proxy manager用
export MYSQL_GITEA_DB=gitea
export MYSQL_NPM_DB=npm

# 默认的 MySQL账号， 密码随机
export MYSQL_USER=base
export MYSQL_PASSWORD=$(randomString16)


################
# postgresql 配置
export POSTGRES_IP=172.16.0.11
export POSTGRES_DB=outline
export POSTGRES_DATA_DIR=./data
# 密码随机
export POSTGRES_USER=outline
export POSTGRES_PASSWORD=$(randomString16)


################
## redis 相关配置
export REDIS_IP=172.16.0.20
# 密码随机
export REDIS_PASSWORD=$(randomString16)
export REDIS_DATA_DIR=./data
export REDIS_LOG_DIR=./logs


################
## minio 配置，这个可以用 阿里云oss、腾讯云cos等 s3兼容的对象存储替代
export MINIO_ENABLED=true
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
## nginx proxy manager 相关的配置
export NPM_IP=172.16.0.40
export NPM_DATA_DIR=./data
export NPM_LETSENCRYPT_DIR=./letsencrypt

# nginx proxy manager 使用 mysql 作为存储
export NPM_DB_HOST=${MYSQL_IP}
export NPM_DB_PORT=3306
export NPM_DB_USER=${MYSQL_USER}
export NPM_DB_PASSWORD=${MYSQL_PASSWORD}
export NPM_DB_NAME=${MYSQL_NPM_DB}

# nginx proxy manager 默认的 用户名密码， 需要在首次登录后修改
export NPM_ADMIN_USER_DEFAULT=admin@example.com
export NPM_ADMIN_PASSWORD_DEFAULT=changeme

# nginx proxy manager 首次登录后，用户名改成自己的邮箱，密码随机 16位字符
export NPM_ADMIN_USER=${ADMIN_EMAIL}
export NPM_ADMIN_PASSWORD=$(randomString16)


################
## gitea相关的配置，主要用于做一个 oidc的认证服务
export GITEA_IP=172.16.0.50
export GITEA_PORT=3000
export GITEA_DATA_DIR=./data

# gitea的 db配置，默认用的 mysql
export GITEA_DB_TYPE=mysql
export GITEA_DB_HOST=${MYSQL_IP}:3306
export GITEA_DB_NAME=${MYSQL_GITEA_DB}
export GITEA_DB_USER=${MYSQL_USER}
export GITEA_DB_PASSWD=${MYSQL_PASSWORD}
export GITEA_DOMAIN_NAME=gitea.${ROOT_DOMAIN_NAME}

# gitea中 创建的 app名称
export GITEA_APP_NAME=outline

# 注册时不能用 admin作为管理员账号，这是保留值
export GITEA_ADMIN_USER=root
export GITEA_ADMIN_PASSWORD=$(randomString16)
export GITEA_ADMIN_EMAIL=${ADMIN_EMAIL}


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
export OUTLINE_DOMAIN_NAME=outline.${ROOT_DOMAIN_NAME}

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
