// swift-tools-version: 6.0
import PackageDescription

// ProRounds module graph — a single package declaring the layered modules of
// docs/ARCHITECTURE_GUIDE.md §2.1. Target-level dependencies compile-enforce the
// layering direction: Foundation ← Data ← Feature, with DesignSystem available to
// Data/Feature. A target that imports a module it does not list as a dependency
// fails to compile — and no Feature target may depend on a sibling Feature.
//
// Most modules are empty placeholders this change; they are fleshed out by later
// OpenSpec changes. FoundationTiming and FoundationUtilities carry real code now
// because the next change (the RoundTimerEngine) is written test-first against them.

let package = Package(
    name: "ProRoundsModules",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        // Foundation
        .library(name: "ProRoundsFoundationUtilities", targets: ["ProRoundsFoundationUtilities"]),
        .library(name: "ProRoundsFoundationDiagnostics", targets: ["ProRoundsFoundationDiagnostics"]),
        .library(name: "ProRoundsFoundationTiming", targets: ["ProRoundsFoundationTiming"]),
        .library(name: "ProRoundsFoundationAudio", targets: ["ProRoundsFoundationAudio"]),
        .library(name: "ProRoundsFoundationPersistence", targets: ["ProRoundsFoundationPersistence"]),
        .library(name: "ProRoundsFoundationCoaching", targets: ["ProRoundsFoundationCoaching"]),
        // Design system
        .library(name: "ProRoundsDesignSystem", targets: ["ProRoundsDesignSystem"]),
        // Data
        .library(name: "ProRoundsDataConfig", targets: ["ProRoundsDataConfig"]),
        .library(name: "ProRoundsDataSessions", targets: ["ProRoundsDataSessions"]),
        .library(name: "ProRoundsDataSettings", targets: ["ProRoundsDataSettings"]),
        // Feature
        .library(name: "ProRoundsFeatureTimer", targets: ["ProRoundsFeatureTimer"]),
        .library(name: "ProRoundsFeatureConfig", targets: ["ProRoundsFeatureConfig"]),
        .library(name: "ProRoundsFeaturePerformance", targets: ["ProRoundsFeaturePerformance"]),
        .library(name: "ProRoundsFeatureSettings", targets: ["ProRoundsFeatureSettings"]),
    ],
    dependencies: [
        // Test-only. Used solely by the design-system snapshot tests; never linked into the app.
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.17.0"),
    ],
    targets: [
        // MARK: - Foundation (no upward dependencies)
        .target(name: "ProRoundsFoundationUtilities"),
        .target(name: "ProRoundsFoundationDiagnostics"),
        .target(name: "ProRoundsFoundationTiming"),
        .target(name: "ProRoundsFoundationAudio", resources: [.process("Resources")]),
        .target(name: "ProRoundsFoundationPersistence"),
        // Catalog + cue scheduler for assisted coaching. Pure: no audio, no UI, no clock —
        // it is an output of the round timer, never an input to it.
        // `.copy` for the clips, not `.process`: processing FLATTENS the tree, and the 26 forked
        // phrases share a filename across numbers/ and names/ (jab.m4a exists in both). Copying
        // preserves the clips/<convention>/<id>.m4a layout docs/coaching/README.md defines.
        .target(name: "ProRoundsFoundationCoaching", dependencies: [
            "ProRoundsFoundationTiming",
            "ProRoundsFoundationUtilities",
        ], resources: [
            .process("Resources/phrases.json"),
            .process("Resources/beginner_shadow.json"),
            .process("Resources/beginner_bag.json"),
            .copy("Resources/clips"),
        ]),

        // MARK: - Design system (may use Foundation)
        .target(name: "ProRoundsDesignSystem", dependencies: [
            "ProRoundsFoundationUtilities",
        ]),

        // MARK: - Data (may reach Foundation, not Feature)
        .target(name: "ProRoundsDataConfig", dependencies: [
            "ProRoundsFoundationPersistence",
            "ProRoundsFoundationUtilities",
        ]),
        .target(name: "ProRoundsDataSessions", dependencies: [
            "ProRoundsFoundationPersistence",
            "ProRoundsFoundationUtilities",
        ]),
        .target(name: "ProRoundsDataSettings", dependencies: [
            "ProRoundsFoundationAudio",
            "ProRoundsFoundationUtilities",
        ]),

        // MARK: - Feature (may reach Data / Foundation / DesignSystem; never a sibling Feature)
        .target(name: "ProRoundsFeatureTimer", dependencies: [
            "ProRoundsDataConfig",
            "ProRoundsDataSessions",
            "ProRoundsFoundationTiming",
            "ProRoundsFoundationAudio",
            "ProRoundsDesignSystem",
        ]),
        .target(name: "ProRoundsFeatureConfig", dependencies: [
            "ProRoundsDataConfig",
            "ProRoundsFoundationUtilities",
            "ProRoundsDesignSystem",
        ]),
        .target(name: "ProRoundsFeaturePerformance", dependencies: [
            "ProRoundsDataSessions",
            "ProRoundsDesignSystem",
            "ProRoundsFoundationUtilities",
        ]),
        .target(name: "ProRoundsFeatureSettings", dependencies: [
            "ProRoundsDataSettings",
            "ProRoundsDesignSystem",
            "ProRoundsFoundationAudio",
            "ProRoundsFoundationUtilities",
        ]),

        // MARK: - Tests (for modules with real code)
        .testTarget(name: "ProRoundsFoundationTimingTests", dependencies: [
            "ProRoundsFoundationTiming",
        ]),
        .testTarget(name: "ProRoundsFoundationUtilitiesTests", dependencies: [
            "ProRoundsFoundationUtilities",
        ]),
        .testTarget(name: "ProRoundsFoundationAudioTests", dependencies: [
            "ProRoundsFoundationAudio",
        ]),
        .testTarget(name: "ProRoundsFoundationPersistenceTests", dependencies: [
            "ProRoundsFoundationPersistence",
        ]),
        // `.copy`, not `.process`, for the same reason as the target above: Fixtures/schedules/
        // is nested, and processing would flatten it into the bundle root.
        .testTarget(name: "ProRoundsFoundationCoachingTests", dependencies: [
            "ProRoundsFoundationCoaching",
        ], resources: [.copy("Fixtures")]),
        .testTarget(name: "ProRoundsDataConfigTests", dependencies: [
            "ProRoundsDataConfig",
        ]),
        .testTarget(name: "ProRoundsDataSessionsTests", dependencies: [
            "ProRoundsDataSessions",
        ]),
        .testTarget(name: "ProRoundsFeatureTimerTests", dependencies: [
            "ProRoundsFeatureTimer",
            "ProRoundsDataConfig",
            "ProRoundsDataSessions",
            "ProRoundsFoundationTiming",
            "ProRoundsFoundationAudio",
            .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
        ], exclude: ["__Snapshots__"]),
        .testTarget(name: "ProRoundsFeatureConfigTests", dependencies: [
            "ProRoundsFeatureConfig",
            "ProRoundsDataConfig",
            .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
        ], exclude: ["__Snapshots__"]),
        .testTarget(name: "ProRoundsFeaturePerformanceTests", dependencies: [
            "ProRoundsFeaturePerformance",
            "ProRoundsDataSessions",
            .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
        ], exclude: ["__Snapshots__"]),
        .testTarget(name: "ProRoundsDataSettingsTests", dependencies: [
            "ProRoundsDataSettings",
        ]),
        .testTarget(name: "ProRoundsFeatureSettingsTests", dependencies: [
            "ProRoundsFeatureSettings",
            "ProRoundsFoundationAudio",
            .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
        ], exclude: ["__Snapshots__"]),
        .testTarget(name: "ProRoundsDesignSystemTests", dependencies: [
            "ProRoundsDesignSystem",
            .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
        ], exclude: ["__Snapshots__"]),
    ]
)
