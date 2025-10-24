# Config.sh 配置重用指南

## 问题背景

在之前的版本中，每次执行 `config.sh` 都会重新生成随机密码，导致：
1. 多次执行密码不一致
2. 升级时会覆盖生产环境的密码
3. 无法实现配置的幂等性

## 解决方案

现在 `config.sh` 实现了智能的配置重用机制：

### 工作原理

1. **首次执行**：
   - 检测到没有 `deploy.conf`
   - 生成所有随机密码
   - 部署完成后保存到 `deploy.conf`

2. **后续执行**：
   - 自动加载已有的 `deploy.conf`
   - 重用所有已存在的密码
   - 只为新增的变量生成密码

### 实现细节

```bash
# config.sh 开头会先加载已有配置
if [ -f "deploy.conf" ]; then
    echo "Found deploy.conf, loading existing configuration to preserve passwords..."
    set -a
    source deploy.conf
    set +a
fi

# 使用 setIfEmpty 函数，只在变量不存在时才生成新值
setIfEmpty POSTGRES_PASSWORD "$(randomString16)"
setIfEmpty REDIS_PASSWORD "$(randomString16)"
setIfEmpty RSSHUB_ACCESS_KEY "$(randomString16)"
```

## 使用场景

### 场景 1: 全新部署

```bash
# 第一次部署
./deploy.sh service

# deploy.conf 会被创建，包含所有生成的密码
# 以后每次执行都会重用这些密码
```

### 场景 2: 已有环境升级

假设你已经部署了旧版本，现在要添加 RSS 服务：

```bash
# 你的 deploy.conf 已经存在，包含：
# POSTGRES_PASSWORD=old_password_123
# REDIS_PASSWORD=old_redis_456
# ... 其他旧配置

# 执行升级
./deploy.sh service

# 结果：
# - 旧密码保持不变（从 deploy.conf 加载）
# - 新增的 RSS 服务密码会被生成：
#   RSSHUB_ACCESS_KEY=<新生成>
#   FRESHRSS_ADMIN_PASSWORD=<新生成>
#   FRESHRSS_DB_PASSWORD=<新生成>
```

### 场景 3: 重新部署（幂等性）

```bash
# 第一次部署
./deploy.sh service
# 生成密码：POSTGRES_PASSWORD=abc123...

# 第二次执行（例如修改配置后）
./deploy.sh service
# 密码保持不变：POSTGRES_PASSWORD=abc123...（从 deploy.conf 加载）
```

## 密码管理最佳实践

### 1. 备份 deploy.conf

```bash
# 部署成功后，立即备份配置
cp deploy.conf deploy.conf.backup.$(date +%Y%m%d)

# 或保存到安全的地方
cp deploy.conf /secure/location/outline-deploy-backup.conf
```

### 2. 如果需要重置某个密码

```bash
# 编辑 deploy.conf，删除要重置的密码行
vim deploy.conf
# 删除这行：POSTGRES_PASSWORD=old_password

# 再次执行 config.sh，会生成新密码
source config.sh
# 新密码会被生成：POSTGRES_PASSWORD=<新值>
```

### 3. 手动修改密码

```bash
# 直接编辑 deploy.conf
vim deploy.conf

# 修改密码
POSTGRES_PASSWORD=my_custom_password

# 重新部署时会使用你的自定义密码
./deploy.sh restart postgresql
```

### 4. 完全重新开始

```bash
# 删除 deploy.conf 和所有数据
rm -f deploy.conf
rm -rf */data */logs

# 重新部署，所有密码都会重新生成
./deploy.sh service
```

## 测试验证

项目包含了两个测试脚本来验证功能：

```bash
# 简单测试
./test_config_reuse.sh

# 完整场景测试
./test_full_workflow.sh
```

## 技术实现

### setIfEmpty 函数

```bash
function setIfEmpty() {
    local var_name=$1
    local var_value=$2
    # 只有当变量不存在或为空时才设置新值
    if [ -z "${!var_name}" ]; then
        export "$var_name=$var_value"
    fi
}
```

### 使用示例

```bash
# 旧方式（每次都重新生成）
export POSTGRES_PASSWORD=$(randomString16)

# 新方式（只在不存在时生成）
setIfEmpty POSTGRES_PASSWORD "$(randomString16)"
```

## 兼容性

- ✅ 兼容旧版本的 deploy.conf
- ✅ 如果没有 deploy.conf，行为与旧版本完全相同
- ✅ 支持增量添加新配置项
- ✅ 多次执行保证幂等性

## 常见问题

### Q: 我的旧 deploy.conf 还能用吗？

A: 完全可以！新版本会自动加载并重用旧配置中的所有密码。

### Q: 如果我想更改某个密码怎么办？

A: 有两种方式：
1. 直接编辑 `deploy.conf` 修改密码
2. 删除 `deploy.conf` 中的该行，重新运行会生成新密码

### Q: deploy.conf 丢失了怎么办？

A: 如果数据库等服务已经在运行，你需要：
1. 尝试从备份恢复 deploy.conf
2. 或者手动创建 deploy.conf，填入与数据库中相同的密码
3. 最坏情况：删除所有数据，重新部署

### Q: 为什么有时候随机函数还是会执行？

A: 虽然 `setIfEmpty` 不会设置已存在的变量，但 `$(randomString16)` 在调用函数前就会执行。这不影响功能（旧值仍会被保留），只是会有一些不必要的计算。这是 bash 的正常行为。

### Q: 升级后需要重启服务吗？

A: 看情况：
- 如果只是添加新服务（如 RSS 服务）：不需要重启旧服务
- 如果修改了已有服务的密码：需要重启该服务
- 如果只是添加新的配置项：不需要重启

## 总结

新的配置重用机制确保了：
- ✅ **安全性**：密码不会意外改变
- ✅ **幂等性**：多次执行结果一致
- ✅ **可维护性**：易于理解和管理
- ✅ **升级友好**：平滑添加新功能
- ✅ **向后兼容**：不影响旧版本使用
