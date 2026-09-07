import Testing
import Foundation
import ProRoundsDataConfig
import ProRoundsFoundationUtilities
@testable import ProRoundsFeatureConfig

@Suite("Coaching in the editor draft")
struct CoachingDraftTests {
    @Test("a new draft has coaching off")
    func defaultsOff() {
        #expect(ConfigurationDraft().coachingLevel == nil)
    }

    @Test("the section is offered only where a script exists", arguments: WorkoutType.allCases)
    func sectionVisibility(type: WorkoutType) {
        var draft = ConfigurationDraft()
        draft.workoutType = type
        #expect(draft.showsCoachingSection == type.supportsCoaching)
    }

    @Test("an existing configuration's coaching level loads into the draft")
    func loadsFromConfiguration() {
        let configuration = Configuration(
            workoutType: .heavyBag, rounds: 6, roundDuration: .seconds(120),
            restDuration: .seconds(45), prepDuration: .seconds(20),
            warningLead: .seconds(10), coachingLevel: .beginner)
        #expect(ConfigurationDraft(configuration).coachingLevel == .beginner)
    }

    @Test("the draft builds a configuration carrying the level")
    func buildsWithLevel() {
        var draft = ConfigurationDraft()
        draft.workoutType = .shadowBoxing
        draft.coachingLevel = .beginner
        #expect(draft.build(id: UUID()).coachingLevel == .beginner)
    }

    /// Switching type to look at something and losing a coaching choice is data loss in miniature,
    /// but the alternatives are worse: saving an invalid configuration, or blocking the type change
    /// outright. Clearing happens before save, so cancelling still discards it.
    @Test("switching to an unscripted type clears coaching")
    func switchingTypeClearsCoaching() {
        var draft = ConfigurationDraft()
        draft.workoutType = .shadowBoxing
        draft.coachingLevel = .beginner
        draft.workoutType = .skipping
        #expect(draft.coachingLevel == nil)
    }

    @Test("switching between scripted types keeps coaching")
    func switchingBetweenScriptedTypesKeepsCoaching() {
        var draft = ConfigurationDraft()
        draft.workoutType = .shadowBoxing
        draft.coachingLevel = .beginner
        draft.workoutType = .heavyBag
        #expect(draft.coachingLevel == .beginner)
    }

    /// The clearing above is what makes this unreachable through the UI, but the validator is the
    /// backstop — an invalid combination must never reach the store.
    @Test("a draft can never build an invalid coaching combination")
    func draftNeverBuildsInvalid() {
        for type in WorkoutType.allCases {
            var draft = ConfigurationDraft()
            draft.coachingLevel = .beginner
            draft.workoutType = type
            #expect(ConfigurationValidator.isValid(draft.build(id: UUID())))
        }
    }

    @Test("coaching does not change the live total or auto-name preview")
    func previewUnaffected() {
        var plain = ConfigurationDraft()
        plain.workoutType = .heavyBag
        var coached = plain
        coached.coachingLevel = .beginner
        #expect(coached.total == plain.total)
        #expect(coached.autoName == plain.autoName)
    }
}
