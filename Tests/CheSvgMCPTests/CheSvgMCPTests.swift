import XCTest
@testable import CheSvgMCPCore

final class SVGDocumentTests: XCTestCase {

    // MARK: - Document Creation

    func testCreateDocument() {
        let doc = SVGDocument(width: 800, height: 600)
        XCTAssertNotNil(doc.root)
        XCTAssertEqual(doc.root?.attribute(forName: "width")?.stringValue, "800.0")
        XCTAssertEqual(doc.root?.attribute(forName: "height")?.stringValue, "600.0")
        XCTAssertFalse(doc.isDirty)
    }

    func testCreateDocumentWithViewBox() {
        let doc = SVGDocument(width: 100, height: 100, viewBox: "0 0 100 100")
        XCTAssertEqual(doc.root?.attribute(forName: "viewBox")?.stringValue, "0 0 100 100")
    }

    // MARK: - Adding Elements

    func testAddRect() {
        let doc = SVGDocument(width: 200, height: 200)
        let id = doc.addRect(x: 10, y: 20, width: 100, height: 50)
        XCTAssertFalse(id.isEmpty)
        XCTAssertTrue(doc.isDirty)

        let info = doc.getElement(id: id)
        XCTAssertNotNil(info)
        XCTAssertEqual(info?.type, "rect")
        XCTAssertEqual(info?.attributes["width"], "100.0")
    }

    func testAddCircle() {
        let doc = SVGDocument(width: 200, height: 200)
        let id = doc.addCircle(cx: 100, cy: 100, r: 50)
        let info = doc.getElement(id: id)
        XCTAssertEqual(info?.type, "circle")
        XCTAssertEqual(info?.attributes["r"], "50.0")
    }

    func testAddPath() {
        let doc = SVGDocument(width: 200, height: 200)
        let id = doc.addPath(d: "M10 10 L90 90 Z")
        let info = doc.getElement(id: id)
        XCTAssertEqual(info?.type, "path")
        XCTAssertEqual(info?.attributes["d"], "M10 10 L90 90 Z")
    }

    func testAddText() {
        let doc = SVGDocument(width: 200, height: 200)
        let id = doc.addText("Hello", x: 50, y: 50)
        let info = doc.getElement(id: id)
        XCTAssertEqual(info?.type, "text")
    }

    func testAddGroup() {
        let doc = SVGDocument(width: 200, height: 200)
        let groupId = doc.addGroup(id: "mygroup")
        let rectId = doc.addRect(x: 0, y: 0, width: 50, height: 50, parentId: groupId)

        let children = doc.listElements(parentId: groupId)
        XCTAssertEqual(children.count, 1)
        XCTAssertEqual(children.first?.id, rectId)
    }

    func testAddWithCustomId() {
        let doc = SVGDocument(width: 200, height: 200)
        let id = doc.addRect(x: 0, y: 0, width: 100, height: 100, id: "my-rect")
        XCTAssertEqual(id, "my-rect")
    }

    // MARK: - Element Operations

    func testListElements() {
        let doc = SVGDocument(width: 200, height: 200)
        doc.addRect(x: 0, y: 0, width: 100, height: 100)
        doc.addCircle(cx: 50, cy: 50, r: 25)
        let elements = doc.listElements()
        XCTAssertEqual(elements.count, 2)
    }

    func testModifyElement() {
        let doc = SVGDocument(width: 200, height: 200)
        let id = doc.addRect(x: 0, y: 0, width: 100, height: 100)
        let result = doc.modifyElement(id: id, attributes: ["fill": "red", "width": "200"])
        XCTAssertTrue(result)
        let info = doc.getElement(id: id)
        XCTAssertEqual(info?.attributes["fill"], "red")
        XCTAssertEqual(info?.attributes["width"], "200")
    }

    func testDeleteElement() {
        let doc = SVGDocument(width: 200, height: 200)
        let id = doc.addRect(x: 0, y: 0, width: 100, height: 100)
        XCTAssertTrue(doc.deleteElement(id: id))
        XCTAssertNil(doc.findElement(byId: id))
    }

    func testMoveElement() {
        let doc = SVGDocument(width: 200, height: 200)
        let groupId = doc.addGroup(id: "target")
        let rectId = doc.addRect(x: 0, y: 0, width: 50, height: 50)

        XCTAssertTrue(doc.moveElement(id: rectId, newParentId: groupId, index: nil))
        let children = doc.listElements(parentId: groupId)
        XCTAssertEqual(children.count, 1)
    }

    func testDuplicateElement() {
        let doc = SVGDocument(width: 200, height: 200)
        let id = doc.addRect(x: 10, y: 20, width: 100, height: 50)
        let newId = doc.duplicateElement(id: id)
        XCTAssertNotNil(newId)
        XCTAssertNotEqual(id, newId)

        let info = doc.getElement(id: newId!)
        XCTAssertEqual(info?.attributes["x"], "20.0") // offset by 10
    }

    // MARK: - Transform

    func testApplyTransform() {
        let doc = SVGDocument(width: 200, height: 200)
        let id = doc.addRect(x: 0, y: 0, width: 50, height: 50)
        let transform = SVGTransformValue(kind: .translate, values: [100, 50])
        XCTAssertTrue(doc.applyTransform(id: id, transform: transform))

        let element = doc.findElement(byId: id)
        XCTAssertEqual(element?.attribute(forName: "transform")?.stringValue, "translate(100.0,50.0)")
    }

    func testAppendTransform() {
        let doc = SVGDocument(width: 200, height: 200)
        let id = doc.addRect(x: 0, y: 0, width: 50, height: 50)
        doc.applyTransform(id: id, transform: SVGTransformValue(kind: .translate, values: [10, 20]))
        doc.applyTransform(id: id, transform: SVGTransformValue(kind: .rotate, values: [45]))

        let element = doc.findElement(byId: id)
        XCTAssertEqual(element?.attribute(forName: "transform")?.stringValue,
                       "translate(10.0,20.0) rotate(45.0)")
    }

    // MARK: - Style

    func testSetStyle() {
        let doc = SVGDocument(width: 200, height: 200)
        let id = doc.addRect(x: 0, y: 0, width: 100, height: 100)

        var style = SVGStyleProperties()
        style.fill = "#ff0000"
        style.stroke = "blue"
        style.strokeWidth = 2.0
        XCTAssertTrue(doc.setStyle(id: id, style: style))

        let element = doc.findElement(byId: id)
        XCTAssertEqual(element?.attribute(forName: "fill")?.stringValue, "#ff0000")
        XCTAssertEqual(element?.attribute(forName: "stroke")?.stringValue, "blue")
        XCTAssertEqual(element?.attribute(forName: "stroke-width")?.stringValue, "2.0")
    }

    // MARK: - Gradients

    func testAddLinearGradient() {
        let doc = SVGDocument(width: 200, height: 200)
        let gradId = doc.addLinearGradient(
            id: "grad1",
            stops: [
                (offset: "0%", color: "red", opacity: nil),
                (offset: "100%", color: "blue", opacity: 0.5)
            ]
        )
        XCTAssertEqual(gradId, "grad1")

        let defs = doc.root?.children?.compactMap { $0 as? XMLElement }.first { $0.localName == "defs" }
        XCTAssertNotNil(defs)

        let gradient = defs?.children?.compactMap { $0 as? XMLElement }
            .first { $0.attribute(forName: "id")?.stringValue == "grad1" }
        XCTAssertNotNil(gradient)
        XCTAssertEqual(gradient?.localName, "linearGradient")
    }

    // MARK: - SVG Properties

    func testGetSVGInfo() {
        let doc = SVGDocument(width: 400, height: 300)
        doc.addRect(x: 0, y: 0, width: 100, height: 100)
        let info = doc.getSVGInfo()
        XCTAssertEqual(info["width"], "400.0")
        XCTAssertEqual(info["_element_count"], "1")
    }

    func testSetViewBox() {
        let doc = SVGDocument(width: 800, height: 600)
        doc.setViewBox("0 0 100 100")
        XCTAssertEqual(doc.root?.attribute(forName: "viewBox")?.stringValue, "0 0 100 100")
    }

    // MARK: - Serialization

    func testSVGString() {
        let doc = SVGDocument(width: 200, height: 200)
        doc.addRect(x: 10, y: 10, width: 50, height: 50, id: "r1")
        let xml = doc.svgString()
        XCTAssertTrue(xml.contains("<rect"))
        XCTAssertTrue(xml.contains("id=\"r1\""))
    }

    // MARK: - Batch Operations

    func testBatchSetStyle() {
        let doc = SVGDocument(width: 200, height: 200)
        let id1 = doc.addRect(x: 0, y: 0, width: 50, height: 50)
        let id2 = doc.addCircle(cx: 100, cy: 100, r: 25)

        var style = SVGStyleProperties()
        style.fill = "green"
        let count = doc.batchSetStyle(ids: [id1, id2], style: style)
        XCTAssertEqual(count, 2)

        XCTAssertEqual(doc.findElement(byId: id1)?.attribute(forName: "fill")?.stringValue, "green")
        XCTAssertEqual(doc.findElement(byId: id2)?.attribute(forName: "fill")?.stringValue, "green")
    }

    // MARK: - Document Manager

    func testDocumentManagerCreateAndClose() {
        let manager = SVGDocumentManager()
        let (id, _) = manager.createDocument(width: 100, height: 100)
        XCTAssertNotNil(manager.getDocument(id))
        XCTAssertTrue(manager.closeDocument(docId: id))
        XCTAssertNil(manager.getDocument(id))
    }

    func testDocumentManagerList() {
        let manager = SVGDocumentManager()
        _ = manager.createDocument(width: 100, height: 100, docId: "a")
        _ = manager.createDocument(width: 200, height: 200, docId: "b")
        let docs = manager.listDocuments()
        XCTAssertEqual(docs.count, 2)
    }

    func testDocumentManagerSaveAndReopen() throws {
        let manager = SVGDocumentManager()
        let (id, doc) = manager.createDocument(width: 300, height: 200, docId: "test")
        doc.addRect(x: 0, y: 0, width: 100, height: 100, id: "r1")

        let tmpPath = NSTemporaryDirectory() + "test_svg_\(UUID().uuidString).svg"
        try manager.saveDocument(docId: id, path: tmpPath)
        manager.closeDocument(docId: id)

        let (id2, doc2) = try manager.openDocument(path: tmpPath)
        let elements = doc2.listElements()
        XCTAssertTrue(elements.contains { $0.id == "r1" })
        manager.closeDocument(docId: id2)

        try? FileManager.default.removeItem(atPath: tmpPath)
    }
}
