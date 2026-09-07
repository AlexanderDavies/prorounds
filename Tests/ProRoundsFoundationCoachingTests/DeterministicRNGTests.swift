import Testing
import Foundation
@testable import ProRoundsFoundationCoaching

/// Ground truth emitted by `scripts/coach-script.py seed-vectors`.
///
/// `unitBits` are IEEE-754 bit patterns rather than decimals on purpose: a decimal round-trip is
/// exactly where a port silently loses the last mantissa bit, so comparing decimal strings would
/// pass while the sequences diverged.
private struct SeedVectors: Decodable {
    struct Vector: Decodable {
        let configId: String
        let roundIndex: Int
        let seed: String
        let nextU64: [String]
        let unitBits: [String]
    }
    let vectors: [Vector]

    static func load() throws -> SeedVectors {
        let url = try #require(Bundle.module.url(
            forResource: "seed_vectors", withExtension: "json", subdirectory: "Fixtures"))
        return try JSONDecoder().decode(SeedVectors.self, from: Data(contentsOf: url))
    }
}

private func u64(_ hex: String) throws -> UInt64 {
    try #require(UInt64(hex, radix: 16), "not 16-digit hex: \(hex)")
}

@Suite("SplitMix64 matches the Python reference")
struct SplitMix64Tests {
    @Test("next() reproduces the reference sequence for every seed vector")
    func nextMatchesReference() throws {
        for vector in try SeedVectors.load().vectors {
            var rng = SplitMix64(seed: try u64(vector.seed))
            for (index, expected) in vector.nextU64.enumerated() {
                let actual = rng.next()
                #expect(actual == (try u64(expected)),
                        "\(vector.configId)#\(vector.roundIndex) value \(index): got \(String(actual, radix: 16))")
            }
        }
    }

    @Test("unit() is bit-identical to the reference, not merely close")
    func unitIsBitIdentical() throws {
        for vector in try SeedVectors.load().vectors {
            var rng = SplitMix64(seed: try u64(vector.seed))
            for (index, bits) in vector.unitBits.enumerated() {
                let expected = Double(bitPattern: try u64(bits))
                let actual = rng.unit()
                #expect(actual.bitPattern == expected.bitPattern,
                        "\(vector.configId)#\(vector.roundIndex) unit \(index): got \(actual) expected \(expected)")
            }
        }
    }

    @Test("unit() stays in [0, 1)")
    func unitIsInRange() {
        var rng = SplitMix64(seed: 0xDEAD_BEEF)
        for _ in 0..<10_000 {
            let value = rng.unit()
            #expect(value >= 0 && value < 1)
        }
    }

    @Test("the same seed replays, a different seed diverges")
    func determinism() {
        var first = SplitMix64(seed: 42)
        var replay = SplitMix64(seed: 42)
        var other = SplitMix64(seed: 43)
        let sequence = (0..<32).map { _ in first.next() }
        #expect(sequence == (0..<32).map { _ in replay.next() })
        #expect(sequence != (0..<32).map { _ in other.next() })
    }
}

@Suite("Coaching seed derivation")
struct CoachSeedTests {
    @Test("FNV-1a digest matches the reference for every vector")
    func seedMatchesReference() throws {
        for vector in try SeedVectors.load().vectors {
            let actual = CoachSeed.seed(configID: vector.configId, roundIndex: vector.roundIndex)
            #expect(actual == (try u64(vector.seed)),
                    "\(vector.configId)#\(vector.roundIndex): got \(String(actual, radix: 16)) expected \(vector.seed)")
        }
    }

    /// The reference seeds with the raw index and only displays `round_index + 1`
    /// (coach-script.py:283). A one-based port produces a plausible schedule that matches nothing.
    @Test("roundIndex is zero-based")
    func roundIndexIsZeroBased() throws {
        let vectors = try SeedVectors.load().vectors
        let demo0 = try #require(vectors.first { $0.configId == "demo" && $0.roundIndex == 0 })
        let demo1 = try #require(vectors.first { $0.configId == "demo" && $0.roundIndex == 1 })
        #expect(CoachSeed.seed(configID: "demo", roundIndex: 0) == (try u64(demo0.seed)))
        #expect(CoachSeed.seed(configID: "demo", roundIndex: 0) != (try u64(demo1.seed)))
    }

    @Test("an empty config ID still seeds")
    func emptyConfigID() throws {
        let vector = try #require(try SeedVectors.load().vectors.first { $0.configId.isEmpty })
        #expect(CoachSeed.seed(configID: "", roundIndex: vector.roundIndex) == (try u64(vector.seed)))
    }
}
