# blink-calc

A [blink.cmp](https://github.com/Saghen/blink.cmp) source for basic math calculations, similar to [cmp-calc](https://github.com/hrsh7th/cmp-calc).

## Features

- Evaluates mathematical expressions in real-time as you type
- Basic arithmetic: `+`, `-`, `*`, `/`, power `^`, and parentheses
- Lua math library functions (`sin`, `cos`, `sqrt`, ...) plus `ln`, `log2`, `log10`, `mod`
- Trigonometry in radians or degrees (`angle = "deg"`)
- Constants: `pi`, `e`, `phi`, `tau`
- Factorial `5!` and combinatorics: `fact`, `gcd`, `lcm`, `perm`, `comb`
- Statistics: `sum`, `avg`, `mean`, `median`, `min`, `max`
- Boolean & comparison expressions: `2+2 >= 3`, `5 == 5`, `5 ~= 6`
- Bitwise functions plus infix operators: `5 & 3`, `12 | 3`, `12 ~ 10`, `1 << 4`, `16 >> 2`
- Vectors: `vec`, `dot`, `cross`, `mag`, `norm`
- Percentages: `20% of 150`, `150 + 20%`, `50%`
- `ans` references the last accepted result (e.g. `ans + 2`)
- Number bases: `0xFF`/`0b1010` input and optional hex/binary result items
- Scientific / fixed output notation (`notation`)
- Digit separators in input (`1_000_000`) and optional grouped result items
- Unit & currency conversion: `5 km to mi`, `100 cm in m`, `convert(100, "c", "f")` (currencies via `currency_rates`)
- Date math: `2024-01-10 - 2024-01-01`, `today + 3 days`
- Optional buffer variables: reuse `x = 2+2` from earlier lines (`buffer_variables`)
- Works inside comments: ignores a leading `--`, `#`, `//`, `/*`, or `;`
- Context gating: disable per filetype, complete only inside comments, or require an operator
- Rich documentation popup with hex/binary/scientific/grouped forms (`show_documentation`)
- Copy the accepted result to a register (`copy_register`)
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
            precision = 4,        -- decimal places used to tame floating-point noise
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
| `precision` | `integer` | `4` | Decimal places used to tame floating-point noise |
| `separator` | `string` | `" = "` | Text between expression and result in the equation item |
| `angle` | `"rad" \| "deg"` | `"rad"` | Angle unit used by trig functions (`sin`, `cos`, `asin`, ...) |
| `notation` | `"auto" \| "fixed" \| "scientific"` | `"auto"` | Output notation for numeric results |
| `show_documentation` | `boolean` | `true` | Show hex/binary/scientific/grouped forms in the documentation popup |
| `min_length` | `integer` | `0` | Minimum expression length before completing |
| `require_operator` | `boolean` | `false` | Require an operator so bare numbers do not complete |
| `comment_only` | `boolean` | `false` | Only complete inside comments or strings (uses treesitter when available) |
| `disabled_filetypes` | `string[]` | `{}` | Filetypes in which the source is disabled |
| `buffer_variables` | `boolean` | `false` | Resolve `name = expr` assignments from earlier buffer lines |
| `copy_register` | `false \| string` | `false` | Register to copy the accepted result into (e.g. `"+"`) |
| `currency_rates` | `table<string, number> \| fun(done) \| string` | `{}` | Currency code → value in a shared base unit. A static table is used as-is; a function is an async provider invoked as `provider(done)` (call `done(rates)` when ready); a string names a built-in provider (e.g. `"er-api"`). Providers run off the completion path and are pulled at most once per `currency_cache_ttl` (results cached on disk) |
| `currency_cache_ttl` | `integer` | `86400` | Seconds a provider's rates are reused before re-pulling (default: once per day) |

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
- `5 & 3` → suggests `1`; `1 << 4` → suggests `16`
- `2+2 >= 3` → suggests `true`
- `sin(30)` → suggests `0.5` (with `angle = "deg"`)
- `dot(vec(1,2,3), vec(4,5,6))` → suggests `32`; `mag(vec(3,4))` → suggests `5`
- `ans + 2` → adds `2` to the last accepted result
- `5 km to mi` → suggests `3.1069`; `convert(100, "c", "f")` → suggests `212`
- `2024-01-10 - 2024-01-01` → suggests `9`; `today + 3 days` → suggests a date
- `0xFF` → suggests `255` (with `show_bases`, also `0xFF` and `0b11111111`)
- `1_000_000` → suggests `1000000` (with `group_digits`, also `1,000,000`)
- `1500000` → suggests `1.5e+06` (with `notation = "scientific"`)

### Daily currency rates

The quickest setup uses a built-in provider by name:

```lua
currency_rates = "er-api", -- async curl to open.er-api.com, pulled once per day
```

`currency_rates` can also be a **function** provider. It is **async**: the
plugin schedules it off the completion path and hands it a `done` callback, so
it never blocks Neovim. Call `done(rates)` with a `code -> rate` table when your
fetch finishes (call `done({})` on failure to keep the previous cached rates).
Results are persisted to disk under `stdpath("cache")` and reused for
`currency_cache_ttl` seconds (default `86400` — once per day), even across
restarts. Until the first fetch resolves, conversions use the cached (or empty)
rates; they never wait on the network.

> **Your provider must be non-blocking.** Use `vim.system` (async) rather than
> `vim.fn.system`, and always pass a timeout so a hung host cannot wedge the
> fetch. A blocking provider defeats the point and can freeze the editor.

The plugin stays network-free itself — you decide how rates are fetched:

```lua
currency_rates = function(done)
  -- runs once per day, off the completion path; never block here
  vim.system(
    { "curl", "-s", "--max-time", "10", "https://open.er-api.com/v6/latest/USD" },
    { text = true },
    function(out)
      local ok, body = pcall(vim.json.decode, out.stdout or "")
      if not ok or not body or not body.rates then
        return done({}) -- empty -> previous cached rates are kept
      end
      -- this API returns "units of <code> per 1 USD"; convert(value, from, to)
      -- uses value * rates[from] / rates[to], so invert to get "USD per unit".
      local rates = {}
      for code, per_usd in pairs(body.rates) do
        rates[code:lower()] = 1 / per_usd
      end
      done(rates)
    end
  )
end,
```

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
