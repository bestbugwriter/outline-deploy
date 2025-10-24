# 升级说明 - 配置重用功能

## 重要变更

本次更新对 `config.sh` 进行了重大改进，添加了**配置重用机制**，解决了多次执行密码不一致的问题。

## 升级前必读

### 如果你是全新部署

✅ 无需特别操作，直接按照常规流程部署即可：

```bash
./deploy.sh service
```

### 如果你已经有运行中的环境

⚠️ **重要**：升级前请确保你有 `deploy.conf` 文件！

#### 情况 1: 已有 deploy.conf

✅ 完美！你可以安全升级：

```bash
# 1. 备份现有配置
cp deploy.conf deploy.conf.backup

# 2. 拉取新代码
git pull

# 3. 部署（会自动重用旧密码）
./deploy.sh service
```

**结果**：
- 所有旧密码保持不变
- 新增的 RSS 服务会生成新密码
- PostgreSQL 会自动创建 FreshRSS 数据库

#### 情况 2: 没有 deploy.conf

⚠️ **需要手动创建**：

如果你之前部署但没有 deploy.conf，需要手动创建一个包含当前密码的文件：

```bash
# 创建 deploy.conf
cat > deploy.conf << EOF
# 填入你当前使用的密码（从容器环境变量或数据库配置中获取）
POSTGRES_PASSWORD=<你的实际密码>
REDIS_PASSWORD=<你的实际密码>
GITEA_ADMIN_PASSWORD=<你的实际密码>
GITEA_DB_PASSWD=<你的实际密码>
OUTLINE_DB_PASSWORD=<你的实际密码>
OUTLINE_SECRET_KEY=<你的实际密钥>
OUTLINE_UTILS_SECRET=<你的实际密钥>
# ... 其他你已在使用的配置
EOF

# 然后再升级
./deploy.sh service
```

如何获取当前密码？

```bash
# 从运行中的容器获取
docker exec postgres env | grep POSTGRES_PASSWORD
docker exec redis redis-cli CONFIG GET requirepass

# 或从数据库连接测试
docker exec -it postgres psql -U postgres -c "\du"
```

## 变更详情

### 1. config.sh 改进

**新增功能**：
- 启动时自动加载已有的 `deploy.conf`
- 使用 `setIfEmpty` 函数确保已有值不被覆盖
- 只为新增配置项生成密码

**技术实现**：
```bash
# 在文件开头添加了
if [ -f "deploy.conf" ]; then
    echo "Found deploy.conf, loading existing configuration to preserve passwords..."
    set -a
    source deploy.conf
    set +a
fi
```

### 2. deploy.sh 改进

**已有功能**（之前已实现）：
- `saveConfigToFile()` 函数替代 `env > deploy.conf`
- 只导出 config.sh 中定义的变量
- deploy.conf 文件更简洁、易维护

### 3. 新增 RSS 服务

- RSSHub: RSS 源生成器
- Browserless: 无头浏览器服务
- FreshRSS: RSS 阅读器
- 自动创建 PostgreSQL 数据库

## 升级后验证

### 1. 检查密码是否保持不变

```bash
# 查看 deploy.conf
cat deploy.conf | grep PASSWORD

# 验证数据库连接
docker exec -it postgres psql -U postgres -c "SELECT 1"
```

### 2. 检查新服务是否正常

```bash
# 查看 RSS 服务状态
cd rss
docker compose ps

# 查看日志
docker compose logs -f
```

### 3. 验证新密码已生成

```bash
# 查看 RSS 服务密码
grep RSSHUB_ACCESS_KEY deploy.conf
grep FRESHRSS_ADMIN_PASSWORD deploy.conf
grep FRESHRSS_DB_PASSWORD deploy.conf
```

## 回滚方案

如果升级后遇到问题，可以回滚：

```bash
# 1. 停止新服务
cd rss
docker compose down

# 2. 恢复旧配置
cp deploy.conf.backup deploy.conf

# 3. 切换到旧版本代码
git checkout <旧版本tag或commit>

# 4. 重启服务
./deploy.sh restart postgresql
./deploy.sh restart redis
```

## 兼容性说明

- ✅ 完全兼容旧版本的 deploy.conf
- ✅ 如果没有 deploy.conf，行为与旧版本相同（全部生成新密码）
- ✅ 不影响已运行的服务
- ✅ 可以增量添加新配置

## 常见升级问题

### Q: 升级后数据库连接失败

A: 检查 deploy.conf 中的密码是否与实际运行的密码一致：

```bash
# 测试 PostgreSQL
docker exec postgres psql -U postgres -c "\l"

# 测试 Redis
docker exec redis redis-cli -a "$REDIS_PASSWORD" PING
```

### Q: RSS 服务无法连接数据库

A: 确保 PostgreSQL 容器已重启以创建新数据库：

```bash
# 重启 PostgreSQL（会执行 init-db.sh）
./deploy.sh restart postgresql

# 检查数据库是否创建
docker exec postgres psql -U postgres -c "\l" | grep freshrss
```

### Q: 想重新生成某个密码

A: 编辑 deploy.conf，删除该密码行，然后重新运行：

```bash
# 删除要重置的密码
vim deploy.conf
# 删除: RSSHUB_ACCESS_KEY=xxx

# 重新生成
source config.sh
cd rss
docker compose restart rsshub
```

## 技术支持

如有问题，请：
1. 查看 [CONFIG_REUSE_GUIDE.md](./CONFIG_REUSE_GUIDE.md) 详细文档
2. 查看 [CHANGES.md](./CHANGES.md) 了解所有变更
3. 查看 [rss/README.md](./rss/README.md) 了解 RSS 服务配置

## 总结

本次升级的核心改进：
- ✅ **安全性提升**：密码不会意外改变
- ✅ **幂等性保证**：多次执行结果一致
- ✅ **平滑升级**：不影响已有服务
- ✅ **新增功能**：RSS 服务套件

只要你有 deploy.conf 备份，升级就是完全安全的！
