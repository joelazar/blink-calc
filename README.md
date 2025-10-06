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
  dependencies = { { "joelazar/blink-calc" } },
  opts = {
    sources = {
      default = { 'lsp', 'path', 'snippets', 'buffer', 'calc' },
      providers = {
        calc = {
          name = 'Calc',
          module = 'blink-calc',
        },
      },
    },
  },
}
```

## Usage

Simply type a mathematical expression and the completion menu will show the result:

- `2+2` → suggests `4`
- `10*5+3` → suggests `53`
- `sqrt(16)` → suggests `4.0`
- `sin(3.14159/2)` → suggests `1.0`
- `2+2=` → suggests `4` and `2+2 = 4`

## Testing

Run the test suite with:

```bash
nvim --headless -c "luafile tests/test_calc.lua" -c "qa"
```

## License

MIT
