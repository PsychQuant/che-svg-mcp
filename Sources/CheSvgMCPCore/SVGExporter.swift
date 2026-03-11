import Foundation
#if canImport(AppKit)
import AppKit
import CoreGraphics

public class SVGExporter {

    /// Export SVG to PNG using WebView rendering
    public static func exportPNG(svg: SVGDocument, width: Int, height: Int, outputPath: String) async throws {
        let svgData = svg.svgString(pretty: false).data(using: .utf8)!
        let url = URL(fileURLWithPath: outputPath)

        // Use NSImage to render SVG
        guard let image = NSImage(data: svgData) else {
            throw SVGError.exportFailed("Failed to create image from SVG data")
        }

        let targetSize = NSSize(width: width, height: height)
        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: width,
            pixelsHigh: height,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )!

        NSGraphicsContext.saveGraphicsState()
        let ctx = NSGraphicsContext(bitmapImageRep: rep)
        NSGraphicsContext.current = ctx
        image.draw(in: NSRect(origin: .zero, size: targetSize),
                   from: NSRect(origin: .zero, size: image.size),
                   operation: .copy, fraction: 1.0)
        NSGraphicsContext.restoreGraphicsState()

        guard let pngData = rep.representation(using: .png, properties: [:]) else {
            throw SVGError.exportFailed("Failed to generate PNG data")
        }
        try pngData.write(to: url)
    }

    /// Export SVG to PDF using Core Graphics
    public static func exportPDF(svg: SVGDocument, width: Int, height: Int, outputPath: String) async throws {
        let svgData = svg.svgString(pretty: false).data(using: .utf8)!
        let url = URL(fileURLWithPath: outputPath) as CFURL

        guard let image = NSImage(data: svgData) else {
            throw SVGError.exportFailed("Failed to create image from SVG data")
        }

        let pageRect = CGRect(x: 0, y: 0, width: width, height: height)
        guard let context = CGContext(url, mediaBox: nil, nil) else {
            throw SVGError.exportFailed("Failed to create PDF context")
        }

        var mediaBox = pageRect
        context.beginPage(mediaBox: &mediaBox)

        let nsCtx = NSGraphicsContext(cgContext: context, flipped: false)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = nsCtx
        image.draw(in: NSRect(origin: .zero, size: NSSize(width: width, height: height)),
                   from: NSRect(origin: .zero, size: image.size),
                   operation: .copy, fraction: 1.0)
        NSGraphicsContext.restoreGraphicsState()

        context.endPage()
        context.closePDF()
    }

    /// Get a base64 PNG preview (for inline display)
    public static func getPreview(svg: SVGDocument, width: Int = 400, height: Int = 300) async throws -> String {
        let svgData = svg.svgString(pretty: false).data(using: .utf8)!
        guard let image = NSImage(data: svgData) else {
            throw SVGError.exportFailed("Failed to create image from SVG data")
        }

        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: width,
            pixelsHigh: height,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )!

        NSGraphicsContext.saveGraphicsState()
        let ctx = NSGraphicsContext(bitmapImageRep: rep)
        NSGraphicsContext.current = ctx
        image.draw(in: NSRect(origin: .zero, size: NSSize(width: width, height: height)),
                   from: NSRect(origin: .zero, size: image.size),
                   operation: .copy, fraction: 1.0)
        NSGraphicsContext.restoreGraphicsState()

        guard let pngData = rep.representation(using: .png, properties: [:]) else {
            throw SVGError.exportFailed("Failed to generate preview PNG")
        }
        return pngData.base64EncodedString()
    }
}
#else
// Stub for non-macOS platforms
public class SVGExporter {
    public static func exportPNG(svg: SVGDocument, width: Int, height: Int, outputPath: String) async throws {
        throw SVGError.exportFailed("PNG export requires macOS")
    }
    public static func exportPDF(svg: SVGDocument, width: Int, height: Int, outputPath: String) async throws {
        throw SVGError.exportFailed("PDF export requires macOS")
    }
    public static func getPreview(svg: SVGDocument, width: Int = 400, height: Int = 300) async throws -> String {
        throw SVGError.exportFailed("Preview requires macOS")
    }
}
#endif
