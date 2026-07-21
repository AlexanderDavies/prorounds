import Testing
import Foundation
@testable import ProRoundsFeaturePerformance
import ProRoundsDataSessions
import ProRoundsFoundationUtilities

@MainActor
@Suite("PerformanceViewModel")
struct PerformanceViewModelTests {
    private func makeModel(seed: [Session]) async throws -> PerformanceViewModel {
        let repo = SwiftDataSessionRepository(modelContainer: try SessionStore.makeContainer(inMemory: true))
        for session in seed { try await repo.save(session) }
        return PerformanceViewModel(sessions: repo, calendar: MetricsFixture.calendar,
                                    now: { MetricsFixture.reference })
    }

    @Test("Load builds series and summary")
    func loads() async throws {
        let model = try await makeModel(seed: [
            MetricsFixture.session(.heavyBag, roundMinutes: 3, rounds: 12, daysAgo: 1)
        ])
        await model.load()
        #expect(model.isLoaded)
        #expect(!model.isEmpty)
        #expect(model.data.summary.activeMinutes == 36)
        #expect(model.visibleSeries.contains { $0.id == .type(.heavyBag) })
    }

    @Test("Empty when there are no sessions")
    func empty() async throws {
        let model = try await makeModel(seed: [])
        await model.load()
        #expect(model.isEmpty)
        #expect(model.data.isEmpty)
    }

    @Test("Changing range recomputes from the already-loaded sessions")
    func rangeRecomputes() async throws {
        let model = try await makeModel(seed: [
            MetricsFixture.session(.heavyBag, roundMinutes: 3, rounds: 10, daysAgo: 20) // in month, not week
        ])
        await model.load()
        #expect(model.range == .week)
        #expect(model.data.summary.sessionCount == 0) // nothing this week

        model.setRange(.month)
        #expect(model.data.summary.sessionCount == 1) // now included, no refetch
    }

    @Test("Toggling a legend series hides it from the visible series")
    func toggleHides() async throws {
        let model = try await makeModel(seed: [
            MetricsFixture.session(.heavyBag, roundMinutes: 3, rounds: 12, daysAgo: 1)
        ])
        await model.load()
        #expect(model.visibleSeries.contains { $0.id == .type(.heavyBag) })

        model.toggle(.type(.heavyBag))
        #expect(model.isHidden(.type(.heavyBag)))
        #expect(!model.visibleSeries.contains { $0.id == .type(.heavyBag) })

        model.toggle(.type(.heavyBag))
        #expect(model.visibleSeries.contains { $0.id == .type(.heavyBag) })
    }
}
