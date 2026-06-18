import AppKit

class StatusBarController: NSObject {
    private var statusItem: NSStatusItem!
    private var statusBarButton: NSStatusBarButton!
    private let popoverController: PopoverController
    private let bridgeHandler: BridgeHandler
    private var balanceBelowThreshold = false
    private let lowBalanceThreshold = 1.0

    init(bridgeHandler: BridgeHandler) {
        self.bridgeHandler = bridgeHandler
        self.popoverController = PopoverController(bridgeHandler: bridgeHandler)

        super.init()

        setupStatusItem()
        setupObservers()
    }

    private func setupObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(activeKeyChanged),
            name: NSNotification.Name("ActiveKeyChanged"),
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(balanceDidUpdate),
            name: NSNotification.Name("BalanceDidUpdate"),
            object: nil
        )
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusBarButton = statusItem.button

        setupCustomIcon()

        statusBarButton.action = #selector(togglePopover)
        statusBarButton.target = self
    }

    private func setupCustomIcon() {
        let iconSize = NSSize(width: 18, height: 18)
        let image = NSImage(size: iconSize)
        image.lockFocus()

        let rect = NSRect(origin: .zero, size: iconSize)
        let path = NSBezierPath(roundedRect: rect, xRadius: 4, yRadius: 4)

        let gradient = NSGradient(starting: NSColor(red: 0.23, green: 0.51, blue: 0.96, alpha: 1.0),
                                  ending: NSColor(red: 0.55, green: 0.34, blue: 0.97, alpha: 1.0))
        gradient?.draw(in: path, angle: 135)

        let text = "D" as NSString
        let textAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 11),
            .foregroundColor: NSColor.white
        ]
        let textSize = text.size(withAttributes: textAttrs)
        let textRect = NSRect(
            x: (iconSize.width - textSize.width) / 2,
            y: (iconSize.height - textSize.height) / 2 - 0.5,
            width: textSize.width,
            height: textSize.height
        )
        text.draw(in: textRect, withAttributes: textAttrs)

        image.unlockFocus()
        image.isTemplate = false

        statusBarButton.image = image
    }

    func showPopoverOnLaunch() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self, let button = self.statusBarButton else { return }
            self.popoverController.show(relativeTo: button.bounds, of: button)
        }
    }

    private func updateIcon(normal: Bool) {
        setupCustomIcon()

        if balanceBelowThreshold {
            statusBarButton.contentTintColor = .systemYellow
        } else {
            statusBarButton.contentTintColor = nil
        }
    }

    @objc private func togglePopover() {
        guard let button = statusBarButton else { return }

        if popoverController.isShown {
            if !popoverController.isCurrentlyPinned {
                popoverController.close()
            }
        } else {
            popoverController.show(relativeTo: button.bounds, of: button)
        }
    }

    @objc private func activeKeyChanged(_ notification: Notification) {
        let keyId = notification.object as? String
        bridgeHandler.setActiveKeyId(keyId)
    }

    @objc private func balanceDidUpdate(_ notification: Notification) {
        if let balanceString = notification.object as? String,
           let balance = Double(balanceString) {
            balanceBelowThreshold = balance < lowBalanceThreshold
            updateIcon(normal: !balanceBelowThreshold)
        }
    }

    func setBalanceBelowThreshold(_ below: Bool) {
        balanceBelowThreshold = below
        updateIcon(normal: !below)
    }
}
