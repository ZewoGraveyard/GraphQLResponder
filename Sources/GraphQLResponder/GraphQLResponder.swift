@_exported import HTTP
import GraphQL
import Graphiti

public let noRootValue: Void = Void()

extension MediaType {
    public static var html: MediaType {
        return MediaType(type: "text", subtype: "html", parameters: ["charset": "utf-8"])
    }
}

public struct GraphQLResponder<Root, Context> : Responder {
    let schema: Schema<Root, Context>
    let graphiQL: Bool
    let rootValue: Root
    let context: Context?

    public init(
        schema: Schema<Root, Context>,
        graphiQL: Bool = false,
        rootValue: Root,
        context: Context? = nil
    ) {
        self.schema = schema
        self.graphiQL = graphiQL
        self.rootValue = rootValue
        self.context = context
    }

    public func respond(to request: Request) throws -> Response {
        var query: String? = nil
        var variables: [String: GraphQL.Map]? = nil
        var operationName: String? = nil
        var raw: Bool? = nil

        loop: for queryItem in request.url.queryItems {
            switch queryItem.name {
            case "query":
                query = queryItem.value
            case "variables":
                // TODO: parse variables as JSON
                break
            case "operationName":
                operationName = queryItem.value
            case "raw":
                raw = queryItem.value.flatMap({ Bool($0) })
            default:
                continue loop
            }
        }

        // Get data from ContentNegotiationMiddleware

        if query == nil {
            query = request.content?["query"].string
        }

        if variables == nil {
            if let vars = request.content?["variables"].dictionary {
                var newVariables: [String: GraphQL.Map] = [:]

                for (key, value) in vars {
                    newVariables[key] = convert(map: value)
                }

                variables = newVariables
            }
        }

        if operationName == nil {
            operationName = request.content?["operationName"].string
        }

        if raw == nil {
            raw = request.content?["raw"].bool
        }

        // TODO: Parse the body from Content-Type

        let showGraphiql = graphiQL && !(raw ?? false) && request.accept.matches(other: .html)

        if !showGraphiql {
            guard let graphQLQuery = query else {
                throw HTTPError.badRequest(body: "Must provide query string.")
            }

            let result: GraphQL.Map

            if Context.self is Request.Type && context == nil {
                result = try schema.execute(
                    request: graphQLQuery,
                    rootValue: rootValue,
                    context: request as! Context,
                    variables: variables ?? [:],
                    operationName: operationName
                )
            } else if let context = context {
                result = try schema.execute(
                    request: graphQLQuery,
                    rootValue: rootValue,
                    context: context,
                    variables: variables ?? [:],
                    operationName: operationName
                )
            } else {
                result = try schema.execute(
                    request: graphQLQuery,
                    rootValue: rootValue,
                    variables: variables ?? [:],
                    operationName: operationName
                )
            }

            return Response(content: convert(map: result))
        } else {
            var result: GraphQL.Map? = nil

            if let graphQLQuery = query {
                if Context.self is Request.Type && context == nil {
                    result = try schema.execute(
                        request: graphQLQuery,
                        rootValue: rootValue,
                        context: request as! Context,
                        variables: variables ?? [:],
                        operationName: operationName
                    )
                } else if let context = context {
                    result = try schema.execute(
                        request: graphQLQuery,
                        rootValue: rootValue,
                        context: context,
                        variables: variables ?? [:],
                        operationName: operationName
                    )
                } else {
                    result = try schema.execute(
                        request: graphQLQuery,
                        rootValue: rootValue,
                        variables: variables ?? [:],
                        operationName: operationName
                    )
                }
            }

            let html = renderGraphiQL(
                query: query,
                variables: variables,
                operationName: operationName,
                result: result
            )

            // TODO: Add an initializer that takes body and contentType to HTTP
            var response = Response(body: html)
            response.contentType = .html
            return response
        }
    }
}

func convert(map: Axis.Map) -> GraphQL.Map {
    switch map {
    case .null:
        return .null
    case .bool(let bool):
        return .bool(bool)
    case .double(let double):
        return .double(double)
    case .int(let int):
        return .int(int)
    case .string(let string):
        return .string(string)
    case .array(let array):
        return .array(array.map({ convert(map: $0) }))
    case .dictionary(let dictionary):
        var dict: [String: GraphQL.Map] = [:]

        for (key, value) in dictionary {
            dict[key] = convert(map: value)
        }

        return .dictionary(dict)
    default:
        return .null
    }
}

func convert(map: GraphQL.Map) -> Axis.Map {
    switch map {
    case .null:
        return .null
    case .bool(let bool):
        return .bool(bool)
    case .double(let double):
        return .double(double)
    case .int(let int):
        return .int(int)
    case .string(let string):
        return .string(string)
    case .array(let array):
        return .array(array.map({ convert(map: $0) }))
    case .dictionary(let dictionary):
        var dict: [String: Axis.Map] = [:]
        
        for (key, value) in dictionary {
            dict[key] = convert(map: value)
        }
        
        return .dictionary(dict)
    }
}
