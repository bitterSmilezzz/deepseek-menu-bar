#!/usr/bin/env swift
import AppKit
import Foundation

let args = CommandLine.arguments
let sourcePath: String?
let outputDir: String

if args.count >= 3 {
    sourcePath = args[1]
    outputDir = args[2]
} else if args.count >= 2 {
    sourcePath = nil
    outputDir = args[1]
} else {
    print("Usage: gen_icon.swift [source_png] <output_dir>")
    exit(1)
}

let assetsDir = "\(outputDir)/icon.iconset"

guard let sourcePath = sourcePath,
      let sourceImage = NSImage(contentsOfFile: sourcePath) else {
    generateProgrammaticIcon(outputDir: outputDir)
    exit(0)
}

let sourceRep = sourceImage.representations.first as? NSBitmapImageRep
let sourceWidth = CGFloat(sourceRep?.pixelsWide ?? 225)
let sourceHeight = CGFloat(sourceRep?.pixelsHigh ?? 225)

generateIcons(outputDir: outputDir) { img, name, size in
    let crop = min(sourceWidth, sourceHeight)
    let srcX = (sourceWidth - crop) / 2
    let srcY = (sourceHeight - crop) / 2
    let srcRect = NSRect(x: srcX, y: srcY, width: crop, height: crop)
    let dstRect = NSRect(x: 0, y: 0, width: CGFloat(size), height: CGFloat(size))
    img.lockFocus()
    sourceImage.draw(in: dstRect, from: srcRect, operation: .copy, fraction: 1.0)
    img.unlockFocus()
}

packIcons(outputDir: outputDir)

func generateProgrammaticIcon(outputDir: String) {
    generateIcons(outputDir: outputDir) { img, name, size in
        img.lockFocus()
        let inset = CGFloat(size) / 10
        let rect = NSRect(x: 0, y: 0, width: CGFloat(size), height: CGFloat(size)).insetBy(dx: inset, dy: inset)
        let path = NSBezierPath(roundedRect: rect, xRadius: CGFloat(size) / 5, yRadius: CGFloat(size) / 5)
        let gradient = NSGradient(
            starting: NSColor(red: 0.23, green: 0.51, blue: 0.96, alpha: 1.0),
            ending: NSColor(red: 0.55, green: 0.34, blue: 0.97, alpha: 1.0))
        gradient?.draw(in: path, angle: 135)
        let text = "D" as NSString
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: CGFloat(size) * 0.5),
            .foregroundColor: NSColor.white
        ]
        let ts = text.size(withAttributes: attrs)
        text.draw(at: NSPoint(x: (CGFloat(size) - ts.width) / 2, y: (CGFloat(size) - ts.height) / 2 - 1), withAttributes: attrs)
        img.unlockFocus()
    }
    packIcons(outputDir: outputDir)
}

func generateIcons(outputDir: String, draw: (NSImage, String, Int) -> Void) {
    let sizes: [(String, Int)] = [
        ("icon_16x16.png", 16), ("icon_16x16@2x.png", 32),
        ("icon_32x32.png", 32), ("icon_32x32@2x.png", 64),
        ("icon_128x128.png", 128), ("icon_128x128@2x.png", 256),
        ("icon_256x256.png", 256), ("icon_256x256@2x.png", 512),
        ("icon_512x512.png", 512), ("icon_512x512@2x.png", 1024),
    ]
    try? FileManager.default.createDirectory(atPath: assetsDir, withIntermediateDirectories: true)
    for (name, size) in sizes {
        let img = NSImage(size: NSSize(width: size, height: size))
        draw(img, name, size)
        guard let tiff = img.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let png = bitmap.representation(using: .png, properties: [:]) else {
            print("Failed to render: \(name)")
            continue
        }
        try? png.write(to: URL(fileURLWithPath: "\(assetsDir)/\(name)"))
        print("  \(name) \(size)x\(size)")
    }
}

func packIcons(outputDir: String) {
    let icnsPath = "\(outputDir)/app.icns"
    let task = Process()
    task.launchPath = "/usr/bin/iconutil"
    task.arguments = ["-c", "icns", assetsDir, "-o", icnsPath]
    try? task.run()
    task.waitUntilExit()
    print("  -> \(icnsPath)")
}
