#!/usr/bin/env swift
import AppKit
import Foundation

let baseDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
let assetsDir = "\(baseDir)/icon.iconset"
try? FileManager.default.createDirectory(atPath: assetsDir, withIntermediateDirectories: true)

let sizes: [(String, Int)] = [
    ("icon_16x16.png", 16), ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32), ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128), ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256), ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512), ("icon_512x512@2x.png", 1024),
]

for (name, size) in sizes {
    let img = NSImage(size: NSSize(width: size, height: size))
    img.lockFocus()
    
    let rect = NSRect(x: 0, y: 0, width: CGFloat(size), height: CGFloat(size))
    let margin = CGFloat(size) / 10
    let inset = rect.insetBy(dx: margin, dy: margin)
    let path = NSBezierPath(roundedRect: inset, xRadius: CGFloat(size) / 5, yRadius: CGFloat(size) / 5)
    
    let gradient = NSGradient(
        starting: NSColor(red: 0.23, green: 0.51, blue: 0.96, alpha: 1.0),
        ending: NSColor(red: 0.55, green: 0.34, blue: 0.97, alpha: 1.0))
    gradient?.draw(in: path, angle: 135)
    
    let text = "D" as NSString
    let fontSize = CGFloat(size) * 0.5
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.boldSystemFont(ofSize: fontSize),
        .foregroundColor: NSColor.white
    ]
    let textSize = text.size(withAttributes: attrs)
    let textPoint = NSPoint(
        x: (CGFloat(size) - textSize.width) / 2,
        y: (CGFloat(size) - textSize.height) / 2 - 1)
    text.draw(at: textPoint, withAttributes: attrs)
    
    img.unlockFocus()
    
    guard let tiff = img.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else {
        fatalError("Failed to render PNG")
    }
    try png.write(to: URL(fileURLWithPath: "\(assetsDir)/\(name)"))
    print("  \(name) \(size)x\(size)")
}

let icnsPath = "\(baseDir)/app.icns"
let task = Process()
task.launchPath = "/usr/bin/iconutil"
task.arguments = ["-c", "icns", assetsDir, "-o", icnsPath]
try task.run()
task.waitUntilExit()
print("  -> \(icnsPath)")
