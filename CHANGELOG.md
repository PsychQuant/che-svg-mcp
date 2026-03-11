# Changelog

## [0.1.0] - 2026-03-11

### Added
- Initial project structure with full SVG manipulation capabilities
- **Document Management**: create_svg, open_svg, save_svg, close_svg, list_documents
- **Element Creation**: add_rect, add_circle, add_ellipse, add_line, add_polyline, add_polygon, add_path, add_text, add_image, add_group
- **Element Operations**: list_elements, get_element, modify_element, delete_element, move_element, duplicate_element
- **Transform**: translate, rotate, scale, skewX, skewY, matrix (append or replace)
- **Style**: fill, stroke, opacity, fonts, dashes, line caps/joins
- **Gradients**: add_linear_gradient, add_radial_gradient with color stops
- **Export**: export_png, export_pdf via Core Graphics, get_preview (base64 PNG)
- **Batch**: batch_style, batch_transform for multi-element operations
- **Utility**: get_svg_info, set_viewbox, get_svg_text
- 33 tools total
- 24 unit tests (all passing)
