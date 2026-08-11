# 🤖 JA MES Test Record Tool v2.4.0 - 中文说明

<p align="center">
  <br>
  <i><b>基于 Dart & Flutter 开发的高性能 Windows 桌面应用程序，用于自动化查询、检查和导出 Foxconn CloudMES 系统的测试记录、工序/条码历史与 BOM 组件追溯数据。</b></i>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/banben-2.4.0-blue.svg" alt="版本 2.4.0">
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

**JA MES Test Record Tool** 是一款专为优化 **Foxconn CloudMES** API 平台测试记录查询、工序历史提取、BOM 组件追溯和 SN 验证、测试报告导出而设计的专业工具。

专为测试工程师和 QA 团队打造，支持每个 SN 三种数据视图的极速异步并行查询、浏览器 CDP 自动同步 Token 凭据，以及带 Excel 风格搜索与排序的现代化交互界面。

---

## 💡 主要功能 (v2.4.0)

### 📊 数据视图
- 🗂️ **每个 SN 三种数据视图**：在 **测试记录** (Pass/Fail 结果)、**条码历史** (完整工序/工站流程) 与 **组件清单** (WIP BOM/物料追溯 — 制造商、料号、生产日期码、批次/包装号) 之间切换。
- 🔍 **Excel 风格搜索筛选**：每个记录列表都有即时搜索框，输入时匹配任意字段。
- ⬍ **点击排序**：排序按钮可选择字段并切换升序/降序，三种视图均支持。
- 📋 **可选取并复制数据**：任意记录数值均可通过拖动选取或双击选中，并复制 (Ctrl+C)，如同电子表格。
- 🔢 **智能记录数量**："SN 记录" 会自动显示 `(N)` 数量，当只有 0 或 1 条记录时自动隐藏。

### 🎨 界面
- 🏝️ **Dynamic Island 风格悬停工具栏**：3 个视图标签与模板/导入/导出/语言/主题按钮默认收起为图标，悬停时展开为文字标签 — 避免工具栏溢出。窗口最大化时所有按钮自动保持展开状态。
- 🎨 **多语言与实心主题**：支持暗黑/亮色主题及 **英文**、**越南文**、**中文** 三语切换。

### 🔐 凭据与连接
- ⚡ **启动时 Token 过期自动弹窗**：启动程序时自动检测 Token 有效性，过期时立即弹出 2 步凭据同步窗口。
- 🌐 **兼容 Chrome 与 Microsoft Edge 多浏览器**：内置 Edge 专用进程隔离标志 (`--disable-features=msEdgeStartupBoost...`)，彻底解决登录弹窗卡死问题。
- 🌐 **CDP 网络拦截自动获取凭据**：通过 CDP 实时拦截浏览器 API 报文，100% 准确提取 **Token**、**UUID**、**Operation-ID** 和 **Cookie**。
- 🛡️ **全新验证徽章图标 (🛡️)**：设置界面底部直观的连接验证徽章图标 `Icons.verified_outlined`。
- 🔄 **保存设置时自动重新查询**：点击保存自动清除旧 401 错误并重新查询队列中的所有 SN。
- 🔒 **不硬编码任何凭据**：Token/Cookie 绝不写死在源代码中 — 由用户通过设置界面自行提供，仅保存在本地、已被 Git 忽略的 `config.json` 中。

### ⚙️ 核心与数据管理
- ⚡ **SN 智能队列与并行查询**：支持单条或批量 SN 异步并行 API 查询，覆盖全部三种数据视图。
- 📄 **智能 CSV 导入导出**：自动过滤包含 `"SN"` 字样的标题行，并生成结构化的 CSV 报告。
- 🛠️ **Header 字符自动清理引擎**：自动清理隐藏换行符 (`\r\n`)、多余空格及双引号。
- 📋 **系统日志自动管理**：按日期保存日志并自动清理超过 7 天的旧日志文件。

---

## 📸 界面截图

<p align="center">
  <img src="../docs/screenshots/2026-08-11_133916.jpg" alt="测试记录视图，含搜索筛选、排序按钮与记录数量" width="850">
  <br><i>测试记录 — 搜索、排序与记录数量位于同一行</i>
  <br><br>
  <img src="../docs/screenshots/2026-08-11_134048.jpg" alt="组件清单视图，展示 WIP BOM 组件追溯" width="850">
  <br><i>组件清单 — 按 SN 展示 WIP BOM/物料追溯</i>
  <br><br>
  <img src="../docs/screenshots/2026-07-26_231301.png" alt="全新整洁 2 步设置界面与验证徽章图标" width="850">
  <br><i>设置 — 2 步 CDP 凭据同步向导</i>
  <br><br>
  <img src="../docs/screenshots/2026-07-26_231317.png" alt="启动时 Token 过期自动警告弹窗" width="850">
  <br><i>启动时 Token 过期自动警告弹窗</i>
</p>

---

## 🖥️ 使用说明

### 1. 添加 SN 序列号
* **单条添加**：在左侧输入框中输入 SN，按 **Enter** 键或点击 **[+]** 按钮。
* **批量导入**：点击 **[模板]** 下载 CSV 示例文件。填入 SN 后点击 **[导入]**。包含 `"SN"` 的标题行将被自动跳过。

### 2. 浏览三种数据视图
* 将鼠标悬停在 "结果详细信息" 旁的图标工具栏上可显示名称，或直接点击 — 无需先悬停：
  - 📋 **测试记录**：各工站的 Pass/Fail 测试结果。
  - 🔳 **条码历史**：SN 的完整工序/工站流程历史。
  - 🧩 **组件清单**：WIP BOM/物料追溯 (制造商、料号、生产日期码、批次/包装号)。
* 使用任意列表上的 **搜索框** 按任意字段筛选，使用 **[排序]** 按钮选择字段并切换升序/降序。
* 拖动选取或双击任意数值即可选中，然后按 **Ctrl+C** 复制 — 如同电子表格操作。
* 点击 **[导出]** 将所有已获取的测试记录数据保存为结构化 CSV 文件。

### 3. 从浏览器自动同步 Token (2 步 CDP 向导)
1. 点击 **设置 ⚙️** (或通过启动时的 Token 过期自动警告弹窗)。
2. **步骤 1**：点击 **[1. 打开浏览器]** 启动 Chrome 或 Microsoft Edge。
3. 在网页上登录您的 MES 账号。
4. **步骤 2**：点击 **[2. 同步凭据]**，程序将通过 CDP 网络拦截自动提取正确的 **Token**、**UUID**、**Operation-ID** 和 **Cookie**。
5. 点击 **保存** 即可自动清除历史错误界面并重新查询队列中的所有 SN。

### 4. 监控连接状态
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
│   ├── main.dart                  # 应用入口、Provider 与 window_manager 初始化
│   └── modules/
│       ├── api_client.dart        # MES API 客户端：TestRecord、SnProcessRecord 与 WipComponentRecord
│       ├── browser_helper.dart    # CDP 拦截与 Edge/Chrome 自动化
│       ├── config_service.dart    # 本地 config.json 读写 (不硬编码任何凭据)
│       ├── constants.dart         # 全局常量与默认配置 (v2.4.0)
│       ├── logger_service.dart    # 日志服务与 7 天自动清理
│       ├── logic.dart             # 状态管理：SN 队列、三种记录列表、ViewMode
│       ├── translations.dart      # 多语言字典 (EN, VN, CN)
│       └── ui/
│           ├── main_window.dart   # 标签页、搜索/排序、悬停图标、对话框 (WindowListener)
│           ├── styles.dart        # 主题调度器 (暗黑/亮色)
│           ├── styles_win10.dart  # Windows 10 半透明主题
│           └── styles_win11.dart  # Windows 11 亚克力主题
│
├── docs/
│   └── screenshots/                 # 应用界面截图
│       ├── 2026-08-11_133916.jpg    # 测试记录 — 搜索/排序/数量
│       ├── 2026-08-11_134048.jpg    # 组件清单 — BOM 追溯
│       ├── 2026-07-26_231301.png    # 设置界面与验证徽章图标
│       └── 2026-07-26_231317.png    # 启动时 Token 过期自动警告弹窗
├── i18n/
│   ├── README.vi.md               # 越南语说明文档
│   └── README.zh-CN.md            # 中文说明文档 (本文件)
├── pubspec.yaml                   # Flutter 包配置文件 (v2.4.0+2)
├── ABOUT.txt                      # 项目卡片
├── CHANGELOG.md                   # 完整版本历史
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

---

## ⚙️ 配置与设置

所有凭据均通过应用内的 **设置 ⚙️** 对话框提供 (粘贴原始 Header、浏览器 CDP 同步或手动输入) — **源代码中不硬编码任何内容**。数据仅保存在可执行文件旁的本地 `config.json` 中：

```json
{
  "token": "",
  "sns": ["SN123456", "SN789012"],
  "lang": "en",
  "operationId": "1826874274766209025",
  "uuid": "e1d5e78c-bf60-4aba-9b5f-a94b15cb63d4",
  "cookie": ""
}
```

`config.json` 与 `logs/` 文件夹均已通过 `.gitignore` 排除，切勿提交至 Git。

---

## 📜 更新日志摘要

- **[2.4.0]** — 新增条码历史与组件清单标签页、Excel 风格搜索/排序、可选取复制数据、Dynamic Island 悬停工具栏、移除硬编码凭据。
- **[2.3.0]** — 启动时 Token 过期自动警告弹窗、Edge/Chrome 防卡死标志、连接验证徽章图标。
- **[2.2.0]** — 保存设置时自动重新查询 SN 队列、即时连接验证。

完整版本历史请见 [**CHANGELOG.md**](../CHANGELOG.md)。
