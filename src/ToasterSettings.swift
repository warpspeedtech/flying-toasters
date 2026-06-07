//
//  ToasterSettings.swift
//  Flying Toasters
//
//  Plain value type for the tunable options (kept free of AppKit so the scene can be
//  exercised headlessly). Persistence to ScreenSaverDefaults lives in Defaults.swift.
//

import CoreGraphics
import Foundation

struct ToasterSettings: Equatable {
    /// Target number of toasters on a full-size display.
    var toasterCount: Int = 30
    /// Pieces of toast per toaster (the original ran roughly 3 toasters : 1 toast).
    var toastRatio: Double = 0.34
    /// Overall speed multiplier over the classic 10/16/24 s traversal tiers.
    var speed: Double = 1.0
    /// Toast darkness, 0 = the genuine golden sprite, 1 = burnt (the original's slider).
    var darkness: Double = 0.0
    /// Authentic 4-step flap (true) vs. a smoother multi-frame flap (false).
    var authenticFlap: Bool = true
    /// A faint retro starfield behind the toasters (off by default — the classic is black).
    var showStars: Bool = false

    static let `default` = ToasterSettings()

    // Slider ranges used by the configure sheet.
    static let toasterRange = 1...60
    static let speedRange = 0.25...3.0
}
