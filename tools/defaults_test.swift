//
//  defaults_test.swift
//  Verifies the saver's settings persist to the shared ScreenSaverDefaults domain and
//  are visible across processes (i.e. a separate configurator app can drive the saver).
//
//  Usage: defaults_test read
//         defaults_test write <count> <speed> <darkness>
//

import Foundation
import ScreenSaver

@main
enum DefaultsTest {
    static func main() {
        let a = CommandLine.arguments
        if a.count > 1, a[1] == "write" {
            var s = FT.load()
            if a.count > 2, let c = Int(a[2]) { s.toasterCount = c }
            if a.count > 3, let sp = Double(a[3]) { s.speed = sp }
            if a.count > 4, let d = Double(a[4]) { s.darkness = d }
            FT.save(s)
            print("wrote  count=\(s.toasterCount) speed=\(s.speed) darkness=\(s.darkness)")
        } else {
            let s = FT.load()
            print("read   count=\(s.toasterCount) speed=\(s.speed) darkness=\(s.darkness) toast=\(s.toastRatio) stars=\(s.showStars)")
        }
    }
}
