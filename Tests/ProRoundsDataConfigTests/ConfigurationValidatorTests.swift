import Testing
import Foundation
@testable import ProRoundsDataConfig
import ProRoundsFoundationUtilities

@Suite("ConfigurationValidator")
struct ConfigurationValidatorTests {
    private func config(rounds: Int = 12, round: Duration = .seconds(180), rest: Duration = .seconds(60),
                        prep: Duration = .seconds(10), lead: Duration = .seconds(10)) -> Configuration {
        Configuration(workoutType: .heavyBag, rounds: rounds, roundDuration: round,
                      restDuration: rest, prepDuration: prep, warningLead: lead)
    }

    @Test("A well-formed configuration is valid")
    func wellFormedIsValid() {
        #expect(ConfigurationValidator.validate(config()).isEmpty)
        #expect(ConfigurationValidator.isValid(config()))
    }

    @Test("Zero rounds is rejected")
    func zeroRounds() {
        #expect(ConfigurationValidator.validate(config(rounds: 0)).contains(.roundCountTooLow))
    }

    @Test("Non-positive round duration is rejected")
    func zeroRoundDuration() {
        let errors = ConfigurationValidator.validate(config(round: .zero, lead: .zero))
        #expect(errors.contains(.roundDurationNotPositive))
    }

    @Test("Negative rest or prep is rejected")
    func negativeRestPrep() {
        #expect(ConfigurationValidator.validate(config(rest: .seconds(-1))).contains(.restDurationNegative))
        #expect(ConfigurationValidator.validate(config(prep: .seconds(-1))).contains(.prepDurationNegative))
    }

    @Test("A warning lead at or beyond the round length is rejected")
    func warningLeadTooLong() {
        #expect(ConfigurationValidator.validate(config(round: .seconds(180), lead: .seconds(180)))
            .contains(.warningLeadOutOfRange))
    }

    @Test("A zero warning lead is accepted")
    func zeroLeadAccepted() {
        #expect(!ConfigurationValidator.validate(config(lead: .zero)).contains(.warningLeadOutOfRange))
    }

    @Test("All violations are reported together")
    func multipleViolations() {
        let errors = ConfigurationValidator.validate(config(rounds: 0, round: .zero, lead: .zero))
        #expect(errors.contains(.roundCountTooLow))
        #expect(errors.contains(.roundDurationNotPositive))
    }
}
