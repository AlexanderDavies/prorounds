import Testing
import Foundation
import ProRoundsDataConfig
import ProRoundsFoundationUtilities
@testable import ProRoundsFeatureConfig

@Suite("Coaching badge on the list row")
struct CoachingRowDisplayTests {
    private func make(_ level: CoachingLevel?) -> Configuration {
        Configuration(workoutType: .shadowBoxing, rounds: 12, roundDuration: .seconds(180),
                      restDuration: .seconds(60), prepDuration: .seconds(20),
                      warningLead: .seconds(10), coachingLevel: level)
    }

    @Test("a coached row carries the level's name")
    func coachedRowIsBadged() {
        #expect(ConfigDisplayMapper.row(make(.beginner)).coachingBadge == "Beginner")
    }

    @Test("an uncoached row has no badge")
    func uncoachedRowHasNone() {
        #expect(ConfigDisplayMapper.row(make(nil)).coachingBadge == nil)
    }

    /// The badge names the level rather than merely marking the row as coached, so a second level
    /// is a new string rather than a redesign.
    @Test("the badge is the level name, not a generic marker")
    func badgeNamesTheLevel() {
        let badge = ConfigDisplayMapper.row(make(.beginner)).coachingBadge
        #expect(badge == CoachingLevel.beginner.displayName)
    }

    @Test("coaching does not disturb the rest of the row")
    func restOfRowUnchanged() {
        let coached = ConfigDisplayMapper.row(make(.beginner))
        let plain = ConfigDisplayMapper.row(make(nil))
        #expect(coached.name == plain.name)
        #expect(coached.metadata == plain.metadata)
        #expect(coached.totalText == plain.totalText)
        #expect(coached.iconSystemName == plain.iconSystemName)
    }
}
