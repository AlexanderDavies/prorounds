import ProRoundsDataConfig

/// The narrow slice of configuration persistence the workout screen needs.
///
/// The coaching chip is a *second entry point into one stored value*, not a second copy of it — so
/// the workout screen writes the same `Configuration` the editor does. It takes this rather than the
/// full repository because saving is all it may do: the running screen has no business listing or
/// deleting configurations.
public protocol ConfigurationWriting: Sendable {
    func save(_ configuration: Configuration) async throws
}
