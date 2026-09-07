import Testing
import Foundation
@testable import ProRoundsFeatureTimer
import ProRoundsDataConfig
import ProRoundsDataSessions
import ProRoundsFoundationAudio
import ProRoundsFoundationTiming
import ProRoundsFoundationUtilities

@MainActor
@Suite("Editing the coaching level from the workout screen")
struct CoachLevelEditingTests {
    private func makeModel(
        coaching: CoachingLevel? = nil
    ) -> (WorkoutViewModel, SpyConfigurationWriter) {
        let config = Configuration(
            workoutType: .heavyBag, rounds: 3, roundDuration: .seconds(60),
            restDuration: .seconds(30), prepDuration: .zero, warningLead: .zero,
            coachingLevel: coaching)
        let writer = SpyConfigurationWriter()
        let engine = RoundTimerEngine(
            configuration: config, timeSource: FakeTimeSource(), player: SpyAudioCuePlayer())
        let model = WorkoutViewModel(
            configuration: config, engine: engine, idleTimer: FakeIdleTimer(),
            interruptions: FakeAudioInterruptionMonitor(), sessions: NoopSessionRepository(),
            configurationWriter: writer)
        return (model, writer)
    }

    @Test("the chip reflects the configuration's stored level")
    func chipReflectsStoredLevel() {
        let (model, _) = makeModel(coaching: .beginner)
        model.onAppear()
        #expect(model.display.coachingChipLabel == "Coach: Beginner")
    }

    /// Two entry points, one stored value. Setting the level here must write the same
    /// `Configuration.coachingLevel` the editor writes, not a second copy of the state.
    @Test("setting the level writes through to the configuration")
    func setLevelPersists() async {
        let (model, writer) = makeModel()
        model.onAppear()
        await model.setCoachingLevel(.beginner)
        #expect(writer.saved.count == 1)
        #expect(writer.saved.first?.coachingLevel == .beginner)
        #expect(model.display.coachingChipLabel == "Coach: Beginner")
    }

    @Test("turning coaching off writes through too")
    func clearLevelPersists() async {
        let (model, writer) = makeModel(coaching: .beginner)
        model.onAppear()
        await model.setCoachingLevel(nil)
        #expect(writer.saved.first?.coachingLevel == nil)
        #expect(model.display.coachingChipLabel == "Coach: Off")
    }

    @Test("nothing else about the configuration changes")
    func onlyCoachingChanges() async {
        let (model, writer) = makeModel()
        model.onAppear()
        await model.setCoachingLevel(.beginner)
        let saved = writer.saved.first
        #expect(saved?.rounds == 3)
        #expect(saved?.roundDuration == .seconds(60))
        #expect(saved?.workoutType == .heavyBag)
    }

    @Test("a save failure leaves the displayed level matching what was stored")
    func saveFailureDoesNotLie() async {
        let (model, writer) = makeModel()
        writer.shouldFail = true
        model.onAppear()
        await model.setCoachingLevel(.beginner)
        #expect(model.display.coachingChipLabel == "Coach: Off",
                "the chip must not claim a level that was never saved")
    }
}

/// Records what the workout screen writes back, so the "one stored value" claim is checked rather
/// than assumed.
@MainActor
final class SpyConfigurationWriter: ConfigurationWriting {
    private(set) var saved: [Configuration] = []
    var shouldFail = false

    func save(_ configuration: Configuration) async throws {
        if shouldFail { throw NSError(domain: "spy", code: 1) }
        saved.append(configuration)
    }
}

/// The workout screen's session saving is not what these tests are about.
final class NoopSessionRepository: SessionRepository, @unchecked Sendable {
    func save(_ session: Session) async throws {}
    func all() async throws -> [Session] { [] }
    func byWorkoutType() async throws -> [WorkoutType: [Session]] { [:] }
}
