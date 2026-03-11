import Foundation
import CheSvgMCPCore

do {
    let server = try await CheSvgMCPServer()
    try await server.run()
} catch {
    fputs("Error: \(error)\n", stderr)
    exit(1)
}
