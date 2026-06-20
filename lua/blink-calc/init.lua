---@class BlinkCalc.Source
local source = {}

local function value_kind()
  local ok, types = pcall(require, "blink.cmp.types")
  return ok and types.CompletionItemKind.Value or 12
end

---@param opts? BlinkCalc.UserOptions
---@return BlinkCalc.Source
function source.new(opts)
  local self = setmetatable({}, { __index = source })
  self.opts = require("blink-calc.config").merge(opts)
  return self
end

---@return string[]
function source:get_trigger_characters()
  return { "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "+", "-", "*", "/", "=", "(", ")", "%", "!" }
end

---@return boolean
function source:enabled()
  return true
end

---@param ctx blink.cmp.Context
---@param callback fun(response?: blink.cmp.CompletionResponse)
function source:get_completions(ctx, callback)
  local Calc = require("blink-calc.calc")
  local line = ctx.line
  local col = ctx.cursor[2]

  local start_col = Calc.find_expression_start(line, col)
  local expr = line:sub(start_col, col)
  local chars_removed = 0

  local leading_spaces = expr:match("^(%s*)")
  if leading_spaces then
    chars_removed = chars_removed + #leading_spaces
    expr = expr:sub(#leading_spaces + 1)
  end

  local before_len = #expr
  expr = expr:gsub("^%-%-+%s*", "")
  expr = expr:gsub("^#+%s*", "")
  expr = expr:gsub("^//+%s*", "")
  expr = expr:gsub("^/%*+%s*", "")
  chars_removed = chars_removed + (before_len - #expr)

  expr = expr:match("^(.-)%s*$") or expr

  local expr_start_col = start_col + chars_removed

  if expr:match("=%s*[%d%.]+$") then
    return callback()
  end

  local expr_without_eq = expr:gsub("=$", "")
  if not expr_without_eq:match("[%d%+%-%*/%.%(%)]") then
    return callback()
  end

  local result = Calc.evaluate(expr)
  if not result then
    return callback()
  end

  local result_str = Calc.format(result, self.opts.precision)
  local kind = value_kind()

  ---@type lsp.Range
  local range = {
    start = { line = ctx.cursor[1] - 1, character = expr_start_col - 1 },
    ["end"] = { line = ctx.cursor[1] - 1, character = col },
  }

  local function item(text)
    return { label = text, kind = kind, textEdit = { newText = text, range = range } }
  end

  local items = { item(result_str) }

  local is_int = result == math.floor(result) and math.abs(result) < 2 ^ 53
  if self.opts.show_bases and is_int and result >= 0 then
    table.insert(items, item(Calc.to_hex(result)))
    table.insert(items, item(Calc.to_bin(result)))
  end

  if self.opts.group_digits and is_int then
    local grouped = Calc.group(result_str, self.opts.group_digits)
    if grouped ~= result_str then
      table.insert(items, item(grouped))
    end
  end

  local ends_with_eq = line:sub(col, col) == "=" or (col > 0 and line:sub(col - 1, col - 1) == "=")
  if self.opts.show_equation and ends_with_eq then
    local clean_expr = expr:gsub("=$", ""):gsub("%s+", " "):match("^%s*(.-)%s*$")
    table.insert(items, item(clean_expr .. self.opts.separator .. result_str))
  end

  callback({ items = items })
end

return source
