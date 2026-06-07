//
//  ToasterArt.swift
//  Flying Toasters
//
//  Loads the genuine After Dark sprites (embedded in Sprites.swift): the 256x64
//  toaster sheet is sliced into its four wing-flap frames, and the 64x64 toast is
//  tinted by the "darkness" setting. The scene blits these with nearest-neighbor
//  scaling so the original pixel art stays crisp (not blurry) on Retina.
//

import CoreGraphics
import ImageIO
import CoreImage
import Foundation

final class ToasterArt {

    /// The original sheet has four wing positions.
    static let authenticFrameCount = 4
    static let smoothFrameCount = 4   // kept for call-site compatibility; real art is 4

    /// Native pixel size of one sprite (the originals are 64x64).
    static let nativeSize = 64

    private(set) var toasterFrames: [CGImage] = []
    private(set) var toastImage: CGImage?

    private var baseToast: CGImage?
    private var builtDarkness: CGFloat = -1
    private var decoded = false

    private lazy var ciContext = CIContext(options: [.useSoftwareRenderer: false])

    /// Decode the sprites once, then re-tint the toast only when darkness changes.
    /// `pixelSize`/`wingFrameCount` are accepted for call-site compatibility but the
    /// genuine art is used at native resolution and scaled by the scene.
    func rebuildIfNeeded(pixelSize: CGFloat = 0, darkness: CGFloat, wingFrameCount: Int = 4) {
        decodeIfNeeded()
        if toastImage == nil || abs(darkness - builtDarkness) > 0.005 {
            builtDarkness = darkness
            if let base = baseToast {
                toastImage = tintedToast(base, darkness: darkness)
            }
        }
    }

    private func decodeIfNeeded() {
        guard !decoded else { return }
        decoded = true

        if let sheet = ToasterArt.decodeGIF(Sprites.toasterSheetData) {
            let h = sheet.height
            let fw = max(1, sheet.width / ToasterArt.authenticFrameCount)
            toasterFrames = (0..<ToasterArt.authenticFrameCount).compactMap { i in
                sheet.cropping(to: CGRect(x: i * fw, y: 0, width: fw, height: h))
            }
        }
        baseToast = ToasterArt.decodeGIF(Sprites.toastData)
    }

    // MARK: Decoding & tinting

    private static func decodeGIF(_ data: Data) -> CGImage? {
        guard let src = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(src, 0, nil)
    }

    /// Darken/brown the toast to emulate the original's darkness slider.
    /// 0 = the genuine golden sprite, 1 = burnt. Transparency is preserved.
    private func tintedToast(_ base: CGImage, darkness d: CGFloat) -> CGImage {
        if d <= 0.005 { return base }
        let ci = CIImage(cgImage: base)
        guard let f = CIFilter(name: "CIColorMatrix") else { return base }
        f.setValue(ci, forKey: kCIInputImageKey)
        // Scale channels toward black, dropping blue/green faster than red -> browner.
        let r = 1 - 0.45 * d, g = 1 - 0.70 * d, b = 1 - 0.85 * d
        f.setValue(CIVector(x: r, y: 0, z: 0, w: 0), forKey: "inputRVector")
        f.setValue(CIVector(x: 0, y: g, z: 0, w: 0), forKey: "inputGVector")
        f.setValue(CIVector(x: 0, y: 0, z: b, w: 0), forKey: "inputBVector")
        f.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
        guard let out = f.outputImage,
              let cg = ciContext.createCGImage(out, from: CGRect(x: 0, y: 0, width: base.width, height: base.height))
        else { return base }
        return cg
    }
}
