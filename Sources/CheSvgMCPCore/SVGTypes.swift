import Foundation

// MARK: - Safe Attribute Setting

extension XMLElement {
    /// Set individual attributes without replacing existing ones.
    /// `setAttributesWith` replaces ALL attributes; this method adds/updates individually.
    func setSafeAttributes(_ dict: [String: String]) {
        for (key, value) in dict {
            if let existing = attribute(forName: key) {
                existing.stringValue = value
            } else {
                let node = XMLNode.attribute(withName: key, stringValue: value) as! XMLNode
                addAttribute(node)
            }
        }
    }
}

// MARK: - SVG Element Types

public enum SVGElementType: String {
    case rect, circle, ellipse, line, polyline, polygon, path, text, image, group = "g"
    case linearGradient, radialGradient, defs, clipPath, mask, pattern, use, symbol
    case svg
}

// MARK: - Transform

public struct SVGTransformValue {
    public enum Kind: String {
        case translate, rotate, scale, skewX, skewY, matrix
    }

    public let kind: Kind
    public let values: [Double]

    public var svgString: String {
        let valStr = values.map { String($0) }.joined(separator: ",")
        return "\(kind.rawValue)(\(valStr))"
    }
}

// MARK: - Style Properties

public struct SVGStyleProperties {
    public var fill: String?
    public var stroke: String?
    public var strokeWidth: Double?
    public var opacity: Double?
    public var fillOpacity: Double?
    public var strokeOpacity: Double?
    public var strokeLinecap: String?
    public var strokeLinejoin: String?
    public var strokeDasharray: String?
    public var fontFamily: String?
    public var fontSize: Double?
    public var fontWeight: String?
    public var textAnchor: String?
    public var dominantBaseline: String?
    public var display: String?
    public var visibility: String?

    public init() {}

    public func applyTo(_ element: XMLElement) {
        if let v = fill { element.setSafeAttributes(["fill": v]) }
        if let v = stroke { element.setSafeAttributes(["stroke": v]) }
        if let v = strokeWidth { element.setSafeAttributes(["stroke-width": String(v)]) }
        if let v = opacity { element.setSafeAttributes(["opacity": String(v)]) }
        if let v = fillOpacity { element.setSafeAttributes(["fill-opacity": String(v)]) }
        if let v = strokeOpacity { element.setSafeAttributes(["stroke-opacity": String(v)]) }
        if let v = strokeLinecap { element.setSafeAttributes(["stroke-linecap": v]) }
        if let v = strokeLinejoin { element.setSafeAttributes(["stroke-linejoin": v]) }
        if let v = strokeDasharray { element.setSafeAttributes(["stroke-dasharray": v]) }
        if let v = fontFamily { element.setSafeAttributes(["font-family": v]) }
        if let v = fontSize { element.setSafeAttributes(["font-size": String(v)]) }
        if let v = fontWeight { element.setSafeAttributes(["font-weight": v]) }
        if let v = textAnchor { element.setSafeAttributes(["text-anchor": v]) }
        if let v = dominantBaseline { element.setSafeAttributes(["dominant-baseline": v]) }
        if let v = display { element.setSafeAttributes(["display": v]) }
        if let v = visibility { element.setSafeAttributes(["visibility": v]) }
    }

    public static func from(_ dict: [String: Any]) -> SVGStyleProperties {
        var s = SVGStyleProperties()
        s.fill = dict["fill"] as? String
        s.stroke = dict["stroke"] as? String
        s.strokeWidth = dict["stroke_width"] as? Double
        s.opacity = dict["opacity"] as? Double
        s.fillOpacity = dict["fill_opacity"] as? Double
        s.strokeOpacity = dict["stroke_opacity"] as? Double
        s.strokeLinecap = dict["stroke_linecap"] as? String
        s.strokeLinejoin = dict["stroke_linejoin"] as? String
        s.strokeDasharray = dict["stroke_dasharray"] as? String
        s.fontFamily = dict["font_family"] as? String
        s.fontSize = dict["font_size"] as? Double
        s.fontWeight = dict["font_weight"] as? String
        s.textAnchor = dict["text_anchor"] as? String
        s.dominantBaseline = dict["dominant_baseline"] as? String
        s.display = dict["display"] as? String
        s.visibility = dict["visibility"] as? String
        return s
    }
}

// MARK: - Element Info (for listing)

public struct SVGElementInfo {
    public let id: String
    public let type: String
    public let attributes: [String: String]
    public let childCount: Int

    public var description: String {
        var parts = ["\(type)"]
        if !id.isEmpty { parts.append("id=\"\(id)\"") }
        for (k, v) in attributes.sorted(by: { $0.key < $1.key }) {
            if k != "id" { parts.append("\(k)=\"\(v)\"") }
        }
        if childCount > 0 { parts.append("children=\(childCount)") }
        return parts.joined(separator: " ")
    }
}
