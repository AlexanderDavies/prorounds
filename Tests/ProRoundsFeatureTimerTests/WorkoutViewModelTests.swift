import Testing
import Foundation
@testable import ProRoundsFeatureTimer
import ProRoundsDataConfig
import ProRoundsDataSessions
import ProRoundsFoundationAudio
import ProRoundsFoundationTiming
import ProRoundsFoundationUtilities

/// A session repository that fails on demand, for the save-failure path.
actor FailingSessionRepository: SessionRepository {
    private var shouldFail: Bool
    private(set) var savedCount = 0

    init(shouldFail: Bool) { self.shouldFail = shouldFail }
    func stopFailing() { shouldFail = false }

    enum Failure: Error { case save }
    func save(_ session: Session) async throws {
        if shouldFail { throw Failure.save }
        savedCount += 1
    }
    func all() async throws -> [Session] { [] }
    func byWorkoutType() async throws -> [WorkoutType: [Session]] { [:] }
}

@MainActor
@Suite("WorkoutViewModel")
struct WorkoutViewModelTests {
    private struct Harness {
        let fake: FakeTimeSource
        let idle: FakeIdleTimer
        let interruptions: FakeAudioInterruptionMonitor
        let sessions: SwiftDataSessionRepository
        let engine: RoundTimerEngine
        let model: WorkoutViewModel
    }

    private func makeHarness(rounds: Int = 1, round: Int = 5,
                             sessions: (any SessionRepository)? = nil) throws -> Harness {
        let fake = FakeTimeSource()
        let config = Configuration(workoutType: .heavyBag, rounds: rounds, roundDuration: .seconds(round),
                                   restDuration: .zero, prepDuration: .zero, warningLead: .zero,
                                   customName: "Session")
        let engine = RoundTimerEngine(configuration: config, timeSource: fake,
                                      player: SpyAudioCuePlayer(), warningSound: .buzzer)
        let idle = FakeIdleTimer()
        let interruptions = FakeAudioInterruptionMonitor()
        let sessionRepo = try SwiftDataSessionRepository(modelContainer: SessionStore.makeContainer(inMemory: true))
        let model = WorkoutViewModel(configuration: config, engine: engine, idleTimer: idle,
                                     interruptions: interruptions, sessions: sessions ?? sessionRepo,
                                     countDirection: .countDown)
        return Harness(fake: fake, idle: idle, interruptions: interruptions, sessions: sessionRepo,
                       engine: engine, model: model)
    }

    private func poll(_ condition: @escaping () async -> Bool) async {
        var iterations = 0
        while await !condition(), iterations < 100_000 { await Task.yield(); iterations += 1 }
    }

    @Test("onAppear shows the ready state without starting; Play starts and runs to finish")
    func onAppearIsIdleThenPlayStarts() async throws {
        let h = try makeHarness()
        h.model.onAppear()
        #expect(h.idle.isDisabled)
        #expect(h.model.title == "Session")
        // Ready, not running: the control shows Play and the engine has not started.
        #expect(!h.model.display.isStarted)
        #expect(!h.model.display.isRunning)
        #expect(!h.engine.snapshot.started)

        h.model.playPause() // start
        await poll { h.engine.snapshot.started }
        #expect(h.model.display.isStarted)

        for _ in 0..<6 { h.fake.advanceAndTick(by: .seconds(1)) }
        await poll { h.model.display.isFinished }
        #expect(h.model.display.isFinished)
        #expect(!h.idle.isDisabled) // restored on finish
    }

    @Test("Play starts from idle, then toggles pause; reset returns to idle")
    func transportForwards() async throws {
        let h = try makeHarness(round: 60)
        h.model.onAppear()

        h.model.playPause() // idle → start
        await poll { h.engine.snapshot.phase == .round(index: 1) }

        h.model.playPause() // running → pause
        #expect(h.engine.snapshot.isPaused)

        h.model.reset()
        #expect(!h.idle.isDisabled)
        #expect(!h.engine.snapshot.started) // idle again — Play shows
    }

    @Test("Finishing a workout saves exactly one session")
    func savesSessionOnFinish() async throws {
        let h = try makeHarness(rounds: 1, round: 5)
        h.model.onAppear()
        h.model.playPause() // start
        for _ in 0..<6 { h.fake.advanceAndTick(by: .seconds(1)) }
        await poll { h.model.display.isFinished }
        await poll { (try? await h.sessions.all().count) == 1 }

        let saved = try await h.sessions.all()
        #expect(saved.count == 1)
        #expect(saved.first?.configurationName == "Session")
        #expect(saved.first?.roundsCompleted == 1)
        #expect(h.model.saveFailed == false)
    }

    @Test("Resetting before finishing saves nothing")
    func resetSavesNothing() async throws {
        let h = try makeHarness(round: 60)
        h.model.onAppear()
        h.model.playPause() // start
        await poll { h.engine.snapshot.phase == .round(index: 1) }
        h.model.reset()
        // Give any erroneous save a chance to run.
        for _ in 0..<50 { await Task.yield() }
        #expect(try await h.sessions.all().isEmpty)
    }

    @Test("A save failure sets saveFailed, and retry saves once the repo recovers")
    func saveFailureThenRetry() async throws {
        let failing = FailingSessionRepository(shouldFail: true)
        let h = try makeHarness(rounds: 1, round: 5, sessions: failing)
        h.model.onAppear()
        h.model.playPause() // start
        for _ in 0..<6 { h.fake.advanceAndTick(by: .seconds(1)) }
        await poll { h.model.saveFailed }
        #expect(h.model.saveFailed)

        await failing.stopFailing()
        h.model.retrySave()
        await poll { await failing.savedCount == 1 }
        #expect(await failing.savedCount == 1)
        #expect(!h.model.saveFailed)
    }

    @Test("An interruption pauses the workout and it resumes when the interruption ends")
    func interruptionPausesAndResumes() async throws {
        let h = try makeHarness(round: 60)
        h.model.onAppear()
        h.model.playPause() // start
        await poll { h.engine.snapshot.phase == .round(index: 1) && !h.engine.snapshot.isPaused }

        h.interruptions.send(.began)
        await poll { h.engine.snapshot.isPaused }
        #expect(h.engine.snapshot.isPaused)

        h.interruptions.send(.ended)
        await poll { !h.engine.snapshot.isPaused }
        #expect(!h.engine.snapshot.isPaused)
    }
}
