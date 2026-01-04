# Google 登录配置指南

## ✅ 已完成的代码实现

1. ✅ `GoogleSignInHelper.swift` - Google 登录辅助类
2. ✅ `AuthManager.swift` - 已实现 `signInWithGoogle()` 方法
3. ✅ `AppDelegate.swift` - 处理 Google Sign In URL 回调
4. ✅ `EarthBuilderApp.swift` - 注册 AppDelegate
5. ✅ `LoginView.swift` - Google 登录按钮已存在

## 🔧 在 Xcode 中需要完成的配置

### 步骤 1：清理 Build Settings 中的 Info.plist File 设置

1. 在 Xcode 中打开项目
2. 选择 **EarthBuilder** Target
3. 选择 **Build Settings** 标签
4. 搜索 **"Info.plist File"**
5. 找到 **"Info.plist File"** 设置
6. **清空此设置的值**（删除 `EarthBuilder/Info.plist`，留空）
7. 确认 **"Generate Info.plist File"** 设置为 **"Yes"**

### 步骤 2：验证 URL Schemes 配置

1. 选择 **EarthBuilder** Target
2. 选择 **Info** 标签
3. 展开 **URL Types** 部分
4. 确认已添加：
   - **URL Schemes**: `com.googleusercontent.apps.908977472998-8e5knp6gb3t78kffhm5glmvh1t3ucu9s`
   - **Identifier**: `com.googleusercontent.apps.908977472998-8e5knp6gb3t78kffhm5glmvh1t3ucu9s`
   - **Role**: Editor

如果没有，点击 **+** 添加新的 URL Type。

### 步骤 3：确认 GoogleSignIn SDK 已添加

1. 在项目导航器中，选择项目根目录
2. 选择 **EarthBuilder** Target
3. 选择 **General** 标签
4. 滚动到 **Frameworks, Libraries, and Embedded Content** 部分
5. 确认 **GoogleSignIn** 已添加
   - 如果没有，点击 **+** → **Add Other** → **Add Package Dependency**
   - 输入：`https://github.com/google/GoogleSignIn-iOS`
   - 选择最新版本

## 📝 配置说明

### Client ID 信息
- **Client ID**: `908977472998-8e5knp6gb3t78kffhm5glmvh1t3ucu9s.apps.googleusercontent.com`
- **URL Scheme**: `com.googleusercontent.apps.908977472998-8e5knp6gb3t78kffhm5glmvh1t3ucu9s`

### Supabase 配置
- ✅ Google Provider 已启用
- ✅ Authorized Client IDs 已填入
- ✅ Skip nonce check 已开启

## 🧪 测试步骤

1. **清理并重新构建项目**：
   ```
   Product → Clean Build Folder (Shift + Cmd + K)
   Product → Build (Cmd + B)
   ```

2. **运行应用**：
   ```
   Product → Run (Cmd + R)
   ```

3. **测试 Google 登录**：
   - 打开应用
   - 点击"通过 Google 登录"按钮
   - 查看控制台日志，应该看到：
     ```
     🟢 [认证] 开始 Google 登录流程
     🔵 [Google登录] 开始执行 Google 登录流程
     ✅ [Google登录] 成功获取根视图控制器
     🔵 [Google登录] Google Sign In 配置完成
     ...
     ```
   - 选择 Google 账号登录
   - 登录成功后应该自动跳转到主界面

## 🐛 常见问题排查

### 问题 0: "Multiple commands produce Info.plist" 构建错误

**原因**: Xcode 同时使用自定义 Info.plist 文件和自动生成功能，导致冲突

**解决**:
1. 在 Build Settings 中搜索 "Info.plist File"
2. **清空** "Info.plist File" 设置的值
3. 确认 "Generate Info.plist File" 设置为 "Yes"
4. 在 Info 标签页中配置 URL Types（应该已经配置好）
5. Clean Build Folder (Shift + Cmd + K)
6. 重新构建 (Cmd + B)

### 问题 1: "未配置应用"错误

**原因**: URL Schemes 配置不正确

**解决**:
1. 检查 Info.plist 中的 URL Scheme
2. 确保格式为：`com.googleusercontent.apps.` + `反向的 Client ID`
3. 重新构建项目

### 问题 2: "回调 URL 无效"

**原因**: AppDelegate 未正确处理 URL

**解决**:
1. 确认 `AppDelegate.swift` 已添加到项目
2. 确认 `EarthBuilderApp.swift` 中已注册 AppDelegate
3. 查看控制台日志确认回调被处理

### 问题 3: Google Sign In 按钮没有反应

**原因**: GoogleSignIn SDK 未正确链接

**解决**:
1. 检查 **Frameworks, Libraries, and Embedded Content**
2. 确认 GoogleSignIn 已添加
3. 清理构建文件夹并重新构建

## 📊 日志说明

登录过程中会看到以下日志：

- 🟢 **绿色** - AuthManager 认证流程
- 🔵 **蓝色** - Google 登录详细步骤
- ✅ **成功** - 操作成功完成
- ❌ **错误** - 操作失败
- 📊 **信息** - 数据和状态信息
- 🔗 **回调** - URL 回调处理

## 🎯 完成检查清单

- [ ] Build Settings 中 "Info.plist File" 已清空
- [ ] "Generate Info.plist File" 设置为 "Yes"
- [ ] URL Schemes 配置正确（已通过截图确认 ✅）
- [ ] GoogleSignIn SDK 已添加
- [ ] 项目成功构建
- [ ] Google 登录按钮可点击
- [ ] 能够打开 Google 登录页面
- [ ] 登录成功后能跳转回应用
- [ ] 用户信息正确显示

## 📞 需要帮助？

如果遇到问题，请检查：
1. Xcode 控制台的完整日志
2. URL Schemes 配置是否正确
3. GoogleSignIn SDK 版本是否最新
