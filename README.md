# GraphQLResponder

[![Swift][swift-badge]][swift-url]
[![License][mit-badge]][mit-url]
[![Slack][slack-badge]][slack-url]
[![Travis][travis-badge]][travis-url]
[![Codecov][codecov-badge]][codecov-url]
[![Codebeat][codebeat-badge]][codebeat-url]

## Installation

```swift
import PackageDescription

let package = Package(
    dependencies: [
        .Package(url: "https://github.com/Zewo/GraphQLResponder.git", majorVersion: 0, minor: 14),
    ]
)
```

## Usage

### Configuration

`GraphQLResponder` has the following parameters:

- **`schema`**: A `Schema` instance from [`Graphiti`](https://github.com/GraphQLSwift/Graphiti). A `Schema` *must* be provided.
- **`graphiQL `**: If `true`, presents [GraphiQL](https://github.com/graphql/graphiql) when the GraphQL endpoint is loaded in a browser. We recommend that you set `graphiql` to `true` when your app is in development because it's quite useful. You may or may not want it in production.
- **`rootValue`**: A value to pass as the `rootValue` to the schema's `execute` function from [`Graphiti`](https://github.com/GraphQLSwift/Graphiti).
- **`contextValue`**: A value to pass as the `contextValue` to the schema's `execute` function from [`Graphiti`](https://github.com/GraphQLSwift/Graphiti). If `context` is not provided, the `request` struct is passed as the context.

### Request Parameters

Once installed as a reponder, `GraphQLResponder` will accept requests with the parameters:

- **`query`**: A string GraphQL document to be executed.
- **`operationName`**: If the provided query contains multiple named operations, this specifies which operation should be executed. If not provided, a 400 error will be returned if the query contains multiple named operations.
- **`variables`**: The runtime values to use for any GraphQL query variables as a JSON object. (Currently not supported in the URL's query-string)
- **`raw`**: If the `graphiql` option is enabled and the raw parameter is provided raw JSON will always be returned instead of GraphiQL even when loaded from a browser.

`GraphQLResponder` will first look for each parameter in the URL's query-string:

```
/graphql?query=query+getUser($id:ID){user(id:$id){name}}&variables={"id":"4"}
```
If not found in the query-string, it will look in the POST request body. This requires a `ContentNegotiationMiddleware` to be mounted in the responder chain.

### Example

Example using [HTTPServer](https://github.com/Zewo/HTTPServer).

```swift
import HTTPServer
import Graphiti
import GraphQLResponder

let schema = try Schema<Void> { schema in
    schema.query = try ObjectType(name: "RootQueryType") { query in
        try query.field(
            name: "hello",
            type: String.self,
            description: "Cliche or classic?"
            resolve: { (_, _, _, _) in
                return "world"
            }
        )
    }
}

let graphql = GraphQLResponder(schema: schema, graphiQL: true, rootValue: noRootValue)

let router = BasicRouter { route in
    route.add(methods: [.get, .post], path: "/graphql", responder: graphql)
}

let contentNegotiation = ContentNegotiationMiddleware(mediaTypes: [.json])
let server = try Server(port: 8080, middleware: [contentNegotiation], responder: router)
try server.start()
```

## Support

If you need any help you can join our [Slack](http://slack.zewo.io) and go to the **#help** channel. Or you can create a Github [issue](https://github.com/Zewo/Zewo/issues/new) in our main repository. When stating your issue be sure to add enough details, specify what module is causing the problem and reproduction steps.

## Community

[![Slack][slack-image]][slack-url]

The entire Zewo code base is licensed under MIT. By contributing to Zewo you are contributing to an open and engaged community of brilliant Swift programmers. Join us on [Slack](http://slack.zewo.io) to get to know us!

## License

This project is released under the MIT license. See [LICENSE](LICENSE) for details.

[swift-badge]: https://img.shields.io/badge/Swift-3.0-orange.svg?style=flat
[swift-url]: https://swift.org
[mit-badge]: https://img.shields.io/badge/License-MIT-blue.svg?style=flat
[mit-url]: https://tldrlegal.com/license/mit-license
[slack-image]: http://s13.postimg.org/ybwy92ktf/Slack.png
[slack-badge]: https://zewo-slackin.herokuapp.com/badge.svg
[slack-url]: http://slack.zewo.io
[travis-badge]: https://travis-ci.org/Zewo/GraphQLResponder.svg?branch=master
[travis-url]: https://travis-ci.org/Zewo/GraphQLResponder
[codecov-badge]: https://codecov.io/gh/Zewo/GraphQLResponder/branch/master/graph/badge.svg
[codecov-url]: https://codecov.io/gh/Zewo/GraphQLResponder
[codebeat-badge]: https://codebeat.co/badges/97fc8ffa-eff3-495f-b61d-b3c5d29f2280
[codebeat-url]: https://codebeat.co/projects/github-com-zewo-graphqlresponder
