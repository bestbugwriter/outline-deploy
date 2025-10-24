# 📢 重要更新说明

## 🎉 新功能

### 1. RSS 服务套件
新增三个 RSS 相关服务，提供完整的 RSS 解决方案。

### 2. 配置重用机制（重要！）
**解决了密码管理的核心问题**：现在 `config.sh` 会自动重用 `deploy.conf` 中的已有密码，不会每次都重新生成。

## 🚀 快速上手

### 如果你是全新部署
直接运行：
```bash
./deploy.sh service
```

### 如果你已有运行中的环境
**必读**：请确保你有 `deploy.conf` 文件！

```bash
# 1. 备份现有配置
cp deploy.conf deploy.conf.backup

# 2. 拉取新代码
git pull

# 3. 部署（会自动重用旧密码）
./deploy.sh service
```

## 📚 详细文档

- **[CONFIG_REUSE_GUIDE.md](./CONFIG_REUSE_GUIDE.md)** - 配置重用完整指南 ⭐
- **[UPGRADE_NOTES.md](./UPGRADE_NOTES.md)** - 升级说明和注意事项 ⭐
- **[FINAL_SUMMARY.md](./FINAL_SUMMARY.md)** - 完整总结
- **[CHANGES.md](./CHANGES.md)** - 详细变更记录
- **[rss/README.md](./rss/README.md)** - RSS 服务说明
- **[rss/QUICKSTART.md](./rss/QUICKSTART.md)** - RSS 快速开始

## 🧪 测试

运行幂等性测试，验证配置重用功能：
```bash
./test_idempotency.sh
```

## ❓ 常见问题

### Q: 配置重用是什么意思？
A: 现在执行 `config.sh` 会先加载已有的 `deploy.conf`，重用其中的密码，只为新增的配置项生成密码。这样：
- ✅ 密码不会意外改变
- ✅ 多次执行结果一致
- ✅ 升级时安全可靠

### Q: 我的旧环境会受影响吗？
A: 不会！只要你有 `deploy.conf` 文件，所有旧密码都会被保留。

### Q: 如何查看生成的密码？
A: 查看 `deploy.conf` 文件：
```bash
cat deploy.conf
grep FRESHRSS_ADMIN_PASSWORD deploy.conf
```

## 🔥 核心改进

**之前**：
```bash
# 每次执行都重新生成密码
export POSTGRES_PASSWORD=$(randomString16)
# 结果：每次都不同，无法重用
```

**现在**：
```bash
# 只在变量不存在时才生成
setIfEmpty POSTGRES_PASSWORD "$(randomString16)"
# 结果：有 deploy.conf 就重用，没有就生成
```

## ⚠️ 重要提醒

1. **一定要备份 deploy.conf** - 这是你所有密码的唯一记录
2. **不要提交 deploy.conf 到 git** - 已在 .gitignore 中
3. **升级前先备份** - `cp deploy.conf deploy.conf.backup`

## 📊 本次更新统计

- 新增服务：3 个（RSSHub, Browserless, FreshRSS）
- 新增配置：17 个环境变量
- 核心改进：配置重用机制
- 新增文档：6 个 Markdown 文件
- 修改文件：5 个
- 测试通过：✅ 幂等性测试、语法检查、Docker Compose 验证

---

**需要帮助？** 查看详细文档或运行测试脚本！
