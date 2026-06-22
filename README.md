# blink-calc

A [blink.cmp](https://github.com/Saghen/blink.cmp) source for basic math calculations, similar to [cmp-calc](https://github.com/hrsh7th/cmp-calc).

## Features

Type an expression and the completion menu shows the result. Each feature below has an example of what you type and what you get back.

Arithmetic with `+`, `-`, `*`, `/`, power `^`, and parentheses:

```
2+2=         → 4   and   2+2 = 4
10*5+3       → 53
```

Lua math functions (`sin`, `cos`, `sqrt`, ...) plus `ln`, `log2`, `log10`, `mod`:

```
sqrt(16)     → 4
log2(8)      → 3
```

Trigonometry in radians or degrees (`angle = "deg"`):

```
sin(30)      → 0.5   (with angle = "deg")
```

Constants `pi`, `e`, `phi`, `tau`:

```
2*pi         → 6.28
```

Factorial and combinatorics (`fact`, `gcd`, `lcm`, `perm`, `comb`):

```
5!           → 120
gcd(12,18)   → 6
```

Statistics (`sum`, `avg`, `mean`, `median`, `min`, `max`):

```
avg(2,4,6)   → 4
```

Boolean and comparison expressions:

```
2+2 >= 3     → true
5 == 5       → true
```

Bitwise functions and infix operators (`5 & 3`, `12 | 3`, `12 ~ 10`, `1 << 4`, `16 >> 2`):

```
band(12,10)  → 8
5 & 3        → 1
1 << 4       → 16
```

Vectors (`vec`, `dot`, `cross`, `mag`, `norm`):

```
dot(vec(1,2,3), vec(4,5,6))   → 32
mag(vec(3,4))                 → 5
```

Percentages:

```
20% of 150   → 30
150 + 20%    → 180
50%          → 0.5
```

`ans` references the last accepted result:

```
ans + 2      → adds 2 to the last accepted result
```

Unit conversion with `to`/`in` or `convert`:

```
5 km to mi   → 3.11
100 cm in m  → 1
convert(100, "c", "f")   → 212
```

Currency conversion once you set `currency_rates` (see below):

```
100 usd to eur   → 92
convert(50, "gbp", "usd")   → 63
```

Date math:

```
2024-01-10 - 2024-01-01   → 9
today + 3 days            → a date
```

Number bases for input, with optional hex/binary result items (`show_bases`):

```
0xFF         → 255   (with show_bases, also 0xFF and 0b11111111)
```

Digit separators in input, with optional grouped result items (`group_digits`):

```
1_000_000    → 1000000   (with group_digits, also 1,000,000)
```

Scientific or fixed output notation (`notation`):

```
1500000      → 1.5e+06   (with notation = "scientific")
```

More behavior you configure rather than type:

- Reuse `x = 2+2` assignments from earlier buffer lines (`buffer_variables`)
- Works inside comments: ignores a leading `--`, `#`, `//`, `/*`, or `;`
- Context gating: disable per filetype, complete only inside comments, or require an operator
- Documentation popup with hex/binary/scientific/grouped forms (`show_documentation`)
- Copy the accepted result to a register (`copy_register`)
- Configurable result precision and equation separator

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
            precision = 2,        -- decimal places used to tame floating-point noise
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

| Option               | Type                                           | Default  | Description                                                                                                                                                                                                                                                                                                                                       |
| -------------------- | ---------------------------------------------- | -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `show_equation`      | `boolean`                                      | `true`   | Offer an extra `expr = result` item when typing with `=`                                                                                                                                                                                                                                                                                          |
| `show_bases`         | `boolean`                                      | `false`  | Offer hex and binary items for non-negative integer results                                                                                                                                                                                                                                                                                       |
| `group_digits`       | `boolean \| string`                            | `false`  | Offer a digit-grouped item for large integers; `true` uses `,`, or pass a custom separator                                                                                                                                                                                                                                                        |
| `precision`          | `integer`                                      | `2`      | Decimal places used to tame floating-point noise                                                                                                                                                                                                                                                                                                  |
| `separator`          | `string`                                       | `" = "`  | Text between expression and result in the equation item                                                                                                                                                                                                                                                                                           |
| `angle`              | `"rad" \| "deg"`                               | `"rad"`  | Angle unit used by trig functions (`sin`, `cos`, `asin`, ...)                                                                                                                                                                                                                                                                                     |
| `notation`           | `"auto" \| "fixed" \| "scientific"`            | `"auto"` | Output notation for numeric results                                                                                                                                                                                                                                                                                                               |
| `show_documentation` | `boolean`                                      | `true`   | Show hex/binary/scientific/grouped forms in the documentation popup                                                                                                                                                                                                                                                                               |
| `min_length`         | `integer`                                      | `0`      | Minimum expression length before completing                                                                                                                                                                                                                                                                                                       |
| `require_operator`   | `boolean`                                      | `false`  | Require an operator so bare numbers do not complete                                                                                                                                                                                                                                                                                               |
| `comment_only`       | `boolean`                                      | `false`  | Only complete inside comments or strings (uses treesitter when available)                                                                                                                                                                                                                                                                         |
| `disabled_filetypes` | `string[]`                                     | `{}`     | Filetypes in which the source is disabled                                                                                                                                                                                                                                                                                                         |
| `buffer_variables`   | `boolean`                                      | `false`  | Resolve `name = expr` assignments from earlier buffer lines                                                                                                                                                                                                                                                                                       |
| `copy_register`      | `false \| string`                              | `false`  | Register to copy the accepted result into (e.g. `"+"`)                                                                                                                                                                                                                                                                                            |
| `currency_rates`     | `table<string, number> \| fun(done) \| string` | `{}`     | Currency code → value in a shared base unit. A static table is used as-is; a function is an async provider invoked as `provider(done)` (call `done(rates)` when ready); a string names a built-in provider (e.g. `"er-api"`). Providers run off the completion path and are pulled at most once per `currency_cache_ttl` (results cached on disk) |
| `currency_cache_ttl` | `integer`                                      | `86400`  | Seconds a provider's rates are reused before re-pulling (default: once per day)                                                                                                                                                                                                                                                                   |

## Currency rates

Currency conversion needs exchange rates, which you supply through
`currency_rates`. The quickest setup names the built-in provider:

```lua
currency_rates = "er-api", -- async curl to open.er-api.com, pulled once per day
```

You can also pass a static `code -> rate` table, or a function that fetches
rates yourself. A function runs off the completion path and gets a `done`
callback, so it never blocks Neovim. Call `done(rates)` when the fetch finishes,
or `done({})` on failure to keep the cached rates. Results are cached on disk
and reused for `currency_cache_ttl` seconds (default `86400`).

Your provider must be non-blocking: use `vim.system`, not `vim.fn.system`, and
always pass a timeout.

```lua
currency_rates = function(done)
  vim.system(
    { "curl", "-s", "--max-time", "10", "https://open.er-api.com/v6/latest/USD" },
    { text = true },
    function(out)
      local ok, body = pcall(vim.json.decode, out.stdout or "")
      if not ok or not body or not body.rates then
        return done({})
      end
      -- API returns units per 1 USD; convert(value, from, to) uses
      -- value * rates[from] / rates[to], so invert to get USD per unit.
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
