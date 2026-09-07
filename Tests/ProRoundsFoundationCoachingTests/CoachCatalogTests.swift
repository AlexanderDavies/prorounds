import Testing
import Foundation
@testable import ProRoundsFoundationCoaching

@Suite("Phrase catalog decoding")
struct CoachCatalogTests {
    @Test("the bundled catalog decodes to 89 phrases")
    func decodesEveryPhrase() throws {
        let catalog = try CoachCatalog.bundled()
        #expect(catalog.phrases.count == 89)
        #expect(catalog.order.count == 89)
    }

    @Test("kind counts match the authored catalog")
    func kindCounts() throws {
        let catalog = try CoachCatalog.bundled()
        let counts = Dictionary(grouping: catalog.order.compactMap { catalog[$0] }, by: \.kind)
            .mapValues(\.count)
        #expect(counts[.technique] == 35)
        #expect(counts[.combo] == 21)
        #expect(counts[.defence] == 16)
        #expect(counts[.movement] == 10)
        #expect(counts[.effort] == 7)
    }

    @Test("a forked phrase carries both conventions")
    func forkedText() throws {
        let jab = try #require(try CoachCatalog.bundled()["jab"])
        #expect(jab.clip == .forked)
        #expect(jab.text.spoken(.numbers) == "One")
        #expect(jab.text.spoken(.names) == "Jab")
    }

    @Test("a shared phrase reads the same under either convention")
    func sharedText() throws {
        let work = try #require(try CoachCatalog.bundled()["effort_work"])
        #expect(work.clip == .shared)
        #expect(work.text.spoken(.numbers) == "Work!")
        #expect(work.text.spoken(.names) == "Work!")
    }

    /// Holds for all 89 phrases in the authored catalog, so it is encoded in the types rather than
    /// left as a coincidence: a shared clip always has plain text and a single ticker line, a
    /// forked clip always has per-convention text and a punch ticker.
    @Test("clip kind, text shape and ticker shape agree for every phrase")
    func shapesAgree() throws {
        let catalog = try CoachCatalog.bundled()
        for id in catalog.order {
            let phrase = try #require(catalog[id])
            switch (phrase.clip, phrase.text, phrase.ticker) {
            case (.shared, .shared, .line), (.forked, .forked, .punches):
                break
            default:
                Issue.record("\(id): clip \(phrase.clip) disagrees with its text or ticker shape")
            }
        }
    }

    @Test("optional fields decode when present and default when absent")
    func optionalFields() throws {
        let catalog = try CoachCatalog.bundled()
        let follows = try #require(catalog["tech_lazy_hand"])
        #expect(follows.follows == ["jab"])
        let plain = try #require(catalog["tech_chin_down"])
        #expect(plain.follows.isEmpty)
        let windowed = try #require(catalog["effort_last_ten"])
        #expect(windowed.windowFromRoundEndMs == 8000...12000)
        #expect(plain.windowFromRoundEndMs == nil)
    }

    @Test("estMs is the measured duration, not the old hand estimate")
    func measuredDurations() throws {
        let catalog = try CoachCatalog.bundled()
        for id in catalog.order {
            let phrase = try #require(catalog[id])
            #expect(phrase.estMs > 0, "\(id) has no duration")
            #expect(phrase.estMs < 6000, "\(id) is implausibly long at \(phrase.estMs)ms")
        }
    }

    @Test("an unknown kind is rejected rather than defaulted")
    func unknownKindThrows() throws {
        let json = Data("""
        {"version":1,"level":"beginner","phrases":[
          {"id":"x","kind":"heckling","clip":"shared","tags":[],"estMs":500,
           "text":"hi","ticker":{"line":"hi"}}]}
        """.utf8)
        #expect(throws: (any Error).self) { try CoachCatalog(data: json) }
    }

    @Test("malformed JSON throws rather than yielding an empty catalog")
    func malformedThrows() {
        #expect(throws: (any Error).self) { try CoachCatalog(data: Data("{ not json".utf8)) }
    }
}

@Suite("Clip resolution")
struct ClipResolutionTests {
    @Test("a forked phrase resolves per convention", arguments: [NamingConvention.numbers, .names])
    func forkedResolvesPerConvention(convention: NamingConvention) throws {
        let jab = try #require(try CoachCatalog.bundled()["jab"])
        let url = try #require(jab.clipURL(for: convention, in: CoachingBundle.resources))
        #expect(url.deletingLastPathComponent().lastPathComponent == convention.rawValue)
        #expect(url.lastPathComponent == "jab.m4a")
    }

    @Test("a shared phrase ignores the convention")
    func sharedIgnoresConvention() throws {
        let work = try #require(try CoachCatalog.bundled()["effort_work"])
        let byNumbers = try #require(work.clipURL(for: .numbers, in: CoachingBundle.resources))
        let byNames = try #require(work.clipURL(for: .names, in: CoachingBundle.resources))
        #expect(byNumbers == byNames)
        #expect(byNumbers.deletingLastPathComponent().lastPathComponent == "shared")
    }

    @Test("every phrase in the catalog resolves to a real clip")
    func everyPhraseHasClips() throws {
        let catalog = try CoachCatalog.bundled()
        for id in catalog.order {
            let phrase = try #require(catalog[id])
            for convention in [NamingConvention.numbers, .names] {
                let url = phrase.clipURL(for: convention, in: CoachingBundle.resources)
                #expect(url != nil, "\(id) has no clip for \(convention.rawValue)")
            }
        }
    }
}

@Suite("Ticker rendering")
struct CoachTickerTests {
    /// The running screen's dual-convention ticker (UX brief, Decision 3). Nothing in this change
    /// renders it, but the accessors are public API here, so they are covered here rather than
    /// shipped untested into change 3.
    @Test("a shared phrase renders one line under either convention")
    func sharedTicker() throws {
        let phrase = try #require(try CoachCatalog.bundled()["effort_work"])
        #expect(phrase.ticker.primary(.numbers) == "Work!")
        #expect(phrase.ticker.primary(.names) == "Work!")
        #expect(phrase.ticker.modifier == nil)
    }

    @Test("a forked phrase renders per convention")
    func forkedTicker() throws {
        let phrase = try #require(try CoachCatalog.bundled()["jab_cross"])
        #expect(phrase.ticker.primary(.numbers) == "1 · 2")
        #expect(phrase.ticker.primary(.names) == "Jab Cross")
        #expect(phrase.ticker.modifier == nil)
    }

    /// The modifier is carried separately so the view can set it apart from the punch numbers —
    /// "1 · 2" large, "to the body" beneath it.
    @Test("a modifier is exposed separately from the punches")
    func tickerModifier() throws {
        let phrase = try #require(try CoachCatalog.bundled()["jab_cross_body"])
        #expect(phrase.ticker.primary(.numbers) == "1 · 2")
        #expect(phrase.ticker.modifier == "to the body")
    }

    @Test("exactly the 15 authored phrases carry a modifier")
    func modifierCount() throws {
        let catalog = try CoachCatalog.bundled()
        let withModifier = catalog.order.compactMap { catalog[$0] }.filter { $0.ticker.modifier != nil }
        #expect(withModifier.count == 15)
        #expect(withModifier.allSatisfy { $0.clip == .forked })
    }

    @Test("every phrase renders a non-empty ticker under both conventions")
    func tickerAlwaysRenders() throws {
        let catalog = try CoachCatalog.bundled()
        for id in catalog.order {
            let phrase = try #require(catalog[id])
            for convention in NamingConvention.allCases {
                #expect(!phrase.ticker.primary(convention).isEmpty, "\(id) has an empty ticker")
            }
        }
    }
}
