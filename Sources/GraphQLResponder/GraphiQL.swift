import Graphiti

// Current latest version of GraphiQL.
let graphiQLVersion = "0.7.1"

let escapeMapping: [Character: String] = [
    "\r": "\\r",
    "\n": "\\n",
    "\t": "\\t",
    "\\": "\\\\",
    "\"": "\\\"",

    "\u{2028}": "\\u2028",
    "\u{2029}": "\\u2029",

    "\r\n": "\\r\\n"
]

func escape(_ source: String) -> String {
    var string = "\""

    for character in source.characters {
        if let escapedSymbol = escapeMapping[character] {
            string.append(escapedSymbol)
        } else {
            string.append(character)
        }
    }

    string.append("\"")
    return string
}

// Ensures string values are safe to be used within a <script> tag.
func safeSerialize(_ data: String?) -> String {
    //return data ? JSON.stringify(data).replace(/\//g, '\\/') : null;
    guard let data = data else {
        return "null"
    }

    return escape(data)
}

/**
 * When GraphQLResponder receives a request which does not Accept JSON, but does
 * Accept HTML, it may present GraphiQL, the in-browser GraphQL explorer IDE.
 *
 * When shown, it will be pre-populated with the result of having executed the
 * requested query.
 */
func renderGraphiQL(
    query: String?,
    variables: [String: GraphQL.Map]?,
    operationName: String?,
    result: GraphQL.Map?
) -> String {
    let variablesString = variables.map({ GraphQL.Map.dictionary($0).description })
    let resultString = result.map({ $0.description })

    return "<!--" +
    "The request to this GraphQL server provided the header \"Accept: text/html\"\n" +
    "and as a result has been presented GraphiQL - an in-browser IDE for exploring GraphQL.\n" +
    "If you wish to receive JSON, provide the header \"Accept: application/json\" or\n" +
    "add \"&raw\" to the end of the URL within a browser.\n" +
    "-->\n" +
    "<!DOCTYPE html>\n" +
    "<html>\n" +
    "<head>\n" +
    "<meta charset=\"utf-8\" />\n" +
    "<title>GraphiQL</title>\n" +
    "<meta name=\"robots\" content=\"noindex\" />\n" +
    "<style>\n" +
    "html, body {\n" +
    "    height: 100%;\n" +
    "    margin: 0;\n" +
    "    overflow: hidden;\n" +
    "    width: 100%;\n" +
    "}\n" +
    "</style>\n" +
    "<link href=\"//cdn.jsdelivr.net/graphiql/\(graphiQLVersion)/graphiql.css\" rel=\"stylesheet\" />\n" +
    "    <script src=\"//cdn.jsdelivr.net/fetch/0.9.0/fetch.min.js\"></script>\n" +
    "<script src=\"//cdn.jsdelivr.net/react/15.0.0/react.min.js\"></script>\n" +
    "<script src=\"//cdn.jsdelivr.net/react/15.0.0/react-dom.min.js\"></script>\n" +
    "<script src=\"//cdn.jsdelivr.net/graphiql/\(graphiQLVersion)/graphiql.min.js\"></script>\n" +
    "</head>\n" +
    "<body>\n" +
    "<script>\n" +
    "// Collect the URL parameters\n" +
    "var parameters = {};\n" +
    "window.location.search.substr(1).split('&').forEach(function (entry) {\n" +
    "    var eq = entry.indexOf('=');\n" +
    "    if (eq >= 0) {\n" +
    "        parameters[decodeURIComponent(entry.slice(0, eq))] =\n" +
    "            decodeURIComponent(entry.slice(eq + 1));\n" +
    "    }\n" +
    "});\n" +
    "// Produce a Location query string from a parameter object.\n" +
    "function locationQuery(params) {\n" +
    "    return '?' + Object.keys(params).map(function (key) {\n" +
    "        return encodeURIComponent(key) + '=' +\n" +
    "            encodeURIComponent(params[key]);\n" +
    "    }).join('&');\n" +
    "}\n" +
    "// Derive a fetch URL from the current URL, sans the GraphQL parameters.\n" +
    "var graphqlParamNames = {\n" +
    "    query: true,\n" +
    "    variables: true,\n" +
    "    operationName: true\n" +
    "};\n" +
    "var otherParams = {};\n" +
    "for (var k in parameters) {\n" +
    "    if (parameters.hasOwnProperty(k) && graphqlParamNames[k] !== true) {\n" +
    "        otherParams[k] = parameters[k];\n" +
    "    }\n" +
    "}\n" +
    "var fetchURL = locationQuery(otherParams);\n" +
    "// Defines a GraphQL fetcher using the fetch API.\n" +
    "function graphQLFetcher(graphQLParams) {\n" +
    "    return fetch(fetchURL, {\n" +
    "        method: 'post',\n" +
    "        headers: {\n" +
    "            'Accept': 'application/json',\n" +
    "            'Content-Type': 'application/json'\n" +
    "        },\n" +
    "        body: JSON.stringify(graphQLParams),\n" +
    "        credentials: 'include',\n" +
    "    }).then(function (response) {\n" +
    "        return response.text();\n" +
    "    }).then(function (responseBody) {\n" +
    "        try {\n" +
    "        return JSON.parse(responseBody);\n" +
    "        } catch (error) {\n" +
    "        return responseBody;\n" +
    "        }\n" +
    "    });\n" +
    "}\n" +
    "// When the query and variables string is edited, update the URL bar so\n" +
    "// that it can be easily shared.\n" +
    "function onEditQuery(newQuery) {\n" +
    "    parameters.query = newQuery;\n" +
    "    updateURL();\n" +
    "}\n" +
    "function onEditVariables(newVariables) {\n" +
    "    parameters.variables = newVariables;\n" +
    "    updateURL();\n" +
    "}\n" +
    "function onEditOperationName(newOperationName) {\n" +
    "    parameters.operationName = newOperationName;\n" +
    "    updateURL();\n" +
    "}\n" +
    "function updateURL() {\n" +
    "    history.replaceState(null, null, locationQuery(parameters));\n" +
    "}\n" +
    "// Render <GraphiQL /> into the body.\n" +
    "ReactDOM.render(\n" +
    "    React.createElement(GraphiQL, {\n" +
    "        fetcher: graphQLFetcher,\n" +
    "        onEditQuery: onEditQuery,\n" +
    "        onEditVariables: onEditVariables,\n" +
    "        onEditOperationName: onEditOperationName,\n" +
    "        query: \(safeSerialize(query)),\n" +
    "        response: \(safeSerialize(resultString)),\n" +
    "        variables: \(safeSerialize(variablesString)),\n" +
    "        operationName: \(safeSerialize(operationName)),\n" +
    "    }),\n" +
    "    document.body\n" +
    ");\n" +
    "</script>\n" +
    "</body>\n" +
    "</html>\n"
}
