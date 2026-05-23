// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MoneyToday",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "MoneyToday", targets: ["MoneyToday"]),
        .executable(name: "MoneyTodayChecks", targets: ["MoneyTodayChecks"])
    ],
    targets: [
        .target(
            name: "MoneyTodayCore"
        ),
        .executableTarget(
            name: "MoneyToday",
            dependencies: ["MoneyTodayCore"],
            path: "Sources/MoneyTodayApp"
        ),
        .executableTarget(
            name: "MoneyTodayChecks",
            dependencies: ["MoneyTodayCore"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
