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
        if #available(macOS 10.13, *) {
            webView.setValue(true, forKey: "drawsBackground")
            webView.setValue(NSColor(red: 0x0a/255, green: 0x0a/255, blue: 0x0f/255, alpha: 1), forKey: "backgroundColor")
        }

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
        let distPaths = possibleDistPaths()
        for distPath in distPaths {
            let indexPath = (distPath as NSString).appendingPathComponent("index.html")
            if FileManager.default.fileExists(atPath: indexPath) {
                do {
                    let html = try String(contentsOfFile: indexPath, encoding: .utf8)
                    let url = URL(fileURLWithPath: distPath)
                    webView.loadHTMLString(html, baseURL: url)
                    return
                } catch {
                    continue
                }
            }
        }
        loadFallback()
    }

    private func possibleDistPaths() -> [String] {
        var paths: [String] = []

        if let resourcePath = Bundle.main.resourcePath {
            paths.append((resourcePath as NSString).appendingPathComponent("dist"))
        }

        let execURL = Bundle.main.executableURL
        if let execPath = execURL?.path {
            var projectRoot = (execPath as NSString).deletingLastPathComponent
            if projectRoot.hasSuffix(".build/debug") || projectRoot.hasSuffix(".build/release") {
                for _ in 0..<3 {
                    projectRoot = (projectRoot as NSString).deletingLastPathComponent
                }
            } else if projectRoot.hasSuffix("MacOS") {
                projectRoot = ((projectRoot as NSString).deletingLastPathComponent as NSString).deletingLastPathComponent
            }
            projectRoot = (projectRoot as NSString).standardizingPath
            paths.append((projectRoot as NSString).appendingPathComponent("WebUI/dist"))
        }

        paths.append((FileManager.default.currentDirectoryPath as NSString).appendingPathComponent("WebUI/dist"))

        return paths
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
                .paths { font-size: 11px; color: #666; margin-top: 12px; }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="icon">🔍</div>
                <h1>WebUI Not Loaded</h1>
                <p>Please build the WebUI first by running:<br><code>cd WebUI && npm run build</code></p>
                <p class="paths">Searched:<br>\(possibleDistPaths().joined(separator: "<br>"))</p>
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
