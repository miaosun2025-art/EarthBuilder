#!/bin/bash

# 脚本说明:
# 此脚本使用 Supabase Management API 自动更新邮件模板
# 将 Magic Link 模板修改为显示 6 位验证码

# 使用方法:
# 1. 访问 https://supabase.com/dashboard/account/tokens 创建 Access Token
# 2. 运行: SUPABASE_ACCESS_TOKEN="你的token" ./scripts/update-email-templates.sh

set -e  # 遇到错误立即退出

echo "🔧 开始更新 Supabase 邮件模板..."

# 检查是否设置了 Access Token
if [ -z "$SUPABASE_ACCESS_TOKEN" ]; then
    echo "❌ 错误: 请设置 SUPABASE_ACCESS_TOKEN 环境变量"
    echo ""
    echo "获取 Access Token 步骤:"
    echo "1. 访问: https://supabase.com/dashboard/account/tokens"
    echo "2. 点击 'Generate New Token'"
    echo "3. 复制 Token"
    echo "4. 运行: export SUPABASE_ACCESS_TOKEN='你的token'"
    echo "5. 重新运行此脚本"
    exit 1
fi

PROJECT_REF="taskfpupruagdzslzpac"

echo "📧 正在更新 Magic Link 模板（用于注册和找回密码）..."

# 更新邮件模板
curl -X PATCH "https://api.supabase.com/v1/projects/$PROJECT_REF/config/auth" \
  -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "mailer_subjects_magic_link": "{{ .Token }} 是您的 EarthBuilder 验证码",
    "mailer_templates_magic_link_content": "<h2>EarthBuilder 验证码</h2><p>您的验证码是：</p><h1 style=\"color: #ff6b35; font-size: 48px; font-weight: bold; margin: 20px 0;\">{{ .Token }}</h1><p>验证码有效期 60 分钟。如果您没有请求此验证码，请忽略此邮件。</p>"
  }'

echo ""
echo "✅ 邮件模板更新完成！"
echo ""
echo "⏳ 请等待 1-2 分钟让配置生效，然后重新测试注册/找回密码功能"
echo ""
echo "📮 提示: 请检查邮箱的垃圾邮件文件夹，发件人为: noreply@mail.app.supabase.io"
