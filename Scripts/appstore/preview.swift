import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let raw = root.appendingPathComponent("Scripts/appstore/raw")
let size = NSSize(width: 1920, height: 1080)
let space = CGColorSpace(name: CGColorSpace.sRGB)!
let bounds = NSRect(origin: .zero, size: size)
let scenes: [(String, String, String, Bool)] = [
    ("hero-light", "Got an .eml file?", "Double-click it to read the email: headers, text and images.", false),
    ("outlook", "Outlook .msg files too", "Read Outlook messages without installing Outlook.", false),
    ("attachments", "Get the attachments out", "Open any attachment, or save them all to a folder.", false),
    ("hero-dark", "Dark mode and 10 themes", "HTML mail is recolored so it stays readable.", true),
    ("settings-message", "Your font, your size", "Pick the font, text size and theme in Settings.", false),
    ("welcome", "Make it the default", "Then every .eml and .msg opens with a double-click.", false)
]

func context() -> CGContext {
    CGContext(data: nil, width: 1920, height: 1080, bitsPerComponent: 8, bytesPerRow: 1920 * 4, space: space, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)!
}
func layer(_ draw: (CGContext) -> Void) -> CGImage {
    let ctx = context()
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
    draw(ctx)
    NSGraphicsContext.restoreGraphicsState()
    return ctx.makeImage()!
}
func textLayer(_ text: String, y: CGFloat, font: NSFont, color: NSColor) -> CGImage {
    layer { _ in
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        (text as NSString).draw(in: NSRect(x: 100, y: y, width: 1720, height: 80), withAttributes: [.font: font, .foregroundColor: color, .paragraphStyle: paragraph])
    }
}
func window(_ image: NSImage, _ rect: NSRect, _ ctx: CGContext, crop: NSRect? = nil) {
    let mask = NSBezierPath(roundedRect: rect, xRadius: 12, yRadius: 12)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -12), blur: 36, color: NSColor.black.withAlphaComponent(0.25).cgColor)
    NSColor.white.setFill()
    mask.fill()
    ctx.restoreGState()
    ctx.saveGState()
    mask.addClip()
    image.draw(in: rect, from: crop ?? .zero, operation: .sourceOver, fraction: 1)
    ctx.restoreGState()
}
let backgrounds = [false, true].map { dark in
    layer { _ in
        let colors = dark ? [NSColor(calibratedRed: 0.10, green: 0.12, blue: 0.25, alpha: 1), NSColor(calibratedRed: 0.20, green: 0.15, blue: 0.34, alpha: 1)] : [NSColor(calibratedRed: 0.84, green: 0.94, blue: 0.98, alpha: 1), NSColor(calibratedRed: 0.88, green: 0.84, blue: 0.97, alpha: 1)]
        NSGradient(starting: colors[0], ending: colors[1])!.draw(in: bounds, angle: -35)
    }
}
let ink = NSColor(calibratedRed: 0.10, green: 0.13, blue: 0.24, alpha: 1)
let windows = scenes.enumerated().map { index, scene in
    layer { ctx in
        let image = NSImage(contentsOf: raw.appendingPathComponent(scene.0 + ".png"))!
        let area = NSRect(x: 100, y: 70, width: 1720, height: 810)
        let scale = min(area.width / image.size.width, area.height / image.size.height)
        let rect = NSRect(x: area.midX - image.size.width * scale / 2, y: area.midY - image.size.height * scale / 2, width: image.size.width * scale, height: image.size.height * scale)
        if index == 3 {
            let back = NSImage(contentsOf: raw.appendingPathComponent("hero-nord.png"))!
            let darkScale = min(1050 / image.size.width, 730 / image.size.height)
            let backScale = min(1050 / back.size.width, 730 / back.size.height)
            var backRect = NSRect(x: 780, y: 80, width: back.size.width * backScale, height: back.size.height * backScale)
            var darkRect = NSRect(x: 110, y: 130, width: image.size.width * darkScale, height: image.size.height * darkScale)
            let offset = size.width / 2 - backRect.union(darkRect).midX
            backRect.origin.x += offset
            darkRect.origin.x += offset
            window(back, backRect, ctx)
            window(image, darkRect, ctx)
        } else {
            window(image, rect, ctx)
        }
        if index == 4 {
            let settings = NSImage(contentsOf: raw.appendingPathComponent("settings.png"))!
            let crop = NSRect(x: 0, y: settings.size.height * 0.58, width: settings.size.width, height: settings.size.height * 0.42)
            let overlay = NSRect(x: (1920 - settings.size.width) / 2, y: 230, width: settings.size.width, height: crop.height)
            window(settings, overlay, ctx, crop: crop)
        }
    }
}
let titles = scenes.map { textLayer($0.1, y: 950, font: .systemFont(ofSize: 55, weight: .bold), color: $0.3 ? .white : ink) }
let subtitles = scenes.map { textLayer($0.2, y: 875, font: .systemFont(ofSize: 26), color: ($0.3 ? NSColor.white : ink).withAlphaComponent(0.75)) }
let icon = NSImage(contentsOf: root.appendingPathComponent("Sources/EMLViewer/Resources/Assets.xcassets/AppIcon.appiconset/icon_512x512@2x.png"))!
let iconLayer = layer { _ in icon.draw(in: NSRect(x: 830, y: 485, width: 260, height: 260)) }
let cardTitle = textLayer("EML/MSG Viewer", y: 370, font: .systemFont(ofSize: 55, weight: .bold), color: ink)
let cardSubtitles = ["Open email files on your Mac. No mail client needed.", "Download on the Mac App Store"].map { textLayer($0, y: 290, font: .systemFont(ofSize: 30), color: ink.withAlphaComponent(0.75)) }
func ease(_ value: Double) -> CGFloat {
    let t = max(0, min(1, value))
    return CGFloat(1 - (1 - t) * (1 - t))
}
func draw(_ image: CGImage, _ ctx: CGContext, alpha: CGFloat = 1, dx: CGFloat = 0, dy: CGFloat = 0, scale: CGFloat = 1, center: CGPoint = CGPoint(x: 960, y: 475)) {
    ctx.saveGState()
    ctx.setAlpha(alpha)
    ctx.translateBy(x: center.x + dx, y: center.y + dy)
    ctx.scaleBy(x: scale, y: scale)
    ctx.translateBy(x: -center.x, y: -center.y)
    ctx.draw(image, in: bounds)
    ctx.restoreGState()
}
func render(_ index: Int, _ time: Double, _ ctx: CGContext) {
    let card = index == 0 || index == 7
    let scene = index - 1
    draw(backgrounds[!card && scenes[scene].3 ? 1 : 0], ctx)
    if card {
        let progress = ease(time / 0.4)
        let iconProgress = CGFloat(max(0, min(1, time / 0.8)))
        draw(iconLayer, ctx, alpha: iconProgress, scale: 0.9 + 0.1 * iconProgress, center: CGPoint(x: 960, y: 615))
        draw(cardTitle, ctx, alpha: progress)
        draw(cardSubtitles[index == 0 ? 0 : 1], ctx, alpha: ease((time - 0.15) / 0.4))
    } else {
        let progress = ease(time / 0.4)
        let zoom = 1 + CGFloat(max(0, min(1, time / 2.6))) * 0.05
        draw(windows[scene], ctx, alpha: progress, dy: -60 * (1 - progress), scale: zoom)
        draw(titles[scene], ctx, alpha: progress, dy: 20 * (1 - progress))
        let subtitleProgress = ease((time - 0.15) / 0.4)
        draw(subtitles[scene], ctx, alpha: subtitleProgress, dy: 20 * (1 - subtitleProgress))
    }
}
let starts: [Double] = [0, 1.7, 4.0, 6.3, 8.6, 10.9, 13.2, 15.5]
let frame = context()
let next = context()
for number in 0..<(525) {
    let time = Double(number) / 30
    let index = starts.lastIndex(where: { $0 <= time })!
    render(index, time - starts[index], frame)
    if index > 0 && time - starts[index] < 0.3 {
        render(index - 1, time - starts[index - 1], next)
        frame.saveGState()
        frame.setAlpha(CGFloat(1 - (time - starts[index]) / 0.3))
        frame.draw(next.makeImage()!, in: bounds)
        frame.restoreGState()
    }
    FileHandle.standardOutput.write(Data(bytes: frame.data!, count: 1920 * 1080 * 4))
}
