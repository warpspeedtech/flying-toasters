//
//  FlyingToastersView.swift
//  Flying Toasters
//
//  The ScreenSaver principal class. Owns a ToasterScene, advances it once per frame
//  using a real elapsed-time delta (so motion is smooth and resolution-independent),
//  and renders it into the view's Retina-backed context.
//

import AppKit
import ScreenSaver
import QuartzCore

@objc(FlyingToastersView)
final class FlyingToastersView: ScreenSaverView {

    private let scene = ToasterScene()
    private var settings = ToasterSettings.default
    private var lastTime: CFTimeInterval = 0
    private var configuredSize: CGSize = .zero
    private var configuredScale: CGFloat = 0
    private var sheetController: ConfigureSheetController?

    // MARK: Init

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        animationTimeInterval = 1.0 / 60.0
        wantsLayer = true
        layer?.backgroundColor = CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 1)
        settings = FT.load()
        reconfigureIfNeeded(force: true)
    }

    // MARK: Scene sizing

    private func currentScale() -> CGFloat {
        window?.backingScaleFactor ?? layer?.contentsScale ?? 2
    }

    private func reconfigureIfNeeded(force: Bool = false) {
        let size = bounds.size
        let scale = currentScale()
        guard size.width > 0, size.height > 0 else { return }
        if force || size != configuredSize || scale != configuredScale {
            configuredSize = size
            configuredScale = scale
            scene.configure(size: size, scale: scale, settings: settings, isPreview: isPreview)
        }
    }

    // MARK: Animation

    override func startAnimation() {
        super.startAnimation()
        settings = FT.load()
        scene.update(settings: settings)
        lastTime = CACurrentMediaTime()
        reconfigureIfNeeded(force: true)
    }

    override func stopAnimation() {
        super.stopAnimation()
    }

    override func animateOneFrame() {
        autoreleasepool {
            let now = CACurrentMediaTime()
            var dt = now - lastTime
            lastTime = now
            if dt <= 0 || dt > 0.25 { dt = 1.0 / 60.0 }   // guard against pauses/first frame
            reconfigureIfNeeded()
            scene.advance(by: dt)
            setNeedsDisplay(bounds)
        }
    }

    // MARK: Drawing

    override func draw(_ rect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else {
            NSColor.black.setFill(); rect.fill(); return
        }
        reconfigureIfNeeded()
        scene.draw(in: ctx)
    }

    // MARK: Configuration sheet

    override var hasConfigureSheet: Bool { true }

    override var configureSheet: NSWindow? {
        let controller = ConfigureSheetController(settings: settings) { [weak self] newSettings in
            guard let self else { return }
            self.settings = newSettings
            self.scene.update(settings: newSettings)
            self.reconfigureIfNeeded(force: true)
        }
        sheetController = controller   // retain while presented
        return controller.window
    }
}
