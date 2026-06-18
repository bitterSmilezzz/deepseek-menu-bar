import AppKit
import WebKit

class WebViewController: NSViewController {
    private var webView: WKWebView!
    private let bridgeHandler: BridgeHandler
    private var isDevelopmentMode = false

    init(bridgeHandler: BridgeHandler) {
        self.bridgeHandler = bridgeHandler
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 370, height: 520))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        loadContent()
    }

    private func setupWebView() {
        let config = WKWebViewConfiguration()

        let userContentController = WKUserContentController()
        userContentController.add(bridgeHandler, name: "bridge")

        let js = """
        window.__bridgeCallback = function(response) {
            window.dispatchEvent(new CustomEvent('nativeBridgeResponse', { detail: response }));
        };
        window.__callNative = function(method, params) {
            return new Promise(function(resolve, reject) {
                var requestId = 'req_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
                function handler(event) {
                    var response = event.detail;
                    if (response.request_id === requestId) {
                        window.removeEventListener('nativeBridgeResponse', handler);
                        if (response.type === 'error') {
                            reject(new Error(response.error));
                        } else {
                            resolve(response.data);
                        }
                    }
                }
                window.addEventListener('nativeBridgeResponse', handler);
                window.webkit.messageHandlers.bridge.postMessage({
                    method: method,
                    params: params,
                    request_id: requestId
                });
                setTimeout(function() {
                    window.removeEventListener('nativeBridgeResponse', handler);
                    reject(new Error('Request timeout'));
                }, 30000);
            });
        };
        """
        let userScript = WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        userContentController.addUserScript(userScript)

        config.userContentController = userContentController

        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        config.defaultWebpagePreferences = preferences

        config.preferences.setValue(true, forKey: "developerExtrasEnabled")

        webView = WKWebView(frame: view.bounds, configuration: config)
        webView.autoresizingMask = [.width, .height]
        webView.setValue(false, forKey: "drawsBackground")

        view.addSubview(webView)
    }

    private func loadContent() {
        if isDevelopmentMode {
            loadDevServer()
        } else {
            loadLocalFile()
        }
    }

    private func loadLocalFile() {
        guard let resourcePath = Bundle.main.resourcePath else {
            loadFallback()
            return
        }

        let distPath = (resourcePath as NSString).appendingPathComponent("dist")
        var isDir: ObjCBool = false

        if FileManager.default.fileExists(atPath: distPath, isDirectory: &isDir), isDir.boolValue {
            let url = URL(fileURLWithPath: distPath)
            webView.loadFileURL(url.appendingPathComponent("index.html"), allowingReadAccessTo: url)
        } else {
            loadFallback()
        }
    }

    private func loadDevServer() {
        if let url = URL(string: "http://localhost:5173") {
            webView.load(URLRequest(url: url))
        }
    }

    private func loadFallback() {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
                    background: linear-gradient(135deg, #1a1a2e, #16213e);
                    color: #e0e0e0;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    height: 100vh;
                    text-align: center;
                    padding: 20px;
                }
                .container { max-width: 320px; }
                .icon { font-size: 48px; margin-bottom: 16px; }
                h1 { font-size: 20px; margin-bottom: 8px; color: #4fc3f7; }
                p { font-size: 14px; color: #999; line-height: 1.5; }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="icon">🔍</div>
                <h1>WebUI Not Loaded</h1>
                <p>Please build the WebUI first by running:<br><code>cd WebUI && npm run build</code></p>
            </div>
        </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: nil)
    }

    func toggleDeveloperMode() {
        isDevelopmentMode.toggle()
        loadContent()
    }

    var isDeveloperMode: Bool {
        isDevelopmentMode
    }
}
