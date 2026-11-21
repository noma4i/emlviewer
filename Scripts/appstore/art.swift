import AppKit
import Foundation

let url = URL(fileURLWithPath: CommandLine.arguments[1])
let size = NSSize(width: 1200, height: 500)
let image = NSImage(size: size, flipped: false) { rect in
    NSGradient(starting: NSColor(red: 0.43, green: 0.72, blue: 0.80, alpha: 1), ending: NSColor(red: 0.88, green: 0.77, blue: 0.68, alpha: 1))!.draw(in: rect, angle: 90)
    NSColor(red: 0.99, green: 0.91, blue: 0.75, alpha: 1).setFill()
    NSBezierPath(ovalIn: NSRect(x: 765, y: 245, width: 130, height: 130)).fill()
    func hills(_ points: [(CGFloat, CGFloat)], _ color: NSColor) {
        let path = NSBezierPath()
        path.move(to: NSPoint(x: 0, y: 0))
        for (x, y) in points { path.line(to: NSPoint(x: x, y: y)) }
        path.line(to: NSPoint(x: 1200, y: 0))
        path.close()
        color.setFill()
        path.fill()
    }
    hills([(0, 155), (210, 315), (395, 172), (590, 335), (820, 148), (1000, 280), (1200, 155)], NSColor(red: 0.44, green: 0.62, blue: 0.65, alpha: 1))
    hills([(0, 75), (225, 208), (410, 105), (650, 240), (870, 100), (1080, 205), (1200, 125)], NSColor(red: 0.27, green: 0.46, blue: 0.49, alpha: 1))
    hills([(0, 25), (200, 110), (415, 62), (650, 143), (850, 62), (1050, 126), (1200, 50)], NSColor(red: 0.17, green: 0.34, blue: 0.37, alpha: 1))
    return true
}
let bitmap = NSBitmapImageRep(data: image.tiffRepresentation!)!
try bitmap.representation(using: .png, properties: [:])!.write(to: url)
