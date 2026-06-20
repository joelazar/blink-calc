---@class BlinkCalc.Health
local M = {}

---Health check called by `:checkhealth blink-calc`
function M.check()
  vim.health.start("blink-calc")

  if pcall(require, "blink.cmp") then
    vim.health.ok("blink.cmp is installed")
  else
    vim.health.error("blink.cmp is not installed. blink-calc is a blink.cmp source and requires it.")
  end

  local ok = pcall(require, "blink-calc")
  if ok then
    vim.health.ok("blink-calc source module loads")
  else
    vim.health.error("blink-calc source module failed to load")
  end
end

return M
