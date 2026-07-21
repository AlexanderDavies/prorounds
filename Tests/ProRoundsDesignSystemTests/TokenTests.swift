import Testing
import SwiftUI
@testable import ProRoundsDesignSystem
import ProRoundsFoundationUtilities

@Suite("Design tokens")
struct TokenTests {
    @Test("Each workout type has a distinct chart color (validated palette)")
    func chartPalette() {
        let colors = WorkoutType.allCases.map { ProRoundsColor.chartColor(for: $0).color(for: .dark) }
        #expect(Set(colors).count == WorkoutType.allCases.count) // all distinct
        #expect(ProRoundsColor.chartColor(for: .shadowBoxing).color(for: .dark) == Color(hex: 0xE50914))
        #expect(ProRoundsColor.chartColor(for: .sparring).color(for: .dark) == Color(hex: 0xB23A8A))
    }

    @Test("The brand accent is the DESIGN red in both appearances")
    func accentIsSignatureRed() {
        #expect(ProRoundsColor.accent.color(for: .light) == Color(hex: 0xE50914))
        #expect(ProRoundsColor.accent.color(for: .dark) == Color(hex: 0xE50914))
    }

    @Test("Canvas and primary text invert between appearances")
    func canvasAndTextInvert() {
        #expect(ProRoundsColor.canvas.color(for: .dark) == Color(hex: 0x0A0A0B))
        #expect(ProRoundsColor.canvas.color(for: .light) == Color(hex: 0xF7F7F8))
        #expect(ProRoundsColor.textPrimary.color(for: .dark) == Color(hex: 0xF5F5F7))
        #expect(ProRoundsColor.textPrimary.color(for: .light) == Color(hex: 0x0A0A0B))
        // They actually differ between appearances.
        #expect(ProRoundsColor.canvas.light != ProRoundsColor.canvas.dark)
        #expect(ProRoundsColor.textPrimary.light != ProRoundsColor.textPrimary.dark)
    }

    @Test("Spacing tokens follow the 8-pt grid")
    func spacingGrid() {
        #expect(Spacing.xs == 8)
        #expect(Spacing.md == 16)
        #expect(Spacing.lg == 24)
        #expect(Spacing.xxl == 48)
    }

    @Test("Radius tokens match the design scale")
    func radiusScale() {
        #expect(Radius.sm == 8)
        #expect(Radius.md == 12)
        #expect(Radius.lg == 16)
    }

    @Test("Typography scale exists and the timer role uses monospaced digits")
    func typography() {
        #expect(ProRoundsFont.timer.size == 96)
        #expect(ProRoundsFont.timer.monospacedDigits)
        #expect(ProRoundsFont.body.size == 17)
        #expect(!ProRoundsFont.body.monospacedDigits)
        #expect(ProRoundsFont.overline.weight == .bold)
    }
}
