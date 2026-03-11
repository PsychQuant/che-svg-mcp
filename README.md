# che-svg-mcp

SVG 向量圖形操作 MCP Server. Swift 原生，本地運算，不依賴外部 API。

## Features

- Create and edit SVG files programmatically
- All standard shapes: rect, circle, ellipse, line, polyline, polygon, path
- Text, images, and group containers
- Gradients (linear, radial) with color stops
- Transforms (translate, rotate, scale, skew, matrix)
- Full style control (fill, stroke, opacity, fonts, dashes)
- Session-based editing (open → edit → save → close)
- Export to PNG/PDF via Core Graphics
- Batch operations (apply styles/transforms to multiple elements)

## Installation

### Claude Code CLI

```bash
mkdir -p ~/bin
# Download binary from releases
chmod +x ~/bin/CheSvgMCP
claude mcp add --scope user --transport stdio che-svg-mcp -- ~/bin/CheSvgMCP
```

## Tools

### Document Management

| Tool | Description |
|------|-------------|
| `create_svg` | Create a new empty SVG document |
| `open_svg` | Open an existing SVG file for editing |
| `save_svg` | Save an open document to disk |
| `close_svg` | Close a document and release memory |
| `list_documents` | List all open documents |

### Element Creation

| Tool | Description |
|------|-------------|
| `add_rect` | Add a rectangle |
| `add_circle` | Add a circle |
| `add_ellipse` | Add an ellipse |
| `add_line` | Add a line |
| `add_polyline` | Add a polyline (open shape) |
| `add_polygon` | Add a polygon (closed shape) |
| `add_path` | Add a path (SVG path data) |
| `add_text` | Add text |
| `add_image` | Add an image (embedded or linked) |
| `add_group` | Add a group container |

### Element Operations

| Tool | Description |
|------|-------------|
| `list_elements` | List child elements |
| `get_element` | Get element details |
| `modify_element` | Modify element attributes |
| `delete_element` | Delete an element |
| `move_element` | Move/reorder an element |
| `duplicate_element` | Duplicate with offset |

### Style & Transform

| Tool | Description |
|------|-------------|
| `set_style` | Set fill, stroke, opacity, fonts |
| `transform` | Apply translate, rotate, scale, skew, matrix |
| `add_linear_gradient` | Create a linear gradient |
| `add_radial_gradient` | Create a radial gradient |

### Export & Utility

| Tool | Description |
|------|-------------|
| `export_png` | Export to PNG via Core Graphics |
| `export_pdf` | Export to PDF via Core Graphics |
| `get_preview` | Get base64 PNG preview |
| `get_svg_info` | Get document properties |
| `set_viewbox` | Set viewBox and dimensions |
| `get_svg_text` | Get raw SVG XML |
| `batch_style` | Apply style to multiple elements |
| `batch_transform` | Apply transform to multiple elements |

## License

MIT
