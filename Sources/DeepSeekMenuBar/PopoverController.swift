import AppKit
import WebKit

class PopoverController: NSObject {
    private let popover: NSPopover
    private let webViewController: WebViewController
    private let bridgeHandler: BridgeHandler
    private var isPinned = false

    var isShown: Bool {
        popover.isShown
    }

    init(bridgeHandler: BridgeHandler) {
        self.bridgeHandler = bridgeHandler
        self.popover = NSPopover()
        self.webViewController = WebViewController(bridgeHandler: bridgeHandler)

        super.init()

        popover.contentViewController = webViewController
        popover.contentSize = NSSize(width: 370, height: 520)
        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self

        bridgeHandler.popoverController = self
    }

    func show(relativeTo rect: NSRect, of view: NSView, preferredEdge: NSRectEdge = .minY) {
        popover.show(relativeTo: rect, of: view, preferredEdge: preferredEdge)
    }

    func close() {
        popover.close()
    }

    func toggle(relativeTo rect: NSRect, of view: NSView, preferredEdge: NSRectEdge = .minY) {
        if popover.isShown {
            if !isPinned {
                close()
            }
        } else {
            show(relativeTo: rect, of: view, preferredEdge: preferredEdge)
        }
    }

    func togglePin() {
        isPinned.toggle()
        popover.behavior = isPinned ? .applicationDefined : .transient

        if let webView = webViewController.view as? WKWebView? {
            let js = "window.dispatchEvent(new CustomEvent('pinChanged', { detail: { isPinned: \(isPinned) } }))"
            webView?.evaluateJavaScript(js, completionHandler: nil)
        }
    }

    var isCurrentlyPinned: Bool {
        isPinned
    }
}

extension PopoverController: NSPopoverDelegate {
    func popoverShouldDetach(_ popover: NSPopover) -> Bool {
        return true
    }

    func popoverDidDetach(_ popover: NSPopover) {
        isPinned = true
    }
}
