import Testing
import Foundation
@testable import ProRoundsFoundationCoaching

@Suite("Coaching resource bundle")
struct CoachingBundleTests {
    @Test("the catalog ships inside the module bundle")
    func catalogIsBundled() throws {
        let url = try #require(CoachingBundle.resources.url(forResource: "phrases", withExtension: "json"))
        #expect(try Data(contentsOf: url).isEmpty == false)
    }

    @Test("both beginner scripts ship inside the module bundle", arguments: ["beginner_shadow", "beginner_bag"])
    func scriptsAreBundled(name: String) throws {
        #expect(CoachingBundle.resources.url(forResource: name, withExtension: "json") != nil)
    }
}

@Suite("Clip layout survives bundling")
struct ClipLayoutTests {
    /// `.process` would flatten these into one directory and silently drop half the forked
    /// clips — numbers/jab.m4a and names/jab.m4a share a filename. This is the regression test
    /// for that, and it is why the target uses `.copy` for `clips`.
    @Test("forked phrases keep a clip per convention", arguments: ["numbers", "names"])
    func forkedClipsAreAddressableByConvention(convention: String) throws {
        let url = CoachingBundle.resources.url(
            forResource: "jab", withExtension: "m4a", subdirectory: "clips/\(convention)")
        #expect(url != nil, "clips/\(convention)/jab.m4a missing from the bundle")
    }

    @Test("the three clip directories carry 26 / 26 / 63")
    func clipCounts() throws {
        let expected = ["numbers": 26, "names": 26, "shared": 63]
        for (dir, count) in expected {
            let urls = CoachingBundle.resources.urls(
                forResourcesWithExtension: "m4a", subdirectory: "clips/\(dir)")
            #expect(urls?.count == count, "clips/\(dir) had \(urls?.count ?? 0), expected \(count)")
        }
    }
}
