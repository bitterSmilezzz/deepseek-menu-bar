import AppKit

class StatusBarController: NSObject {
    private var statusItem: NSStatusItem!
    private let popoverController: PopoverController
    private let bridgeHandler: BridgeHandler

    init(bridgeHandler: BridgeHandler) {
        self.bridgeHandler = bridgeHandler
        self.popoverController = PopoverController(bridgeHandler: bridgeHandler)

        super.init()

        setupStatusItem()
        setupRightClickMonitor()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = createIcon()

        statusItem.button?.action = #selector(togglePopover)
        statusItem.button?.target = self
    }

    private func setupRightClickMonitor() {
        NSEvent.addLocalMonitorForEvents(matching: .rightMouseUp) { [weak self] event in
            guard let self = self, let button = self.statusItem.button,
                  event.window == button.window else { return event }
            let loc = button.convert(event.locationInWindow, from: nil)
            if button.bounds.contains(loc) {
                self.showContextMenu(at: button)
                return nil
            }
            return event
        }
    }

    private func showContextMenu(at view: NSView) {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "关于 DeepSeek 工具箱", action: #selector(showAbout), keyEquivalent: ""))

        let running = ProxyServer.shared.isRunning
        let proxyTitle = running ? "停止代理" : "启动代理"
        let proxyAction = running ? #selector(stopProxy) : #selector(startProxy)
        menu.addItem(NSMenuItem(title: proxyTitle, action: proxyAction, keyEquivalent: ""))

        menu.addItem(NSMenuItem(title: "打开窗口", action: #selector(openWindow), keyEquivalent: "w"))
        menu.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(title: "退出 DeepSeek 工具箱", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: view.bounds.height), in: view)
    }

    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "DeepSeek 工具箱"
        alert.informativeText = "AI 用量追踪器 v2.0\n本地 HTTP 代理 · Token 统计 · 实时计费"
        alert.alertStyle = .informational
        alert.runModal()
    }

    @objc private func startProxy() {
        try? ProxyServer.shared.start()
    }

    @objc private func stopProxy() {
        ProxyServer.shared.stop()
    }

    @objc private func openWindow() {
        NotificationCenter.default.post(name: NSNotification.Name("ToggleWindow"), object: nil)
    }

    private func createIcon() -> NSImage {
        let size = NSSize(width: 20, height: 16)
        let image = NSImage(size: size)
        image.lockFocus()
        let rect = NSRect(x: 0, y: 0, width: 20, height: 16)
        let path = NSBezierPath(roundedRect: rect, xRadius: 4, yRadius: 4)
        let gradient = NSGradient(
            starting: NSColor(red: 0.23, green: 0.51, blue: 0.96, alpha: 1.0),
            ending: NSColor(red: 0.55, green: 0.34, blue: 0.97, alpha: 1.0))
        gradient?.draw(in: path, angle: 135)

        let running = ProxyServer.shared.isRunning
        let indicator = running ? "●" : "D"
        let text = indicator as NSString
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 11),
            .foregroundColor: running ? NSColor(red: 0.1, green: 0.8, blue: 0.5, alpha: 1.0) : NSColor.white
        ]
        let textSize = text.size(withAttributes: attrs)
        text.draw(at: NSPoint(x: (size.width - textSize.width) / 2, y: (size.height - textSize.height) / 2 - 0.5), withAttributes: attrs)
        image.unlockFocus()
        image.isTemplate = false
        return image
    }

    func showPopoverOnLaunch() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self, let button = self.statusItem.button else { return }
            self.popoverController.show(relativeTo: button.bounds, of: button)
        }
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popoverController.isShown {
            if !popoverController.isCurrentlyPinned { popoverController.close() }
        } else {
            popoverController.show(relativeTo: button.bounds, of: button)
        }
    }

    @objc private func quitApp() {
        ProxyServer.shared.stop()
        NSApplication.shared.terminate(nil)
    }
}
