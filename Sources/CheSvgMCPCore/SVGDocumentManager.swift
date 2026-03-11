import Foundation

public class SVGDocumentManager {
    private var documents: [String: SVGDocument] = [:]
    private var originalPaths: [String: String] = [:]
    private var nextDocNum: Int = 1

    public init() {}

    // MARK: - Create

    public func createDocument(width: Double, height: Double, viewBox: String? = nil,
                               docId: String? = nil) -> (id: String, doc: SVGDocument) {
        let doc = SVGDocument(width: width, height: height, viewBox: viewBox)
        let id = docId ?? generateDocId()
        documents[id] = doc
        return (id, doc)
    }

    // MARK: - Open

    public func openDocument(path: String, docId: String? = nil) throws -> (id: String, doc: SVGDocument) {
        let url = URL(fileURLWithPath: path)
        let doc = try SVGDocument(contentsOf: url)
        let id = docId ?? generateDocId()
        documents[id] = doc
        originalPaths[id] = path
        return (id, doc)
    }

    // MARK: - Save

    public func saveDocument(docId: String, path: String?) throws {
        guard let doc = documents[docId] else {
            throw SVGError.documentNotFound(docId)
        }
        let savePath = path ?? originalPaths[docId]
        guard let finalPath = savePath else {
            throw SVGError.noSavePath
        }
        let url = URL(fileURLWithPath: finalPath)
        try doc.save(to: url)
        originalPaths[docId] = finalPath
    }

    // MARK: - Close

    public func closeDocument(docId: String) -> Bool {
        documents.removeValue(forKey: docId) != nil
    }

    // MARK: - Get

    public func getDocument(_ docId: String) -> SVGDocument? {
        documents[docId]
    }

    // MARK: - List

    public func listDocuments() -> [(id: String, path: String?, dirty: Bool, elementCount: Int)] {
        documents.map { (id, doc) in
            let info = doc.getSVGInfo()
            let count = Int(info["_element_count"] ?? "0") ?? 0
            return (id: id, path: originalPaths[id], dirty: doc.isDirty, elementCount: count)
        }.sorted { $0.id < $1.id }
    }

    // MARK: - Helpers

    private func generateDocId() -> String {
        let id = "svg\(nextDocNum)"
        nextDocNum += 1
        return id
    }
}

// MARK: - Errors

public enum SVGError: LocalizedError {
    case documentNotFound(String)
    case elementNotFound(String)
    case noSavePath
    case invalidArgument(String)
    case exportFailed(String)

    public var errorDescription: String? {
        switch self {
        case .documentNotFound(let id): return "Document not found: \(id)"
        case .elementNotFound(let id): return "Element not found: \(id)"
        case .noSavePath: return "No save path specified and no original path available"
        case .invalidArgument(let msg): return "Invalid argument: \(msg)"
        case .exportFailed(let msg): return "Export failed: \(msg)"
        }
    }
}
