//
//  shot_main.swift
//  Hosts the REAL FlyingToastersView (the screen saver's principal class) in an
//  offscreen window, lets it animate in real wall-clock time for a few seconds, then
//  snapshots its own rendered content to a PNG. No screen-recording permission needed
//  (the app captures its own view), and nothing pops onto the screen.
//
//  Usage: shot_main [out.png] [width] [height] [seconds]
//

import AppKit
import ScreenSaver
import QuartzCore

@main
enum Shot {
    static func main() {
        let a = CommandLine.arguments
        let out = a.count > 1 ? a[1] : "images/screenshot.png"
        let w = a.count > 2 ? Int(a[2]) ?? 1600 : 1600
        let h = a.count > 3 ? Int(a[3]) ?? 1000 : 1000
        let seconds = a.count > 4 ? Double(a[4]) ?? 4.0 : 4.0

        let app = NSApplication.shared
        app.setActivationPolicy(.prohibited)   // no Dock icon, no visible UI

        let frame = NSRect(x: 0, y: 0, width: w, height: h)
        // Offscreen window so the view has a real backing/scale but never appears.
        let win = NSWindow(contentRect: frame, styleMask: [.borderless],
                           backing: .buffered, defer: false)
        win.setFrameOrigin(NSPoint(x: -20000, y: -20000))
        win.alphaValue = 0

        guard let view = FlyingToastersView(frame: frame, isPreview: false) else {
            fputs("could not create view\n", stderr); exit(1)
        }
        win.contentView = view
        view.startAnimation()

        // Drive animation at 60 Hz so real time advances the simulation.
        let t = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak view] _ in
            view?.animateOneFrame()
        }
        RunLoop.main.add(t, forMode: .common)

        // After it settles, snapshot the view's own content and quit.
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            guard let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else {
                fputs("no rep\n", stderr); exit(1)
            }
            view.cacheDisplay(in: view.bounds, to: rep)
            if let data = rep.representation(using: .png, properties: [:]) {
                try? data.write(to: URL(fileURLWithPath: out))
                fputs("wrote \(out) (\(rep.pixelsWide)x\(rep.pixelsHigh))\n", stderr)
            }
            exit(0)
        }
        app.run()
    }
}
