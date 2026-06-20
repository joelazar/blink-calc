---@class BlinkCalc.Config
local M = {}

---@class BlinkCalc.DefaultOptions
local defaults = {
  show_equation = true,
}

M.defaults = defaults

---Merge user options over defaults and validate them
---@param opts? BlinkCalc.UserOptions
---@return BlinkCalc.Options
function M.merge(opts)
  local config = vim.tbl_deep_extend("force", {}, vim.deepcopy(defaults), opts or {})

  if type(config.show_equation) ~= "boolean" then
    local Util = require("blink-calc.util")
    Util.error(("Invalid 'show_equation' option: expected boolean, got %s"):format(type(config.show_equation)))
    config.show_equation = defaults.show_equation
  end

  return config
end

return M
