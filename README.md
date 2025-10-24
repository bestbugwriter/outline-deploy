# vps-deploy

## 介绍

Outline 知识库的 Docker 部署方案，包含所需的所有服务。

**核心特性**：
- 🔐 配置自动重用 - 升级时密码不会改变
- 📦 一键部署 - 所有服务自动配置
- 🔒 HTTPS 自动化 - https-portal 自动申请证书
- 🎯 OIDC 认证 - 使用自建 Gitea
- 📊 可选服务 - Minio/Drawio/Grist/RSS 按需启用

**服务组件**：
- **PostgreSQL** - 数据库
- **Redis** - 缓存
- **Gitea** - OIDC 认证提供商
- **Minio** - S3 对象存储（可选）
- **https-portal** - 反向代理和 HTTPS
- **Outline** - 知识库主服务
- **RSS 套件** - RSSHub + Browserless + FreshRSS（可选，新增）

## 📢 最新更新

### v2.0 - 配置重用机制 + RSS 服务
- ✅ **配置自动重用**：升级时旧密码自动保留，新密码自动生成
- ✅ **RSS 服务套件**：RSSHub + Browserless + FreshRSS
- ✅ **统一开关管理**：所有可选服务通过 `*_ENABLED` 控制

**查看详情**：[更新说明.md](./更新说明.md)

## 准备

#### 域名

需要有一个域名，阿里云、腾讯云都可以买。

需要建几个二级域名，并配置dns解析，用于站点访问。具体看 config.sh 中的 ROOT_DOMAIN_NAME 引用。

比如我有一个域名 abc.com

需要一个 gitea.abc.com, 用于gitea服务访问。

需要一个 outline.abc.com， 用于 outline 服务访问。

需要一个 minio-s3.abc.com，用于 s3 接口上传下载文件使用。（可选）

需要一个 minio.abc.com，用于 s3 web服务的访问（可选）。

## 快速开始

### 1. 克隆仓库
```bash
git clone https://github.com/bestbugwriter/outline-deploy.git
cd outline-deploy
```

### 2. 配置域名
编辑 `config.sh`，修改域名和邮箱：
```bash
export ROOT_DOMAIN_NAME=你的域名.com
export ADMIN_EMAIL=你的邮箱@example.com
```

### 3. 启用可选服务（可选）
```bash
# 启用 RSS 服务
export RSS_ENABLED=true

# 启用 Minio 对象存储
export MINIO_ENABLED=true
```

### 4. 部署
```bash
# 全新部署（包括安装 Docker）
./deploy.sh all

# 或只部署服务（Docker 已安装）
./deploy.sh service
```

### 5. 访问服务
部署完成后会显示访问地址和密码：
- Outline: `https://outline.你的域名.com`
- Gitea: `https://gitea.你的域名.com`
- FreshRSS: `http://服务器IP:92` (如已启用)

密码保存在 `deploy.conf` 文件中。

## 常用命令

```bash
# 重启某个服务
./deploy.sh restart postgresql
./deploy.sh restart redis
./deploy.sh restart outline

# 查看所有容器状态
docker ps

# 查看服务日志
docker compose -f outline/docker-compose.yml logs -f
docker compose -f rss/docker-compose.yml logs -f

# 查看配置密码
cat deploy.conf | grep PASSWORD
```

## 升级说明

### 升级现有环境
```bash
# 1. 备份配置（重要！）
cp deploy.conf deploy.conf.backup

# 2. 拉取最新代码
git pull

# 3. 部署（自动保留旧密码）
./deploy.sh service
```

### 升级 Outline 版本
```bash
# 1. 修改 outline/docker-compose.yml 中的镜像 tag
vim outline/docker-compose.yml
# 例如：image: outlinewiki/outline:0.79.0

# 2. 重新部署
source config.sh
cd outline
docker compose up --force-recreate outline -d
```

参考：https://github.com/outline/outline/discussions/6919#discussioncomment-9519087

## 相关文档

- **[更新说明.md](./更新说明.md)** - 配置重用机制和 RSS 服务详情
- **[rss/README.md](./rss/README.md)** - RSS 服务说明
- **[rss/快速开始.md](./rss/快速开始.md)** - RSS 服务使用指南

## 故障排查

### 配置文件丢失
```bash
# 如果 deploy.conf 丢失，但服务还在运行
# 可以从容器中提取密码
docker exec postgres env | grep PASSWORD
docker exec redis redis-cli CONFIG GET requirepass
```

### 服务无法启动
```bash
# 查看详细日志
docker compose -f <服务目录>/docker-compose.yml logs

# 检查端口占用
netstat -tulpn | grep <端口号>

# 检查网络
docker network ls
```

### 数据库连接失败
```bash
# 重启 PostgreSQL（会重新执行初始化脚本）
./deploy.sh restart postgresql

# 检查数据库列表
docker exec postgres psql -U postgres -c "\l"
```

## 项目结构

```
.
├── config.sh              # 配置文件
├── deploy.sh              # 部署脚本
├── deploy.conf            # 生成的配置（包含密码）
├── postgresql/            # PostgreSQL 服务
├── redis/                 # Redis 服务
├── gitea/                 # Gitea 服务
├── minio/                 # Minio 服务（可选）
├── outline/               # Outline 服务
├── https-portal/          # HTTPS 反向代理
├── drawio/                # Draw.io（可选）
├── grist/                 # Grist（可选）
└── rss/                   # RSS 服务（可选）
    ├── docker-compose.yml
    ├── README.md
    └── 快速开始.md
```

## License

MIT
