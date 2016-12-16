import PackageDescription

let package = Package(
    name: "GraphQLResponder",
    dependencies: [
        .Package(url: "https://github.com/GraphQLSwift/Graphiti.git", majorVersion: 0, minor: 2),
        .Package(url: "https://github.com/Zewo/HTTP.git", majorVersion: 0, minor: 14),
    ]
)
