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

        if popoverController.isShown {
            if !popoverController.isCurrentlyPinned {
                popoverController.close()
            }
        } else {
            popoverController.show(relativeTo: button.bounds, of: button)
        }
    }
}
