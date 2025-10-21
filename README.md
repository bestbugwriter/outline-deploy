# vps-deploy

## 介绍

outline的部署脚本。 使用 docker-compose管理。

使用自建的 https-portal 管理各个服务的反向代理、自动申请 https 证书。

使用 Ory Hydra + Ory Kratos 作为 Outline 的 OIDC 认证提供商。不再使用默认的 Slack。

使用自建的 minio 作为 S3 提供商。可选，可以配置其他 S3 提供商，比如 阿里云，腾讯云。

使用自建的 MySQL、Postgresql、Redis 容器作为数据存储。

### 组件

MySQL, https://www.mysql.com/

Postgresql, https://www.postgresql.org/

Redis, https://redis.io/

MinIO, https://min.io/

Ory Hydra, https://www.ory.sh/hydra/

Ory Kratos, https://www.ory.sh/kratos/

https-portal, https://github.com/SteveLTN/https-portal

Outline, https://www.getoutline.com/

## 准备

#### 域名

需要有一个域名，阿里云、腾讯云都可以买。

需要建几个二级域名，并配置dns解析，用于站点访问。具体看 config.sh 中的 ROOT_DOMAIN_NAME 引用。

比如我有一个域名 abc.com

需要一个 auth.abc.com， 用于 OIDC 发行人（Hydra public）。

需要一个 auth-ui.abc.com， 用于 Hydra 登录/授权页面。

需要一个 login.abc.com， 用于 Kratos 自助账户页面（注册/登录/设置等）。

需要一个 outline.abc.com， 用于 Outline 服务访问。

需要一个 minio-s3.abc.com，用于 S3 接口上传下载文件使用。

需要一个 minio.abc.com，用于 S3 Web 服务的访问（可选）。

## 部署

### 克隆部署仓库

`git clone https://github.com/bestbugwriter/outline-deploy.git
`

### 部署所有服务

`./deploy all
`

最后打印出访问服务的关键信息。

## 其他运维

##### 单独部署docker

`./deploy docker
`

##### 单独部署服务

`./deploy service
`

##### 组件重启

`./deploy restart 组件
`

#### 升级outline


修改 outline的 docker-compose.yml中的镜像tag，然后 source config.sh，进入到 outline目录  执行 
docker compose up --force-recreate outline -d

https://github.com/outline/outline/discussions/6919#discussioncomment-9519087 
