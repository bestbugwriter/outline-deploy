# 📖 文档索引 - 从这里开始

## 🚀 快速开始

**如果你是第一次使用**，按以下顺序阅读：

1. **[README_CHANGES.md](./README_CHANGES.md)** ⭐ 从这里开始！了解本次更新内容
2. **[UPGRADE_NOTES.md](./UPGRADE_NOTES.md)** ⭐ 升级指南（如果你已有环境）

## 📚 详细文档

根据你的需求选择：

### 配置和部署
- **[CONFIG_REUSE_GUIDE.md](./CONFIG_REUSE_GUIDE.md)** - 配置重用机制详解
- **[HOW_IT_WORKS.md](./HOW_IT_WORKS.md)** - 技术实现原理

### RSS 服务
- **[rss/README.md](./rss/README.md)** - RSS 服务说明
- **[rss/QUICKSTART.md](./rss/QUICKSTART.md)** - RSS 快速开始

### 参考资料
- **[CHANGES.md](./CHANGES.md)** - 详细变更记录
- **[FINAL_SUMMARY.md](./FINAL_SUMMARY.md)** - 完整总结

## 🎯 根据场景选择文档

### 场景 1: 我想快速了解改了什么
👉 阅读 [README_CHANGES.md](./README_CHANGES.md) （3分钟）

### 场景 2: 我要升级现有环境
👉 阅读 [UPGRADE_NOTES.md](./UPGRADE_NOTES.md) （5分钟）

### 场景 3: 我想了解配置重用怎么工作的
👉 阅读 [HOW_IT_WORKS.md](./HOW_IT_WORKS.md) （10分钟）

### 场景 4: 我要部署 RSS 服务
👉 阅读 [rss/QUICKSTART.md](./rss/QUICKSTART.md) （5分钟）

### 场景 5: 我想看完整的技术细节
👉 阅读 [CONFIG_REUSE_GUIDE.md](./CONFIG_REUSE_GUIDE.md) + [FINAL_SUMMARY.md](./FINAL_SUMMARY.md) （20分钟）

## ⚡ 最快上手方式

```bash
# 全新部署
./deploy.sh service

# 已有环境升级
cp deploy.conf deploy.conf.backup  # 备份配置
git pull                            # 拉取新代码
./deploy.sh service                 # 部署（自动重用旧密码）
```

## 🆘 遇到问题？

1. 查看 [UPGRADE_NOTES.md](./UPGRADE_NOTES.md) 的常见问题部分
2. 运行测试脚本：`./test_idempotency.sh`
3. 检查日志：`docker compose logs -f`

---

**提示**：不要被文档数量吓到！选择适合你场景的文档即可。
