import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let raw = root.appendingPathComponent("Scripts/appstore/raw")
let output = root.appendingPathComponent("AppStore/screenshots/en-US")
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
let frames: [(String, String, String, String, Bool)] = [
    ("01-open-eml", "hero-light", "Every email, beautifully clear", "Open .eml files and see every detail.", false),
    ("02-open-msg", "outlook", "Outlook messages made simple", "Read .msg files right on your Mac.", false),
    ("03-attachments", "attachments", "Every attachment within reach", "Find and save your files in one place.", false),
    ("04-dark", "hero-dark", "Ten themes, always readable", "Read comfortably in your preferred appearance.", true),
    ("05-settings", "settings-message", "Make reading your own", "Choose your font, size, and appearance.", false),
    ("06-welcome", "welcome", "Open mail in a click", "A simple home for .eml and .msg files.", false)
]
let size = NSSize(width: 2880, height: 1800)
let cs = CGColorSpace(name: CGColorSpace.sRGB)!
for (name, source, title, subtitle, dark) in frames {
    let context = CGContext(data: nil, width: 2880, height: 1800, bitsPerComponent: 8, bytesPerRow: 2880 * 4, space: cs, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
    let colors = dark ? [NSColor(calibratedRed: 0.10, green: 0.12, blue: 0.25, alpha: 1), NSColor(calibratedRed: 0.20, green: 0.15, blue: 0.34, alpha: 1)] : [NSColor(calibratedRed: 0.84, green: 0.94, blue: 0.98, alpha: 1), NSColor(calibratedRed: 0.88, green: 0.84, blue: 0.97, alpha: 1)]
    NSGradient(starting: colors[0], ending: colors[1])!.draw(in: NSRect(origin: .zero, size: size), angle: -35)
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    let ink = dark ? NSColor.white : NSColor(calibratedRed: 0.10, green: 0.13, blue: 0.24, alpha: 1)
    (title as NSString).draw(in: NSRect(x: 120, y: 1605, width: 2640, height: 100), withAttributes: [.font: NSFont.systemFont(ofSize: 82, weight: .bold), .foregroundColor: ink, .paragraphStyle: paragraph])
    (subtitle as NSString).draw(in: NSRect(x: 120, y: 1525, width: 2640, height: 60), withAttributes: [.font: NSFont.systemFont(ofSize: 39, weight: .regular), .foregroundColor: ink.withAlphaComponent(0.75), .paragraphStyle: paragraph])
    if name == "04-dark" {
        let back = NSImage(contentsOf: raw.appendingPathComponent("hero-nord.png"))!
        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: -18), blur: 55, color: NSColor.black.withAlphaComponent(0.3).cgColor)
        back.draw(in: NSRect(x: 1490, y: 140, width: 1300 * back.size.width / back.size.height, height: 1300))
        context.restoreGState()
    }
    let image = NSImage(contentsOf: raw.appendingPathComponent(source + ".png"))!
    let scale = min(2300 / image.size.width, 1380 / image.size.height)
    let rect = name == "04-dark" ? NSRect(x: 176, y: 140, width: 1300 * image.size.width / image.size.height, height: 1300) : NSRect(x: (2880 - image.size.width * scale) / 2, y: 100 + (1380 - image.size.height * scale) / 2, width: image.size.width * scale, height: image.size.height * scale)
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -18), blur: 55, color: NSColor.black.withAlphaComponent(0.25).cgColor)
    image.draw(in: rect)
    context.restoreGState()
    if name == "05-settings" {
        let settings = NSImage(contentsOf: raw.appendingPathComponent("settings.png"))!
        let crop = NSRect(x: 0, y: settings.size.height * 0.58, width: settings.size.width, height: settings.size.height * 0.42)
        let overlay = NSRect(x: 1430, y: 360, width: settings.size.width * 1.7, height: crop.height * 1.7)
        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: -16), blur: 48, color: NSColor.black.withAlphaComponent(0.35).cgColor)
        settings.draw(in: overlay, from: crop, operation: .sourceOver, fraction: 1)
        context.restoreGState()
    }
    NSGraphicsContext.restoreGraphicsState()
    let bitmap = NSBitmapImageRep(cgImage: context.makeImage()!)
    try bitmap.representation(using: .png, properties: [:])!.write(to: output.appendingPathComponent(name + ".png"))
}
