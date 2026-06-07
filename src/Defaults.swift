//
//  Defaults.swift
//  Flying Toasters
//
//  Persists ToasterSettings to the screensaver's own preferences domain via
//  ScreenSaverDefaults, so the configure sheet and the running saver share state.
//

import Foundation
import ScreenSaver

enum FT {
    /// Preferences domain for the module. Must be stable across launches.
    static let moduleName = "com.warpspeed.flyingtoasters"

    private enum Key {
        static let toasterCount = "toasterCount"
        static let toastRatio   = "toastRatio"
        static let speed        = "speed"
        static let darkness     = "darkness"
        static let authenticFlap = "authenticFlap"
        static let showStars    = "showStars"
        static let seeded       = "seededDefaults"
    }

    static var store: ScreenSaverDefaults {
        ScreenSaverDefaults(forModuleWithName: moduleName) ?? ScreenSaverDefaults()
    }

    static func registerDefaults() {
        let d = ToasterSettings.default
        store.register(defaults: [
            Key.toasterCount: d.toasterCount,
            Key.toastRatio: d.toastRatio,
            Key.speed: d.speed,
            Key.darkness: d.darkness,
            Key.authenticFlap: d.authenticFlap,
            Key.showStars: d.showStars,
        ])
    }

    static func load() -> ToasterSettings {
        registerDefaults()
        let s = store
        var out = ToasterSettings.default
        // Only override from store if values were ever written (register covers the rest).
        out.toasterCount = max(ToasterSettings.toasterRange.lowerBound,
                               min(ToasterSettings.toasterRange.upperBound, s.integer(forKey: Key.toasterCount)))
        if s.object(forKey: Key.toastRatio) != nil { out.toastRatio = s.double(forKey: Key.toastRatio) }
        if s.object(forKey: Key.speed) != nil {
            out.speed = min(ToasterSettings.speedRange.upperBound,
                            max(ToasterSettings.speedRange.lowerBound, s.double(forKey: Key.speed)))
        }
        if s.object(forKey: Key.darkness) != nil { out.darkness = min(1, max(0, s.double(forKey: Key.darkness))) }
        out.authenticFlap = s.object(forKey: Key.authenticFlap) == nil ? d_authentic : s.bool(forKey: Key.authenticFlap)
        out.showStars = s.bool(forKey: Key.showStars)
        return out
    }

    private static var d_authentic: Bool { ToasterSettings.default.authenticFlap }

    static func save(_ s: ToasterSettings) {
        let store = self.store
        store.set(s.toasterCount, forKey: Key.toasterCount)
        store.set(s.toastRatio, forKey: Key.toastRatio)
        store.set(s.speed, forKey: Key.speed)
        store.set(s.darkness, forKey: Key.darkness)
        store.set(s.authenticFlap, forKey: Key.authenticFlap)
        store.set(s.showStars, forKey: Key.showStars)
        store.synchronize()
    }
}
