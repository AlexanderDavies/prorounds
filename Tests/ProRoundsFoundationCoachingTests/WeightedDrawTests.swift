import Testing
@testable import ProRoundsFoundationCoaching

@Suite("Weighted draw")
struct WeightedDrawTests {
    private struct Entry { let id: String; let weight: Double }

    @Test("an empty pool draws nothing")
    func emptyPool() {
        var rng = SplitMix64(seed: 1)
        #expect(weightedChoice([Entry](), using: &rng, weight: \.weight) == nil)
    }

    @Test("a zero-weight entry is never drawn from a mixed pool")
    func zeroWeightNeverChosen() {
        let pool = [Entry(id: "never", weight: 0), Entry(id: "a", weight: 1), Entry(id: "b", weight: 1)]
        var rng = SplitMix64(seed: 7)
        for _ in 0..<5_000 {
            #expect(weightedChoice(pool, using: &rng, weight: \.weight)?.id != "never")
        }
    }

    /// The reference's trailing `return items[-1]`. With every weight zero, `total` is 0, so `x` is
    /// 0 and `x < acc` is false for every element — the loop falls through. It is a real branch,
    /// not defensive padding, and a port that raises or returns nil here diverges.
    @Test("an all-zero pool falls through to the last entry")
    func allZeroFallsThroughToLast() {
        let pool = [Entry(id: "a", weight: 0), Entry(id: "b", weight: 0), Entry(id: "last", weight: 0)]
        var rng = SplitMix64(seed: 3)
        for _ in 0..<100 {
            #expect(weightedChoice(pool, using: &rng, weight: \.weight)?.id == "last")
        }
    }

    @Test("weights govern the distribution")
    func distribution() {
        let pool = [Entry(id: "light", weight: 1), Entry(id: "heavy", weight: 3)]
        var rng = SplitMix64(seed: 99)
        var heavy = 0
        let draws = 20_000
        for _ in 0..<draws where weightedChoice(pool, using: &rng, weight: \.weight)?.id == "heavy" {
            heavy += 1
        }
        let share = Double(heavy) / Double(draws)
        #expect(share > 0.72 && share < 0.78, "heavy share \(share), expected ~0.75")
    }

    @Test("a draw is deterministic in the generator")
    func deterministic() {
        let pool = [Entry(id: "a", weight: 2), Entry(id: "b", weight: 5), Entry(id: "c", weight: 1)]
        var one = SplitMix64(seed: 2024), two = SplitMix64(seed: 2024)
        let first = (0..<50).map { _ in weightedChoice(pool, using: &one, weight: \.weight)?.id }
        #expect(first == (0..<50).map { _ in weightedChoice(pool, using: &two, weight: \.weight)?.id })
    }
}
