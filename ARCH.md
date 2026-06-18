# DeepSeek Menu Bar - 技术架构文档

## 1. 技术选型

### 1.1 核心架构决策

| 对比项 | Swift + WKWebView ✅ | Tauri (Tray + 弹窗) | Electron (Tray) |
|--------|---------------------|-------------------|-----------------|
| **菜单栏体验** | ✅ 原生 NSPopover，完美 | ⚠️ 模拟弹窗，体验次之 | ⚠️ 模拟弹窗，有延迟 |
| **Pin 置顶** | ✅ NSPopover 原生支持 | ⚠️ 需手动实现 | ⚠️ 需手动实现 |
| **关闭行为** | ✅ 点击外部自动关闭 | ⚠️ 需 focus 事件监听 | ⚠️ 需 focus 事件监听 |
| **包体积** | ✅ ~5MB | ✅ ~8MB | ❌ ~150MB |
| **内存占用** | ✅ ~20MB | ✅ ~30MB | ❌ ~100MB |
| **Web UI 开发** | ✅ React/TS 不变 | ✅ React/TS 不变 | ✅ React/TS 不变 |

**最终决策：Swift (AppKit) + WKWebView**

### 1.2 技术栈明细

| 层级 | 技术 | 说明 |
|------|------|------|
| **原生壳层** | Swift + AppKit | NSStatusBarButton + NSPopover |
| **Web 容器** | WKWebView | 嵌入 Swift，加载本地 Web UI |
| **前端框架** | React 18 + TypeScript | UI 组件化 |
| **样式方案** | Tailwind CSS | 原子化 CSS |
| **状态管理** | Zustand | 轻量状态管理 |
| **构建工具** | Vite | 快速构建，输出静态文件 |
| **安全存储** | macOS Keychain (通过 Swift) | 加密存储 API Key |
| **网络请求** | URLSession (通过 Swift) → JS Bridge | 避免 CORS 问题 |
| **资讯搜索** | Web Search API | 搜索 DeepSeek 相关新闻 |

### 1.3 架构图

```
┌────────────────────────────────────────────────────────────┐
│                    macOS App Bundle                         │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              Swift 原生层 (AppKit)                   │   │
│  │                                                      │   │
│  │  ┌──────────────┐    ┌─────────────┐                │   │
│  │  │ NSStatusBar   │    │ NSPopover   │                │   │
│  │  │ Button (图标) │───→│ (弹出面板)  │                │   │
│  │  └──────────────┘    └──────┬──────┘                │   │
│  │                             │                        │   │
│  │                    ┌────────▼────────┐               │   │
│  │                    │   WKWebView     │               │   │
│  │                    │  (Web UI 容器)  │               │   │
│  │                    └────────┬────────┘               │   │
│  │                             │                        │   │
│  │  ┌──────────────────────────▼─────────────────────┐ │   │
│  │  │           MessageHandler (JS Bridge)            │ │   │
│  │  │  • getBalance() • getUsage() • getTools()      │ │   │
│  │  │  • saveKey() • loadKeys() • searchNews()       │ │   │
│  │  └────────────────────────────────────────────────┘ │   │
│  │                                                      │   │
│  │  ┌────────────────────────────────────────────┐      │   │
│  │  │            Native Services                  │      │   │
│  │  │  ┌──────────┐  ┌──────────┐  ┌─────────┐  │      │   │
│  │  │  │ Keychain │  │URLSession│  │ Timer   │  │      │   │
│  │  │  │ (密钥)   │  │ (API)    │  │ (定时刷新)│  │      │   │
│  │  │  └──────────┘  └──────────┘  └─────────┘  │      │   │
│  │  └────────────────────────────────────────────┘      │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              Web UI 层 (React)                       │   │
│  │                                                      │   │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────────────┐    │   │
│  │  │ 首页看板  │ │ 工具列表 │ │ 设置页           │    │   │
│  │  │ (Dashboard)│ │ (Tools)  │ │ (Settings)       │    │   │
│  │  └──────────┘ └──────────┘ └──────────────────┘    │   │
│  │                                                      │   │
│  │  ┌──── Zustand Store ────────────────────────────┐  │   │
│  │  │  balance | usage | tools | keys | settings    │  │   │
│  │  └──────────────────────────────────────────────┘  │   │
│  └─────────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────┘
```

---

## 2. 项目结构

```
deepseek-dashboard/
├── DeepSeekMenuBar.xcodeproj/     # Xcode 项目
├── Sources/
│   └── DeepSeekMenuBar/
│       ├── AppDelegate.swift       # 应用入口，NSStatusBar 配置
│       ├── StatusBarController.swift # 菜单栏图标管理
│       ├── PopoverController.swift   # NSPopover 管理
│       ├── WebViewController.swift   # WKWebView + JS Bridge
│       ├── KeychainManager.swift     # macOS Keychain CRUD
│       ├── APIClient.swift           # DeepSeek API 调用
│       └── Info.plist                # 应用配置 (LSUIElement=true)
├── WebUI/                           # React Web 前端
│   ├── src/
│   │   ├── components/
│   │   │   ├── PopupPanel.tsx        # 面板容器
│   │   │   ├── Dashboard.tsx         # 首页看板
│   │   │   ├── BalanceCard.tsx       # 余额卡片
│   │   │   ├── UsageCard.tsx         # 用量卡片
│   │   │   ├── ToolList.tsx          # 工具列表
│   │   │   ├── NewsFeed.tsx          # 资讯列表
│   │   │   ├── Settings.tsx          # 设置页
│   │   │   └── AccountSwitcher.tsx   # 账号切换器
│   │   ├── hooks/
│   │   │   └── useBridge.ts          # JS Bridge 通信
│   │   ├── stores/
│   │   │   └── appStore.ts           # Zustand Store
│   │   ├── types/
│   │   │   └── index.ts              # TypeScript 类型
│   │   ├── App.tsx
│   │   └── main.tsx
│   ├── index.html
│   ├── package.json
│   ├── vite.config.ts
│   ├── tailwind.config.ts
│   └── tsconfig.json
├── build.sh                          # 一键构建脚本
└── README.md
```

---

## 3. JS Bridge 接口定义

Web UI 通过 `window.webkit.messageHandlers` 与 Swift 原生层通信，接口如下：

### 3.1 Web → Native 调用

| 方法名 | 参数 | 返回 | 说明 |
|--------|------|------|------|
| `getBalance` | - | `{ balance: number, currency: string }` | 获取余额 |
| `getUsage` | - | `{ inputTokens: number, outputTokens: number, date: string }` | 获取当日用量 |
| `getTools` | - | `Tool[]` | 获取工具列表 |
| `searchNews` | `{ query: string }` | `NewsItem[]` | 搜索 DeepSeek 资讯 |
| `saveApiKey` | `{ key: string, name: string }` | `boolean` | 保存 API Key |
| `deleteApiKey` | `{ id: string }` | `boolean` | 删除 API Key |
| `getApiKeys` | - | `ApiKey[]` | 获取所有 Key |
| `setActiveKey` | `{ id: string }` | `boolean` | 切换当前 Key |
| `togglePin` | - | `{ pinned: boolean }` | 切换置顶 |
| `getAppInfo` | - | `{ version: string, platform: string }` | 获取应用信息 |

### 3.2 Native → Web 回调

| 事件名 | 数据 | 说明 |
|--------|------|------|
| `onDataUpdate` | `{ type: 'balance' \| 'usage', data: any }` | 定时数据刷新推送 |
| `onThemeChange` | `{ theme: 'light' \| 'dark' }` | 系统主题切换通知 |

---

## 4. 数据流

```
用户操作 → React UI → Zustand Store → window.webkit.postMessage()
                                         ↓
                              Swift MessageHandler
                                         ↓
                               Keychain / URLSession / Timer
                                         ↓
                              Swift 回调 → WKWebView.evaluateJavaScript()
                                         ↓
                              Zustand Store 更新 → UI 刷新
```

---

## 5. 关键实现细节

### 5.1 菜单栏图标
```swift
// AppDelegate.swift
let statusItem = NSStatusBar.system.statusItem(
    withLength: NSStatusItem.variableLength
)
statusItem.button?.image = NSImage(named: "menubar-icon")
```

### 5.2 弹出面板
```swift
// PopoverController.swift
let popover = NSPopover()
popover.contentSize = NSSize(width: 360, height: 480)
popover.behavior = .transient  // 点击外部自动关闭
popover.contentViewController = WebViewController()
```

### 5.3 安全性
- `LSUIElement = true` → 无 Dock 图标
- API Key 仅通过 Keychain 存取
- 通过 `SecItemAdd`/`SecItemCopyMatching` 操作 Keychain

### 5.4 自动刷新
- 使用 `Timer.scheduledTimer` 定时调用 API
- 默认间隔 300 秒（5 分钟）
- 数据通过 WKWebView 的 `evaluateJavaScript` 推送到 UI

---

## 6. 开发与构建

### 6.1 开发流程
```bash
# 1. 开发 Web UI（React 热更新）
cd WebUI
npm install
npm run dev            # 开发服务器 http://localhost:5173

# 2. 在 Xcode 中打开项目，设置 WebView 指向 localhost
# 3. Xcode Run → 菜单栏出现图标
```

### 6.2 生产构建
```bash
# 一键构建
./build.sh
```

`build.sh` 会执行：
1. `cd WebUI && npm run build` → 生成 `dist/` 静态文件
2. 将 `dist/` 复制到 Xcode 项目资源中
3. `xcodebuild -archive` → 生成 `.app`

### 6.3 系统要求
- Xcode 15.0+
- Node.js 18+
- macOS 13.0+ (部署目标)

---

## 7. 依赖清单

### 7.1 Swift (原生层)
- 纯 Swift 标准库，无第三方依赖
- 使用系统框架：AppKit, WebKit, Security(Keychain)

### 7.2 Web UI 层
```json
{
  "dependencies": {
    "react": "^18.3.0",
    "react-dom": "^18.3.0",
    "zustand": "^4.5.0"
  },
  "devDependencies": {
    "@types/react": "^18.3.0",
    "@types/react-dom": "^18.3.0",
    "@vitejs/plugin-react": "^4.3.0",
    "autoprefixer": "^10.4.0",
    "postcss": "^8.4.0",
    "tailwindcss": "^3.4.0",
    "typescript": "^5.4.0",
    "vite": "^5.4.0"
  }
}
```
