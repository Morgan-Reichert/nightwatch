// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NightwatchiOS",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "NightwatchiOS",
            targets: ["NightwatchiOS"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/supabase/supabase-swift.git",
            from: "2.0.0"
        )
    ],
    targets: [
        .target(
            name: "NightwatchiOS",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift")
            ],
            path: "NightwatchiOS"
        )
    ]
)
