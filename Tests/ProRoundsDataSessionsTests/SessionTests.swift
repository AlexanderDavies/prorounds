import Testing
import Foundation
@testable import ProRoundsDataSessions
import ProRoundsFoundationUtilities

enum SessionFixture {
    static func make(
        type: WorkoutType = .heavyBag,
        name: String = "Heavy Bag Blast",
        rounds: Int = 12,
        round: Duration = .seconds(180),
        rest: Duration = .seconds(60),
        prep: Duration = .seconds(10),
        completed: Int = 12,
        total: Duration = .seconds(2830),
        date: Date = .now,
        id: UUID = UUID()
    ) -> Session {
        Session(id: id, date: date, workoutType: type, configurationName: name, rounds: rounds,
                roundDuration: round, restDuration: rest, prepDuration: prep,
                roundsCompleted: completed, totalDuration: total)
    }
}

@Suite("Session")
struct SessionTests {
    @Test("Captures the workout's key details")
    func captures() {
        let session = SessionFixture.make()
        #expect(session.workoutType == .heavyBag)
        #expect(session.configurationName == "Heavy Bag Blast")
        #expect(session.roundsCompleted == 12)
        #expect(session.totalDuration == .seconds(2830))
    }

    @Test("Active duration is the sum of round time, excluding rest and prep")
    func activeDuration() {
        // 12 rounds × 3:00 = 36:00, regardless of the 1:00 rest / 0:10 prep.
        #expect(SessionFixture.make().activeDuration == .seconds(12 * 180))
    }
}
