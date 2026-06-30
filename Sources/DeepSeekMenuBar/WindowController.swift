import AppKit
import WebKit

class WindowController: NSObject {
    private var window: NSWindow?
    private var webView: WKWebView?
    private(set) var isVisible = false

    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(toggleWindow), name: NSNotification.Name("ToggleWindow"), object: nil)
    }

    @objc func toggleWindow() {
        if isVisible {
            closeWindow()
        } else {
            showWindow()
        }
    }

    func showWindow() {
        if window == nil {
            createWindow()
        }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        isVisible = true
    }

    func closeWindow() {
        window?.orderOut(nil)
        isVisible = false
    }

    private func createWindow() {
        let windowRect = NSRect(x: 0, y: 0, width: 900, height: 620)
        window = NSWindow(
            contentRect: windowRect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false)
        window?.title = "DeepSeek 工具箱"
        window?.center()
        window?.isReleasedWhenClosed = false
        window?.minSize = NSSize(width: 520, height: 400)

        let webConfig = WKWebViewConfiguration()
        let controller = WKUserContentController()
        webConfig.userContentController = controller
        webConfig.preferences.setValue(true, forKey: "developerExtrasEnabled")

        let wkWebView = WKWebView(frame: windowRect, configuration: webConfig)
        wkWebView.autoresizingMask = [.width, .height]
        webView = wkWebView

        window?.contentView = wkWebView

        if let distPath = findDistPath(),
           let html = try? String(contentsOfFile: distPath.appendingPathComponent("index.html").path, encoding: .utf8) {
            wkWebView.loadHTMLString(html, baseURL: distPath)
        }
    }

    private func findDistPath() -> URL? {
        let paths = [
            Bundle.main.resourceURL?.appendingPathComponent("dist"),
            Bundle.main.bundleURL.deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("WebUI/dist")
        ]
        for p in paths {
            if let p = p, FileManager.default.fileExists(atPath: p.path) {
                return p
            }
        }
        return nil
    }
}
