---@class BlinkCalc.Calc
local M = {}

local function factorial(n)
  if n < 0 or n ~= math.floor(n) then
    return 0 / 0
  end
  local r = 1
  for i = 2, n do
    r = r * i
  end
  return r
end

local function gcd(a, b)
  a, b = math.abs(a), math.abs(b)
  while b ~= 0 do
    a, b = b, a % b
  end
  return a
end

local function lcm(a, b)
  if a == 0 or b == 0 then
    return 0
  end
  return math.abs(a * b) / gcd(a, b)
end

local function sum(...)
  local s = 0
  for _, v in ipairs({ ... }) do
    s = s + v
  end
  return s
end

local function avg(...)
  return sum(...) / select("#", ...)
end

local function median(...)
  local t = { ... }
  table.sort(t)
  local n = #t
  if n % 2 == 1 then
    return t[(n + 1) / 2]
  end
  return (t[n / 2] + t[n / 2 + 1]) / 2
end

local env = setmetatable({
  e = math.exp(1),
  phi = (1 + math.sqrt(5)) / 2,
  tau = 2 * math.pi,
  ln = math.log,
  log2 = function(x)
    return math.log(x) / math.log(2)
  end,
  log10 = math.log10 or function(x)
    return math.log(x) / math.log(10)
  end,
  mod = math.fmod,
  fact = factorial,
  gcd = gcd,
  lcm = lcm,
  perm = function(n, r)
    return factorial(n) / factorial(n - r)
  end,
  comb = function(n, r)
    return factorial(n) / (factorial(r) * factorial(n - r))
  end,
  sum = sum,
  avg = avg,
  mean = avg,
  median = median,
}, { __index = math })

local ok_bit, bit = pcall(require, "bit")
if ok_bit then
  env.band, env.bor, env.bxor, env.bnot = bit.band, bit.bor, bit.bxor, bit.bnot
  env.lshift, env.rshift = bit.lshift, bit.rshift
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

    if not char:match("[%w%+%-%*/%.%(%),=%s%%_!]") then
      if paren_count == 0 then
        break
      end
    end

    i = i - 1
  end

  return i + 1
end

---@param expr string
---@return string expr with percentage phrases rewritten as arithmetic
function M.resolve_percentages(expr)
  expr = expr:gsub("([%d%.]+)%s*%%%s*of%s*([%d%.]+)", "(%2*%1/100)")
  expr = expr:gsub("([%d%.]+)%s*([%+%-])%s*([%d%.]+)%s*%%", function(a, op, b)
    return ("(%s%s%s*%s/100)"):format(a, op, a, b)
  end)
  expr = expr:gsub("([%d%.]+)%s*%%", "(%1/100)")
  return expr
end

---@param expr string raw math expression
---@return string normalized expression ready for evaluation
function M.preprocess(expr)
  expr = expr:gsub("=%s*$", "")
  expr = M.resolve_percentages(expr)
  expr = expr:gsub("0[bB]([01]+)", function(bits)
    return tostring(tonumber(bits, 2))
  end)
  expr = expr:gsub("([%d%.]+)%s*!", "fact(%1)")
  while expr:find("%d_%d") do
    expr = expr:gsub("(%d)_(%d)", "%1%2")
  end
  return (expr:gsub("%s+", ""))
end

---@param expr string raw math expression
---@return number|nil result nil when the expression cannot be evaluated
function M.evaluate(expr)
  local func = load("return " .. M.preprocess(expr))
  if not func then
    return nil
  end

  setfenv(func, env)
  local ok, result = pcall(func)
  if not ok or type(result) ~= "number" or result ~= result or math.abs(result) == math.huge then
    return nil
  end

  return result
end

---@param n number
---@param precision integer decimal places used to tame float noise
---@return string
function M.format(n, precision)
  if n == math.floor(n) and math.abs(n) < 1e15 then
    return string.format("%d", n)
  end
  local s = string.format("%." .. precision .. "f", n)
  return (s:gsub("0+$", ""):gsub("%.$", ""))
end

---@param n number non-negative integer
---@return string
function M.to_hex(n)
  return string.format("0x%X", n)
end

---@param n number non-negative integer
---@return string
function M.to_bin(n)
  if n == 0 then
    return "0b0"
  end
  local bits = ""
  while n > 0 do
    bits = (n % 2) .. bits
    n = math.floor(n / 2)
  end
  return "0b" .. bits
end

---@param s string integer rendered as a string
---@param sep string grouping separator
---@return string
function M.group(s, sep)
  local sign, digits = s:match("^(%-?)(%d+)$")
  if not digits then
    return s
  end
  local grouped = digits:reverse():gsub("(%d%d%d)", "%1" .. sep):reverse()
  return sign .. (grouped:gsub("^" .. vim.pesc(sep), ""))
end

return M
