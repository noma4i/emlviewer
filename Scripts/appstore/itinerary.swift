import AppKit
import Foundation

let destination = URL(fileURLWithPath: CommandLine.arguments[1]) as CFURL
let art = NSImage(contentsOfFile: CommandLine.arguments[2])!
var media = CGRect(x: 0, y: 0, width: 612, height: 792)
let context = CGContext(destination, mediaBox: &media, nil)!
context.beginPDFPage(nil)
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
NSColor.white.setFill()
NSRect(x: 0, y: 0, width: 612, height: 792).fill()
art.draw(in: NSRect(x: 50, y: 500, width: 512, height: 213))
let ink = NSColor(red: 0.15, green: 0.24, blue: 0.27, alpha: 1)
func line(_ text: String, _ y: CGFloat, _ size: CGFloat, _ weight: NSFont.Weight) {
    (text as NSString).draw(at: NSPoint(x: 50, y: y), withAttributes: [.font: NSFont.systemFont(ofSize: size, weight: weight), .foregroundColor: ink])
}
line("YOUR TRAVEL ITINERARY", 742, 12, .semibold)
line("Harbor Point", 442, 32, .bold)
line("May 12 - May 16", 409, 18, .medium)
line("Avery Lane", 373, 15, .regular)
line("Tuesday, May 12", 321, 17, .semibold)
line("Arrival and check-in at Harbor House", 297, 14, .regular)
line("Wednesday, May 13", 253, 17, .semibold)
line("Coastal walk and afternoon at leisure", 229, 14, .regular)
line("Thursday, May 14", 185, 17, .semibold)
line("Local gardens and sunset by the water", 161, 14, .regular)
line("Friday, May 15", 117, 17, .semibold)
line("Market visit and departure preparations", 93, 14, .regular)
NSGraphicsContext.restoreGraphicsState()
context.endPDFPage()
context.closePDF()
