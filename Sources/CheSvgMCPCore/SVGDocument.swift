import Foundation

public class SVGDocument {
    public private(set) var xmlDocument: XMLDocument
    public private(set) var isDirty: Bool = false
    public let sourcePath: String?
    private var nextId: Int = 1

    // MARK: - Init

    public init(width: Double, height: Double, viewBox: String? = nil) {
        let svgString = """
        <?xml version="1.0" encoding="UTF-8"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="\(width)" height="\(height)"\(viewBox.map { " viewBox=\"\($0)\"" } ?? "")></svg>
        """
        self.xmlDocument = try! XMLDocument(xmlString: svgString, options: [])
        self.sourcePath = nil
    }

    public init(contentsOf url: URL) throws {
        self.xmlDocument = try XMLDocument(contentsOf: url, options: [])
        self.sourcePath = url.path
    }

    public init(xmlString: String) throws {
        self.xmlDocument = try XMLDocument(xmlString: xmlString, options: [])
        self.sourcePath = nil
    }

    // MARK: - Root

    public var root: XMLElement? {
        xmlDocument.rootElement()
    }

    // MARK: - ID Generation

    private func generateElementId() -> String {
        let id = "e\(nextId)"
        nextId += 1
        return id
    }

    private func ensureId(_ element: XMLElement) -> String {
        if let existing = element.attribute(forName: "id")?.stringValue, !existing.isEmpty {
            return existing
        }
        let id = generateElementId()
        element.setSafeAttributes(["id": id])
        return id
    }

    // MARK: - Find Element

    public func findElement(byId id: String) -> XMLElement? {
        guard let root = root else { return nil }
        return findElementRecursive(in: root, id: id)
    }

    private func findElementRecursive(in element: XMLElement, id: String) -> XMLElement? {
        if element.attribute(forName: "id")?.stringValue == id {
            return element
        }
        for child in element.children ?? [] {
            if let childElement = child as? XMLElement,
               let found = findElementRecursive(in: childElement, id: id) {
                return found
            }
        }
        return nil
    }

    // MARK: - List Elements

    public func listElements(parentId: String? = nil) -> [SVGElementInfo] {
        let parent: XMLElement
        if let pid = parentId {
            guard let found = findElement(byId: pid) else { return [] }
            parent = found
        } else {
            guard let r = root else { return [] }
            parent = r
        }

        var results: [SVGElementInfo] = []
        for child in parent.children ?? [] {
            guard let element = child as? XMLElement else { continue }
            let elementId = element.attribute(forName: "id")?.stringValue ?? ""
            var attrs: [String: String] = [:]
            for attr in element.attributes ?? [] {
                if let name = attr.name, let val = attr.stringValue {
                    attrs[name] = val
                }
            }
            let childCount = (element.children ?? []).compactMap { $0 as? XMLElement }.count
            results.append(SVGElementInfo(
                id: elementId,
                type: element.localName ?? element.name ?? "unknown",
                attributes: attrs,
                childCount: childCount
            ))
        }
        return results
    }

    // MARK: - Get Element Info

    public func getElement(id: String) -> SVGElementInfo? {
        guard let element = findElement(byId: id) else { return nil }
        var attrs: [String: String] = [:]
        for attr in element.attributes ?? [] {
            if let name = attr.name, let val = attr.stringValue {
                attrs[name] = val
            }
        }
        let childCount = (element.children ?? []).compactMap { $0 as? XMLElement }.count
        return SVGElementInfo(
            id: element.attribute(forName: "id")?.stringValue ?? "",
            type: element.localName ?? element.name ?? "unknown",
            attributes: attrs,
            childCount: childCount
        )
    }

    // MARK: - Add Elements

    @discardableResult
    public func addRect(x: Double, y: Double, width: Double, height: Double,
                        rx: Double? = nil, ry: Double? = nil,
                        id: String? = nil, parentId: String? = nil,
                        style: SVGStyleProperties? = nil) -> String {
        let element = XMLElement(name: "rect")
        element.setSafeAttributes([
            "x": String(x), "y": String(y),
            "width": String(width), "height": String(height)
        ])
        if let rx = rx { element.setSafeAttributes(["rx": String(rx)]) }
        if let ry = ry { element.setSafeAttributes(["ry": String(ry)]) }
        return addElement(element, id: id, parentId: parentId, style: style)
    }

    @discardableResult
    public func addCircle(cx: Double, cy: Double, r: Double,
                          id: String? = nil, parentId: String? = nil,
                          style: SVGStyleProperties? = nil) -> String {
        let element = XMLElement(name: "circle")
        element.setSafeAttributes(["cx": String(cx), "cy": String(cy), "r": String(r)])
        return addElement(element, id: id, parentId: parentId, style: style)
    }

    @discardableResult
    public func addEllipse(cx: Double, cy: Double, rx: Double, ry: Double,
                           id: String? = nil, parentId: String? = nil,
                           style: SVGStyleProperties? = nil) -> String {
        let element = XMLElement(name: "ellipse")
        element.setSafeAttributes(["cx": String(cx), "cy": String(cy), "rx": String(rx), "ry": String(ry)])
        return addElement(element, id: id, parentId: parentId, style: style)
    }

    @discardableResult
    public func addLine(x1: Double, y1: Double, x2: Double, y2: Double,
                        id: String? = nil, parentId: String? = nil,
                        style: SVGStyleProperties? = nil) -> String {
        let element = XMLElement(name: "line")
        element.setSafeAttributes(["x1": String(x1), "y1": String(y1), "x2": String(x2), "y2": String(y2)])
        return addElement(element, id: id, parentId: parentId, style: style)
    }

    @discardableResult
    public func addPolyline(points: String, id: String? = nil, parentId: String? = nil,
                            style: SVGStyleProperties? = nil) -> String {
        let element = XMLElement(name: "polyline")
        element.setSafeAttributes(["points": points])
        return addElement(element, id: id, parentId: parentId, style: style)
    }

    @discardableResult
    public func addPolygon(points: String, id: String? = nil, parentId: String? = nil,
                           style: SVGStyleProperties? = nil) -> String {
        let element = XMLElement(name: "polygon")
        element.setSafeAttributes(["points": points])
        return addElement(element, id: id, parentId: parentId, style: style)
    }

    @discardableResult
    public func addPath(d: String, id: String? = nil, parentId: String? = nil,
                        style: SVGStyleProperties? = nil) -> String {
        let element = XMLElement(name: "path")
        element.setSafeAttributes(["d": d])
        return addElement(element, id: id, parentId: parentId, style: style)
    }

    @discardableResult
    public func addText(_ text: String, x: Double, y: Double,
                        id: String? = nil, parentId: String? = nil,
                        style: SVGStyleProperties? = nil) -> String {
        let element = XMLElement(name: "text")
        element.setSafeAttributes(["x": String(x), "y": String(y)])
        element.stringValue = text
        return addElement(element, id: id, parentId: parentId, style: style)
    }

    @discardableResult
    public func addImage(href: String, x: Double, y: Double, width: Double, height: Double,
                         id: String? = nil, parentId: String? = nil) -> String {
        let element = XMLElement(name: "image")
        element.setSafeAttributes([
            "href": href, "x": String(x), "y": String(y),
            "width": String(width), "height": String(height)
        ])
        return addElement(element, id: id, parentId: parentId, style: nil)
    }

    @discardableResult
    public func addGroup(id: String? = nil, parentId: String? = nil,
                         style: SVGStyleProperties? = nil) -> String {
        let element = XMLElement(name: "g")
        return addElement(element, id: id, parentId: parentId, style: style)
    }

    private func addElement(_ element: XMLElement, id: String?, parentId: String?,
                            style: SVGStyleProperties?) -> String {
        if let customId = id {
            element.setSafeAttributes(["id": customId])
        }
        let elementId = id ?? ensureId(element)
        style?.applyTo(element)

        let parent: XMLElement
        if let pid = parentId, let found = findElement(byId: pid) {
            parent = found
        } else {
            parent = root!
        }
        parent.addChild(element)
        isDirty = true
        return elementId
    }

    // MARK: - Modify Element

    public func modifyElement(id: String, attributes: [String: String]) -> Bool {
        guard let element = findElement(byId: id) else { return false }
        element.setSafeAttributes(attributes)
        isDirty = true
        return true
    }

    // MARK: - Delete Element

    public func deleteElement(id: String) -> Bool {
        guard let element = findElement(byId: id), let parent = element.parent as? XMLElement else { return false }
        parent.removeChild(at: element.index)
        isDirty = true
        return true
    }

    // MARK: - Move Element (reorder / reparent)

    public func moveElement(id: String, newParentId: String?, index: Int?) -> Bool {
        guard let element = findElement(byId: id),
              let oldParent = element.parent as? XMLElement else { return false }

        let detached = element.copy() as! XMLElement
        oldParent.removeChild(at: element.index)

        let newParent: XMLElement
        if let npid = newParentId, let found = findElement(byId: npid) {
            newParent = found
        } else {
            newParent = root!
        }

        if let idx = index, idx < (newParent.childCount) {
            newParent.insertChild(detached, at: idx)
        } else {
            newParent.addChild(detached)
        }
        isDirty = true
        return true
    }

    // MARK: - Duplicate Element

    public func duplicateElement(id: String, offsetX: Double = 10, offsetY: Double = 10) -> String? {
        guard let element = findElement(byId: id),
              let parent = element.parent as? XMLElement else { return nil }
        let copy = element.copy() as! XMLElement
        let newId = generateElementId()
        copy.setSafeAttributes(["id": newId])

        // offset position if applicable
        if let x = copy.attribute(forName: "x")?.stringValue, let xv = Double(x) {
            copy.setSafeAttributes(["x": String(xv + offsetX)])
        }
        if let y = copy.attribute(forName: "y")?.stringValue, let yv = Double(y) {
            copy.setSafeAttributes(["y": String(yv + offsetY)])
        }
        if let cx = copy.attribute(forName: "cx")?.stringValue, let cxv = Double(cx) {
            copy.setSafeAttributes(["cx": String(cxv + offsetX)])
        }
        if let cy = copy.attribute(forName: "cy")?.stringValue, let cyv = Double(cy) {
            copy.setSafeAttributes(["cy": String(cyv + offsetY)])
        }

        parent.addChild(copy)
        isDirty = true
        return newId
    }

    // MARK: - Transform

    public func applyTransform(id: String, transform: SVGTransformValue, replace: Bool = false) -> Bool {
        guard let element = findElement(byId: id) else { return false }
        if replace {
            element.setSafeAttributes(["transform": transform.svgString])
        } else {
            let existing = element.attribute(forName: "transform")?.stringValue ?? ""
            let newTransform = existing.isEmpty ? transform.svgString : "\(existing) \(transform.svgString)"
            element.setSafeAttributes(["transform": newTransform])
        }
        isDirty = true
        return true
    }

    // MARK: - Style

    public func setStyle(id: String, style: SVGStyleProperties) -> Bool {
        guard let element = findElement(byId: id) else { return false }
        style.applyTo(element)
        isDirty = true
        return true
    }

    // MARK: - Gradients

    @discardableResult
    public func addLinearGradient(id: String, x1: String = "0%", y1: String = "0%",
                                  x2: String = "100%", y2: String = "0%",
                                  stops: [(offset: String, color: String, opacity: Double?)]) -> String {
        let defs = getOrCreateDefs()
        let gradient = XMLElement(name: "linearGradient")
        gradient.setSafeAttributes(["id": id, "x1": x1, "y1": y1, "x2": x2, "y2": y2])
        for stop in stops {
            let stopEl = XMLElement(name: "stop")
            stopEl.setSafeAttributes(["offset": stop.offset, "stop-color": stop.color])
            if let op = stop.opacity { stopEl.setSafeAttributes(["stop-opacity": String(op)]) }
            gradient.addChild(stopEl)
        }
        defs.addChild(gradient)
        isDirty = true
        return id
    }

    @discardableResult
    public func addRadialGradient(id: String, cx: String = "50%", cy: String = "50%",
                                  r: String = "50%", fx: String? = nil, fy: String? = nil,
                                  stops: [(offset: String, color: String, opacity: Double?)]) -> String {
        let defs = getOrCreateDefs()
        let gradient = XMLElement(name: "radialGradient")
        gradient.setSafeAttributes(["id": id, "cx": cx, "cy": cy, "r": r])
        if let fx = fx { gradient.setSafeAttributes(["fx": fx]) }
        if let fy = fy { gradient.setSafeAttributes(["fy": fy]) }
        for stop in stops {
            let stopEl = XMLElement(name: "stop")
            stopEl.setSafeAttributes(["offset": stop.offset, "stop-color": stop.color])
            if let op = stop.opacity { stopEl.setSafeAttributes(["stop-opacity": String(op)]) }
            gradient.addChild(stopEl)
        }
        defs.addChild(gradient)
        isDirty = true
        return id
    }

    private func getOrCreateDefs() -> XMLElement {
        guard let root = root else { fatalError("No root element") }
        if let existing = root.children?.compactMap({ $0 as? XMLElement }).first(where: { $0.localName == "defs" }) {
            return existing
        }
        let defs = XMLElement(name: "defs")
        root.insertChild(defs, at: 0)
        return defs
    }

    // MARK: - SVG Properties

    public func getSVGInfo() -> [String: String] {
        guard let root = root else { return [:] }
        var info: [String: String] = [:]
        for attr in root.attributes ?? [] {
            if let name = attr.name, let val = attr.stringValue {
                info[name] = val
            }
        }
        let elementCount = countElements(in: root)
        info["_element_count"] = String(elementCount)
        return info
    }

    private func countElements(in element: XMLElement) -> Int {
        var count = 0
        for child in element.children ?? [] {
            if let childEl = child as? XMLElement {
                count += 1 + countElements(in: childEl)
            }
        }
        return count
    }

    public func setViewBox(_ viewBox: String) {
        root?.setSafeAttributes(["viewBox": viewBox])
        isDirty = true
    }

    public func setSize(width: Double?, height: Double?) {
        if let w = width { root?.setSafeAttributes(["width": String(w)]) }
        if let h = height { root?.setSafeAttributes(["height": String(h)]) }
        isDirty = true
    }

    // MARK: - Serialization

    public func svgString(pretty: Bool = true) -> String {
        let opts: XMLNode.Options = pretty ? [.nodePrettyPrint] : []
        return xmlDocument.xmlString(options: opts)
    }

    public func save(to url: URL) throws {
        let data = xmlDocument.xmlData(options: [.nodePrettyPrint])
        try data.write(to: url)
        isDirty = false
    }

    // MARK: - Batch Operations

    public func batchSetStyle(ids: [String], style: SVGStyleProperties) -> Int {
        var count = 0
        for id in ids {
            if setStyle(id: id, style: style) { count += 1 }
        }
        return count
    }

    public func batchTransform(ids: [String], transform: SVGTransformValue, replace: Bool = false) -> Int {
        var count = 0
        for id in ids {
            if applyTransform(id: id, transform: transform, replace: replace) { count += 1 }
        }
        return count
    }

    // MARK: - All element IDs matching type

    public func allElementIds(ofType type: String? = nil) -> [String] {
        guard let root = root else { return [] }
        var ids: [String] = []
        collectIds(in: root, type: type, into: &ids)
        return ids
    }

    private func collectIds(in element: XMLElement, type: String?, into ids: inout [String]) {
        let localName = element.localName ?? element.name ?? ""
        if let t = type {
            if localName == t, let id = element.attribute(forName: "id")?.stringValue, !id.isEmpty {
                ids.append(id)
            }
        } else {
            if let id = element.attribute(forName: "id")?.stringValue, !id.isEmpty {
                ids.append(id)
            }
        }
        for child in element.children ?? [] {
            if let childEl = child as? XMLElement {
                collectIds(in: childEl, type: type, into: &ids)
            }
        }
    }
}
