# RSS 服务配置

本目录包含三个 RSS 相关服务的配置：

## 服务说明

### 1. RSSHub
- **容器名**: rsshub
- **镜像**: diygod/rsshub
- **端口**: 1200
- **IP地址**: 由 `RSSHUB_IP` 变量配置（默认: 172.16.0.90）
- **功能**: 万物皆可 RSS，将各种网站转换为 RSS 订阅源
- **依赖**: Redis（用于缓存）、Browserless（用于渲染 JavaScript 页面）

**访问密钥**: 
- `ACCESS_KEY` 在 config.sh 中自动随机生成
- 健康检查地址: `http://<RSSHUB_IP>:1200/healthz?key=<ACCESS_KEY>`

**Telegram 配置**:
- `TELEGRAM_SESSION` 和 `TELEGRAM_TOKEN` 需要手动在 deploy.conf 中配置
- 如不使用 Telegram 功能，可保持为空

### 2. Browserless
- **容器名**: browserless
- **镜像**: browserless/chrome
- **端口**: 3000
- **IP地址**: 由 `BROWSERLESS_IP` 变量配置（默认: 172.16.0.91）
- **功能**: 提供无头 Chrome 浏览器服务，供 RSSHub 使用
- **健康检查**: `http://<BROWSERLESS_IP>:3000/pressure`

### 3. FreshRSS
- **容器名**: freshrss
- **镜像**: freshrss/freshrss
- **端口**: 80
- **IP地址**: 由 `FRESHRSS_IP` 变量配置（默认: 172.16.0.92）
- **功能**: RSS 阅读器和聚合器
- **数据库**: PostgreSQL（使用现有的 PostgreSQL 实例）

**默认管理员账号**:
- 用户名: admin
- 密码: 在 deploy.conf 中查看 `FRESHRSS_ADMIN_PASSWORD`

**数据持久化**:
- 文章数据: `./fr-data`
- 扩展插件: `./fr-extensions`

## 部署

这些服务会在运行 `deploy.sh service` 时自动部署（需要添加到部署流程中）。

手动部署：
```bash
cd /path/to/project
source config.sh
cd rss
docker compose up -d
```

## 配置文件

所有配置变量在 `config.sh` 中定义：

- `RSSHUB_IP`, `RSSHUB_PORT`, `RSSHUB_ACCESS_KEY`
- `BROWSERLESS_IP`, `BROWSERLESS_PORT`
- `FRESHRSS_IP`, `FRESHRSS_PORT`, `FRESHRSS_ADMIN_PASSWORD`
- `FRESHRSS_DB_*` (数据库配置)
- `TELEGRAM_SESSION`, `TELEGRAM_TOKEN` (可选)

部署后，这些配置会保存到 `deploy.conf` 文件中，方便下次部署时重用。

## 注意事项

1. **首次部署**: PostgreSQL 会自动创建 FreshRSS 数据库和用户
2. **Redis 依赖**: RSSHub 使用项目现有的 Redis 实例进行缓存
3. **网络**: 所有服务都连接到 `br0` 网络，IP 地址为静态分配
4. **Telegram 功能**: 如需使用 RSSHub 的 Telegram 相关功能，需要手动配置 `TELEGRAM_SESSION` 和 `TELEGRAM_TOKEN`
