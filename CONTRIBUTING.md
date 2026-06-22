# Contributing to blink-calc

Thank you for your interest in contributing to blink-calc!

## Development Setup

### Prerequisites

| Tool                                                                | Version  | Required for  | Install                                                           |
| ------------------------------------------------------------------- | -------- | ------------- | ----------------------------------------------------------------- |
| [Neovim](https://github.com/neovim/neovim)                          | ≥ 0.12.3 | tests, dev    | [releases](https://github.com/neovim/neovim/releases)             |
| [StyLua](https://github.com/JohnnyMorganz/StyLua)                   | 2.4.1    | lint, format  | [releases](https://github.com/JohnnyMorganz/StyLua/releases)      |
| [lua-language-server](https://github.com/LuaLS/lua-language-server) | latest   | type checking | [releases](https://github.com/LuaLS/lua-language-server/releases) |

### Clone and verify

```bash
git clone https://github.com/joelazar/blink-calc.git
cd blink-calc
make check
```

Tests auto-install their dependencies ([mini.test](https://github.com/echasnovski/mini.test) + [luassert](https://github.com/lunarmodules/luassert)) via [lazy.minit](https://github.com/folke/lazy.nvim) on first run.

## Make Targets

| Target                      | Description                                        |
| --------------------------- | -------------------------------------------------- |
| `make test`                 | Run all tests                                      |
| `make test-one MODULE=calc` | Run a single test file (`tests/calc_spec.lua`)     |
| `make lint`                 | Check formatting with StyLua (`--check`)           |
| `make format`               | Auto-format Lua files with StyLua                  |
| `make typecheck`            | Type check with lua-language-server                |
| `make check`                | Run lint + typecheck + test                        |
| `make dev`                  | Launch Neovim with repro config for manual testing |

## Project Layout

```
lua/blink-calc/
├── init.lua      # blink.cmp source object
├── calc.lua      # pure expression evaluation
├── config.lua    # option defaults and validation
├── util.lua      # notifications
├── health.lua    # :checkhealth blink-calc
└── types.lua     # LuaCATS type definitions
tests/
├── minit.lua         # lazy.minit bootstrap
├── calc_spec.lua     # source + evaluation tests
└── health_spec.lua   # health check tests
```

## Commits

Use [conventional commits](https://www.conventionalcommits.org/) for automatic
versioning via release-please:

- `feat:` — new features (minor bump)
- `fix:` — bug fixes (patch bump)
- `docs:` — documentation changes
- `test:` — adding or updating tests
- `refactor:` — code refactoring without behavior changes

## CI

| Workflow               | Trigger           | Jobs                                                                 |
| ---------------------- | ----------------- | -------------------------------------------------------------------- |
| `ci.yml`               | Push/PR to `main` | StyLua lint, lua-language-server typecheck, tests (stable + nightly) |
| `release-github.yml`   | Push to `main`    | release-please (changelog + GitHub release)                          |
| `release-luarocks.yml` | Tag `v*.*.*`      | LuaRocks publish                                                     |
