import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController!
    private var bridgeHandler: BridgeHandler!
    private var windowController: WindowController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        bridgeHandler = BridgeHandler()
        statusBarController = StatusBarController(bridgeHandler: bridgeHandler)
        windowController = WindowController()

        statusBarController.showPopoverOnLaunch()

        DispatchQueue.global(qos: .background).async {
            try? ProxyServer.shared.start()
        }
    }
}
