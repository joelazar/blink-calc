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
  return {
    "0",
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8",
    "9",
    "+",
    "-",
    "*",
    "/",
    "=",
    "(",
    ")",
    "%",
    "!",
    "<",
    ">",
    "&",
    "|",
  }
end

---@return boolean
function source:enabled()
  local disabled = self.opts.disabled_filetypes
  if disabled and #disabled > 0 then
    local ft = vim.bo[vim.api.nvim_get_current_buf()].filetype
    if vim.tbl_contains(disabled, ft) then
      return false
    end
  end
  return true
end

-- Treesitter-aware comment/string test, falling back to a leading-marker
-- heuristic when no parser is available.
local COMMENT_MARKERS = { "--", "#", "//", "/*", ";" }

local function in_comment(ctx)
  if vim.treesitter and vim.treesitter.get_parser then
    local ok, parser = pcall(vim.treesitter.get_parser, ctx.bufnr)
    if ok and parser then
      local node = vim.treesitter.get_node({
        bufnr = ctx.bufnr,
        pos = { ctx.cursor[1] - 1, math.max(ctx.cursor[2] - 1, 0) },
      })
      while node do
        local t = node:type()
        if t:find("comment") or t:find("string") then
          return true
        end
        node = node:parent()
      end
      return false
    end
  end
  local lead = vim.trim(ctx.line:sub(1, ctx.cursor[2]))
  for _, marker in ipairs(COMMENT_MARKERS) do
    if lead:sub(1, #marker) == marker then
      return true
    end
  end
  return false
end

---@param expr string normalized (comment-stripped) expression
---@param opts BlinkCalc.Options
---@return boolean
local function passes_gating(expr, opts)
  if #expr < opts.min_length then
    return false
  end
  if opts.require_operator and expr:match("^%-?[%d%._]+%%?$") then
    return false
  end
  return true
end

---@param result number
---@param opts BlinkCalc.Options
---@return lsp.MarkupContent?
local function build_documentation(result, opts)
  if not opts.show_documentation or type(result) ~= "number" then
    return nil
  end
  local Calc = require("blink-calc.calc")
  local lines = {}
  local is_int = result == math.floor(result) and math.abs(result) < 2 ^ 53
  if is_int and result >= 0 then
    lines[#lines + 1] = "hex: " .. Calc.to_hex(result)
    lines[#lines + 1] = "bin: " .. Calc.to_bin(result)
  end
  lines[#lines + 1] = "sci: " .. Calc.format(result, { notation = "scientific", precision = opts.precision })
  if is_int then
    lines[#lines + 1] = "grouped: " .. Calc.group(Calc.format(result, opts), ",")
  end
  if #lines == 0 then
    return nil
  end
  return { kind = "markdown", value = table.concat(lines, "\n") }
end

---@param ctx blink.cmp.Context
---@param callback fun(response?: blink.cmp.CompletionResponse)
function source:get_completions(ctx, callback)
  local Calc = require("blink-calc.calc")
  local line = ctx.line
  local col = ctx.cursor[2]

  if self.opts.comment_only and not in_comment(ctx) then
    return callback()
  end

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

  if expr:match("[^<>=~!]=%s*[%d%.]+$") then
    return callback()
  end

  local expr_without_eq = expr:gsub("=$", "")
  if not expr_without_eq:match("[%w%+%-%*/%.%(%)]") then
    return callback()
  end

  if not passes_gating(expr, self.opts) then
    return callback()
  end

  local eval_opts = self.opts
  if self.opts.buffer_variables then
    local row = ctx.cursor[1]
    local lines = vim.api.nvim_buf_get_lines(ctx.bufnr, 0, row - 1, false)
    eval_opts = vim.tbl_extend("force", {}, self.opts, { variables = Calc.scan_variables(lines) })
  end

  local result = Calc.evaluate(expr, eval_opts)
  if result == nil then
    return callback()
  end

  local result_str = Calc.format(result, self.opts)
  local kind = value_kind()

  ---@type lsp.Range
  local range = {
    start = { line = ctx.cursor[1] - 1, character = expr_start_col - 1 },
    ["end"] = { line = ctx.cursor[1] - 1, character = col },
  }

  local filter_text = line:sub(expr_start_col, col)
  local documentation = build_documentation(result, self.opts)
  local function item(text)
    return {
      label = text,
      kind = kind,
      filterText = filter_text,
      textEdit = { newText = text, range = range },
      documentation = documentation,
      data = { value = result, copy = text },
    }
  end

  local items = { item(result_str) }

  if type(result) == "number" then
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
  end

  local ends_with_eq = line:sub(col, col) == "=" or (col > 0 and line:sub(col - 1, col - 1) == "=")
  if self.opts.show_equation and ends_with_eq then
    local clean_expr = expr:gsub("=$", ""):gsub("%s+", " "):match("^%s*(.-)%s*$")
    table.insert(items, item(clean_expr .. self.opts.separator .. result_str))
  end

  callback({ items = items })
end

---Accept hook: update `ans` and optionally copy the result to a register.
---@param ctx blink.cmp.Context
---@param item lsp.CompletionItem
---@param callback fun()
---@param default_implementation? fun()
function source:execute(ctx, item, callback, default_implementation)
  if type(default_implementation) == "function" then
    default_implementation()
  end
  local Calc = require("blink-calc.calc")
  if item.data then
    if type(item.data.value) == "number" then
      Calc.set_ans(item.data.value)
    end
    if self.opts.copy_register and item.data.copy ~= nil then
      vim.fn.setreg(self.opts.copy_register, tostring(item.data.copy))
    end
  end
  if type(callback) == "function" then
    callback()
  end
end

return source
