//
//  render_sprites.swift
//  Headless sprite-sheet renderer for visual verification of ToasterArt.
//  Build with ToasterArt.swift and run; writes a PNG to the given path.
//

import CoreGraphics
import ImageIO
import Foundation

private let sRGBcs = CGColorSpace(name: CGColorSpace.sRGB)!

private func writePNG(_ image: CGImage, to path: String) {
    let url = URL(fileURLWithPath: path)
    guard let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else {
        fputs("failed to create destination\n", stderr); exit(1)
    }
    CGImageDestinationAddImage(dest, image, nil)
    CGImageDestinationFinalize(dest)
}

@main
struct RenderSprites {
    static func main() {
        let cell = 220
        let cols = 5
        let rows = 2
        let W = cell * cols
        let H = cell * rows

        let ctx = CGContext(data: nil, width: W, height: H, bitsPerComponent: 8, bytesPerRow: 0,
                            space: sRGBcs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.interpolationQuality = .none   // crisp pixel art
        ctx.setFillColor(CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
        ctx.setStrokeColor(CGColor(srgbRed: 0.18, green: 0.18, blue: 0.22, alpha: 1))
        ctx.setLineWidth(1)
        for c in 0...cols { ctx.stroke(CGRect(x: CGFloat(c*cell), y: 0, width: 0.1, height: CGFloat(H))) }
        for rr in 0...rows { ctx.stroke(CGRect(x: 0, y: CGFloat(rr*cell), width: CGFloat(W), height: 0.1)) }

        let art = ToasterArt()
        let spriteSize: CGFloat = CGFloat(cell) * 0.88
        let inset = (CGFloat(cell) - spriteSize) / 2

        func cellRect(_ col: Int, _ row: Int) -> CGRect {
            let y = CGFloat((rows - 1 - row) * cell) + inset
            return CGRect(x: CGFloat(col * cell) + inset, y: y, width: spriteSize, height: spriteSize)
        }

        // Row 0: four wing frames + toast at medium darkness
        art.rebuildIfNeeded(pixelSize: spriteSize, darkness: 0.5)
        for i in 0..<4 { ctx.draw(art.toasterFrames[i], in: cellRect(i, 0)) }
        ctx.draw(art.toastImage!, in: cellRect(4, 0))

        // Row 1: toast darkness sweep 0.0 .. 1.0
        for i in 0..<5 {
            let d = CGFloat(i) / 4.0
            art.rebuildIfNeeded(pixelSize: spriteSize, darkness: d)
            ctx.draw(art.toastImage!, in: cellRect(i, 1))
        }

        let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1]
                : "research/reference/my-sprites.png"
        writePNG(ctx.makeImage()!, to: out)
        fputs("wrote \(out)\n", stderr)
    }
}
