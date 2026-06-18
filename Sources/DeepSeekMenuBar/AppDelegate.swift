import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController!
    private var bridgeHandler: BridgeHandler!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        bridgeHandler = BridgeHandler()
        statusBarController = StatusBarController(bridgeHandler: bridgeHandler)

        statusBarController.showPopoverOnLaunch()
    }
}
