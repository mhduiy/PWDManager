# 🔐 PWD Manager

<div align="center">

**一个功能强大、安全可靠、界面精美的跨平台密码管理器**

[![Flutter](https://img.shields.io/badge/Flutter-3.4.3+-02569B.svg?style=flat&logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.4.3+-0175C2.svg?style=flat&logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Linux%20%7C%20Windows%20%7C%20macOS-lightgrey.svg)](https://flutter.dev/desktop)

</div>

## ✨ 功能亮点

### 🔒 核心安全功能
- **军用级加密**：采用AES-256加密算法保护所有敏感数据
- **生物认证**：支持指纹/面容ID解锁（Android/iOS）
- **多重验证**：6位数字主密码 + 生物认证双重保护
- **防护机制**：内置截屏防护、防录屏检测、后台自动锁定
- **访问控制**：多次错误自动锁定、自定义锁定时间

### 💎 用户体验
- **智能分类**：11种预设分类，支持智能推荐
- **网站图标**：内置100+网站图标，自动识别和颜色匹配
- **强大搜索**：支持用途、账号全文搜索，实时过滤
- **多种排序**：按用途、账号、创建时间、访问次数排序
- **收藏功能**：一键收藏常用密码，优先显示

### 🎨 界面设计
- **Material Design 3**：遵循最新设计规范
- **深色主题**：支持跟随系统/手动切换
- **自定义主题**：多种主题色彩可选
- **流畅动画**：丰富的过渡动画和触觉反馈
- **响应式布局**：完美适配各种屏幕尺寸

### 🚀 高级功能
- **密码生成器**：可配置长度、字符类型的强密码生成
- **密码强度检测**：实时分析密码安全等级
- **访问统计**：记录查看次数、最后访问时间
- **滑动操作**：左右滑动快速编辑、收藏、分享、删除
- **批量管理**：支持批量操作和分类管理

### 📤 分享与备份
- **二维码分享**：生成二维码快速分享密码
- **系统分享**：支持文本分享和剪贴板操作
- **数据导入导出**：JSON格式备份与恢复
- **跨平台同步**：支持多设备数据迁移

## 📱 支持平台

- ✅ **Android** 7.0+ (API 24+)
- ✅ **iOS** 12.0+
- ✅ **Linux** (Ubuntu 18.04+)
- ✅ **Windows** 10+
- ✅ **macOS** 10.14+

## 📋 系统要求

### 开发环境
- Flutter SDK 3.4.3+
- Dart SDK 3.4.3+
- Android Studio / VS Code
- Xcode (仅iOS/macOS开发)

### 运行环境
- **Android**: API 24+ (Android 7.0+)
- **iOS**: iOS 12.0+
- **Linux**: Ubuntu 18.04+ / 其他现代Linux发行版
- **Windows**: Windows 10 1809+
- **macOS**: macOS 10.14+

## 🛠️ 安装指南

### 开发环境搭建

1. **安装Flutter**
   ```bash
   # 下载Flutter SDK
   git clone https://github.com/flutter/flutter.git -b stable
   
   # 添加到PATH环境变量
   export PATH="$PATH:`pwd`/flutter/bin"
   
   # 验证安装
   flutter doctor
   ```

2. **克隆项目**
   ```bash
   git clone https://github.com/yourusername/PWDManager.git
   cd PWDManager
   ```

3. **安装依赖**
   ```bash
   flutter pub get
   ```

4. **运行应用**
   ```bash
   # 开发模式
   flutter run
   
   # 调试模式
   flutter run --debug
   
   # 发布模式
   flutter run --release
   ```

### 平台特定配置

#### Android
```bash
# 构建APK
flutter build apk

# 构建AAB
flutter build appbundle
```

#### iOS
```bash
# 构建iOS应用
flutter build ios
```

#### Linux
```bash
# 构建Linux应用
flutter build linux
```

#### Windows
```bash
# 构建Windows应用
flutter build windows
```

#### macOS
```bash
# 构建macOS应用
flutter build macos
```

## 📦 核心依赖

| 包名 | 版本 | 用途 |
|------|------|------|
| sqflite | ^2.3.0 | 本地数据库 |
| local_auth | ^2.1.7 | 生物认证 |
| encrypt | ^5.0.0 | 数据加密 |
| shared_preferences | ^2.2.2 | 配置存储 |
| flutter_slidable | ^3.0.1 | 滑动操作 |
| qr_flutter | ^4.1.0 | 二维码生成 |
| share_plus | ^7.2.1 | 系统分享 |
| window_manager | ^0.5.0 | 桌面端窗口管理 |

## 🏗️ 项目结构

```
lib/
├── main.dart                    # 应用入口
├── password.dart               # 密码数据模型
├── databasehelper.dart         # 数据库操作
├── password_page.dart          # 密码列表页面
├── my_page.dart               # 设置页面
├── authentication_page.dart    # 认证页面
├── password_auth.dart          # 认证逻辑
├── password_generator.dart     # 密码生成器
├── password_edit_full_dialog.dart # 密码编辑对话框
└── utils/
    ├── password_strength.dart   # 密码强度检测
    ├── password_category.dart   # 分类管理
    └── website_icons.dart      # 网站图标
```

## 🎯 功能详解

### 🔐 安全认证
- **主密码设置**：6位数字密码，支持修改
- **生物认证**：指纹/面容ID快速解锁
- **自动锁定**：可配置锁定时间(1-60分钟)
- **错误保护**：连续错误自动锁定
- **后台锁定**：应用切换后台自动锁定

### 📂 分类管理
内置11种智能分类：
- 🌐 全部
- 👥 社交 (微信、QQ、微博等)
- 📧 邮箱 (Gmail、Outlook等)
- 🏦 银行 (各大银行、支付宝等)
- 🛒 购物 (淘宝、京东、拼多多等)
- 💼 工作 (GitHub、企业系统等)
- 🎬 娱乐 (爱奇艺、Netflix等)
- 🎮 游戏 (Steam、LOL等)
- 📚 学习 (在线课程、学校系统等)
- ☁️ 云存储 (百度网盘、OneDrive等)
- 📁 其他

### 🔍 搜索功能
- **实时搜索**：输入即搜，无需确认
- **全文匹配**：搜索用途和账号信息
- **分类筛选**：结合分类进行精准筛选
- **搜索高亮**：关键词高亮显示

### 📊 数据统计
- **总密码数**：所有保存的密码数量
- **收藏统计**：被收藏的密码数量
- **今日新增**：当天新增的密码数量
- **分类分布**：各分类密码数量统计
- **访问记录**：记录查看次数和时间

### 🎨 主题定制
- **跟随系统**：自动切换深色/浅色主题
- **手动切换**：独立的主题模式设置
- **主题色彩**：多种预设颜色可选
- **Material 3**：最新设计语言支持

## 📸 应用截图

> 注：建议添加应用的实际截图展示各个功能界面

## 🔒 安全说明

### 数据加密
- 使用AES-256加密算法
- 每个字段独立加密
- 密钥本地生成，不上传云端

### 隐私保护
- 所有数据仅存储在本地设备
- 不收集任何用户隐私信息
- 支持完全离线使用

### 安全建议
1. 设置强度较高的主密码
2. 启用生物认证功能
3. 定期备份密码数据
4. 避免在不安全环境使用
5. 定期更新应用版本

## 🤝 贡献指南

欢迎参与项目开发！

### 开发流程
1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

### 代码规范
- 遵循 Dart/Flutter 官方代码规范
- 使用 `flutter analyze` 检查代码质量
- 添加必要的注释和文档
- 确保新功能有对应的测试

## 📝 更新日志

### v1.0.0 (2024-12-19)
- ✨ 初始版本发布
- 🔐 完整的密码管理功能
- 🎨 Material Design 3 界面
- 📱 跨平台支持
- 🔒 多重安全防护
- 📂 智能分类系统
- 🌐 网站图标识别

## 📄 许可证

本项目采用 [MIT License](LICENSE) 开源协议。

## 💬 反馈与支持

如果您在使用过程中遇到问题或有改进建议，请通过以下方式联系我们：

- 📧 Email: your.email@example.com
- 🐛 Issues: [GitHub Issues](https://github.com/yourusername/PWDManager/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/yourusername/PWDManager/discussions)

## ⭐ 致谢

感谢所有开源项目的贡献者，特别是：
- [Flutter Team](https://flutter.dev) - 跨平台UI框架
- [Material Design](https://material.io) - 设计规范
- 所有依赖包的维护者

---

<div align="center">

**如果这个项目对您有帮助，请给个 ⭐ Star 支持一下！**

Made with ❤️ by [Your Name]

</div>
