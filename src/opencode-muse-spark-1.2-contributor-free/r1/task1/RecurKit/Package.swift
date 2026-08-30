// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "RecurKit",
    products: [
        .library(name: "RecurKit", targets: ["RecurKit"]),
        .executable(name: "RecurKitChecks", targets: ["RecurKitChecks"]),
    ],
    targets: [
        .target(name: "RecurKit"),
        // The check suite is a plain executable on purpose: it runs on a
        // bare Swift toolchain (Command Line Tools included) with no
        // XCTest/Testing framework runtime, everywhere, sandboxed or not.
        .executableTarget(
            name: "RecurKitChecks",
            dependencies: ["RecurKit"],
            // Language mode 5: the harness keeps plain global check
            // arrays; strict-concurrency guarantees add nothing to a
            // sequential check runner.
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
