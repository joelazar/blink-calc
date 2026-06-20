---@class BlinkCalc.Config
local M = {}

---@class BlinkCalc.DefaultOptions
local defaults = {
  show_equation = true,
  show_bases = false,
  group_digits = false,
  precision = 10,
  separator = " = ",
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
    config[key] = defaults[key]
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

  return config
end

return M
