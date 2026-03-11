import Foundation
import MCP

public class CheSvgMCPServer {
    private let server: Server
    private let transport: StdioTransport
    private let tools: [Tool]
    private let docManager = SVGDocumentManager()

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

    // MARK: - Handler Registration

    private func registerHandlers() async {
        await server.withMethodHandler(ListTools.self) { [tools] _ in
            ListTools.Result(tools: tools)
        }

        await server.withMethodHandler(CallTool.self) { [weak self] params in
            guard let self else {
                return CallTool.Result(content: [.text("Server unavailable")], isError: true)
            }
            return try await self.handleToolCall(params)
        }
    }

    // MARK: - Tool Call Dispatch

    private func handleToolCall(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        let args = params.arguments ?? [:]

        do {
            switch params.name {
            // Document Management
            case "create_svg": return try handleCreateSVG(args)
            case "open_svg": return try handleOpenSVG(args)
            case "save_svg": return try handleSaveSVG(args)
            case "close_svg": return handleCloseSVG(args)
            case "list_documents": return handleListDocuments()

            // Element Creation
            case "add_rect": return try handleAddRect(args)
            case "add_circle": return try handleAddCircle(args)
            case "add_ellipse": return try handleAddEllipse(args)
            case "add_line": return try handleAddLine(args)
            case "add_polyline": return try handleAddPolyline(args)
            case "add_polygon": return try handleAddPolygon(args)
            case "add_path": return try handleAddPath(args)
            case "add_text": return try handleAddText(args)
            case "add_image": return try handleAddImage(args)
            case "add_group": return try handleAddGroup(args)

            // Element Operations
            case "list_elements": return try handleListElements(args)
            case "get_element": return try handleGetElement(args)
            case "modify_element": return try handleModifyElement(args)
            case "delete_element": return try handleDeleteElement(args)
            case "move_element": return try handleMoveElement(args)
            case "duplicate_element": return try handleDuplicateElement(args)

            // Transform & Style
            case "transform": return try handleTransform(args)
            case "set_style": return try handleSetStyle(args)

            // Gradients
            case "add_linear_gradient": return try handleAddLinearGradient(args)
            case "add_radial_gradient": return try handleAddRadialGradient(args)

            // SVG Properties
            case "get_svg_info": return try handleGetSVGInfo(args)
            case "set_viewbox": return try handleSetViewBox(args)

            // Export
            case "export_png": return try await handleExportPNG(args)
            case "export_pdf": return try await handleExportPDF(args)
            case "get_preview": return try await handleGetPreview(args)

            // Batch
            case "batch_style": return try handleBatchStyle(args)
            case "batch_transform": return try handleBatchTransform(args)

            // Utility
            case "get_svg_text": return try handleGetSVGText(args)

            default:
                return CallTool.Result(content: [.text("Unknown tool: \(params.name)")], isError: true)
            }
        } catch {
            return CallTool.Result(content: [.text("Error: \(error.localizedDescription)")], isError: true)
        }
    }

    // MARK: - Document Management Handlers

    private func handleCreateSVG(_ args: [String: Value]) throws -> CallTool.Result {
        let width = args["width"]?.asDouble ?? 800
        let height = args["height"]?.asDouble ?? 600
        let viewBox = args["viewbox"]?.stringValue
        let docId = args["doc_id"]?.stringValue

        let (id, _) = docManager.createDocument(width: width, height: height, viewBox: viewBox, docId: docId)
        return CallTool.Result(content: [.text("Created SVG document: \(id) (\(Int(width))×\(Int(height)))")])
    }

    private func handleOpenSVG(_ args: [String: Value]) throws -> CallTool.Result {
        guard let path = args["path"]?.stringValue else {
            throw SVGError.invalidArgument("path is required")
        }
        let docId = args["doc_id"]?.stringValue
        let (id, doc) = try docManager.openDocument(path: path, docId: docId)
        let info = doc.getSVGInfo()
        let w = info["width"] ?? "?"
        let h = info["height"] ?? "?"
        let count = info["_element_count"] ?? "0"
        return CallTool.Result(content: [.text("Opened SVG: \(id) (\(w)×\(h), \(count) elements)")])
    }

    private func handleSaveSVG(_ args: [String: Value]) throws -> CallTool.Result {
        guard let docId = args["doc_id"]?.stringValue else {
            throw SVGError.invalidArgument("doc_id is required")
        }
        let path = args["path"]?.stringValue
        try docManager.saveDocument(docId: docId, path: path)
        return CallTool.Result(content: [.text("Saved document: \(docId)")])
    }

    private func handleCloseSVG(_ args: [String: Value]) -> CallTool.Result {
        guard let docId = args["doc_id"]?.stringValue else {
            return CallTool.Result(content: [.text("doc_id is required")], isError: true)
        }
        let closed = docManager.closeDocument(docId: docId)
        return CallTool.Result(content: [.text(closed ? "Closed: \(docId)" : "Document not found: \(docId)")])
    }

    private func handleListDocuments() -> CallTool.Result {
        let docs = docManager.listDocuments()
        if docs.isEmpty {
            return CallTool.Result(content: [.text("No open documents")])
        }
        let lines = docs.map { d in
            let pathStr = d.path.map { " (\($0))" } ?? ""
            let dirtyStr = d.dirty ? " [modified]" : ""
            return "• \(d.id)\(pathStr) — \(d.elementCount) elements\(dirtyStr)"
        }
        return CallTool.Result(content: [.text(lines.joined(separator: "\n"))])
    }

    // MARK: - Element Creation Handlers

    private func handleAddRect(_ args: [String: Value]) throws -> CallTool.Result {
        let (doc, docId) = try getDoc(args)
        let x = args["x"]?.asDouble ?? 0
        let y = args["y"]?.asDouble ?? 0
        guard let width = args["width"]?.asDouble, let height = args["height"]?.asDouble else {
            throw SVGError.invalidArgument("width and height are required")
        }
        let rx = args["rx"]?.asDouble
        let ry = args["ry"]?.asDouble
        let style = extractStyle(args)
        let id = doc.addRect(x: x, y: y, width: width, height: height, rx: rx, ry: ry,
                             id: args["id"]?.stringValue, parentId: args["parent_id"]?.stringValue, style: style)
        return CallTool.Result(content: [.text("Added rect: \(id) in \(docId)")])
    }

    private func handleAddCircle(_ args: [String: Value]) throws -> CallTool.Result {
        let (doc, docId) = try getDoc(args)
        guard let cx = args["cx"]?.asDouble, let cy = args["cy"]?.asDouble, let r = args["r"]?.asDouble else {
            throw SVGError.invalidArgument("cx, cy, and r are required")
        }
        let style = extractStyle(args)
        let id = doc.addCircle(cx: cx, cy: cy, r: r,
                               id: args["id"]?.stringValue, parentId: args["parent_id"]?.stringValue, style: style)
        return CallTool.Result(content: [.text("Added circle: \(id) in \(docId)")])
    }

    private func handleAddEllipse(_ args: [String: Value]) throws -> CallTool.Result {
        let (doc, docId) = try getDoc(args)
        guard let cx = args["cx"]?.asDouble, let cy = args["cy"]?.asDouble,
              let rx = args["rx"]?.asDouble, let ry = args["ry"]?.asDouble else {
            throw SVGError.invalidArgument("cx, cy, rx, and ry are required")
        }
        let style = extractStyle(args)
        let id = doc.addEllipse(cx: cx, cy: cy, rx: rx, ry: ry,
                                id: args["id"]?.stringValue, parentId: args["parent_id"]?.stringValue, style: style)
        return CallTool.Result(content: [.text("Added ellipse: \(id) in \(docId)")])
    }

    private func handleAddLine(_ args: [String: Value]) throws -> CallTool.Result {
        let (doc, docId) = try getDoc(args)
        guard let x1 = args["x1"]?.asDouble, let y1 = args["y1"]?.asDouble,
              let x2 = args["x2"]?.asDouble, let y2 = args["y2"]?.asDouble else {
            throw SVGError.invalidArgument("x1, y1, x2, and y2 are required")
        }
        let style = extractStyle(args)
        let id = doc.addLine(x1: x1, y1: y1, x2: x2, y2: y2,
                             id: args["id"]?.stringValue, parentId: args["parent_id"]?.stringValue, style: style)
        return CallTool.Result(content: [.text("Added line: \(id) in \(docId)")])
    }

    private func handleAddPolyline(_ args: [String: Value]) throws -> CallTool.Result {
        let (doc, docId) = try getDoc(args)
        guard let points = args["points"]?.stringValue else {
            throw SVGError.invalidArgument("points is required")
        }
        let style = extractStyle(args)
        let id = doc.addPolyline(points: points,
                                 id: args["id"]?.stringValue, parentId: args["parent_id"]?.stringValue, style: style)
        return CallTool.Result(content: [.text("Added polyline: \(id) in \(docId)")])
    }

    private func handleAddPolygon(_ args: [String: Value]) throws -> CallTool.Result {
        let (doc, docId) = try getDoc(args)
        guard let points = args["points"]?.stringValue else {
            throw SVGError.invalidArgument("points is required")
        }
        let style = extractStyle(args)
        let id = doc.addPolygon(points: points,
                                id: args["id"]?.stringValue, parentId: args["parent_id"]?.stringValue, style: style)
        return CallTool.Result(content: [.text("Added polygon: \(id) in \(docId)")])
    }

    private func handleAddPath(_ args: [String: Value]) throws -> CallTool.Result {
        let (doc, docId) = try getDoc(args)
        guard let d = args["d"]?.stringValue else {
            throw SVGError.invalidArgument("d (path data) is required")
        }
        let style = extractStyle(args)
        let id = doc.addPath(d: d,
                             id: args["id"]?.stringValue, parentId: args["parent_id"]?.stringValue, style: style)
        return CallTool.Result(content: [.text("Added path: \(id) in \(docId)")])
    }

    private func handleAddText(_ args: [String: Value]) throws -> CallTool.Result {
        let (doc, docId) = try getDoc(args)
        guard let text = args["text"]?.stringValue else {
            throw SVGError.invalidArgument("text is required")
        }
        let x = args["x"]?.asDouble ?? 0
        let y = args["y"]?.asDouble ?? 0
        let style = extractStyle(args)
        let id = doc.addText(text, x: x, y: y,
                             id: args["id"]?.stringValue, parentId: args["parent_id"]?.stringValue, style: style)
        return CallTool.Result(content: [.text("Added text: \(id) in \(docId)")])
    }

    private func handleAddImage(_ args: [String: Value]) throws -> CallTool.Result {
        let (doc, docId) = try getDoc(args)
        guard let href = args["href"]?.stringValue else {
            throw SVGError.invalidArgument("href is required")
        }
        let x = args["x"]?.asDouble ?? 0
        let y = args["y"]?.asDouble ?? 0
        let width = args["width"]?.asDouble ?? 100
        let height = args["height"]?.asDouble ?? 100
        let id = doc.addImage(href: href, x: x, y: y, width: width, height: height,
                              id: args["id"]?.stringValue, parentId: args["parent_id"]?.stringValue)
        return CallTool.Result(content: [.text("Added image: \(id) in \(docId)")])
    }

    private func handleAddGroup(_ args: [String: Value]) throws -> CallTool.Result {
        let (doc, docId) = try getDoc(args)
        let style = extractStyle(args)
        let id = doc.addGroup(id: args["id"]?.stringValue, parentId: args["parent_id"]?.stringValue, style: style)
        return CallTool.Result(content: [.text("Added group: \(id) in \(docId)")])
    }

    // MARK: - Element Operations Handlers

    private func handleListElements(_ args: [String: Value]) throws -> CallTool.Result {
        let (doc, _) = try getDoc(args)
        let parentId = args["parent_id"]?.stringValue
        let elements = doc.listElements(parentId: parentId)
        if elements.isEmpty {
            return CallTool.Result(content: [.text("No elements found")])
        }
        let lines = elements.map { "• \($0.description)" }
        return CallTool.Result(content: [.text("Elements (\(elements.count)):\n\(lines.joined(separator: "\n"))")])
    }

    private func handleGetElement(_ args: [String: Value]) throws -> CallTool.Result {
        let (doc, _) = try getDoc(args)
        guard let elementId = args["element_id"]?.stringValue else {
            throw SVGError.invalidArgument("element_id is required")
        }
        guard let info = doc.getElement(id: elementId) else {
            throw SVGError.elementNotFound(elementId)
        }
        return CallTool.Result(content: [.text(info.description)])
    }

    private func handleModifyElement(_ args: [String: Value]) throws -> CallTool.Result {
        let (doc, _) = try getDoc(args)
        guard let elementId = args["element_id"]?.stringValue else {
            throw SVGError.invalidArgument("element_id is required")
        }
        var attributes: [String: String] = [:]
        if let attrsValue = args["attributes"] {
            if let obj = attrsValue.objectValue {
                for (k, v) in obj {
                    attributes[k] = v.stringValue ?? String(describing: v)
                }
            }
        }
        guard doc.modifyElement(id: elementId, attributes: attributes) else {
            throw SVGError.elementNotFound(elementId)
        }
        return CallTool.Result(content: [.text("Modified element: \(elementId)")])
    }

    private func handleDeleteElement(_ args: [String: Value]) throws -> CallTool.Result {
        let (doc, _) = try getDoc(args)
        guard let elementId = args["element_id"]?.stringValue else {
            throw SVGError.invalidArgument("element_id is required")
        }
        guard doc.deleteElement(id: elementId) else {
            throw SVGError.elementNotFound(elementId)
        }
        return CallTool.Result(content: [.text("Deleted element: \(elementId)")])
    }

    private func handleMoveElement(_ args: [String: Value]) throws -> CallTool.Result {
        let (doc, _) = try getDoc(args)
        guard let elementId = args["element_id"]?.stringValue else {
            throw SVGError.invalidArgument("element_id is required")
        }
        let newParentId = args["new_parent_id"]?.stringValue
        let index = args["index"]?.asInt
        guard doc.moveElement(id: elementId, newParentId: newParentId, index: index) else {
            throw SVGError.elementNotFound(elementId)
        }
        return CallTool.Result(content: [.text("Moved element: \(elementId)")])
    }

    private func handleDuplicateElement(_ args: [String: Value]) throws -> CallTool.Result {
        let (doc, _) = try getDoc(args)
        guard let elementId = args["element_id"]?.stringValue else {
            throw SVGError.invalidArgument("element_id is required")
        }
        let offsetX = args["offset_x"]?.asDouble ?? 10
        let offsetY = args["offset_y"]?.asDouble ?? 10
        guard let newId = doc.duplicateElement(id: elementId, offsetX: offsetX, offsetY: offsetY) else {
            throw SVGError.elementNotFound(elementId)
        }
        return CallTool.Result(content: [.text("Duplicated \(elementId) → \(newId)")])
    }

    // MARK: - Transform & Style Handlers

    private func handleTransform(_ args: [String: Value]) throws -> CallTool.Result {
        let (doc, _) = try getDoc(args)
        guard let elementId = args["element_id"]?.stringValue else {
            throw SVGError.invalidArgument("element_id is required")
        }
        guard let typeStr = args["type"]?.stringValue,
              let kind = SVGTransformValue.Kind(rawValue: typeStr) else {
            throw SVGError.invalidArgument("type must be one of: translate, rotate, scale, skewX, skewY, matrix")
        }
        guard let valuesStr = args["values"]?.stringValue else {
            throw SVGError.invalidArgument("values is required (comma-separated numbers)")
        }
        let values = valuesStr.split(separator: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
        let replace = args["replace"]?.asBool ?? false

        let transform = SVGTransformValue(kind: kind, values: values)
        guard doc.applyTransform(id: elementId, transform: transform, replace: replace) else {
            throw SVGError.elementNotFound(elementId)
        }
        return CallTool.Result(content: [.text("Applied \(typeStr) to \(elementId)")])
    }

    private func handleSetStyle(_ args: [String: Value]) throws -> CallTool.Result {
        let (doc, _) = try getDoc(args)
        guard let elementId = args["element_id"]?.stringValue else {
            throw SVGError.invalidArgument("element_id is required")
        }
        let style = extractStyle(args)
        guard doc.setStyle(id: elementId, style: style) else {
            throw SVGError.elementNotFound(elementId)
        }
        return CallTool.Result(content: [.text("Set style on \(elementId)")])
    }

    // MARK: - Gradient Handlers

    private func handleAddLinearGradient(_ args: [String: Value]) throws -> CallTool.Result {
        let (doc, _) = try getDoc(args)
        guard let gradientId = args["gradient_id"]?.stringValue else {
            throw SVGError.invalidArgument("gradient_id is required")
        }
        let x1 = args["x1"]?.stringValue ?? "0%"
        let y1 = args["y1"]?.stringValue ?? "0%"
        let x2 = args["x2"]?.stringValue ?? "100%"
        let y2 = args["y2"]?.stringValue ?? "0%"
        let stops = extractStops(args)

        doc.addLinearGradient(id: gradientId, x1: x1, y1: y1, x2: x2, y2: y2, stops: stops)
        return CallTool.Result(content: [.text("Added linear gradient: \(gradientId) (\(stops.count) stops)")])
    }

    private func handleAddRadialGradient(_ args: [String: Value]) throws -> CallTool.Result {
        let (doc, _) = try getDoc(args)
        guard let gradientId = args["gradient_id"]?.stringValue else {
            throw SVGError.invalidArgument("gradient_id is required")
        }
        let cx = args["cx"]?.stringValue ?? "50%"
        let cy = args["cy"]?.stringValue ?? "50%"
        let r = args["r"]?.stringValue ?? "50%"
        let fx = args["fx"]?.stringValue
        let fy = args["fy"]?.stringValue
        let stops = extractStops(args)

        doc.addRadialGradient(id: gradientId, cx: cx, cy: cy, r: r, fx: fx, fy: fy, stops: stops)
        return CallTool.Result(content: [.text("Added radial gradient: \(gradientId) (\(stops.count) stops)")])
    }

    // MARK: - SVG Properties Handlers

    private func handleGetSVGInfo(_ args: [String: Value]) throws -> CallTool.Result {
        let (doc, _) = try getDoc(args)
        let info = doc.getSVGInfo()
        let lines = info.sorted { $0.key < $1.key }.map { "  \($0.key): \($0.value)" }
        return CallTool.Result(content: [.text("SVG Info:\n\(lines.joined(separator: "\n"))")])
    }

    private func handleSetViewBox(_ args: [String: Value]) throws -> CallTool.Result {
        let (doc, _) = try getDoc(args)
        guard let viewBox = args["viewbox"]?.stringValue else {
            throw SVGError.invalidArgument("viewbox is required (e.g. \"0 0 800 600\")")
        }
        doc.setViewBox(viewBox)
        let width = args["width"]?.asDouble
        let height = args["height"]?.asDouble
        if width != nil || height != nil {
            doc.setSize(width: width, height: height)
        }
        return CallTool.Result(content: [.text("Set viewBox: \(viewBox)")])
    }

    // MARK: - Export Handlers

    private func handleExportPNG(_ args: [String: Value]) async throws -> CallTool.Result {
        let (doc, _) = try getDoc(args)
        guard let outputPath = args["output_path"]?.stringValue else {
            throw SVGError.invalidArgument("output_path is required")
        }
        let width = args["width"]?.asInt ?? 800
        let height = args["height"]?.asInt ?? 600
        try await SVGExporter.exportPNG(svg: doc, width: width, height: height, outputPath: outputPath)
        return CallTool.Result(content: [.text("Exported PNG: \(outputPath) (\(width)×\(height))")])
    }

    private func handleExportPDF(_ args: [String: Value]) async throws -> CallTool.Result {
        let (doc, _) = try getDoc(args)
        guard let outputPath = args["output_path"]?.stringValue else {
            throw SVGError.invalidArgument("output_path is required")
        }
        let width = args["width"]?.asInt ?? 800
        let height = args["height"]?.asInt ?? 600
        try await SVGExporter.exportPDF(svg: doc, width: width, height: height, outputPath: outputPath)
        return CallTool.Result(content: [.text("Exported PDF: \(outputPath) (\(width)×\(height))")])
    }

    private func handleGetPreview(_ args: [String: Value]) async throws -> CallTool.Result {
        let (doc, _) = try getDoc(args)
        let width = args["width"]?.asInt ?? 400
        let height = args["height"]?.asInt ?? 300
        let base64 = try await SVGExporter.getPreview(svg: doc, width: width, height: height)
        return CallTool.Result(content: [.text("data:image/png;base64,\(base64)")])
    }

    // MARK: - Batch Handlers

    private func handleBatchStyle(_ args: [String: Value]) throws -> CallTool.Result {
        let (doc, _) = try getDoc(args)
        let ids = extractStringArray(args, key: "element_ids")
        guard !ids.isEmpty else {
            throw SVGError.invalidArgument("element_ids is required (array of IDs)")
        }
        let style = extractStyle(args)
        let count = doc.batchSetStyle(ids: ids, style: style)
        return CallTool.Result(content: [.text("Applied style to \(count)/\(ids.count) elements")])
    }

    private func handleBatchTransform(_ args: [String: Value]) throws -> CallTool.Result {
        let (doc, _) = try getDoc(args)
        let ids = extractStringArray(args, key: "element_ids")
        guard !ids.isEmpty else {
            throw SVGError.invalidArgument("element_ids is required (array of IDs)")
        }
        guard let typeStr = args["type"]?.stringValue,
              let kind = SVGTransformValue.Kind(rawValue: typeStr) else {
            throw SVGError.invalidArgument("type is required (translate, rotate, scale, skewX, skewY, matrix)")
        }
        guard let valuesStr = args["values"]?.stringValue else {
            throw SVGError.invalidArgument("values is required")
        }
        let values = valuesStr.split(separator: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
        let replace = args["replace"]?.asBool ?? false
        let transform = SVGTransformValue(kind: kind, values: values)
        let count = doc.batchTransform(ids: ids, transform: transform, replace: replace)
        return CallTool.Result(content: [.text("Applied \(typeStr) to \(count)/\(ids.count) elements")])
    }

    // MARK: - Utility Handlers

    private func handleGetSVGText(_ args: [String: Value]) throws -> CallTool.Result {
        let (doc, _) = try getDoc(args)
        let pretty = args["pretty"]?.asBool ?? true
        let text = doc.svgString(pretty: pretty)
        return CallTool.Result(content: [.text(text)])
    }

    // MARK: - Helper Methods

    private func getDoc(_ args: [String: Value]) throws -> (SVGDocument, String) {
        guard let docId = args["doc_id"]?.stringValue else {
            throw SVGError.invalidArgument("doc_id is required")
        }
        guard let doc = docManager.getDocument(docId) else {
            throw SVGError.documentNotFound(docId)
        }
        return (doc, docId)
    }

    private func extractStyle(_ args: [String: Value]) -> SVGStyleProperties {
        var s = SVGStyleProperties()
        s.fill = args["fill"]?.stringValue
        s.stroke = args["stroke"]?.stringValue
        s.strokeWidth = args["stroke_width"]?.asDouble
        s.opacity = args["opacity"]?.asDouble
        s.fillOpacity = args["fill_opacity"]?.asDouble
        s.strokeOpacity = args["stroke_opacity"]?.asDouble
        s.strokeLinecap = args["stroke_linecap"]?.stringValue
        s.strokeLinejoin = args["stroke_linejoin"]?.stringValue
        s.strokeDasharray = args["stroke_dasharray"]?.stringValue
        s.fontFamily = args["font_family"]?.stringValue
        s.fontSize = args["font_size"]?.asDouble
        s.fontWeight = args["font_weight"]?.stringValue
        s.textAnchor = args["text_anchor"]?.stringValue
        s.dominantBaseline = args["dominant_baseline"]?.stringValue
        return s
    }

    private func extractStops(_ args: [String: Value]) -> [(offset: String, color: String, opacity: Double?)] {
        guard let stopsArray = args["stops"]?.arrayValue else { return [] }
        return stopsArray.compactMap { stopValue in
            guard let obj = stopValue.objectValue,
                  let offset = obj["offset"]?.stringValue,
                  let color = obj["color"]?.stringValue else { return nil }
            let opacity = obj["opacity"]?.asDouble
            return (offset: offset, color: color, opacity: opacity)
        }
    }

    private func extractStringArray(_ args: [String: Value], key: String) -> [String] {
        guard let arr = args[key]?.arrayValue else { return [] }
        return arr.compactMap { $0.stringValue }
    }
}

// MARK: - Cross-type Value Conversion

extension Value {
    /// Double from .double or .int (JSON integers parse as .int)
    var asDouble: Double? { Double(self, strict: false) }
    /// Int from .int or .double (if exact)
    var asInt: Int? { Int(self, strict: false) }
    /// Bool from .bool or "true"/"false" strings
    var asBool: Bool? { Bool(self, strict: false) }
}

// MARK: - Tool Definitions

extension CheSvgMCPServer {

    private static func defineTools() -> [Tool] {
        [
            // Document Management
            tool("create_svg", "Create a new empty SVG document",
                 props: [
                    "doc_id": prop("string", "Document ID (auto-generated if omitted)"),
                    "width": prop("number", "Canvas width in pixels", default: "800"),
                    "height": prop("number", "Canvas height in pixels", default: "600"),
                    "viewbox": prop("string", "SVG viewBox attribute (e.g. \"0 0 800 600\")"),
                 ]),

            tool("open_svg", "Open an existing SVG file for editing",
                 props: [
                    "path": prop("string", "Absolute path to .svg file"),
                    "doc_id": prop("string", "Document ID (auto-generated if omitted)"),
                 ],
                 required: ["path"]),

            tool("save_svg", "Save an open SVG document to disk",
                 props: [
                    "doc_id": prop("string", "Document ID"),
                    "path": prop("string", "Output path (uses original path if omitted)"),
                 ],
                 required: ["doc_id"]),

            tool("close_svg", "Close an open SVG document and release memory",
                 props: [
                    "doc_id": prop("string", "Document ID"),
                 ],
                 required: ["doc_id"]),

            tool("list_documents", "List all currently open SVG documents",
                 props: [:]),

            // Element Creation
            tool("add_rect", "Add a rectangle element",
                 props: shapeCommon.merging([
                    "x": prop("number", "X position"),
                    "y": prop("number", "Y position"),
                    "width": prop("number", "Width"),
                    "height": prop("number", "Height"),
                    "rx": prop("number", "Corner radius X"),
                    "ry": prop("number", "Corner radius Y"),
                 ]) { $1 },
                 required: ["doc_id", "width", "height"]),

            tool("add_circle", "Add a circle element",
                 props: shapeCommon.merging([
                    "cx": prop("number", "Center X"),
                    "cy": prop("number", "Center Y"),
                    "r": prop("number", "Radius"),
                 ]) { $1 },
                 required: ["doc_id", "cx", "cy", "r"]),

            tool("add_ellipse", "Add an ellipse element",
                 props: shapeCommon.merging([
                    "cx": prop("number", "Center X"),
                    "cy": prop("number", "Center Y"),
                    "rx": prop("number", "Radius X"),
                    "ry": prop("number", "Radius Y"),
                 ]) { $1 },
                 required: ["doc_id", "cx", "cy", "rx", "ry"]),

            tool("add_line", "Add a line element",
                 props: shapeCommon.merging([
                    "x1": prop("number", "Start X"),
                    "y1": prop("number", "Start Y"),
                    "x2": prop("number", "End X"),
                    "y2": prop("number", "End Y"),
                 ]) { $1 },
                 required: ["doc_id", "x1", "y1", "x2", "y2"]),

            tool("add_polyline", "Add a polyline element (open shape from points)",
                 props: shapeCommon.merging([
                    "points": prop("string", "Space-separated point pairs (e.g. \"10,10 40,40 70,10\")"),
                 ]) { $1 },
                 required: ["doc_id", "points"]),

            tool("add_polygon", "Add a polygon element (closed shape from points)",
                 props: shapeCommon.merging([
                    "points": prop("string", "Space-separated point pairs (e.g. \"50,5 100,100 0,100\")"),
                 ]) { $1 },
                 required: ["doc_id", "points"]),

            tool("add_path", "Add a path element using SVG path data",
                 props: shapeCommon.merging([
                    "d": prop("string", "SVG path data (e.g. \"M10 10 L90 90 Z\")"),
                 ]) { $1 },
                 required: ["doc_id", "d"]),

            tool("add_text", "Add a text element",
                 props: shapeCommon.merging([
                    "text": prop("string", "Text content"),
                    "x": prop("number", "X position"),
                    "y": prop("number", "Y position"),
                    "font_family": prop("string", "Font family"),
                    "font_size": prop("number", "Font size"),
                    "font_weight": prop("string", "Font weight (normal, bold, 100-900)"),
                    "text_anchor": prop("string", "Text anchor (start, middle, end)"),
                 ]) { $1 },
                 required: ["doc_id", "text"]),

            tool("add_image", "Add an image element (embedded or linked)",
                 props: [
                    "doc_id": prop("string", "Document ID"),
                    "href": prop("string", "Image URL or base64 data URI"),
                    "x": prop("number", "X position"),
                    "y": prop("number", "Y position"),
                    "width": prop("number", "Width"),
                    "height": prop("number", "Height"),
                    "id": prop("string", "Element ID"),
                    "parent_id": prop("string", "Parent group ID"),
                 ],
                 required: ["doc_id", "href"]),

            tool("add_group", "Add a group (<g>) container element",
                 props: [
                    "doc_id": prop("string", "Document ID"),
                    "id": prop("string", "Group ID"),
                    "parent_id": prop("string", "Parent group ID"),
                    "fill": prop("string", "Fill color"),
                    "stroke": prop("string", "Stroke color"),
                    "opacity": prop("number", "Opacity (0-1)"),
                 ],
                 required: ["doc_id"]),

            // Element Operations
            tool("list_elements", "List child elements of the document or a group",
                 props: [
                    "doc_id": prop("string", "Document ID"),
                    "parent_id": prop("string", "Parent element ID (root if omitted)"),
                 ],
                 required: ["doc_id"]),

            tool("get_element", "Get detailed info about a specific element",
                 props: [
                    "doc_id": prop("string", "Document ID"),
                    "element_id": prop("string", "Element ID"),
                 ],
                 required: ["doc_id", "element_id"]),

            tool("modify_element", "Modify attributes of an existing element",
                 props: [
                    "doc_id": prop("string", "Document ID"),
                    "element_id": prop("string", "Element ID"),
                    "attributes": .object([
                        "type": .string("object"),
                        "description": .string("Key-value pairs of attributes to set"),
                    ]),
                 ],
                 required: ["doc_id", "element_id", "attributes"]),

            tool("delete_element", "Delete an element by ID",
                 props: [
                    "doc_id": prop("string", "Document ID"),
                    "element_id": prop("string", "Element ID"),
                 ],
                 required: ["doc_id", "element_id"]),

            tool("move_element", "Move an element to a new parent or reorder within parent",
                 props: [
                    "doc_id": prop("string", "Document ID"),
                    "element_id": prop("string", "Element ID to move"),
                    "new_parent_id": prop("string", "New parent ID (root if omitted)"),
                    "index": prop("integer", "Position index within new parent"),
                 ],
                 required: ["doc_id", "element_id"]),

            tool("duplicate_element", "Duplicate an element with optional offset",
                 props: [
                    "doc_id": prop("string", "Document ID"),
                    "element_id": prop("string", "Element ID to duplicate"),
                    "offset_x": prop("number", "X offset for the copy", default: "10"),
                    "offset_y": prop("number", "Y offset for the copy", default: "10"),
                 ],
                 required: ["doc_id", "element_id"]),

            // Transform
            tool("transform", "Apply a transform to an element (translate, rotate, scale, skew, matrix)",
                 props: [
                    "doc_id": prop("string", "Document ID"),
                    "element_id": prop("string", "Element ID"),
                    "type": prop("string", "Transform type: translate, rotate, scale, skewX, skewY, matrix"),
                    "values": prop("string", "Comma-separated values (e.g. \"100,50\" for translate)"),
                    "replace": prop("boolean", "Replace existing transforms (default: false, appends)"),
                 ],
                 required: ["doc_id", "element_id", "type", "values"]),

            // Style
            tool("set_style", "Set visual style properties on an element",
                 props: [
                    "doc_id": prop("string", "Document ID"),
                    "element_id": prop("string", "Element ID"),
                    "fill": prop("string", "Fill color (name, hex, rgb(), url(#gradientId))"),
                    "stroke": prop("string", "Stroke color"),
                    "stroke_width": prop("number", "Stroke width"),
                    "opacity": prop("number", "Opacity (0-1)"),
                    "fill_opacity": prop("number", "Fill opacity (0-1)"),
                    "stroke_opacity": prop("number", "Stroke opacity (0-1)"),
                    "stroke_linecap": prop("string", "Line cap: butt, round, square"),
                    "stroke_linejoin": prop("string", "Line join: miter, round, bevel"),
                    "stroke_dasharray": prop("string", "Dash pattern (e.g. \"5,3\")"),
                    "font_family": prop("string", "Font family"),
                    "font_size": prop("number", "Font size"),
                    "font_weight": prop("string", "Font weight"),
                    "text_anchor": prop("string", "Text anchor: start, middle, end"),
                 ],
                 required: ["doc_id", "element_id"]),

            // Gradients
            tool("add_linear_gradient", "Add a linear gradient definition to <defs>",
                 props: [
                    "doc_id": prop("string", "Document ID"),
                    "gradient_id": prop("string", "Gradient ID (referenced as fill=\"url(#id)\")"),
                    "x1": prop("string", "Start X (default: 0%)"),
                    "y1": prop("string", "Start Y (default: 0%)"),
                    "x2": prop("string", "End X (default: 100%)"),
                    "y2": prop("string", "End Y (default: 0%)"),
                    "stops": .object([
                        "type": .string("array"),
                        "description": .string("Array of {offset, color, opacity?} objects"),
                        "items": .object([
                            "type": .string("object"),
                            "properties": .object([
                                "offset": .object(["type": .string("string"), "description": .string("Stop position (e.g. \"0%\", \"100%\")")]),
                                "color": .object(["type": .string("string"), "description": .string("Stop color")]),
                                "opacity": .object(["type": .string("number"), "description": .string("Stop opacity (0-1)")]),
                            ]),
                        ]),
                    ]),
                 ],
                 required: ["doc_id", "gradient_id", "stops"]),

            tool("add_radial_gradient", "Add a radial gradient definition to <defs>",
                 props: [
                    "doc_id": prop("string", "Document ID"),
                    "gradient_id": prop("string", "Gradient ID"),
                    "cx": prop("string", "Center X (default: 50%)"),
                    "cy": prop("string", "Center Y (default: 50%)"),
                    "r": prop("string", "Radius (default: 50%)"),
                    "fx": prop("string", "Focal point X"),
                    "fy": prop("string", "Focal point Y"),
                    "stops": .object([
                        "type": .string("array"),
                        "description": .string("Array of {offset, color, opacity?} objects"),
                        "items": .object([
                            "type": .string("object"),
                            "properties": .object([
                                "offset": .object(["type": .string("string")]),
                                "color": .object(["type": .string("string")]),
                                "opacity": .object(["type": .string("number")]),
                            ]),
                        ]),
                    ]),
                 ],
                 required: ["doc_id", "gradient_id", "stops"]),

            // SVG Properties
            tool("get_svg_info", "Get SVG document properties (dimensions, viewBox, element count)",
                 props: [
                    "doc_id": prop("string", "Document ID"),
                 ],
                 required: ["doc_id"]),

            tool("set_viewbox", "Set the SVG viewBox and optionally width/height",
                 props: [
                    "doc_id": prop("string", "Document ID"),
                    "viewbox": prop("string", "viewBox value (e.g. \"0 0 800 600\")"),
                    "width": prop("number", "SVG width"),
                    "height": prop("number", "SVG height"),
                 ],
                 required: ["doc_id", "viewbox"]),

            // Export
            tool("export_png", "Export the SVG to a PNG file via Core Graphics",
                 props: [
                    "doc_id": prop("string", "Document ID"),
                    "output_path": prop("string", "Output file path"),
                    "width": prop("integer", "Image width in pixels", default: "800"),
                    "height": prop("integer", "Image height in pixels", default: "600"),
                 ],
                 required: ["doc_id", "output_path"]),

            tool("export_pdf", "Export the SVG to a PDF file via Core Graphics",
                 props: [
                    "doc_id": prop("string", "Document ID"),
                    "output_path": prop("string", "Output file path"),
                    "width": prop("integer", "Page width in points", default: "800"),
                    "height": prop("integer", "Page height in points", default: "600"),
                 ],
                 required: ["doc_id", "output_path"]),

            tool("get_preview", "Get a base64-encoded PNG preview of the SVG",
                 props: [
                    "doc_id": prop("string", "Document ID"),
                    "width": prop("integer", "Preview width", default: "400"),
                    "height": prop("integer", "Preview height", default: "300"),
                 ],
                 required: ["doc_id"]),

            // Batch
            tool("batch_style", "Apply the same style to multiple elements at once",
                 props: [
                    "doc_id": prop("string", "Document ID"),
                    "element_ids": .object([
                        "type": .string("array"),
                        "description": .string("Array of element IDs"),
                        "items": .object(["type": .string("string")]),
                    ]),
                    "fill": prop("string", "Fill color"),
                    "stroke": prop("string", "Stroke color"),
                    "stroke_width": prop("number", "Stroke width"),
                    "opacity": prop("number", "Opacity"),
                 ],
                 required: ["doc_id", "element_ids"]),

            tool("batch_transform", "Apply the same transform to multiple elements",
                 props: [
                    "doc_id": prop("string", "Document ID"),
                    "element_ids": .object([
                        "type": .string("array"),
                        "description": .string("Array of element IDs"),
                        "items": .object(["type": .string("string")]),
                    ]),
                    "type": prop("string", "Transform type"),
                    "values": prop("string", "Comma-separated values"),
                    "replace": prop("boolean", "Replace existing transforms"),
                 ],
                 required: ["doc_id", "element_ids", "type", "values"]),

            // Utility
            tool("get_svg_text", "Get the raw SVG XML text of a document",
                 props: [
                    "doc_id": prop("string", "Document ID"),
                    "pretty": prop("boolean", "Pretty-print XML (default: true)"),
                 ],
                 required: ["doc_id"]),
        ]
    }

    // MARK: - Tool Definition Helpers

    private static func tool(_ name: String, _ description: String,
                             props: [String: Value], required: [String] = []) -> Tool {
        Tool(
            name: name,
            description: description,
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object(props),
                "required": .array(required.map { .string($0) }),
            ])
        )
    }

    private static func prop(_ type: String, _ description: String, default defaultVal: String? = nil) -> Value {
        var obj: [String: Value] = [
            "type": .string(type),
            "description": .string(description),
        ]
        if let d = defaultVal {
            obj["default"] = .string(d)
        }
        return .object(obj)
    }

    private static var shapeCommon: [String: Value] {
        [
            "doc_id": prop("string", "Document ID"),
            "id": prop("string", "Element ID (auto-generated if omitted)"),
            "parent_id": prop("string", "Parent group ID (root SVG if omitted)"),
            "fill": prop("string", "Fill color (name, hex, rgb(), none)"),
            "stroke": prop("string", "Stroke color"),
            "stroke_width": prop("number", "Stroke width"),
            "opacity": prop("number", "Opacity (0-1)"),
        ]
    }
}
