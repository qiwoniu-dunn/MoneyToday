import AppKit
import QuartzCore
import SwiftUI

@main
@MainActor
struct MoneyTodayApplication {
    private static let delegate = AppDelegate()

    static func main() {
        let application = NSApplication.shared
        application.setActivationPolicy(.accessory)
        application.delegate = delegate
        application.run()
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var panel: NSPanel?
    private var outsideClickMonitor: Any?
    private let viewModel = MoneyTickerViewModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
        configurePanel()
        configureStatusItem()
        viewModel.start()
        if ProcessInfo.processInfo.environment["MONEYTODAY_OPEN_PANEL"] == "1" {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self?.showSnapshotPanel()
            }
        }
    }

    private func configurePanel() {
        let panel = MoneyTodayPanel(
            contentRect: NSRect(x: 0, y: 0, width: 410, height: 612),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .popUpMenu
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentViewController = NSHostingController(rootView: MoneyTodayPopover(viewModel: viewModel) { [weak self] height in
            self?.resizePanel(height: height)
        })
        panel.contentView?.wantsLayer = true
        panel.contentView?.layer?.backgroundColor = NSColor.clear.cgColor
        self.panel = panel
    }

    private func resizePanel(height: CGFloat) {
        guard let panel else { return }
        let current = panel.frame
        let targetSize = NSSize(width: 410, height: height)
        guard abs(current.width - targetSize.width) > 0.5 || abs(current.height - targetSize.height) > 0.5 else { return }

        let visibleFrame = panel.screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
        var newY = panel.isVisible ? current.maxY - targetSize.height : current.origin.y
        if visibleFrame != .zero {
            newY = max(newY, visibleFrame.minY + 8)
        }
        let targetFrame = NSRect(origin: NSPoint(x: current.origin.x, y: newY), size: targetSize)
        guard panel.isVisible else {
            panel.setFrame(targetFrame, display: true)
            return
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.22
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().setFrame(targetFrame, display: true)
        }
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = MoneyFlowIcon.makeStatusImage()
        item.button?.image?.isTemplate = true
        item.button?.toolTip = "窝囊费查看器 MoneyToday"
        item.button?.target = self
        item.button?.action = #selector(togglePopover(_:))
        statusItem = item
    }

    @objc private func togglePopover(_ sender: NSStatusBarButton) {
        guard let panel else { return }
        if panel.isVisible {
            hidePanel()
        } else {
            showPanel(attachedTo: sender)
        }
    }

    private func showPanel(attachedTo sender: NSStatusBarButton) {
        guard let panel, let buttonWindow = sender.window else { return }
        let buttonFrame = sender.convert(sender.bounds, to: nil)
        let screenFrame = buttonWindow.convertToScreen(buttonFrame)
        let panelSize = panel.frame.size
        let screenVisibleFrame = buttonWindow.screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero

        var originX = screenFrame.midX - panelSize.width / 2
        originX = min(max(originX, screenVisibleFrame.minX + 8), screenVisibleFrame.maxX - panelSize.width - 8)
        let originY = max(screenVisibleFrame.minY + 8, screenFrame.minY - panelSize.height - 6)

        panel.setFrameOrigin(NSPoint(x: originX, y: originY))
        viewModel.setPanelVisible(true)
        panel.orderFrontRegardless()
        panel.makeKey()
        installOutsideClickMonitor()
    }

    private func hidePanel() {
        panel?.orderOut(nil)
        viewModel.setPanelVisible(false)
        if let outsideClickMonitor {
            NSEvent.removeMonitor(outsideClickMonitor)
            self.outsideClickMonitor = nil
        }
    }

    private func showSnapshotPanel() {
        guard let panel else { return }
        let screenVisibleFrame = NSScreen.main?.visibleFrame ?? .zero
        let panelSize = panel.frame.size
        panel.setFrameOrigin(NSPoint(
            x: screenVisibleFrame.midX - panelSize.width / 2,
            y: screenVisibleFrame.midY - panelSize.height / 2
        ))
        viewModel.setPanelVisible(true)
        panel.orderFrontRegardless()
        panel.makeKey()
        NSApp.activate(ignoringOtherApps: true)
    }

    private func installOutsideClickMonitor() {
        if outsideClickMonitor != nil { return }
        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            Task { @MainActor in
                self?.hidePanel()
            }
        }
    }
}

final class MoneyTodayPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
