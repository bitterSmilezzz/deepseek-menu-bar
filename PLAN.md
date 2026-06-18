# DeepSeek Menu Bar Implementation Plan

> **Goal:** 构建 macOS 菜单栏 DeepSeek API 管理工具（Swift + WKWebView + React）

**Architecture:** Swift (AppKit) 提供原生菜单栏图标 + NSPopover 弹出面板，WKWebView 嵌入 React 前端 UI，通过 JS Bridge 通信。API Key 通过 macOS Keychain 安全存储。

**Tech Stack:** Swift + AppKit, WKWebView, React 18 + TypeScript, Tailwind CSS, Zustand, Vite

---

### Task 1: 项目结构与 Swift 原生层

**Files:**
- Create: `deepseek-dashboard/Sources/AppDelegate.swift`
- Create: `deepseek-dashboard/Sources/StatusBarController.swift`
- Create: `deepseek-dashboard/Sources/PopoverController.swift`
- Create: `deepseek-dashboard/Sources/WebViewController.swift`
- Create: `deepseek-dashboard/Sources/KeychainManager.swift`
- Create: `deepseek-dashboard/Sources/APIClient.swift`
- Create: `deepseek-dashboard/Sources/BridgeHandler.swift`
- Create: `deepseek-dashboard/Info.plist`
- Create: `deepseek-dashboard/DeepSeekMenuBar.xcodeproj/project.pbxproj`

- [ ] **Step 1:** 创建目录结构
- [ ] **Step 2:** 编写 AppDelegate.swift（应用入口 + LSUIElement）
- [ ] **Step 3:** 编写 StatusBarController.swift（NSStatusBar 图标管理）
- [ ] **Step 4:** 编写 PopoverController.swift（NSPopover 管理 + Pin 功能）
- [ ] **Step 5:** 编写 WebViewController.swift（WKWebView + JS Bridge）
- [ ] **Step 6:** 编写 BridgeHandler.swift（Web ↔ Native 通信调度）
- [ ] **Step 7:** 编写 KeychainManager.swift（macOS Keychain CRUD）
- [ ] **Step 8:** 编写 APIClient.swift（DeepSeek API 调用封装）
- [ ] **Step 9:** 创建 Info.plist（LSUIElement=true）
- [ ] **Step 10:** 创建 Xcode 项目文件

### Task 2: WebUI 工程搭建

**Files:**
- Create: `deepseek-dashboard/WebUI/package.json`
- Create: `deepseek-dashboard/WebUI/vite.config.ts`
- Create: `deepseek-dashboard/WebUI/tsconfig.json`
- Create: `deepseek-dashboard/WebUI/tsconfig.node.json`
- Create: `deepseek-dashboard/WebUI/tailwind.config.js`
- Create: `deepseek-dashboard/WebUI/postcss.config.js`
- Create: `deepseek-dashboard/WebUI/index.html`
- Create: `deepseek-dashboard/WebUI/src/main.tsx`
- Create: `deepseek-dashboard/WebUI/src/index.css`

- [ ] **Step 1:** 创建 package.json（react, react-dom, zustand, tailwindcss, vite 依赖）
- [ ] **Step 2:** 配置 Vite + TypeScript + Tailwind
- [ ] **Step 3:** 创建 index.html 入口
- [ ] **Step 4:** 创建 main.tsx + index.css 全局样式
- [ ] **Step 5:** 安装依赖

### Task 3: WebUI 类型定义与 Store

**Files:**
- Create: `deepseek-dashboard/WebUI/src/types/index.ts`
- Create: `deepseek-dashboard/WebUI/src/stores/appStore.ts`
- Create: `deepseek-dashboard/WebUI/src/hooks/useBridge.ts`

- [ ] **Step 1:** 定义 TypeScript 类型（Balance, Usage, Tool, ApiKey, NewsItem 等）
- [ ] **Step 2:** 创建 Zustand Store（管理所有状态）
- [ ] **Step 3:** 创建 useBridge Hook（JS ↔ Native 通信封装）

### Task 4: WebUI 组件开发

**Files:**
- Create: `deepseek-dashboard/WebUI/src/App.tsx`
- Create: `deepseek-dashboard/WebUI/src/components/PopupPanel.tsx`
- Create: `deepseek-dashboard/WebUI/src/components/Dashboard.tsx`
- Create: `deepseek-dashboard/WebUI/src/components/BalanceCard.tsx`
- Create: `deepseek-dashboard/WebUI/src/components/UsageCard.tsx`
- Create: `deepseek-dashboard/WebUI/src/components/ToolList.tsx`
- Create: `deepseek-dashboard/WebUI/src/components/NewsFeed.tsx`
- Create: `deepseek-dashboard/WebUI/src/components/Settings.tsx`
- Create: `deepseek-dashboard/WebUI/src/components/AccountSwitcher.tsx`

- [ ] **Step 1:** 创建 App.tsx（路由/页面切换）
- [ ] **Step 2:** 创建 PopupPanel.tsx（面板容器 + Footer 按钮）
- [ ] **Step 3:** 创建 Dashboard.tsx（首页看板）
- [ ] **Step 4:** 创建 BalanceCard.tsx（余额卡片）
- [ ] **Step 5:** 创建 UsageCard.tsx（用量卡片）
- [ ] **Step 6:** 创建 ToolList.tsx（工具列表页）
- [ ] **Step 7:** 创建 NewsFeed.tsx（资讯列表页）
- [ ] **Step 8:** 创建 Settings.tsx（设置页 + API Key 管理表单）
- [ ] **Step 9:** 创建 AccountSwitcher.tsx（账号切换下拉菜单）

### Task 5: 构建脚本与配置

**Files:**
- Create: `deepseek-dashboard/build.sh`

- [ ] **Step 1:** 编写构建脚本
- [ ] **Step 2:** 验证 WebUI 构建成功
- [ ] **Step 3:** 提交到 GitHub

---

## Execution Order

1. Task 1 → 先搭好 Swift 原生层结构
2. Task 2 + Task 3 → WebUI 工程与数据层（与 Task 1 可并行）
3. Task 4 → WebUI 组件
4. Task 5 → 构建脚本 + 最终验证
