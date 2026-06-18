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

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusBarButton = statusItem.button

        updateIcon(normal: true)

        statusBarButton.action = #selector(togglePopover)
        statusBarButton.target = self
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

    private func updateIcon(normal: Bool) {
        let imageName = normal ? "brain.head.profile" : "brain.head.profile.fill"

        if let image = NSImage(systemSymbolName: imageName, accessibilityDescription: "DeepSeek Menu Bar") {
            image.isTemplate = true
            statusBarButton.image = image
        } else {
            statusBarButton.title = "DS"
        }

        if balanceBelowThreshold {
            if let image = statusBarButton.image {
                let coloredImage = image.copy() as! NSImage
                coloredImage.isTemplate = false
                statusBarButton.image = coloredImage
            }
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
