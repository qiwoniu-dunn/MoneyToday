import AppKit

enum MoneyFlowIcon {
    static func makeStatusImage() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        image.lockFocus()

        NSColor.labelColor.setFill()

        let bag = NSBezierPath()
        bag.move(to: NSPoint(x: 5.0, y: 8.5))
        bag.curve(to: NSPoint(x: 13.0, y: 8.5), controlPoint1: NSPoint(x: 6.8, y: 10.0), controlPoint2: NSPoint(x: 11.2, y: 10.0))
        bag.curve(to: NSPoint(x: 16.0, y: 4.5), controlPoint1: NSPoint(x: 15.0, y: 7.2), controlPoint2: NSPoint(x: 16.2, y: 5.8))
        bag.curve(to: NSPoint(x: 9.0, y: 1.8), controlPoint1: NSPoint(x: 15.5, y: 2.4), controlPoint2: NSPoint(x: 12.8, y: 1.8))
        bag.curve(to: NSPoint(x: 2.0, y: 4.5), controlPoint1: NSPoint(x: 5.2, y: 1.8), controlPoint2: NSPoint(x: 2.5, y: 2.4))
        bag.curve(to: NSPoint(x: 5.0, y: 8.5), controlPoint1: NSPoint(x: 1.8, y: 5.8), controlPoint2: NSPoint(x: 3.0, y: 7.2))
        bag.close()
        bag.fill()

        let knot = NSBezierPath()
        knot.appendRoundedRect(NSRect(x: 5.3, y: 8.0, width: 7.4, height: 2.1), xRadius: 1.0, yRadius: 1.0)
        knot.fill()

        let tie = NSBezierPath()
        tie.move(to: NSPoint(x: 6.0, y: 9.5))
        tie.line(to: NSPoint(x: 4.4, y: 14.5))
        tie.line(to: NSPoint(x: 7.8, y: 12.0))
        tie.close()
        tie.move(to: NSPoint(x: 12.0, y: 9.5))
        tie.line(to: NSPoint(x: 13.6, y: 14.5))
        tie.line(to: NSPoint(x: 10.2, y: 12.0))
        tie.close()
        tie.fill()

        image.unlockFocus()
        image.isTemplate = true
        return image
    }
}
