//
//  load_test.swift
//  Mimics what macOS's screensaver host does: load the .saver bundle, resolve the
//  principal class, confirm it is a ScreenSaverView, instantiate it (preview + full),
//  and run a few frames. Exits non-zero on any failure.
//
//  Usage: load_test "/path/to/Flying Toasters.saver"
//

import AppKit
import ScreenSaver
import Foundation

@main
struct LoadTest {
    static func main() {
        let path = CommandLine.arguments.count > 1 ? CommandLine.arguments[1]
                 : "build/Flying Toasters.saver"
        func fail(_ m: String) -> Never { fputs("FAIL: \(m)\n", stderr); exit(1) }

        guard let bundle = Bundle(path: path) else { fail("could not open bundle at \(path)") }
        guard bundle.load() else { fail("bundle.load() returned false") }
        print("ok: bundle loaded — \(bundle.bundleIdentifier ?? "?")")

        guard let principal = bundle.principalClass else { fail("principalClass is nil") }
        print("ok: principalClass = \(principal)")

        guard let saverType = principal as? ScreenSaverView.Type else {
            fail("principalClass is not a ScreenSaverView subclass")
        }

        let frame = NSRect(x: 0, y: 0, width: 1200, height: 800)
        for preview in [false, true] {
            guard let view = saverType.init(frame: frame, isPreview: preview) else {
                fail("init(frame:isPreview:\(preview)) returned nil")
            }
            print("ok: instantiated (isPreview=\(preview)), hasConfigureSheet=\(view.hasConfigureSheet)")
            view.startAnimation()
            for _ in 0..<5 { view.animateOneFrame() }

            // Render one frame into a bitmap to confirm draw() runs without crashing.
            if !preview, let rep = view.bitmapImageRepForCachingDisplay(in: frame) {
                view.cacheDisplay(in: frame, to: rep)
                print("ok: rendered a frame (\(rep.pixelsWide)x\(rep.pixelsHigh))")
                if let data = rep.representation(using: .png, properties: [:]) {
                    let out = CommandLine.arguments.count > 2 ? CommandLine.arguments[2]
                            : "research/reference/saver-frame.png"
                    try? data.write(to: URL(fileURLWithPath: out))
                    print("ok: wrote \(out)")
                }
            }
            view.stopAnimation()

            if preview, view.configureSheet != nil { print("ok: configureSheet built") }
        }
        print("PASS")
    }
}
