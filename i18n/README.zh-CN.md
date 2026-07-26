# 🤖 JA MES Test Record Tool (v2.0.0) - 中文说明

<p align="center">
  <br>
  <i><b>基于 Dart & Flutter 开发的高性能 Windows 桌面应用程序，用于自动化查询、检查和导出 Foxconn CloudMES 系统测试记录。</b></i>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Dart-3.12+-blue.svg?style=flat-square&logo=dart" alt="Dart">
  <img src="https://img.shields.io/badge/Flutter-3.x-blue.svg?style=flat-square&logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Platform-Windows-0078D6.svg?style=flat-square&logo=windows" alt="Windows">
  <img src="https://img.shields.io/badge/Version-v2.0.0-green.svg?style=flat-square" alt="Version">
  <img src="https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square" alt="License">
</p>

<p align="center">
  <a href="../README.md">🇺🇸 English</a> • 
  <a href="README.vi.md">🇻🇳 Tiếng Việt</a> • 
  <b>🇨🇳 中文</b>
</p>

---

## 🌟 简介

**JA MES Test Record Tool** 是一款专为优化 **Foxconn CloudMES** API 平台测试记录查询、SN 验证和测试报告导出而设计的专业工具。

支持异步并行查询，拥有现代化的 Glassmorphic (毛玻璃) 桌面交互界面。

---

## 💡 主要功能 (v2.0.0)

- **⚡ SN 智能队列与并行查询**：支持单条或批量 SN 异步并行 API 查询。
- **📄 智能 CSV 导入导出**：
  - 自动过滤/跳过包含 `"SN"` 字样的标题行。
  - 一键生成 CSV 模板及完整测试结果导出。
- **🌐 Chrome CDP 网络拦截自动获取凭据**：
  - 自动启动 Chrome/Edge 浏览器并指定动态调试端口 (`--remote-debugging-port=0`)。
  - 通过 Chrome DevTools Protocol (`Network.enable`) 实时拦截浏览器 API 报文。
  - 100% 准确提取真实的 **Token**、**UUID**、**Operation-ID** 和 **Cookie**。
- **🔄 Token 有效性自动监控**：
  - 后台定时器每 3 分钟自动校验 Token。
  - 标题栏状态灯实时显示 (绿色 = 正常，红色 = 过期/错误)。
  - 设置界面中提供手动连接测试工具。
- **🛠️ Header 字符自动清理引擎**：
  - 自动清理隐藏的换行符 (`\r\n`)、多余空格及双引号 (`"..."`)，防止 HTTP `FormatException` 异常。
- **📋 系统日志自动管理**：
  - 按日期保存所有运行日志至 `logs/` 目录 (`mes_log_YYYY-MM-DD.txt`)。
  - 启动时自动清理超过 7 天的旧日志文件。
- **🎨 多语言与透明主题**：
  - 支持亮色/暗色透明 Glassmorphic 主题切换。
  - 动态切换 **英文**、**越南文**、**中文**。

---

## 📖 安装与编译指南

### 环境要求
* **Windows 10 / 11**
* **Flutter SDK 3.x** & **Dart 3.12+**
* 已安装 **Google Chrome** 或 **Microsoft Edge** 浏览器。

### 本地运行
```cmd
flutter pub get
flutter run -d windows
```

### 编译为 Windows 可执行文件 (.exe)
```cmd
flutter build windows
```
编译完成的文件位于：
`build\windows\x64\runner\Release\ja_mes_tool.exe`

---

## 🖥️ 使用说明

### 1. 添加 SN 序列号
* **单条添加**：在左侧边栏输入框中输入 SN，按 **Enter** 键或点击 **[+]** 按钮。
* **批量导入**：点击 **[模板]** 下载 CSV 示例文件。填入 SN 后点击 **[导入]**。包含 `"SN"` 的标题行将被自动跳过。

### 2. 从浏览器自动同步 Token (CDP)
1. 点击 **设置 ⚙️**。
2. 点击 **[打开浏览器登录]** 启动 Chrome/Edge。
3. 在网页上登录您的 MES 账号。
4. 点击 **[从浏览器获取 Token]**。程序将自动刷新页面并从网络报文中提取正确的 **Token**、**UUID**、**Operation-ID** 和 **Cookie**。
5. 或点击 **[粘贴 Header]** 直接粘贴 F12 或 Postman 中的原始 Request Header。

### 3. 监控连接状态
* **"结果详细信息"** 标题旁边的指示灯：
  - 🟢 **绿色**：Token 有效且连接正常。
  - 🔴 **红色**：Token 已过期或未授权 (401)。
* 程序每 **3 分钟** 自动校验一次连接。

---

## 📜 许可证

本项目采用 **MIT 许可证**。详情请参阅 [LICENSE](../LICENSE) 文件。
