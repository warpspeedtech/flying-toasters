//
//  ToasterScene.swift
//  Flying Toasters
//
//  The simulation: a flock of toasters and toast streaming from the top-right to the
//  bottom-left on a 45° diagonal, each toaster flapping out of sync. Pure Core Graphics
//  and Foundation so it can be driven by the ScreenSaverView or rendered headlessly.
//
//  Cadence is taken from the original (see research/original-after-dark-notes.md):
//  three parallax speed tiers traversing the field in ~10/16/24 s, depth-correlated size,
//  a ~0.4 s four-step wing flap with randomized phase, ~3 toasters per piece of toast.
//

import CoreGraphics
import Foundation

final class ToasterScene {

    enum Kind { case toaster, toast }

    struct Sprite {
        var kind: Kind
        var pos: CGPoint          // center, in points
        var depth: Double         // 0 = far/slow/small, 1 = near/fast/large
        var size: CGFloat         // edge length in points
        var speed: CGFloat        // points per second along the travel direction
        var flapClock: Double     // seconds elapsed in the current flap
        var flapPeriod: Double    // seconds for a full up→down→up flap
        var flapPhase: Double     // 0..1 starting offset so flaps beat out of sync
    }

    private(set) var sprites: [Sprite] = []
    private(set) var size: CGSize = .zero
    var scale: CGFloat = 2
    var settings = ToasterSettings.default

    private let art = ToasterArt()
    private var isPreview = false
    private var stars: [(CGPoint, CGFloat)] = []

    // Travel direction: top-right → bottom-left at 45° in a y-up coordinate system.
    private let dir = CGVector(dx: -0.7071067811865476, dy: -0.7071067811865476)

    // MARK: Configuration

    func configure(size: CGSize, scale: CGFloat, settings: ToasterSettings, isPreview: Bool) {
        self.size = CGSize(width: max(1, size.width), height: max(1, size.height))
        self.scale = max(1, scale)
        self.settings = settings
        self.isPreview = isPreview
        reseed()
        rebuildArt()
    }

    /// Apply new settings, reseeding only what must change.
    func update(settings new: ToasterSettings) {
        let countChanged = new.toasterCount != settings.toasterCount || new.toastRatio != settings.toastRatio
        settings = new
        rebuildArt()
        if countChanged { reseed() }
    }

    private func rebuildArt() {
        let maxPixel = ceil(sizeFor(depth: 1) * scale)
        art.rebuildIfNeeded(pixelSize: maxPixel, darkness: CGFloat(settings.darkness),
                            wingFrameCount: settings.authenticFlap ? ToasterArt.authenticFrameCount
                                                                   : ToasterArt.smoothFrameCount)
    }

    private func reseed() {
        sprites.removeAll(keepingCapacity: true)
        let toasterTarget = isPreview ? min(7, settings.toasterCount) : settings.toasterCount
        let toastTarget = max(0, Int((Double(toasterTarget) * settings.toastRatio).rounded()))
        for _ in 0..<toasterTarget { sprites.append(makeSprite(.toaster, initial: true)) }
        for _ in 0..<toastTarget { sprites.append(makeSprite(.toast, initial: true)) }

        // Faint retro starfield (optional).
        stars = (0..<90).map { _ in
            (CGPoint(x: .random(in: 0...size.width), y: .random(in: 0...size.height)),
             CGFloat.random(in: 0.6...1.6))
        }
    }

    // MARK: Sizing & speed (depth-correlated parallax)

    private func sizeFor(depth: Double) -> CGFloat {
        let base = min(size.width, size.height)
        let minS = base * 0.075
        let maxS = base * 0.155
        return minS + CGFloat(depth) * (maxS - minS)
    }

    private func speedFor(depth: Double) -> CGFloat {
        let travel = hypot(size.width, size.height) + 2 * sizeFor(depth: 1)
        let crossTime = (24.0 - depth * 14.0) / max(0.05, settings.speed) // near=10s, far=24s
        return travel / CGFloat(crossTime)
    }

    // MARK: Spawning

    private func makeSprite(_ kind: Kind, initial: Bool) -> Sprite {
        let depth = Double.random(in: 0...1)
        let sz = sizeFor(depth: depth)
        var s = Sprite(kind: kind, pos: .zero, depth: depth, size: sz, speed: speedFor(depth: depth),
                       flapClock: 0, flapPeriod: Double.random(in: 0.30...0.52),
                       flapPhase: Double.random(in: 0...1))
        s.flapClock = Double.random(in: 0...s.flapPeriod)
        s.pos = initial ? randomStartPosition(size: sz) : inflowPosition(size: sz)
        return s
    }

    /// Initial seeding: spread across the screen plus the off-screen upper-right band so
    /// the field is full immediately and there is a queue waiting to fly in.
    private func randomStartPosition(size sz: CGFloat) -> CGPoint {
        let m = sz
        return CGPoint(x: .random(in: -m...(size.width + size.height * 0.4)),
                       y: .random(in: -m...(size.height + size.height * 0.4)))
    }

    /// Re-entry point along the top or right edge (the inflow boundary for down-left motion).
    private func inflowPosition(size sz: CGFloat) -> CGPoint {
        let half = sz / 2
        let topWeight = size.width / (size.width + size.height)
        if Double.random(in: 0...1) < Double(topWeight) {
            return CGPoint(x: .random(in: -half...size.width),
                           y: size.height + half + .random(in: 0...(size.height * 0.3)))
        } else {
            return CGPoint(x: size.width + half + .random(in: 0...(size.width * 0.3)),
                           y: .random(in: -half...size.height))
        }
    }

    // MARK: Simulation

    func advance(by dt: Double) {
        guard dt > 0 else { return }
        let d = CGFloat(dt)
        for i in sprites.indices {
            sprites[i].flapClock += dt
            sprites[i].pos.x += dir.dx * sprites[i].speed * d
            sprites[i].pos.y += dir.dy * sprites[i].speed * d
            let half = sprites[i].size / 2
            if sprites[i].pos.x + half < 0 || sprites[i].pos.y + half < 0 {
                sprites[i] = makeSprite(sprites[i].kind, initial: false)
            }
        }
    }

    // MARK: Drawing

    func draw(in ctx: CGContext) {
        rebuildArt()
        ctx.setFillColor(CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 1))
        ctx.fill(CGRect(origin: .zero, size: size))

        if settings.showStars { drawStars(in: ctx) }

        let native = CGFloat(ToasterArt.nativeSize)
        // Far (small) sprites first so near (large) ones overlap them.
        for s in sprites.sorted(by: { $0.depth < $1.depth }) {
            let img: CGImage?
            switch s.kind {
            case .toaster: img = toasterFrame(for: s)
            case .toast:   img = art.toastImage
            }
            guard let image = img else { continue }
            let rect = CGRect(x: s.pos.x - s.size / 2, y: s.pos.y - s.size / 2,
                              width: s.size, height: s.size)
            // Crisp pixels when upscaling the 64px art; smooth only when shrinking below native.
            ctx.interpolationQuality = (s.size * scale) >= native ? .none : .medium
            ctx.draw(image, in: rect)
        }
    }

    private func toasterFrame(for s: Sprite) -> CGImage? {
        let frames = art.toasterFrames
        guard !frames.isEmpty else { return nil }
        let n = frames.count
        var phase = (s.flapClock / s.flapPeriod + s.flapPhase).truncatingRemainder(dividingBy: 1)
        if phase < 0 { phase += 1 }
        let tri = phase < 0.5 ? phase * 2 : (1 - phase) * 2     // 0 → 1 → 0 triangle
        let idx = min(n - 1, max(0, Int((tri * Double(n - 1)).rounded())))
        return frames[idx]
    }

    private func drawStars(in ctx: CGContext) {
        for (p, r) in stars {
            ctx.setFillColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: Double(r) * 0.18))
            ctx.fillEllipse(in: CGRect(x: p.x, y: p.y, width: r, height: r))
        }
    }
}
