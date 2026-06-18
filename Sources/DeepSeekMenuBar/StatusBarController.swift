import AppKit

class StatusBarController: NSObject {
    private var statusItem: NSStatusItem!
    private var statusBarButton: NSStatusBarButton!
    private let popoverController: PopoverController
    private let bridgeHandler: BridgeHandler

    init(bridgeHandler: BridgeHandler) {
        self.bridgeHandler = bridgeHandler
        self.popoverController = PopoverController(bridgeHandler: bridgeHandler)

        super.init()

        setupStatusItem()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusBarButton = statusItem.button

        statusBarButton.image = createIcon()

        statusBarButton.action = #selector(togglePopover)
        statusBarButton.target = self
        statusBarButton.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    private func createIcon() -> NSImage {
        let size = NSSize(width: 20, height: 16)
        let image = NSImage(size: size)

        image.lockFocus()

        let rect = NSRect(x: 0, y: 0, width: 20, height: 16)
        let path = NSBezierPath(roundedRect: rect, xRadius: 4, yRadius: 4)

        let gradient = NSGradient(
            starting: NSColor(red: 0.23, green: 0.51, blue: 0.96, alpha: 1.0),
            ending: NSColor(red: 0.55, green: 0.34, blue: 0.97, alpha: 1.0)
        )
        gradient?.draw(in: path, angle: 135)

        let text = "D" as NSString
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 11),
            .foregroundColor: NSColor.white
        ]
        let textSize = text.size(withAttributes: attrs)
        let textPoint = NSPoint(
            x: (size.width - textSize.width) / 2,
            y: (size.height - textSize.height) / 2 - 0.5
        )
        text.draw(at: textPoint, withAttributes: attrs)

        image.unlockFocus()
        image.isTemplate = false

        return image
    }

    func showPopoverOnLaunch() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self, let button = self.statusBarButton else { return }
            self.popoverController.show(relativeTo: button.bounds, of: button)
        }
    }

    @objc private func togglePopover() {
        guard let button = statusBarButton else { return }

        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp {
            showContextMenu(button)
            return
        }

        if popoverController.isShown {
            if !popoverController.isCurrentlyPinned {
                popoverController.close()
            }
        } else {
            popoverController.show(relativeTo: button.bounds, of: button)
        }
    }

    private func showContextMenu(_ button: NSStatusBarButton) {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "关于 DeepSeek Menu Bar", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "退出", action: #selector(quitApp), keyEquivalent: "q"))
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height), in: button)
    }

    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "DeepSeek Menu Bar"
        alert.informativeText = "版本 1.0.0\nmacOS 菜单栏 DeepSeek API 管理工具"
        alert.alertStyle = .informational
        alert.runModal()
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
