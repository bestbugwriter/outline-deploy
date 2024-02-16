# vps-deploy

## 介绍

outline的部署脚本。 使用 docker-compose管理。

使用自建的 nginxproxymanager管理各个服务的反向代理、自动申请https证书。

使用自建的 gitea 的 应用作为 outline的 oidc 认证提供商。不再使用 默认的slack。

使用自建的 minio 作为S3 提供商。可选，可以配置其他S3 提供商，比如 阿里云，腾讯云。

使用自建的 MySQL、Postgresql、Redis 容器作为数据存储。

### 组件

MySQL, https://www.mysql.com/

Postgresql, https://www.postgresql.org/

Redis, https://redis.io/

minio, https://min.io/

gitea, https://docs.gitea.com/

nginx proxy manager, https://nginxproxymanager.com/

outline, https://www.getoutline.com/

## 准备

#### 域名

需要有一个域名，阿里云、腾讯云都可以买。

需要建几个二级域名，并配置dns解析，用于站点访问。具体看 config.sh 中的 ROOT_DOMAIN_NAME 引用。

比如我有一个域名 abc.com

需要一个 gitea.abc.com, 用于gitea服务访问。

需要一个 outline.abc.com， 用于 outline 服务访问。

需要一个 minio-s3.abc.com，用于 s3 接口上传下载文件使用。

需要一个 minio.abc.com，用于 s3 web服务的访问（可选）。

## 部署

### 克隆部署仓库

`git clone git@github.com:bestbugwriter/outline-deploy.git
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
