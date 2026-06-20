# blink-calc

A [blink.cmp](https://github.com/Saghen/blink.cmp) source for basic math calculations, similar to [cmp-calc](https://github.com/hrsh7th/cmp-calc).

## Features

- Evaluates mathematical expressions in real-time as you type
- Basic arithmetic: `+`, `-`, `*`, `/`, and parentheses
- Lua math library functions (`sin`, `cos`, `sqrt`, ...) plus `ln`, `log2`, `log10`, `mod`
- Constants: `pi`, `e`, `phi`, `tau`
- Factorial `5!` and combinatorics: `fact`, `gcd`, `lcm`, `perm`, `comb`
- Statistics: `sum`, `avg`, `mean`, `median`, `min`, `max`
- Bitwise functions: `band`, `bor`, `bxor`, `bnot`, `lshift`, `rshift`
- Percentages: `20% of 150`, `150 + 20%`, `50%`
- Number bases: `0xFF`/`0b1010` input and optional hex/binary result items
- Digit separators in input (`1_000_000`) and optional grouped result items
- Configurable result precision and equation separator
- Completion items: the bare result, the full `expr = result`, and optional base/grouped items

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
            show_bases = false,   -- offer hex/binary items for integer results
            group_digits = false, -- offer a digit-grouped item; true uses ',' or pass a custom separator
            precision = 10,       -- decimal places used to tame floating-point noise
            separator = ' = ',    -- text between expression and result in the equation item
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
| `show_bases` | `boolean` | `false` | Offer hex and binary items for non-negative integer results |
| `group_digits` | `boolean \| string` | `false` | Offer a digit-grouped item for large integers; `true` uses `,`, or pass a custom separator |
| `precision` | `integer` | `10` | Decimal places used to tame floating-point noise |
| `separator` | `string` | `" = "` | Text between expression and result in the equation item |

## Usage

Simply type a mathematical expression and the completion menu will show the result:

- `2+2=` → suggests `4` and `2+2 = 4`
- `10*5+3` → suggests `53` and `10*5+3 = 53`
- `sqrt(16)` → suggests `4`
- `5!` → suggests `120`
- `gcd(12,18)` → suggests `6`
- `avg(2,4,6)` → suggests `4`
- `20% of 150` → suggests `30`
- `150 + 20%` → suggests `180`
- `band(12,10)` → suggests `8`
- `0xFF` → suggests `255` (with `show_bases`, also `0xFF` and `0b11111111`)
- `1_000_000` → suggests `1000000` (with `group_digits`, also `1,000,000`)

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
