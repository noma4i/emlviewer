import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let output = root.appendingPathComponent("site/public/img/og.png")
let icon = NSImage(contentsOf: root.appendingPathComponent("Sources/EMLViewer/Resources/Assets.xcassets/AppIcon.appiconset/icon_512x512@2x.png"))!
let window = NSImage(contentsOf: root.appendingPathComponent("Scripts/appstore/raw/hero-light.png"))!
let context = CGContext(data: nil, width: 1200, height: 630, bitsPerComponent: 8, bytesPerRow: 4800, space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
let colors = [NSColor(calibratedRed: 0.84, green: 0.94, blue: 0.98, alpha: 1), NSColor(calibratedRed: 0.88, green: 0.84, blue: 0.97, alpha: 1)]
NSGradient(starting: colors[0], ending: colors[1])!.draw(in: NSRect(x: 0, y: 0, width: 1200, height: 630), angle: -35)
let ink = NSColor(calibratedRed: 0.10, green: 0.13, blue: 0.24, alpha: 1)
icon.draw(in: NSRect(x: 55, y: 425, width: 150, height: 150))
("EML/MSG\nViewer" as NSString).draw(in: NSRect(x: 55, y: 255, width: 540, height: 165), withAttributes: [.font: NSFont.systemFont(ofSize: 72, weight: .bold), .foregroundColor: ink])
("Open .eml and Outlook .msg files on your Mac. No mail client needed." as NSString).draw(in: NSRect(x: 58, y: 105, width: 500, height: 140), withAttributes: [.font: NSFont.systemFont(ofSize: 32), .foregroundColor: ink.withAlphaComponent(0.85)])
let rect = NSRect(x: 638, y: -48, width: 590, height: 590 * window.size.height / window.size.width)
let mask = NSBezierPath(roundedRect: rect, xRadius: 16, yRadius: 16)
context.saveGState()
context.setShadow(offset: CGSize(width: 0, height: -12), blur: 32, color: NSColor.black.withAlphaComponent(0.25).cgColor)
NSColor.white.setFill()
mask.fill()
context.restoreGState()
context.saveGState()
mask.addClip()
window.draw(in: rect)
context.restoreGState()
NSGraphicsContext.restoreGraphicsState()
let bitmap = NSBitmapImageRep(cgImage: context.makeImage()!)
try bitmap.representation(using: .png, properties: [:])!.write(to: output)
