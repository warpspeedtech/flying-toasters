//
//  render_scene.swift
//  Headless renderer for a full Flying Toasters frame, for visual verification/tuning.
//  Usage: render_scene [out.png] [width] [height] [seconds] [count]
//

import CoreGraphics
import ImageIO
import Foundation

private let cs = CGColorSpace(name: CGColorSpace.sRGB)!

private func writePNG(_ image: CGImage, to path: String) {
    let url = URL(fileURLWithPath: path)
    guard let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else {
        fputs("dest failed\n", stderr); exit(1)
    }
    CGImageDestinationAddImage(dest, image, nil)
    CGImageDestinationFinalize(dest)
}

@main
struct RenderScene {
    static func main() {
        let a = CommandLine.arguments
        let out = a.count > 1 ? a[1] : "research/reference/my-scene.png"
        let w = a.count > 2 ? Int(a[2]) ?? 1512 : 1512
        let h = a.count > 3 ? Int(a[3]) ?? 982 : 982
        let seconds = a.count > 4 ? Double(a[4]) ?? 3.0 : 3.0
        let count = a.count > 5 ? Int(a[5]) ?? 16 : 16

        let scale: CGFloat = 2   // emulate Retina backing
        let pxW = w * Int(scale), pxH = h * Int(scale)

        let scene = ToasterScene()
        var settings = ToasterSettings.default
        settings.toasterCount = count
        scene.configure(size: CGSize(width: w, height: h), scale: scale, settings: settings, isPreview: false)

        // settle the simulation
        let dt = 1.0 / 60.0
        var t = 0.0
        while t < seconds { scene.advance(by: dt); t += dt }

        let ctx = CGContext(data: nil, width: pxW, height: pxH, bitsPerComponent: 8, bytesPerRow: 0,
                            space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.scaleBy(x: scale, y: scale)   // draw in points; bitmap is at device pixels
        scene.draw(in: ctx)

        writePNG(ctx.makeImage()!, to: out)
        fputs("wrote \(out) (\(pxW)x\(pxH), \(count) toasters, t=\(seconds)s)\n", stderr)
    }
}
