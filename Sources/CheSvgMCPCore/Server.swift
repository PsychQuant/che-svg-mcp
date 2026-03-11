import Foundation
import MCP

public class CheSvgMCPServer {
    private let server: Server
    private let transport: StdioTransport
    private let tools: [Tool]

    public init() async throws {
        tools = Self.defineTools()

        server = Server(
            name: "che-svg-mcp",
            version: "0.1.0",
            capabilities: .init(tools: .init())
        )

        transport = StdioTransport()
        await registerHandlers()
    }

    public func run() async throws {
        try await server.start(transport: transport)
        await server.waitUntilCompleted()
    }

    // MARK: - Tool Definitions

    private static func defineTools() -> [Tool] {
        [
            Tool(
                name: "hello_world",
                description: "A simple hello world tool",
                inputSchema: .object([
                    "type": .string("object"),
                    "properties": .object([
                        "name": .object([
                            "type": .string("string"),
                            "description": .string("Name to greet")
                        ])
                    ]),
                    "required": .array([])
                ])
            )
        ]
    }

    // MARK: - Handler Registration

    private func registerHandlers() async {
        await server.withMethodHandler(ListTools.self) { _ in
            ListTools.Result(tools: self.tools)
        }

        await server.withMethodHandler(CallTool.self) { params in
            try await self.handleToolCall(params)
        }
    }

    private func handleToolCall(_ params: CallTool.Request) async throws -> CallTool.Result {
        switch params.name {
        case "hello_world":
            let name = (params.arguments?["name"] as? String) ?? "World"
            return CallTool.Result(
                content: [.text("Hello, \(name)!")],
                isError: false
            )
        default:
            return CallTool.Result(
                content: [.text("Unknown tool: \(params.name)")],
                isError: true
            )
        }
    }
}
