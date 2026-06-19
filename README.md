# DeepSeek 工具箱

macOS 菜单栏插件 — 实时查看 DeepSeek API 余额、用量，安全管理 API Key。

![](https://img.shields.io/badge/macOS-13.0%2B-brightgreen)
![](https://img.shields.io/badge/Swift-5.9-orange)
![](https://img.shields.io/badge/React-18-blue)

---

## 痛点解决

**DeepSeek 官方新建 API Key 只显示一次**，关闭弹窗后就再也无法完整复制。本工具解决这个问题：

- 新 Key 创建后立即粘贴保存到 **macOS Keychain**（系统级加密）
- 再次查看时以掩码显示，也可暂时明文查看
- 支持管理多个 API Key，一键切换

## 功能

- 👁️ **余额监控** — 实时显示账户余额（USD）
- 📊 **用量统计** — 当日输入/输出 Token 消耗一目了然
- 🔑 **API Key 管理** — 安全存储于 macOS Keychain，多账号切换
- 🔧 **工具列表** — DeepSeek 支持的工具一览
- 📰 **资讯动态** — 搜索 DeepSeek 最新新闻
- 📌 **Pin 置顶** — 面板可置顶在桌面，方便随时查看
- 🌗 **日夜主题** — 暗夜/日照双模式，0.35s 平滑切换

## 快速开始

### 前置要求

- macOS 13.0+
- Xcode 15.0+
- Node.js 18+

### 构建

```bash
cd deepseek-dashboard

# 一行构建
bash build.sh

# 或分步构建
cd WebUI && npm install && npm run build && cd ..
swift build -c release --product DeepSeekMenuBar --disable-sandbox
```

构建完成后，`DeepSeekMenuBar.app` 会生成在当前目录。

### 运行

双击 `DeepSeekMenuBar.app` 或：

```bash
open DeepSeekMenuBar.app
```

应用启动后会在 **右上角菜单栏** 显示蓝紫色 **D** 图标，点击即可弹出面板。

### 开发模式

WebUI 支持 Vite HMR 热更新开发：

```bash
cd WebUI && npm run dev
```

修改 `WebViewController.swift` 中 `init` 的 `isDevelopmentMode = true`，应用将从 `localhost:5173` 加载页面。

## 项目结构

```
Sources/DeepSeekMenuBar/     ← Swift 原生层
├── AppDelegate.swift         应用入口（LSUIElement 无 Dock）
├── main.swift                显式入口点
├── StatusBarController.swift  菜单栏图标管理
├── PopoverController.swift     NSPopover + Pin 置顶
├── WebViewController.swift     WKWebView + loadHTMLString
├── BridgeHandler.swift         JS ↔ Native 9 个桥接方法
├── KeychainManager.swift       macOS Keychain CRUD
└── APIClient.swift             DeepSeek API 调用

WebUI/                         ← React 前端层
├── src/
│   ├── components/             6 个页面组件
│   ├── hooks/useBridge.ts     桥接 + Mock 数据回退
│   ├── stores/appStore.ts     Zustand 状态管理
│   └── types/index.ts         类型定义
└── vite.config.ts             单文件构建配置

PRD.md                         产品需求文档
ARCH.md                        技术架构文档
prototype.html                 交互式原型
build.sh                       一键构建脚本
```

## 架构

```
┌──────────────────────────────────────────────────┐
│  macOS App (LSUIElement)                         │
│                                                  │
│  NSPopover                                       │
│  ┌──────────────────────────────────────┐        │
│  │ WKWebView  ← loadHTMLString(单文件)  │        │
│  │    │                                       │        │
│  │    └── JS Bridge (webkit.messageHandlers)  │        │
│  │         │  getBalance / getUsage / ...     │        │
│  │         └──→ evaluateJavaScript 回调       │        │
│  └──────────────────────────────────────┘        │
│                                                  │
│  Swift Services                                  │
│  KeychainManager  APIClient  Timer               │
└──────────────────────────────────────────────────┘
```

## 技术栈

| 层级 | 技术 |
|------|------|
| 原生壳层 | Swift + AppKit (NSStatusBar + NSPopover) |
| Web 容器 | WKWebView |
| 前端框架 | React 18 + TypeScript |
| 样式 | Tailwind CSS |
| 状态管理 | Zustand |
| 构建 | Vite + vite-plugin-singlefile |
| 安全存储 | macOS Keychain (Security framework) |

## License

MIT
