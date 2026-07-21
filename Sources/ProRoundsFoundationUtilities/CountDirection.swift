/// Whether the running timer shows time counting down (remaining) or up (elapsed). A display choice
/// only — the engine's sequencing never depends on it (guide §7.6). Persisted by settings later.
public enum CountDirection: String, CaseIterable, Codable, Sendable, Equatable {
    case countDown
    case countUp
}
