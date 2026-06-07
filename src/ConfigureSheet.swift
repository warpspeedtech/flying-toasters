//
//  ConfigureSheet.swift
//  Flying Toasters
//
//  A programmatic Options sheet (no nib) exposing the faithful controls: number of
//  toasters, toast amount, speed, toast darkness, plus flap style and an optional
//  starfield. Mirrors the spirit of the original module's settings.
//

import AppKit

final class ConfigureSheetController: NSObject {

    let window: NSWindow
    private var settings: ToasterSettings
    private let onApply: (ToasterSettings) -> Void

    private let toasterSlider = NSSlider()
    private let toasterValue = NSTextField(labelWithString: "")
    private let toastSlider = NSSlider()
    private let toastValue = NSTextField(labelWithString: "")
    private let speedSlider = NSSlider()
    private let speedValue = NSTextField(labelWithString: "")
    private let darknessSlider = NSSlider()
    private let darknessValue = NSTextField(labelWithString: "")
    private let starsCheck = NSButton(checkboxWithTitle: "Faint starfield behind toasters", target: nil, action: nil)

    init(settings: ToasterSettings, onApply: @escaping (ToasterSettings) -> Void) {
        self.settings = settings
        self.onApply = onApply
        self.window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 440, height: 386),
                               styleMask: [.titled], backing: .buffered, defer: true)
        super.init()
        window.title = "Flying Toasters"
        buildUI()
        syncControlsFromSettings()
    }

    // MARK: Layout

    private func buildUI() {
        let content = NSView(frame: window.contentLayoutRect)
        content.autoresizingMask = [.width, .height]
        window.contentView = content

        let title = NSTextField(labelWithString: "Flying Toasters")
        title.font = NSFont.boldSystemFont(ofSize: 18)
        title.frame = NSRect(x: 24, y: 344, width: 392, height: 24)
        content.addSubview(title)

        let subtitle = NSTextField(labelWithString: "A faithful recreation of the After Dark classic.")
        subtitle.font = NSFont.systemFont(ofSize: 11)
        subtitle.textColor = .secondaryLabelColor
        subtitle.frame = NSRect(x: 24, y: 324, width: 392, height: 18)
        content.addSubview(subtitle)

        var y = 288
        func row(_ label: String, _ slider: NSSlider, _ value: NSTextField,
                 min: Double, max: Double, action: Selector) {
            let l = NSTextField(labelWithString: label)
            l.frame = NSRect(x: 24, y: y, width: 150, height: 18)
            l.alignment = .right
            content.addSubview(l)
            slider.minValue = min; slider.maxValue = max
            slider.target = self; slider.action = action
            slider.frame = NSRect(x: 182, y: y - 2, width: 188, height: 22)
            content.addSubview(slider)
            value.frame = NSRect(x: 376, y: y, width: 52, height: 18)
            value.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)
            value.textColor = .secondaryLabelColor
            content.addSubview(value)
            y -= 40
        }

        row("Number of toasters:", toasterSlider, toasterValue,
            min: Double(ToasterSettings.toasterRange.lowerBound),
            max: Double(ToasterSettings.toasterRange.upperBound), action: #selector(sliderChanged))
        row("Toast:", toastSlider, toastValue, min: 0, max: 1, action: #selector(sliderChanged))
        row("Speed:", speedSlider, speedValue,
            min: ToasterSettings.speedRange.lowerBound, max: ToasterSettings.speedRange.upperBound,
            action: #selector(sliderChanged))
        row("Toast darkness:", darknessSlider, darknessValue, min: 0, max: 1, action: #selector(sliderChanged))

        starsCheck.frame = NSRect(x: 182, y: y, width: 250, height: 20); y -= 8
        content.addSubview(starsCheck)

        let cancel = NSButton(title: "Cancel", target: self, action: #selector(cancel))
        cancel.bezelStyle = .rounded
        cancel.keyEquivalent = "\u{1b}"
        cancel.frame = NSRect(x: 232, y: 16, width: 92, height: 32)
        content.addSubview(cancel)

        let ok = NSButton(title: "Done", target: self, action: #selector(done))
        ok.bezelStyle = .rounded
        ok.keyEquivalent = "\r"
        ok.frame = NSRect(x: 332, y: 16, width: 92, height: 32)
        content.addSubview(ok)
    }

    private func syncControlsFromSettings() {
        toasterSlider.integerValue = settings.toasterCount
        toastSlider.doubleValue = settings.toastRatio / 0.8
        speedSlider.doubleValue = settings.speed
        darknessSlider.doubleValue = settings.darkness
        starsCheck.state = settings.showStars ? .on : .off
        updateValueLabels()
    }

    private func updateValueLabels() {
        toasterValue.stringValue = "\(toasterSlider.integerValue)"
        let pct = Int((toastSlider.doubleValue * 100).rounded())
        toastValue.stringValue = "\(pct)%"
        speedValue.stringValue = String(format: "%.2f×", speedSlider.doubleValue)
        darknessValue.stringValue = String(format: "%.0f%%", darknessSlider.doubleValue * 100)
    }

    // MARK: Actions

    @objc private func sliderChanged() { updateValueLabels() }

    @objc private func done() {
        settings.toasterCount = toasterSlider.integerValue
        settings.toastRatio = toastSlider.doubleValue * 0.8
        settings.speed = speedSlider.doubleValue
        settings.darkness = darknessSlider.doubleValue
        settings.showStars = starsCheck.state == .on
        FT.save(settings)
        onApply(settings)
        endSheet()
    }

    @objc private func cancel() { endSheet() }

    private func endSheet() {
        if let parent = window.sheetParent {
            parent.endSheet(window)
        } else {
            window.orderOut(nil)
        }
    }
}
