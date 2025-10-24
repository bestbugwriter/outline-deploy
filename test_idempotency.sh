#!/bin/bash
# 幂等性测试：验证多次执行 config.sh 产生相同的结果

cd /home/engine/project

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║            Config.sh 幂等性测试                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# 清理环境
rm -f deploy.conf

echo "=== 第一次执行 config.sh（生成新密码）==="
source config.sh >/dev/null 2>&1

# 保存所有密码
PASS1_POSTGRES=$POSTGRES_PASSWORD
PASS1_REDIS=$REDIS_PASSWORD
PASS1_RSSHUB=$RSSHUB_ACCESS_KEY
PASS1_FRESHRSS=$FRESHRSS_ADMIN_PASSWORD
PASS1_OUTLINE_SECRET=$OUTLINE_SECRET_KEY
PASS1_GITEA=$GITEA_ADMIN_PASSWORD

echo "生成的密码:"
echo "  POSTGRES_PASSWORD: $PASS1_POSTGRES"
echo "  REDIS_PASSWORD: $PASS1_REDIS"
echo "  RSSHUB_ACCESS_KEY: $PASS1_RSSHUB"
echo "  FRESHRSS_ADMIN_PASSWORD: $PASS1_FRESHRSS"
echo "  GITEA_ADMIN_PASSWORD: $PASS1_GITEA"
echo "  OUTLINE_SECRET_KEY: ${PASS1_OUTLINE_SECRET:0:20}...${PASS1_OUTLINE_SECRET:(-10)}"
echo ""

# 模拟 deploy.sh 保存配置
echo "=== 保存配置到 deploy.conf ==="
source <(sed '/^main /,$d' deploy.sh)
saveConfigToFile >/dev/null
echo "✓ 已保存 $(wc -l < deploy.conf) 行配置"
echo ""

# 清除当前环境变量
echo "=== 清除当前环境变量 ==="
unset POSTGRES_PASSWORD REDIS_PASSWORD RSSHUB_ACCESS_KEY FRESHRSS_ADMIN_PASSWORD OUTLINE_SECRET_KEY GITEA_ADMIN_PASSWORD
echo "✓ 环境变量已清除"
echo ""

echo "=== 第二次执行 config.sh（从 deploy.conf 加载）==="
source config.sh 2>&1 | head -1

# 保存第二次的密码
PASS2_POSTGRES=$POSTGRES_PASSWORD
PASS2_REDIS=$REDIS_PASSWORD
PASS2_RSSHUB=$RSSHUB_ACCESS_KEY
PASS2_FRESHRSS=$FRESHRSS_ADMIN_PASSWORD
PASS2_OUTLINE_SECRET=$OUTLINE_SECRET_KEY
PASS2_GITEA=$GITEA_ADMIN_PASSWORD

echo "加载的密码:"
echo "  POSTGRES_PASSWORD: $PASS2_POSTGRES"
echo "  REDIS_PASSWORD: $PASS2_REDIS"
echo "  RSSHUB_ACCESS_KEY: $PASS2_RSSHUB"
echo "  FRESHRSS_ADMIN_PASSWORD: $PASS2_FRESHRSS"
echo "  GITEA_ADMIN_PASSWORD: $PASS2_GITEA"
echo "  OUTLINE_SECRET_KEY: ${PASS2_OUTLINE_SECRET:0:20}...${PASS2_OUTLINE_SECRET:(-10)}"
echo ""

# 验证
echo "=== 验证结果 ==="
SUCCESS=true

if [ "$PASS1_POSTGRES" = "$PASS2_POSTGRES" ]; then
    echo "✓ POSTGRES_PASSWORD 一致"
else
    echo "✗ POSTGRES_PASSWORD 不一致！($PASS1_POSTGRES != $PASS2_POSTGRES)"
    SUCCESS=false
fi

if [ "$PASS1_REDIS" = "$PASS2_REDIS" ]; then
    echo "✓ REDIS_PASSWORD 一致"
else
    echo "✗ REDIS_PASSWORD 不一致！"
    SUCCESS=false
fi

if [ "$PASS1_RSSHUB" = "$PASS2_RSSHUB" ]; then
    echo "✓ RSSHUB_ACCESS_KEY 一致"
else
    echo "✗ RSSHUB_ACCESS_KEY 不一致！"
    SUCCESS=false
fi

if [ "$PASS1_FRESHRSS" = "$PASS2_FRESHRSS" ]; then
    echo "✓ FRESHRSS_ADMIN_PASSWORD 一致"
else
    echo "✗ FRESHRSS_ADMIN_PASSWORD 不一致！"
    SUCCESS=false
fi

if [ "$PASS1_OUTLINE_SECRET" = "$PASS2_OUTLINE_SECRET" ]; then
    echo "✓ OUTLINE_SECRET_KEY 一致"
else
    echo "✗ OUTLINE_SECRET_KEY 不一致！"
    SUCCESS=false
fi

if [ "$PASS1_GITEA" = "$PASS2_GITEA" ]; then
    echo "✓ GITEA_ADMIN_PASSWORD 一致"
else
    echo "✗ GITEA_ADMIN_PASSWORD 不一致！"
    SUCCESS=false
fi

echo ""
echo "=== 幂等性测试（第三次执行）==="
echo "不清除环境变量，再次执行 config.sh..."
source config.sh >/dev/null 2>&1
PASS3_POSTGRES=$POSTGRES_PASSWORD

if [ "$PASS1_POSTGRES" = "$PASS3_POSTGRES" ]; then
    echo "✓ 第三次密码仍然一致"
else
    echo "✗ 第三次密码改变了！"
    SUCCESS=false
fi

echo ""
if [ "$SUCCESS" = true ]; then
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  ✓✓✓ 幂等性测试通过！多次执行配置完全一致！                 ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    EXIT_CODE=0
else
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  ✗✗✗ 幂等性测试失败！请检查上面的错误。                     ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    EXIT_CODE=1
fi

echo ""
echo "=== 清理 ==="
rm -f deploy.conf simple_test.sh
echo "✓ 测试环境已清理"

exit $EXIT_CODE
