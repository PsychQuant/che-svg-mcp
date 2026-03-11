# che-svg-mcp

SVG 向量圖形操作 MCP Server. Swift 原生，本地運算，不依賴外部 API。

## Features

- Create and edit SVG files programmatically
- Shapes, paths, text, gradients, groups, transforms
- Session-based editing (open, edit, save lifecycle)
- Export to PNG/PDF via Core Graphics
- Batch operations (recolor, resize, style changes)

## Installation

### Claude Code CLI

```bash
mkdir -p ~/bin
# Download binary from releases
chmod +x ~/bin/CheSvgMCP
claude mcp add --scope user --transport stdio che-svg-mcp -- ~/bin/CheSvgMCP
```

## Tools

| Tool | Description |
|------|-------------|
| `hello_world` | A simple hello world tool |

*More tools coming in v0.2.0.*

## License

MIT
