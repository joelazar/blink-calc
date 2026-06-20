---@class BlinkCalc.Calc
local M = {}

local math_keys = {}
for k in pairs(math) do
  table.insert(math_keys, k)
end

---@param line string
---@param col integer cursor column (1-indexed end of expression)
---@return integer start_col 1-indexed start of the math expression
function M.find_expression_start(line, col)
  local paren_count = 0
  local i = col

  while i > 0 do
    local char = line:sub(i, i)

    if char == "(" then
      paren_count = paren_count + 1
    elseif char == ")" then
      paren_count = paren_count - 1
    end

    if paren_count > 1 then
      break
    end

    if not char:match("[%w%+%-%*/%.%(%),=%s]") then
      if paren_count == 0 then
        break
      end
    end

    i = i - 1
  end

  return i + 1
end

---@param expr string
---@return string expr with bare math.* functions and aliases qualified
function M.resolve_math_functions(expr)
  for _, key in ipairs(math_keys) do
    expr = expr:gsub("([^%w_%.])(" .. key .. ")%(", "%1math.%2(")
    expr = expr:gsub("^(" .. key .. ")%(", "math.%1(")
  end

  expr = expr:gsub("([^%w_])(ln)%(", "%1math.log(")
  expr = expr:gsub("^(ln)%(", "math.log(")

  return expr
end

---@param expr string raw math expression
---@return number|string|nil result nil when the expression cannot be evaluated
function M.evaluate(expr)
  expr = expr:gsub("=$", "")
  expr = expr:gsub("%s+", "")
  expr = M.resolve_math_functions(expr)

  local func = load("return " .. expr)
  if not func then
    return nil
  end

  local ok, result = pcall(func)
  if not ok then
    return nil
  end

  return result
end

return M
