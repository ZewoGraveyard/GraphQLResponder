import XCTest
import Graphiti
@testable import GraphQLResponder

let schema = try! Schema<Void> { schema in
    schema.query = try ObjectType(name: "RootQueryType") { query in
        try query.field(name: "hello", type: String.self) { _ in
            "world"
        }
    }
}

let graphql = GraphQLResponder(schema: schema, rootValue: noRootValue)

class GraphQLResponderTests: XCTestCase {
    func testHello() throws {
        let query: Axis.Map = [
            "query": "{ hello }"
        ]

        let expected: Axis.Map = [
            "data": [
                "hello": "world"
            ]
        ]

        let request = Request(content: query)
        let response = try graphql.respond(to: request)
        XCTAssertEqual(response.content, expected)
    }

    func testBoyhowdy() throws {
        let query: Axis.Map = [
            "query": "{ boyhowdy }"
        ]

        let expected: Axis.Map = [
            "errors": [
                [
                    "message": "Cannot query field \"boyhowdy\" on type \"RootQueryType\".",
                    "locations": [["line": 1, "column": 3]]
                ]
            ]
        ]

        let request = Request(content: query)
        let response = try graphql.respond(to: request)
        XCTAssertEqual(response.content, expected)
    }

    static var allTests : [(String, (GraphQLResponderTests) -> () throws -> Void)] {
        return [
            ("testHello", testHello),
            ("testBoyhowdy", testBoyhowdy),
        ]
    }
}
