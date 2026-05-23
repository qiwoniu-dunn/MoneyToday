import AppKit
import Foundation

let arguments = CommandLine.arguments
guard arguments.count == 2 else {
    fatalError("Usage: generate_app_icon.swift /path/to/MoneyToday.icns")
}

let outputURL = URL(fileURLWithPath: arguments[1])
let iconsetURL = outputURL
    .deletingLastPathComponent()
    .appendingPathComponent("MoneyToday.iconset", isDirectory: true)
let tiffURL = outputURL
    .deletingLastPathComponent()
    .appendingPathComponent("MoneyTodayIcon.tiff")

try? FileManager.default.removeItem(at: iconsetURL)
try FileManager.default.createDirectory(
    at: iconsetURL,
    withIntermediateDirectories: true
)

let sizes: [(name: String, points: CGFloat, scale: CGFloat)] = [
    ("icon_16x16.png", 16, 1),
    ("icon_16x16@2x.png", 16, 2),
    ("icon_32x32.png", 32, 1),
    ("icon_32x32@2x.png", 32, 2),
    ("icon_128x128.png", 128, 1),
    ("icon_128x128@2x.png", 128, 2),
    ("icon_256x256.png", 256, 1),
    ("icon_256x256@2x.png", 256, 2),
    ("icon_512x512.png", 512, 1),
    ("icon_512x512@2x.png", 512, 2)
]

for item in sizes {
    let pixels = Int(item.points * item.scale)
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        fatalError("Failed to create bitmap \(item.name)")
    }

    bitmap.size = NSSize(width: pixels, height: pixels)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    drawIcon(in: NSRect(x: 0, y: 0, width: pixels, height: pixels))
    NSGraphicsContext.restoreGraphicsState()

    guard let png = bitmap.representation(using: .png, properties: [:])
    else {
        fatalError("Failed to render icon \(item.name)")
    }

    try png.write(to: iconsetURL.appendingPathComponent(item.name))
    if item.name == "icon_512x512@2x.png" {
        try bitmap.tiffRepresentation?.write(to: tiffURL)
    }
}

try writeICNS(iconsetURL: iconsetURL, outputURL: outputURL)

try? FileManager.default.removeItem(at: iconsetURL)
try? FileManager.default.removeItem(at: tiffURL)

func writeICNS(iconsetURL: URL, outputURL: URL) throws {
    let chunks: [(type: String, file: String)] = [
        ("icp4", "icon_16x16.png"),
        ("ic11", "icon_16x16@2x.png"),
        ("icp5", "icon_32x32.png"),
        ("icp6", "icon_32x32@2x.png"),
        ("ic07", "icon_128x128.png"),
        ("ic13", "icon_128x128@2x.png"),
        ("ic08", "icon_256x256.png"),
        ("ic14", "icon_256x256@2x.png"),
        ("ic09", "icon_512x512.png"),
        ("ic10", "icon_512x512@2x.png")
    ]

    var body = Data()
    for chunk in chunks {
        let png = try Data(contentsOf: iconsetURL.appendingPathComponent(chunk.file))
        body.append(chunk.type.data(using: .ascii)!)
        body.appendUInt32BE(UInt32(png.count + 8))
        body.append(png)
    }

    var file = Data()
    file.append("icns".data(using: .ascii)!)
    file.appendUInt32BE(UInt32(body.count + 8))
    file.append(body)
    try file.write(to: outputURL, options: .atomic)
}

func drawIcon(in rect: NSRect) {
    let context = NSGraphicsContext.current?.cgContext
    context?.setAllowsAntialiasing(true)
    context?.setShouldAntialias(true)

    let scale = rect.width / 1024
    func r(_ value: CGFloat) -> CGFloat { value * scale }
    func p(_ x: CGFloat, _ y: CGFloat) -> NSPoint { NSPoint(x: r(x), y: r(y)) }

    let base = NSBezierPath(roundedRect: rect.insetBy(dx: r(70), dy: r(70)), xRadius: r(220), yRadius: r(220))
    NSColor(red: 1.0, green: 0.78, blue: 0.16, alpha: 1).setFill()
    base.fill()

    let inner = NSBezierPath(roundedRect: rect.insetBy(dx: r(106), dy: r(106)), xRadius: r(184), yRadius: r(184))
    NSColor(red: 1.0, green: 0.91, blue: 0.34, alpha: 1).setFill()
    inner.fill()

    let glow = NSBezierPath(ovalIn: NSRect(x: r(560), y: r(120), width: r(330), height: r(330)))
    NSColor(red: 1.0, green: 0.55, blue: 0.05, alpha: 0.22).setFill()
    glow.fill()

    let bag = NSBezierPath()
    bag.move(to: p(318, 504))
    bag.curve(to: p(706, 504), controlPoint1: p(402, 610), controlPoint2: p(622, 610))
    bag.curve(to: p(806, 334), controlPoint1: p(774, 440), controlPoint2: p(816, 382))
    bag.curve(to: p(512, 220), controlPoint1: p(786, 252), controlPoint2: p(684, 220))
    bag.curve(to: p(218, 334), controlPoint1: p(340, 220), controlPoint2: p(238, 252))
    bag.curve(to: p(318, 504), controlPoint1: p(208, 382), controlPoint2: p(250, 440))
    bag.close()
    NSColor(red: 0.13, green: 0.48, blue: 0.22, alpha: 1).setFill()
    bag.fill()
    NSColor(red: 0.05, green: 0.24, blue: 0.12, alpha: 1).setStroke()
    bag.lineWidth = r(44)
    bag.lineJoinStyle = .round
    bag.stroke()

    let tie = NSBezierPath()
    tie.move(to: p(376, 530))
    tie.line(to: p(312, 694))
    tie.line(to: p(430, 646))
    tie.move(to: p(648, 530))
    tie.line(to: p(712, 694))
    tie.line(to: p(594, 646))
    NSColor(red: 0.07, green: 0.34, blue: 0.16, alpha: 1).setStroke()
    tie.lineWidth = r(48)
    tie.lineCapStyle = .round
    tie.lineJoinStyle = .round
    tie.stroke()

    let knot = NSBezierPath()
    knot.move(to: p(380, 528))
    knot.curve(to: p(644, 528), controlPoint1: p(448, 565), controlPoint2: p(576, 565))
    NSColor(red: 0.03, green: 0.22, blue: 0.10, alpha: 1).setStroke()
    knot.lineWidth = r(58)
    knot.lineCapStyle = .round
    knot.stroke()

    let yuan = NSBezierPath()
    yuan.move(to: p(512, 462))
    yuan.line(to: p(512, 300))
    yuan.move(to: p(430, 438))
    yuan.line(to: p(512, 372))
    yuan.line(to: p(594, 438))
    yuan.move(to: p(418, 382))
    yuan.line(to: p(606, 382))
    yuan.move(to: p(418, 326))
    yuan.line(to: p(606, 326))
    NSColor(red: 1.0, green: 0.86, blue: 0.22, alpha: 1).setStroke()
    yuan.lineWidth = r(42)
    yuan.lineCapStyle = .round
    yuan.lineJoinStyle = .round
    yuan.stroke()

    let spark = NSBezierPath(ovalIn: NSRect(x: r(692), y: r(268), width: r(92), height: r(92)))
    NSColor(red: 1.0, green: 0.93, blue: 0.45, alpha: 1).setFill()
    spark.fill()
}

private extension Data {
    mutating func appendUInt32BE(_ value: UInt32) {
        append(UInt8((value >> 24) & 0xff))
        append(UInt8((value >> 16) & 0xff))
        append(UInt8((value >> 8) & 0xff))
        append(UInt8(value & 0xff))
    }
}
