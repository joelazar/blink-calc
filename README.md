# blink-calc

A [blink.cmp](https://github.com/Saghen/blink.cmp) source for basic math calculations, similar to [cmp-calc](https://github.com/hrsh7th/cmp-calc).

## Features

- Evaluates mathematical expressions in real-time as you type
- Supports basic arithmetic operations: `+`, `-`, `*`, `/`
- Supports parentheses for complex expressions
- Supports Lua's math library functions (sin, cos, sqrt, etc.)
- Provides two completion options:
  - Just the result
  - Expression with result (when typing with `=`)

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'saghen/blink.cmp',
  dependencies = { 'joelazar/blink-calc' },
  opts = {
    sources = {
      default = { 'lsp', 'path', 'snippets', 'buffer', 'calc' },
      providers = {
        calc = {
          name = 'Calc',
          module = 'blink-calc',
          opts = {
            show_equation = true, -- offer an extra "expr = result" item when typing '='
          },
        },
      },
    },
  },
}
```

## Configuration

Options are passed through the blink.cmp provider `opts` table:

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `show_equation` | `boolean` | `true` | Offer an extra `expr = result` item when typing with `=` |

## Usage

Simply type a mathematical expression and the completion menu will show the result:

- `2+2=` → suggests `4` and `2+2 = 4`
- `10*5+3` → suggests `53` and `10*5+3 = 53`
- `sqrt(16)` → suggests `4.0` and `sqrt(16) = 4.0`
- `sin(3.14159/2)` → suggests `1.0` and `sin(3.14159/2) = 1.0`

## Development

This plugin follows the [base.nvim](https://github.com/S1M0N38/base.nvim) project structure.

```bash
make test       # Run the test suite (mini.test via lazy.minit)
make lint       # Check formatting with StyLua
make typecheck  # Type check with lua-language-server
make check      # lint + typecheck + test
make dev        # Launch Neovim with repro/repro.lua
```

See [`:help blink-calc`](doc/blink-calc.txt) and [CONTRIBUTING.md](CONTRIBUTING.md) for details, and run `:checkhealth blink-calc` to verify your setup.

## License

MIT
