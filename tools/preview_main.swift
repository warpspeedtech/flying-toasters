//
//  preview_main.swift
//  Standalone "Flying Toasters" app: shows the live screen saver in a window AND acts
//  as its settings panel. Because the System Settings → Screen Saver "Options…" button
//  is unreliable for third-party savers on modern macOS (a legacyScreenSaver host bug),
//  this app's Options button writes to the SAME ScreenSaverDefaults domain the installed
//  saver reads, so changes here apply to the real screen saver too.
//
//  Controls: Options… button (or ⌘,) · ⌘F full screen · Esc / ⌘Q quit.
//

import AppKit
import ScreenSaver
import QuartzCore

final class MainWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var saver: ScreenSaverView!
    var timer: Timer?

    func applicationDidFinishLaunching(_ note: Notification) {
        let frame = NSRect(x: 0, y: 0, width: 1280, height: 800)
        window = MainWindow(contentRect: frame,
                            styleMask: [.titled, .closable, .miniaturizable, .resizable],
                            backing: .buffered, defer: false)
        window.title = "Flying Toasters"
        window.center()
        window.backgroundColor = .black
        window.isReleasedWhenClosed = false

        let container = NSView(frame: frame)
        container.autoresizingMask = [.width, .height]
        window.contentView = container

        guard let view = FlyingToastersView(frame: container.bounds, isPreview: false) else {
            fputs("could not create saver view\n", stderr); NSApp.terminate(nil); return
        }
        view.autoresizingMask = [.width, .height]
        saver = view
        container.addSubview(view)

        // Always-visible Options button (the reliable replacement for the System
        // Settings button), pinned to the bottom-right.
        let button = NSButton(title: "Options…", target: self, action: #selector(openOptions))
        button.bezelStyle = .rounded
        button.controlSize = .large
        button.frame = NSRect(x: frame.width - 140, y: 20, width: 120, height: 34)
        button.autoresizingMask = [.minXMargin, .maxYMargin]
        container.addSubview(button)

        let hint = NSTextField(labelWithString: "Options here also apply to the installed screen saver")
        hint.font = .systemFont(ofSize: 11)
        hint.textColor = NSColor.white.withAlphaComponent(0.55)
        hint.frame = NSRect(x: 20, y: 24, width: 460, height: 16)
        hint.autoresizingMask = [.maxXMargin, .maxYMargin]
        container.addSubview(hint)

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        view.startAnimation()
        let t = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak view] _ in
            view?.animateOneFrame()
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t

        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] ev in
            // Esc quits, but only when no sheet is open (so Esc can cancel the sheet).
            if ev.keyCode == 53, self?.window.attachedSheet == nil { NSApp.terminate(nil); return nil }
            return ev
        }

        buildMenu()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ app: NSApplication) -> Bool { true }

    private func buildMenu() {
        let mainMenu = NSMenu()
        let appItem = NSMenuItem()
        mainMenu.addItem(appItem)
        let appMenu = NSMenu()
        appItem.submenu = appMenu
        appMenu.addItem(withTitle: "Options…", action: #selector(openOptions), keyEquivalent: ",").target = self
        appMenu.addItem(withTitle: "Toggle Full Screen", action: #selector(NSWindow.toggleFullScreen(_:)), keyEquivalent: "f")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit Flying Toasters", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        NSApp.mainMenu = mainMenu
    }

    @objc private func openOptions() {
        guard window.attachedSheet == nil, let sheet = saver.configureSheet else { return }
        window.beginSheet(sheet) { [weak self] _ in
            self?.saver.startAnimation()   // reload settings & reset timing after closing
        }
    }
}

@main
enum FlyingToastersApp {
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
        _ = delegate
    }
}
