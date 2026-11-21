import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let raw = root.appendingPathComponent("Scripts/appstore/raw")
let output = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let frames: [(String, String, String, String, Bool)] = [
    ("01-open-eml", "hero-light", "Open .eml files without a mail client", "Headers, HTML body and inline images in one window.", false),
    ("02-open-msg", "outlook", "Open Outlook .msg files", "No Outlook required.", false),
    ("03-attachments", "attachments", "Open or save attachments", "Open in the default app or save all to a folder.", false),
    ("04-dark", "hero-dark", "Dark mode and color themes", "HTML mail is recolored to stay readable.", true),
    ("05-settings", "settings-message", "Font, size and theme", "Set them once in Settings.", false),
    ("06-welcome", "welcome", "Double-click to open", "Set as the default app for .eml and .msg in Finder.", false)
]
let size = NSSize(width: 1920, height: 1080)
let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
for (index, frame) in frames.enumerated() {
    let (name, source, title, subtitle, dark) = frame
    let context = CGContext(data: nil, width: 1920, height: 1080, bitsPerComponent: 8, bytesPerRow: 1920 * 4, space: colorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
    let colors = dark ? [NSColor(calibratedRed: 0.10, green: 0.12, blue: 0.25, alpha: 1), NSColor(calibratedRed: 0.20, green: 0.15, blue: 0.34, alpha: 1)] : [NSColor(calibratedRed: 0.84, green: 0.94, blue: 0.98, alpha: 1), NSColor(calibratedRed: 0.88, green: 0.84, blue: 0.97, alpha: 1)]
    NSGradient(starting: colors[0], ending: colors[1])!.draw(in: NSRect(origin: .zero, size: size), angle: -35)
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    let ink = dark ? NSColor.white : NSColor(calibratedRed: 0.10, green: 0.13, blue: 0.24, alpha: 1)
    (title as NSString).draw(in: NSRect(x: 100, y: 960, width: 1720, height: 70), withAttributes: [.font: NSFont.systemFont(ofSize: 55, weight: .bold), .foregroundColor: ink, .paragraphStyle: paragraph])
    (subtitle as NSString).draw(in: NSRect(x: 100, y: 910, width: 1720, height: 40), withAttributes: [.font: NSFont.systemFont(ofSize: 26), .foregroundColor: ink.withAlphaComponent(0.75), .paragraphStyle: paragraph])
    func drawWindow(_ image: NSImage, in rect: NSRect) {
        let mask = NSBezierPath(roundedRect: rect, xRadius: 12, yRadius: 12)
        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: -12), blur: 36, color: NSColor.black.withAlphaComponent(0.25).cgColor)
        NSColor.white.setFill()
        mask.fill()
        context.restoreGState()
        context.saveGState()
        mask.addClip()
        image.draw(in: rect)
        context.restoreGState()
    }
    let image = NSImage(contentsOf: raw.appendingPathComponent(source + ".png"))!
    let bounds = NSRect(x: 100, y: 70, width: 1720, height: 810)
    let scale = min(bounds.width / image.size.width, bounds.height / image.size.height)
    let rect = NSRect(x: bounds.midX - image.size.width * scale / 2, y: bounds.midY - image.size.height * scale / 2, width: image.size.width * scale, height: image.size.height * scale)
    if name == "04-dark" {
        let back = NSImage(contentsOf: raw.appendingPathComponent("hero-nord.png"))!
        let darkScale = min(1050 / image.size.width, 730 / image.size.height)
        let backScale = min(1050 / back.size.width, 730 / back.size.height)
        var backRect = NSRect(x: 780, y: 80, width: back.size.width * backScale, height: back.size.height * backScale)
        var darkRect = NSRect(x: 110, y: 130, width: image.size.width * darkScale, height: image.size.height * darkScale)
        let offset = size.width / 2 - backRect.union(darkRect).midX
        backRect.origin.x += offset
        darkRect.origin.x += offset
        drawWindow(back, in: backRect)
        drawWindow(image, in: darkRect)
    } else {
        drawWindow(image, in: rect)
    }
    if name == "05-settings" {
        let settings = NSImage(contentsOf: raw.appendingPathComponent("settings.png"))!
        let crop = NSRect(x: 0, y: settings.size.height * 0.58, width: settings.size.width, height: settings.size.height * 0.42)
        let overlay = NSRect(x: (1920 - settings.size.width) / 2, y: 230, width: settings.size.width, height: crop.height)
        let mask = NSBezierPath(roundedRect: overlay, xRadius: 12, yRadius: 12)
        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: -12), blur: 36, color: NSColor.black.withAlphaComponent(0.25).cgColor)
        NSColor.white.setFill()
        mask.fill()
        context.restoreGState()
        context.saveGState()
        mask.addClip()
        settings.draw(in: overlay, from: crop, operation: .sourceOver, fraction: 1)
        context.restoreGState()
    }
    NSGraphicsContext.restoreGraphicsState()
    let bitmap = NSBitmapImageRep(cgImage: context.makeImage()!)
    try bitmap.representation(using: .png, properties: [:])!.write(to: output.appendingPathComponent("\(index).png"))
}
