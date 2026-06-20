---@meta _
--- Definition file for LuaLS type information. Not loaded at runtime.
--- See: https://luals.github.io/wiki/definition-files/

-- blink.cmp (minimal subset used by the source) -------------------------------

---@class blink.cmp.Context
---@field line string current line text
---@field cursor integer[] { row (1-indexed), col (0-indexed) }
---@field bufnr integer buffer handle

---@class blink.cmp.CompletionResponse
---@field items lsp.CompletionItem[] completion items

-- lua/blink-calc/init.lua -----------------------------------------------------

---@class BlinkCalc.Source
---@field opts BlinkCalc.Options merged source options
---@field new fun(opts?: BlinkCalc.UserOptions): BlinkCalc.Source construct a blink.cmp source
---@field get_trigger_characters fun(self: BlinkCalc.Source): string[] characters that trigger completion
---@field enabled fun(self: BlinkCalc.Source): boolean whether the source is active
---@field get_completions fun(self: BlinkCalc.Source, ctx: blink.cmp.Context, callback: fun(response?: blink.cmp.CompletionResponse)) produce calc completions

-- lua/blink-calc/config.lua ---------------------------------------------------

---@class BlinkCalc.Config
---@field defaults BlinkCalc.DefaultOptions default options table
---@field merge fun(opts?: BlinkCalc.UserOptions): BlinkCalc.Options merge and validate user options

---@class BlinkCalc.UserOptions
---@field show_equation? boolean offer an extra "expr = result" item when typing with '=' (optional)

---@class BlinkCalc.DefaultOptions
---@field show_equation boolean offer an extra "expr = result" item when typing with '='

---@class BlinkCalc.Options
---@field show_equation boolean offer an extra "expr = result" item when typing with '='

-- lua/blink-calc/calc.lua -----------------------------------------------------

---@class BlinkCalc.Calc
---@field find_expression_start fun(line: string, col: integer): integer find 1-indexed start of expression
---@field resolve_math_functions fun(expr: string): string qualify bare math functions and aliases
---@field evaluate fun(expr: string): number|string|nil evaluate a math expression

-- lua/blink-calc/util.lua -----------------------------------------------------

---@class BlinkCalc.Util
---@field notify fun(msg: string|table, level?: integer) send notification with plugin title
---@field info fun(msg: string) send info notification
---@field warn fun(msg: string) send warning notification
---@field error fun(msg: string) send error notification

-- lua/blink-calc/health.lua ---------------------------------------------------

---@class BlinkCalc.Health
---@field check fun() perform health check for the plugin
