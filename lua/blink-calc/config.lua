---@class BlinkCalc.Config
local M = {}

---@class BlinkCalc.DefaultOptions
local defaults = {
  show_equation = true,
  show_bases = false,
  group_digits = false,
  precision = 2,
  separator = " = ",
  angle = "rad",
  notation = "auto",
  show_documentation = true,
  min_length = 0,
  require_operator = false,
  comment_only = false,
  disabled_filetypes = {},
  buffer_variables = false,
  copy_register = false,
  currency_rates = {},
  currency_cache_ttl = 86400,
}

M.defaults = defaults

---Merge user options over defaults and validate them
---@param opts? BlinkCalc.UserOptions
---@return BlinkCalc.Options
function M.merge(opts)
  local config = vim.tbl_deep_extend("force", {}, vim.deepcopy(defaults), opts or {})
  local Util = require("blink-calc.util")

  local function reset(key, expected)
    Util.error(("Invalid '%s' option: expected %s, got %s"):format(key, expected, type(config[key])))
    config[key] = vim.deepcopy(defaults[key] --[[@as any]])
  end

  if type(config.show_equation) ~= "boolean" then
    reset("show_equation", "boolean")
  end

  if type(config.show_bases) ~= "boolean" then
    reset("show_bases", "boolean")
  end

  if config.group_digits == true then
    config.group_digits = ","
  elseif config.group_digits ~= false and type(config.group_digits) ~= "string" then
    reset("group_digits", "boolean or string")
  end

  if type(config.precision) ~= "number" or config.precision < 0 then
    reset("precision", "non-negative number")
  end

  if type(config.separator) ~= "string" then
    reset("separator", "string")
  end

  if config.angle ~= "rad" and config.angle ~= "deg" then
    reset("angle", '"rad" or "deg"')
  end

  if config.notation ~= "auto" and config.notation ~= "fixed" and config.notation ~= "scientific" then
    reset("notation", '"auto", "fixed" or "scientific"')
  end

  if type(config.show_documentation) ~= "boolean" then
    reset("show_documentation", "boolean")
  end

  if type(config.min_length) ~= "number" or config.min_length < 0 then
    reset("min_length", "non-negative number")
  end

  if type(config.require_operator) ~= "boolean" then
    reset("require_operator", "boolean")
  end

  if type(config.comment_only) ~= "boolean" then
    reset("comment_only", "boolean")
  end

  if type(config.disabled_filetypes) ~= "table" then
    reset("disabled_filetypes", "table")
  end

  if type(config.buffer_variables) ~= "boolean" then
    reset("buffer_variables", "boolean")
  end

  if config.copy_register ~= false and type(config.copy_register) ~= "string" then
    reset("copy_register", "false or string")
  end

  local rates_type = type(config.currency_rates)
  if rates_type == "string" then
    if require("blink-calc.currency").providers[config.currency_rates] == nil then
      local names = vim.tbl_keys(require("blink-calc.currency").providers)
      reset("currency_rates", 'one of the built-in providers: "' .. table.concat(names, '", "') .. '"')
    end
  elseif rates_type ~= "table" and rates_type ~= "function" then
    reset("currency_rates", "table, function, or built-in provider name")
  end

  if type(config.currency_cache_ttl) ~= "number" or config.currency_cache_ttl <= 0 then
    reset("currency_cache_ttl", "positive number")
  end

  return config
end

return M
