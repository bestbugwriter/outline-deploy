# 配置重用机制 - 工作原理详解

## 问题

之前的实现：
```bash
export POSTGRES_PASSWORD=$(randomString16)
```

**问题**：每次执行 `config.sh` 都会重新生成密码，导致：
- ❌ 多次执行密码不一致
- ❌ 升级时覆盖生产环境密码
- ❌ 无法实现幂等性

## 解决方案

### 1. 启动时加载已有配置

```bash
# config.sh 开头添加
if [ -f "deploy.conf" ]; then
    echo "Found deploy.conf, loading existing configuration..."
    set -a              # 导出所有变量
    source deploy.conf  # 加载已有配置
    set +a              # 关闭自动导出
fi
```

**效果**：如果有 `deploy.conf`，先加载其中的所有配置。

### 2. 条件生成函数

```bash
# 新增 setIfEmpty 函数
function setIfEmpty() {
    local var_name=$1
    local var_value=$2
    # 只有当变量不存在或为空时才设置新值
    if [ -z "${!var_name}" ]; then
        export "$var_name=$var_value"
    fi
}
```

**用法对比**：

```bash
# 旧方式（总是重新生成）
export POSTGRES_PASSWORD=$(randomString16)

# 新方式（只在不存在时生成）
setIfEmpty POSTGRES_PASSWORD "$(randomString16)"
```

### 3. 完整流程

#### 首次部署流程

```
1. 执行 deploy.sh service
   ├─ source config.sh
   │  ├─ 检查 deploy.conf → 不存在
   │  ├─ 定义 setIfEmpty 函数
   │  └─ 为所有变量生成随机值
   │     ├─ setIfEmpty POSTGRES_PASSWORD "$(randomString16)"  → 生成
   │     ├─ setIfEmpty REDIS_PASSWORD "$(randomString16)"      → 生成
   │     └─ setIfEmpty RSSHUB_ACCESS_KEY "$(randomString16)"   → 生成
   │
   ├─ 部署服务...
   │
   └─ saveConfigToFile  → 保存到 deploy.conf
      POSTGRES_PASSWORD=abc123...
      REDIS_PASSWORD=def456...
      RSSHUB_ACCESS_KEY=ghi789...
```

#### 第二次执行流程

```
1. 执行 deploy.sh service
   ├─ source config.sh
   │  ├─ 检查 deploy.conf → 存在！
   │  ├─ 加载 deploy.conf
   │  │  ├─ POSTGRES_PASSWORD=abc123... ✓
   │  │  ├─ REDIS_PASSWORD=def456...    ✓
   │  │  └─ RSSHUB_ACCESS_KEY=ghi789... ✓
   │  │
   │  ├─ 定义 setIfEmpty 函数
   │  └─ 尝试设置变量
   │     ├─ setIfEmpty POSTGRES_PASSWORD "..."  → 跳过（已存在）
   │     ├─ setIfEmpty REDIS_PASSWORD "..."      → 跳过（已存在）
   │     └─ setIfEmpty RSSHUB_ACCESS_KEY "..."   → 跳过（已存在）
   │
   ├─ 部署服务...（使用已有密码）
   │
   └─ saveConfigToFile  → 保存到 deploy.conf（密码不变）
      POSTGRES_PASSWORD=abc123... ← 相同！
      REDIS_PASSWORD=def456...    ← 相同！
      RSSHUB_ACCESS_KEY=ghi789... ← 相同！
```

#### 升级场景流程（添加新服务）

```
旧版本 deploy.conf:
  POSTGRES_PASSWORD=abc123...
  REDIS_PASSWORD=def456...

新版本添加了 RSS 服务，需要新密码：
  RSSHUB_ACCESS_KEY
  FRESHRSS_ADMIN_PASSWORD

执行流程：
1. source config.sh
   ├─ 加载 deploy.conf
   │  ├─ POSTGRES_PASSWORD=abc123... ✓ (旧密码)
   │  └─ REDIS_PASSWORD=def456...    ✓ (旧密码)
   │
   └─ 设置变量
      ├─ setIfEmpty POSTGRES_PASSWORD "..."      → 跳过（已有）
      ├─ setIfEmpty REDIS_PASSWORD "..."         → 跳过（已有）
      ├─ setIfEmpty RSSHUB_ACCESS_KEY "..."      → 生成！（新增）
      └─ setIfEmpty FRESHRSS_ADMIN_PASSWORD "..." → 生成！（新增）

2. saveConfigToFile
   POSTGRES_PASSWORD=abc123...           ← 保留
   REDIS_PASSWORD=def456...              ← 保留
   RSSHUB_ACCESS_KEY=ghi789...           ← 新生成
   FRESHRSS_ADMIN_PASSWORD=jkl012...     ← 新生成
```

## 核心优势

### 1. 幂等性

```bash
# 多次执行结果一致
./deploy.sh service  # POSTGRES_PASSWORD=abc123
./deploy.sh service  # POSTGRES_PASSWORD=abc123 (相同)
./deploy.sh service  # POSTGRES_PASSWORD=abc123 (相同)
```

### 2. 安全升级

```bash
# 旧密码保持不变
Old: POSTGRES_PASSWORD=old123
升级后: POSTGRES_PASSWORD=old123  (保留)
       RSSHUB_ACCESS_KEY=new456   (新增)
```

### 3. 灵活重置

```bash
# 想重置某个密码？删除该行即可
vim deploy.conf
# 删除: POSTGRES_PASSWORD=abc123

source config.sh
# POSTGRES_PASSWORD 会重新生成
```

## 技术细节

### setIfEmpty 工作原理

```bash
setIfEmpty POSTGRES_PASSWORD "$(randomString16)"

# 等价于：
if [ -z "$POSTGRES_PASSWORD" ]; then
    export POSTGRES_PASSWORD="$(randomString16)"
fi
```

**注意**：虽然 `setIfEmpty` 不会设置已存在的变量，但 `$(randomString16)` 在调用函数前就会执行。这是 bash 的正常行为，不影响功能（只是有些许性能开销）。

### 变量间接引用

```bash
var_name="POSTGRES_PASSWORD"
${!var_name}  # 获取 POSTGRES_PASSWORD 的值
```

`setIfEmpty` 使用 `${!var_name}` 来检查变量是否存在。

### deploy.conf 加载

```bash
set -a              # 自动导出后续的所有变量
source deploy.conf  # 加载文件
set +a              # 关闭自动导出
```

`set -a` 确保 deploy.conf 中的变量都被导出到环境中。

## 测试验证

### 简单测试

```bash
# 创建测试
cat > test.sh << 'EOF'
source config.sh
FIRST=$POSTGRES_PASSWORD
source <(sed '/^main /,$d' deploy.sh)
saveConfigToFile
unset POSTGRES_PASSWORD
source config.sh
SECOND=$POSTGRES_PASSWORD
[ "$FIRST" = "$SECOND" ] && echo "✓ PASS" || echo "✗ FAIL"
EOF

bash test.sh
```

### 完整测试

```bash
./test_idempotency.sh
```

## 实际使用

### 场景1：全新部署

```bash
./deploy.sh service
# 自动生成所有密码并保存到 deploy.conf
```

### 场景2：升级部署

```bash
# 确保有 deploy.conf
ls -l deploy.conf

# 备份（推荐）
cp deploy.conf deploy.conf.backup

# 执行升级
./deploy.sh service
# 旧密码保留，新密码生成
```

### 场景3：重置单个密码

```bash
# 编辑 deploy.conf，删除要重置的密码行
vim deploy.conf
# 删除: POSTGRES_PASSWORD=xxx

# 重新生成
source config.sh
# 新密码会被生成

# 重启相关服务
./deploy.sh restart postgresql
```

### 场景4：完全重新开始

```bash
# 删除所有配置和数据
rm -f deploy.conf
rm -rf */data */logs

# 重新部署
./deploy.sh service
# 所有密码重新生成
```

## 总结

**核心思想**：
- 有 `deploy.conf` → 重用已有配置
- 无 `deploy.conf` → 生成新配置
- 部分配置 → 补充缺失的配置

**关键函数**：
- `setIfEmpty` → 条件设置变量
- `saveConfigToFile` → 保存配置

**实现效果**：
- ✅ 幂等性
- ✅ 安全升级
- ✅ 灵活重置
- ✅ 向后兼容

这就是配置重用机制的完整工作原理！
