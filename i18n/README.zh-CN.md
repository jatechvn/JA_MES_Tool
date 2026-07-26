# 🤖 JA MES Test Record Tool v2.3.0 - 中文说明

<p align="center">
  <br>
  <i><b>基于 Dart & Flutter 开发的高性能 Windows 桌面应用程序，用于自动化查询、检查和导出 Foxconn CloudMES 系统测试记录。</b></i>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/banben-2.3.0-blue.svg" alt="版本 2.3.0">
  <img src="https://img.shields.io/badge/pingtai-Windows%20x64-0078D6.svg" alt="平台 Windows">
  <img src="https://img.shields.io/badge/flutter-3.x-02569B.svg" alt="Flutter 3.x">
</p>

<p align="center">
  <a href="../README.md">🇺🇸 English</a> • 
  <a href="README.vi.md">🇻🇳 Tiếng Việt</a> • 
  <b>🇨🇳 中文</b>
</p>

---

## 🌟 简介

**JA MES Test Record Tool** 是一款专为优化 **Foxconn CloudMES** API 平台测试记录查询、SN 验证和测试报告导出而设计的专业工具。

专为测试工程师和 QA 团队打造，支持极速异步并行查询、浏览器 CDP 自动同步 Token 凭据及现代化的实心桌面交互界面。

---

## 💡 主要功能 (v2.3.0)

- ⚡ **启动时 Token 过期自动弹窗**：启动程序时自动检测 Token 有效性，过期时立即弹出 2 步凭据同步窗口。
- 🌐 **兼容 Chrome 与 Microsoft Edge 多浏览器**：内置 Edge 专用进程隔离标志 (`--disable-features=msEdgeStartupBoost...`)，彻底解决登录弹窗卡死问题。
- 🛡️ **全新验证徽章图标 (🛡️)**：设置界面底部直观的连接验证徽章图标 `Icons.verified_outlined`。
- 🔄 **保存设置时自动重新查询**：点击保存自动清除旧 401 错误并重新查询队列中的所有 SN。
- ⚡ **SN 智能队列与并行查询**：支持单条或批量 SN 异步并行 API 查询。
- 📄 **智能 CSV 导入导出**：自动过滤包含 `"SN"` 字样的标题行，并生成结构化的 CSV 报告。
- 🌐 **CDP 网络拦截自动获取凭据**：通过 CDP 实时拦截浏览器 API 报文，100% 准确提取 **Token**、**UUID**、**Operation-ID** 和 **Cookie**。
- 🛠️ **Header 字符自动清理引擎**：自动清理隐藏换行符 (`\r\n`)、多余空格及双引号。
- 📋 **系统日志自动管理**：按日期保存日志并自动清理超过 7 天的旧日志文件。
- 🎨 **多语言与实心主题**：支持暗黑/亮色主题及 **英文**、**越南文**、**中文** 三语切换。

---

## 📸 界面截图

<p align="center">
  <img src="../docs/screenshots/2026-07-26_231301.png" alt="全新整洁 2 步设置界面与验证徽章图标" width="850">
  <br><br>
  <img src="../docs/screenshots/2026-07-26_231317.png" alt="启动时 Token 过期自动警告弹窗" width="850">
</p>

---

## 🖥️ 使用说明

### 1. 添加 SN 序列号
* **单条添加**：在左侧输入框中输入 SN，按 **Enter** 键或点击 **[+]** 按钮。
* **批量导入**：点击 **[模板]** 下载 CSV 示例文件。填入 SN 后点击 **[导入]**。包含 `"SN"` 的标题行将被自动跳过。

### 2. 从浏览器自动同步 Token (2 步 CDP 向导)
1. 点击 **设置 ⚙️** (或通过启动时的 Token 过期自动警告弹窗)。
2. **步骤 1**：点击 **[1. 打开浏览器]** 启动 Chrome 或 Microsoft Edge。
3. 在网页上登录您的 MES 账号。
4. **步骤 2**：点击 **[2. 同步凭据]**，程序将通过 CDP 网络拦截自动提取正确的 **Token**、**UUID**、**Operation-ID** 和 **Cookie**。
5. 点击 **保存** 即可自动清除历史错误界面并重新查询队列中的所有 SN。

### 3. 监控连接状态
* 标题栏 **"设置"** 旁边的指示灯：
  - 🟢 **已连接**：Token 有效且连接正常。
  - 🟡 **检查状态**：Token 已过期或未授权 (401)。
* 程序每 **3 分钟** 自动校验一次连接。
* 在设置界面中点击 **验证徽章图标 (🛡️)** 可手动测试连接。

---

## 🏗️ 项目目录结构

```text
ja_mes_tool/
├── lib/
│   ├── main.dart                  # 应用入口与 Provider 设置
│   └── modules/
│       ├── api_client.dart        # MES API 客户端与 Header 清理器
│       ├── browser_helper.dart    # CDP 拦截与 Edge/Chrome 自动化
│       ├── constants.dart         # 全局常量与默认配置 (v2.3.0)
│       ├── logger_service.dart    # 日志服务与 7 天自动清理
│       ├── logic.dart             # 业务逻辑与后台自动校验
│       ├── translations.dart     # 多语言字典 (EN, VN, CN)
│       └── ui/
│           ├── main_window.dart   # 主界面与 2 步对话框
│           ├── styles.dart        # 暗黑主题定义
│           └── styles_win10.dart  # 亮色主题定义
│
├── docs/
│   └── screenshots/               # 应用界面截图
│       ├── 2026-07-26_231301.png  # 设置界面与验证徽章图标
│       └── 2026-07-26_231317.png  # 启动时 Token 过期自动警告弹窗
├── i18n/
│   ├── README.vi.md               # 越南语说明文档
│   └── README.zh-CN.md            # 中文说明文档 (本文件)
├── pubspec.yaml                   # Flutter 包配置文件 (v2.3.0+1)
├── ABOUT.txt                      # 项目卡片
└── LICENSE                        # 许可证文件
```

---

## 📖 编译与安装指南

### 编译为可执行文件 (.exe)
```cmd
flutter build windows
```
编译完成的可执行文件路径为：
`build\windows\x64\runner\Release\ja_mes_tool.exe`
