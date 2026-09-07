/// A fixed, portable PRNG — the coaching scheduler's only source of randomness.
///
/// `SystemRandomNumberGenerator` cannot be used here. It cannot be seeded, and its sequence is not
/// stable across OS versions or machines, which would break the replay guarantee the coaching UX
/// depends on: the same workout must call the same combinations every time it is run.
///
/// This is a direct port of `SplitMix64` in `scripts/coach-script.py`, which is normative. The
/// constants and shift widths must not be "tidied" — every one is load-bearing for byte-identity
/// with the reference, and `Tests/.../Fixtures/seed_vectors.json` pins them.
public struct SplitMix64: RandomNumberGenerator, Sendable {
    private var state: UInt64

    public init(seed: UInt64) {
        state = seed
    }

    public init(configID: String, roundIndex: Int) {
        self.init(seed: CoachSeed.seed(configID: configID, roundIndex: roundIndex))
    }

    /// `&+` and `&*` wrap on overflow, which is what the reference's `& MASK` does in Python.
    public mutating func next() -> UInt64 {
        state = state &+ 0x9E37_79B9_7F4A_7C15
        // `z` in the canonical formulation and in coach-script.py; spelled out for the linter.
        var mixed = state
        mixed = (mixed ^ (mixed >> 30)) &* 0xBF58_476D_1CE4_E5B9
        mixed = (mixed ^ (mixed >> 27)) &* 0x94D0_49BB_1331_11EB
        return mixed ^ (mixed >> 31)
    }

    /// A `Double` in `[0, 1)`.
    ///
    /// Taking the top 53 bits is what makes this exact: the result is representable without
    /// rounding, so Swift and Python produce identical bit patterns rather than merely close
    /// decimals. Tested against `unitBits` rather than decimal strings for that reason.
    public mutating func unit() -> Double {
        Double(next() >> 11) / Double(1 << 53)
    }
}

/// Derives a scheduler seed from the identity of a round.
public enum CoachSeed {
    /// FNV-1a, 64-bit, over the UTF-8 bytes of `text`.
    public static func fnv1a64(_ text: String) -> UInt64 {
        var hash: UInt64 = 0xCBF2_9CE4_8422_2325
        for byte in text.utf8 {
            hash = (hash ^ UInt64(byte)) &* 0x0000_0100_0000_01B3
        }
        return hash
    }

    /// The seed for one round: FNV-1a over `"<configID>#<roundIndex>"`.
    ///
    /// `roundIndex` is **zero-based**. The reference displays `round_index + 1` for humans but
    /// seeds with the raw value (`coach-script.py:283`); a one-based port yields a plausible
    /// schedule that matches no fixture.
    public static func seed(configID: String, roundIndex: Int) -> UInt64 {
        fnv1a64("\(configID)#\(roundIndex)")
    }
}
