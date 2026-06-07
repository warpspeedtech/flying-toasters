//
//  render_gif.swift
//  Renders a SEAMLESSLY LOOPING animated GIF of the flying toasters, using the genuine
//  sprites from ToasterArt. The loop is exact: every sprite's travel and wing-flap are
//  integer multiples of the loop period, and sprites wrap off-screen, so the final frame
//  equals the first with no visible jump.
//
//  Usage: render_gif [out.gif] [width] [height] [fps] [seconds] [toasters]
//

import CoreGraphics
import ImageIO
import Foundation

// Small deterministic RNG so the layout is reproducible.
struct RNG: RandomNumberGenerator {
    var s: UInt64
    init(_ seed: UInt64) { s = seed }
    mutating func next() -> UInt64 {
        s = s &* 6364136223846793005 &+ 1442695040888963407
        var z = s
        z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
        z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
        return z ^ (z >> 31)
    }
}

@main
struct RenderGIF {
    struct Sprite { var toast: Bool; var a: Double; var q: Double; var n: Int; var size: CGFloat; var m: Int; var a2: Double }

    static func main() {
        let args = CommandLine.arguments
        let out = args.count > 1 ? args[1] : "images/flying-toasters.gif"
        let W = args.count > 2 ? (Int(args[2]) ?? 760) : 760
        let H = args.count > 3 ? (Int(args[3]) ?? 460) : 460
        let fps = args.count > 4 ? (Int(args[4]) ?? 20) : 20
        let seconds = args.count > 5 ? (Double(args[5]) ?? 5) : 5
        let toasters = args.count > 6 ? (Int(args[6]) ?? 24) : 24

        let frames = max(2, Int((Double(fps) * seconds).rounded()))
        let cs = CGColorSpace(name: CGColorSpace.sRGB)!

        let art = ToasterArt()
        art.rebuildIfNeeded(darkness: 0)
        guard !art.toasterFrames.isEmpty, let toastImg = art.toastImage else {
            fputs("sprites failed to load\n", stderr); exit(1)
        }

        let w = Double(W), h = Double(H)
        let invSqrt2 = 1.0 / 2.0.squareRoot()
        let d = (x: -invSqrt2, y: -invSqrt2)        // travel: down-left
        let perp = (x: invSqrt2, y: -invSqrt2)      // perpendicular spread
        let minSide = Double(min(W, H))
        let minS = minSide * 0.075, maxS = minSide * 0.16
        let margin = maxS + 24
        let onExtent = (w + h) * invSqrt2
        let P = onExtent + 2 * margin               // loop distance (wrap happens off-screen)
        let O = (x: w + margin * invSqrt2, y: h + margin * invSqrt2)  // along=0, off top-right
        let qMin = -w * invSqrt2 - margin, qMax = h * invSqrt2 + margin

        // Build the sprite set once (positions are computed per-frame from loop time).
        var rng = RNG(0xF1A11A57)
        let toastCount = Int((Double(toasters) * 0.34).rounded())
        var sprites: [Sprite] = []
        let mMin = max(1, Int((2.0 * seconds).rounded()))
        let mMax = max(mMin + 1, Int((3.0 * seconds).rounded()))
        func make(toast: Bool) -> Sprite {
            let n = Int.random(in: 1...3, using: &rng)
            let base = minS + (maxS - minS) * Double(n - 1) / 2.0
            let size = CGFloat(base * Double.random(in: 0.9...1.1, using: &rng))
            return Sprite(toast: toast,
                          a: Double.random(in: 0..<1, using: &rng),
                          q: Double.random(in: qMin...qMax, using: &rng),
                          n: n, size: size,
                          m: Int.random(in: mMin...mMax, using: &rng),
                          a2: Double.random(in: 0..<1, using: &rng))
        }
        for _ in 0..<toasters { sprites.append(make(toast: false)) }
        for _ in 0..<toastCount { sprites.append(make(toast: true)) }
        sprites.sort { $0.size < $1.size }   // far/small drawn first

        // GIF destination (infinite loop).
        let url = URL(fileURLWithPath: out)
        guard let dest = CGImageDestinationCreateWithURL(url as CFURL, "com.compuserve.gif" as CFString, frames, nil) else {
            fputs("cannot create gif\n", stderr); exit(1)
        }
        CGImageDestinationSetProperties(dest, [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]] as CFDictionary)
        let delay = 1.0 / Double(fps)
        let frameProps = [kCGImagePropertyGIFDictionary: [
            kCGImagePropertyGIFDelayTime: delay,
            kCGImagePropertyGIFUnclampedDelayTime: delay,
        ]] as CFDictionary

        let nativeF = CGFloat(ToasterArt.nativeSize)
        for f in 0..<frames {
            let u = Double(f) / Double(frames)
            let ctx = CGContext(data: nil, width: W, height: H, bitsPerComponent: 8, bytesPerRow: 0,
                                space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
            ctx.setFillColor(CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 1))
            ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))

            for s in sprites {
                var along = (s.a + Double(s.n) * u).truncatingRemainder(dividingBy: 1)
                if along < 0 { along += 1 }
                along *= P
                let px = O.x + d.x * along + perp.x * s.q
                let py = O.y + d.y * along + perp.y * s.q
                // cull off-canvas
                let half = Double(s.size) / 2
                if px + half < 0 || px - half > w || py + half < 0 || py - half > h { continue }

                let img: CGImage
                if s.toast {
                    img = toastImg
                } else {
                    let n = art.toasterFrames.count
                    var phase = (s.a2 + Double(s.m) * u).truncatingRemainder(dividingBy: 1)
                    if phase < 0 { phase += 1 }
                    let tri = phase < 0.5 ? phase * 2 : (1 - phase) * 2
                    img = art.toasterFrames[min(n - 1, max(0, Int((tri * Double(n - 1)).rounded())))]
                }
                ctx.interpolationQuality = (s.size >= nativeF) ? .none : .medium
                ctx.draw(img, in: CGRect(x: CGFloat(px) - s.size / 2, y: CGFloat(py) - s.size / 2,
                                         width: s.size, height: s.size))
            }
            guard let frame = ctx.makeImage() else { continue }
            CGImageDestinationAddImage(dest, frame, frameProps)
        }

        if !CGImageDestinationFinalize(dest) { fputs("finalize failed\n", stderr); exit(1) }
        fputs("wrote \(out) — \(W)x\(H), \(frames) frames @ \(fps)fps, \(sprites.count) sprites\n", stderr)
    }
}
