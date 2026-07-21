import Foundation

/// A specific reason a configuration is invalid (guide §11).
public enum ConfigurationValidationError: Equatable, Sendable {
    case roundCountTooLow          // rounds < 1
    case roundDurationNotPositive  // roundDuration <= 0
    case restDurationNegative      // restDuration < 0
    case prepDurationNegative      // prepDuration < 0
    case warningLeadOutOfRange     // warningLead < 0, or >= roundDuration
}

/// The single home for configuration validation (guide §11). The engine trusts its input and does
/// not re-validate — configurations are checked here, at the create/edit boundary. Every broken
/// rule is reported so an editor can surface them all at once.
public enum ConfigurationValidator {
    public static func validate(_ configuration: Configuration) -> [ConfigurationValidationError] {
        var errors: [ConfigurationValidationError] = []

        if configuration.rounds < 1 {
            errors.append(.roundCountTooLow)
        }
        if configuration.roundDuration <= .zero {
            errors.append(.roundDurationNotPositive)
        }
        if configuration.restDuration < .zero {
            errors.append(.restDurationNegative)
        }
        if configuration.prepDuration < .zero {
            errors.append(.prepDurationNegative)
        }
        // A warning lead must be non-negative and shorter than the round it precedes. When the round
        // duration is itself invalid (≤ 0), skip the "< round" comparison — that error is already
        // reported and the comparison would be meaningless.
        if configuration.warningLead < .zero {
            errors.append(.warningLeadOutOfRange)
        } else if configuration.roundDuration > .zero, configuration.warningLead >= configuration.roundDuration {
            errors.append(.warningLeadOutOfRange)
        }

        return errors
    }

    public static func isValid(_ configuration: Configuration) -> Bool {
        validate(configuration).isEmpty
    }
}
