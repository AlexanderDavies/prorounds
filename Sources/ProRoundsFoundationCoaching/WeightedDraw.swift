/// Weighted selection over a pool, ported from `weighted()` in `scripts/coach-script.py`.
///
/// The accumulation order and the trailing fallback are both deliberate. Summing weights in array
/// order and comparing against a running total reproduces the reference's float behaviour exactly;
/// a "cleaner" formulation (sorting, or comparing against a prefix-sum array) can pick a different
/// element on ties. The final `items.last` is reachable when float error leaves `acc` a hair below
/// `x` on the last element, so it is a real branch, not defensive padding.
func weightedChoice<T>(
    _ items: [T],
    using rng: inout SplitMix64,
    weight: (T) -> Double
) -> T? {
    guard let last = items.last else { return nil }
    let total = items.reduce(0.0) { $0 + weight($1) }
    let x = rng.unit() * total
    var acc = 0.0
    for item in items {
        acc += weight(item)
        if x < acc { return item }
    }
    return last
}
