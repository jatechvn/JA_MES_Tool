# 🤖 JA MES Tool v2.9.1 - 中文说明

<p align="center">
  <br>
  <i><b>基于 Dart & Flutter 开发的高性能 Windows 桌面应用程序，搭载全新 Bento 毛玻璃架构，用于自动化查询、检查和导出 Foxconn CloudMES 系统的测试记录、工序/条码历史与 BOM 组件追溯数据。</b></i>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/banben-2.9.1-blue.svg" alt="版本 2.9.1">
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

**JA MES Tool** 是一款专为优化 **Foxconn CloudMES** API 平台测试记录查询、工序历史提取、BOM 组件追溯和 SN 验证、测试报告导出而设计的专业工具。

专为测试工程师和 QA 团队打造，支持每个 SN 三种数据视图外加一个组件反向追溯视图 (Component Trace)、可跳转至任意标签/操作/设置的命令面板 (Ctrl+K) 的极速异步并行查询、浏览器 CDP 自动同步 Token 凭据，以及搭载 Bento Glassmorphism、Liquid Glass、Dynamic Island 状态胶囊和带 Excel 风格搜索与排序的现代化交互界面。

---

## 💡 主要功能 (v2.9.1)

### 🎨 Bento 毛玻璃视觉架构
- ⚡ **命令面板 (Ctrl+K / Cmd+K)**：聚光灯式搜索覆盖层，列出所有标签、操作与设置 — 输入即按名称/关键词筛选，↑/↓ 导航，回车或点击执行。
- 🌟 **Bento Grid & Liquid Glass 体系**：悬浮式 Bento 卡片设计，配备 1px 顶置光感反射边框，20-24px BackdropFilter 深度毛玻璃模糊以及 GPU 硬件加速的流动 Mesh Orbs 动态光效。
- 🎛️ **4 轴毛玻璃实时调节面板**：设置中提供卡片模糊度 (0-40px)、卡片不透明度 (5-100%)、对话框模糊度 (0-40px)、对话框不透明度 (10-100%) 四大实时调节滑块，支持实时效果预览、一键默认与取消还原。
- 🌓 **单击直切主题 (Light ⇄ Dark)**：一键顺畅切换明暗模式。
- ⏱️ **精准自动 Build 时间戳读取**：自动读取 compiled `data/app.so` 和 exe 二进制修改时间，于 Header 与关于页展示。
- ✨ **iOS 风格流畅过渡动画**：标签/SN 切换带有淡入滑动动画，记录列表以级联效果依次出现并支持弹性滚动，对话框采用缩放淡入淡出效果。
- 🏝️ **Dynamic Island 状态胶囊**：动态波形指示 MES 实时连接状态，集成快速操作工具栏。
- 🪟 **可调节毛玻璃效果**：设置 → 高级 中的"自定义模糊与透明度"面板提供 4 个实时预览滑块 (主背景模糊度/不透明度、对话框模糊度/不透明度)。排序下拉菜单与设置窗口本身都会随拖动滑块实时重新模糊 — 内置安全下限，无论不透明度调多低都能防止文字重叠透视的问题。
- 🎨 **多语言与实心主题**：支持暗黑/亮色主题及 **英文**、**越南文**、**中文** 三语切换。

### 🔐 凭据与连接
- ⚡ **启动时 Token 过期自动弹窗**：启动程序时自动检测 Token 有效性，过期时立即弹出 2 步凭据同步窗口。
- 🌐 **兼容 Chrome 与 Microsoft Edge 多浏览器**：内置 Edge 专用进程隔离标志 (`--disable-features=msEdgeStartupBoost...`)，彻底解决登录弹窗卡死问题。
- 💾 **持久化浏览器配置**：Chrome 与 Microsoft Edge 使用应用独立管理的不同配置目录，可在重启后保留登录会话、密码和书签，同时避免配置冲突。
- 🌐 **CDP 网络拦截自动获取凭据**：通过 CDP 实时拦截浏览器 API 报文，100% 准确提取 **Token**、**UUID**、**Operation-ID** 和 **Cookie**。
- 🛡️ **全新验证徽章图标 (🛡️)**：设置界面底部直观的连接验证徽章图标 `Icons.verified_outlined`。
- 🔄 **保存设置时自动重新查询**：点击保存自动清除旧 401 错误并重新查询队列中的所有 SN。
- 🔒 **不硬编码任何凭据**：Token/Cookie 绝不写死在源代码中 — 由用户通过设置界面自行提供，仅保存在本地、已被 Git 忽略的 `config.json` 中。

### ⚙️ 核心与数据管理
- ⚡ **SN 智能队列与并行查询**：支持单条或批量 SN 异步并行 API 查询，覆盖全部三种数据视图。
- 📄 **智能 CSV 导入导出**：自动过滤包含 `"SN"`/`"CSN"` 字样的标题行，并生成结构化的 CSV 报告 — 位于 Component Trace 标签时，**[模板]/[导入]/[导出]** 三个按钮会自动切换为组件序列号专用的模板/数据。
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

### 1. 命令面板 (Ctrl+K / Cmd+K)
* 在应用内任意位置按 **Ctrl+K**（macOS 键盘为 **Cmd+K**）打开聚光灯式搜索，覆盖所有标签、操作与设置。
* 输入名称或关键词进行筛选，使用 **↑/↓** 选中结果，按 **回车** 或点击执行；按 **Esc** 或点击外部区域关闭。

### 2. 添加 SN 序列号
* **单条添加**：在左侧输入框中输入 SN，按 **Enter** 键或点击 **[+]** 按钮。
* **批量导入**：点击 **[模板]** 下载 CSV 示例文件。填入 SN 后点击 **[导入]**。包含 `"SN"` 的标题行将被自动跳过。

### 3. 浏览三种数据视图
* 将鼠标悬停在 "结果详细信息" 旁的图标工具栏上可显示名称，或直接点击 — 无需先悬停：
  - 📋 **测试记录**：各工站的 Pass/Fail 测试结果。
  - 🔳 **条码历史**：SN 的完整工序/工站流程历史。
  - 🧩 **组件清单**：WIP BOM/物料追溯 (制造商、料号、生产日期码、批次/包装号)。
* 使用任意列表上的 **搜索框** 按任意字段筛选，使用 **[排序]** 按钮选择字段并切换升序/降序。
* 拖动选取或双击任意数值即可选中，然后按 **Ctrl+C** 复制 — 如同电子表格操作。
* 点击 **[导出]** 将所有已获取的测试记录数据保存为结构化 CSV 文件。

### 4. Component Trace（组件反向追溯）
* 点击 **🧭 Component Trace** 标签 — 侧边栏会从 SN 队列切换为 **追溯历史** 列表，输入框位置不变，但改为查询组件序列号，而不是添加 SN。
* 输入或扫描组件序列号后按 **Enter**（或点击 **[+]/🔍**）— 也可一次粘贴多个序列号（每行一个，或用逗号分隔），一次性查询完毕。
* 每个查询过的序列号都会成为侧边栏 **追溯历史** 中的一行（点击可查看已缓存的结果，🔄 重新查询，✕ 删除），并会**保存到本地**，因此关闭重开应用后历史记录依然保留。
* 结果面板会列出该组件当前安装的所有成品序列号，并配有与其他三个视图完全一致的 **搜索/排序** 工具栏。
* 位于该标签时，**[模板]/[导入]/[导出]** 会自动针对组件序列号操作。

### 5. 从浏览器自动同步 Token (2 步 CDP 向导)
1. 点击 **设置 ⚙️** (或通过启动时的 Token 过期自动警告弹窗)。
2. **步骤 1**：点击 **[1. 打开浏览器]** 启动 Chrome 或 Microsoft Edge。
3. 在网页上登录您的 MES 账号。
4. **步骤 2**：点击 **[2. 同步凭据]**，程序将通过 CDP 网络拦截自动提取正确的 **Token**、**UUID**、**Operation-ID** 和 **Cookie**。
5. 点击 **保存** 即可自动清除历史错误界面并重新查询队列中的所有 SN（以及 Component Trace 历史，若有）。

### 6. 监控连接状态
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
│   ├── modules/
│   │   ├── api_client.dart        # MES API 客户端：TestRecord、SnProcessRecord、WipComponentRecord 与 QueryInfoRecord
│   │   ├── browser_helper.dart    # CDP 拦截与 Edge/Chrome 自动化
│   │   ├── build_info.dart        # 从 data/app.so 或可执行文件读取真实编译时间戳
│   │   ├── config_service.dart    # 本地 config.json 读写 (不硬编码任何凭据)
│   │   ├── constants.dart         # 全局常量与默认配置 (v2.9.1)
│   │   ├── logger_service.dart    # 日志服务与 7 天自动清理
│   │   ├── logic.dart             # 状态管理：SN 队列、追溯历史、四种记录列表、ViewMode、SN 解析缓存
│   │   ├── translations.dart      # 多语言字典 (EN, VN, CN)
│   │   └── ui/
│   │       ├── main_window.dart   # 标签页、搜索/排序、对话框、命令面板接入 (WindowListener)
│   │       ├── motion.dart        # 统一动画时长/曲线配置
│   │       ├── styles.dart        # 转发导出 lib/theme/*（保留旧版 import 兼容）
│   │       ├── styles_win10.dart  # 旧版 Win10 主题，已由 lib/theme/styles_win10.dart 取代
│   │       └── styles_win11.dart  # 旧版 Win11 主题，已由 lib/theme/styles_win11.dart 取代
│   ├── theme/                     # Bento 毛玻璃主题系统
│   │   ├── app_colors.dart        # AppColors 颜色令牌集（各主题调色板）
│   │   ├── styles_win10.dart      # Windows 10 (Aero) 毛玻璃颜色/透明度调优
│   │   ├── styles_win11.dart      # Windows 11 (Acrylic/Mica) 毛玻璃颜色/透明度调优
│   │   └── theme_provider.dart    # ThemeProvider：明暗/跟随系统模式，监听 OS 主题变化
│   └── widgets/                   # 可复用毛玻璃 UI 组件
│       ├── app_toast.dart         # 短暂显示的毛玻璃 Toast 通知
│       ├── command_palette.dart   # Ctrl+K / Cmd+K 聚光灯式命令搜索
│       ├── filter_search_dock.dart# 搜索框 + 筛选胶囊组合（毛玻璃风格）
│       ├── glass_dialog.dart      # 毛玻璃模态对话框外壳
│       └── glass_widgets.dart     # BentoCard、MeshBackground、SlidingPillTabBar、KbdTag 等
│
├── windows/
│   └── runner/                    # 原生 Win32 运行器 (大部分由 Flutter 自动生成)
│       ├── win32_window.cpp       # 创建窗口；检测系统暗黑模式并路由至 theme_win10/win11
│       ├── theme_win10.cpp        # 通过未文档化的 SetWindowCompositionAttribute API 实现 Acrylic 模糊背景
│       ├── theme_win11.cpp        # 通过 DWMWA_SYSTEMBACKDROP_TYPE 实现原生 Mica/Acrylic 背景
│       └── resources/app_icon.ico # 应用图标 (任务栏与标题栏)
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
├── pubspec.yaml                   # Flutter 包配置文件 (v2.9.1+15)
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
  "traceCsns": ["OPM1106349G1CCX", "QB940AE002627V05171"],
  "lang": "en",
  "operationId": "1826874274766209025",
  "uuid": "e1d5e78c-bf60-4aba-9b5f-a94b15cb63d4",
  "cookie": ""
}
```

`config.json` 与 `logs/` 文件夹均已通过 `.gitignore` 排除，切勿提交至 Git。

---

## 📜 更新日志摘要

- **[2.9.1]** — **刷新全部**现在会在重新查询前清除标准 SN 与 SN Master 元数据缓存，避免 SN 映射或下一工序信息保持过期。
- **[2.9.0]** — 新增 **命令面板** (Ctrl+K / Cmd+K)：聚光灯式搜索覆盖所有标签、操作与设置，支持关键词筛选与方向键导航，并新增毛玻璃 Toast 通知系统。同时修复命令面板中的 `FocusNode` 内存泄漏，并移除未注册字体的 `fontFamily` 引用。
- **[2.8.0]** — **Bento 毛玻璃与 Liquid Glass 架构全面升级**：全界面重构为悬浮式 Bento 卡片与 GPU 加速 Mesh Orbs 动态光效，高级设置新增 4 轴毛玻璃实时预览滑块与取消还原，单击即时切换明暗主题，以及精准自动读取编译时间戳。同时修复首次启动毛玻璃默认值与设置中"默认"按钮不一致、对话框在同步凭据过程中关闭可能崩溃、以及主题不随系统明暗切换实时更新的问题。
- **[2.7.0]** — 新增 **Component Trace** 视图：反向查询组件自身序列号安装在哪个成品序列号中，侧边栏保留独立且可持久化的查询历史，支持搜索/排序与 CSV 模板/导入/导出 — 与 SN 队列共用同一个添加/搜索输入框，无需新增输入框。
- **[2.6.4]** — SN 主档现在获取完整 API 数据 (下一工序、错误代码、路由、产线代码)；记录列表标题栏新增 "Next" 徽章显示下一工序，SN 标签在空间不足时改为自动滚动，不再截断。
- **[2.6.3]** — Chrome 与 Microsoft Edge 现在使用可持久化的独立配置，支持旧配置迁移与有界 CDP 就绪检查，避免登录窗口卡死。
- **[2.6.2]** — 设置界面拆分为高级设置、使用说明和关于三个标签页；对话框高度会根据当前标签页自动调整。

完整版本历史请见 [**CHANGELOG.md**](../CHANGELOG.md)。
