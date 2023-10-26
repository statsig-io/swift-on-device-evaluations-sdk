// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "Statsig",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "Statsig",
            targets: [
                "Statsig",
            ]),
    ],
    dependencies: [
        .package(url: "https://github.com/AliSoftware/OHHTTPStubs.git", from: "9.1.0"),
        .package(url: "https://github.com/Quick/Quick.git", from: "7.3.0"),
        .package(url: "https://github.com/Quick/Nimble.git", from: "13.0.0")
    ],
    targets: [
        .target(
            name: "Statsig",
            dependencies: ["StatsigInternalObjC"]),

        .target(
            name: "StatsigInternalObjC",
            dependencies: []),


        // Unit Tests
//        .target(
//            name: "StatsigTestUtils",
//            dependencies: [
//                "OHHTTPStubs",
//                .product(name: "OHHTTPStubsSwift", package: "OHHTTPStubs")
//            ],
//            path: "Tests/TestUtils",
//            resources:[
//                .process("Resources")
//            ]),
//        .testTarget(
//            name: "StatsigOnDeviceEvaluationsTestsSwift",
//            dependencies: [
//                "StatsigOnDeviceEvaluations",
//                "StatsigTestUtils",
//                "Quick",
//                "Nimble"
//            ]
//        ),
//        .testTarget(
//            name: "StatsigOnDeviceEvaluationsTestsObjC",
//            dependencies: [
//                "StatsigOnDeviceEvaluations",
//                "StatsigTestUtils",
//                "Nimble"
//            ]
//        ),
//        .testTarget(
//            name: "StatsigPrecomputedEvaluationsTestsSwift",
//            dependencies: [
//                "StatsigPrecomputedEvaluations",
//                "Quick",
//                "Nimble",
//                "OHHTTPStubs",
//                .product(name: "OHHTTPStubsSwift", package: "OHHTTPStubs")
//            ]
//        ),
//        .testTarget(
//            name: "StatsigPrecomputedEvaluationsTestsObjC",
//            dependencies: [
//                "StatsigPrecomputedEvaluations",
//                "Quick",
//                "Nimble",
//                "OHHTTPStubs",
//                .product(name: "OHHTTPStubsSwift", package: "OHHTTPStubs")
//            ],
//            resources:[
//                .process("Resources")
//            ]
//        )
    ]
)
