import Foundation
import Observation
import ProRoundsDataConfig
import ProRoundsFoundationUtilities

/// View model for the create/edit editor (guide §3.2). Holds a mutable `ConfigurationDraft`, exposes
/// the live total/auto-name preview, validates on save via the single `ConfigurationValidator`, and
/// persists through the repository only when valid.
@MainActor
@Observable
public final class ConfigEditorViewModel {
    var draft: ConfigurationDraft
    private(set) var errors: [ConfigurationValidationError] = []

    public let isEditing: Bool
    private let existingId: Configuration.ID?
    private let repository: any ConfigurationRepository

    /// `configuration == nil` creates a new one; otherwise edits the given one.
    public init(editing configuration: Configuration?, repository: any ConfigurationRepository) {
        self.repository = repository
        if let configuration {
            draft = ConfigurationDraft(configuration)
            existingId = configuration.id
            isEditing = true
        } else {
            draft = ConfigurationDraft()
            existingId = nil
            isEditing = false
        }
    }

    var totalText: String { DurationFormat.clock(draft.total) }
    /// The live auto-generated name, shown as the name field's placeholder while it's blank.
    var autoName: String { draft.autoName }

    private var pendingConfiguration: Configuration {
        draft.build(id: existingId ?? UUID())
    }

    /// Validates and persists. Returns `true` when saved (caller dismisses); `false` leaves `errors`
    /// populated and persists nothing.
    @discardableResult
    func save() async -> Bool {
        errors = ConfigurationValidator.validate(pendingConfiguration)
        guard errors.isEmpty else { return false }
        try? await repository.save(pendingConfiguration)
        return true
    }

    func delete() async {
        guard let existingId else { return }
        try? await repository.delete(existingId)
    }
}
