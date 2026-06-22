---@class BlinkCalc.Calc
local M = {}

-- Last accepted result, referenced as `ans` in a later expression.
M.ans = 0

---@param v number
function M.set_ans(v)
  M.ans = v
end

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

-- Vectors --------------------------------------------------------------------
local vec_mt = {}
M.vec_mt = vec_mt

local function vec(...)
  return setmetatable({ ... }, vec_mt)
end

local function dot(a, b)
  local s = 0
  for i = 1, #a do
    s = s + a[i] * b[i]
  end
  return s
end

local function cross(a, b)
  return setmetatable({
    a[2] * b[3] - a[3] * b[2],
    a[3] * b[1] - a[1] * b[3],
    a[1] * b[2] - a[2] * b[1],
  }, vec_mt)
end

local function magnitude(v)
  local s = 0
  for i = 1, #v do
    s = s + v[i] * v[i]
  end
  return math.sqrt(s)
end

local function normalize(v)
  local m = magnitude(v)
  local out = {}
  for i = 1, #v do
    out[i] = v[i] / m
  end
  return setmetatable(out, vec_mt)
end

-- Date & duration ------------------------------------------------------------
local date_mt = {}
local dur_mt = {}
M.date_mt = date_mt

local function make_date(epoch)
  return setmetatable({ epoch = epoch }, date_mt)
end

local function make_dur(seconds)
  return setmetatable({ seconds = seconds }, dur_mt)
end

local DAY = 86400

local function parse_date(str)
  local y, m, d = str:match("^(%d%d%d%d)%-(%d%d?)%-(%d%d?)$")
  if not y then
    return nil
  end
  return make_date(os.time({
    year = tonumber(y) --[[@as integer]],
    month = tonumber(m) --[[@as integer]],
    day = tonumber(d) --[[@as integer]],
    hour = 12,
  }))
end

local function start_of_today()
  local t = os.date("*t")
  return make_date(os.time({ year = t.year, month = t.month, day = t.day, hour = 12 }))
end

date_mt.__sub = function(a, b)
  if getmetatable(a) == date_mt and getmetatable(b) == date_mt then
    return math.floor((a.epoch - b.epoch) / DAY + 0.5)
  end
  if getmetatable(a) == date_mt and getmetatable(b) == dur_mt then
    return make_date(a.epoch - b.seconds)
  end
  return 0 / 0
end

date_mt.__add = function(a, b)
  local date, dur = a, b
  if getmetatable(a) == dur_mt then
    date, dur = b, a
  end
  return make_date(date.epoch + dur.seconds)
end

local function dur_factory(unit_seconds)
  return function(n)
    return make_dur(n * unit_seconds)
  end
end

-- Unit conversion ------------------------------------------------------------
-- Linear units expressed as a factor to a base unit per dimension. Conversion
-- between two units of the same dimension is value * from_factor / to_factor.
local UNIT_FACTORS = {
  -- length (base: metre)
  mm = 0.001,
  cm = 0.01,
  m = 1,
  km = 1000,
  inch = 0.0254,
  ["in"] = 0.0254,
  ft = 0.3048,
  yd = 0.9144,
  mi = 1609.344,
  -- mass (base: gram)
  mg = 0.001,
  g = 1,
  kg = 1000,
  lb = 453.59237,
  oz = 28.349523125,
  -- time (base: second)
  s = 1,
  min = 60,
  h = 3600,
  day = 86400,
  -- data (base: byte)
  b = 1,
  kb = 1024,
  mb = 1024 ^ 2,
  gb = 1024 ^ 3,
  tb = 1024 ^ 4,
}

local UNIT_DIMENSION = {}
for _, group in ipairs({
  { "mm", "cm", "m", "km", "inch", "in", "ft", "yd", "mi" },
  { "mg", "g", "kg", "lb", "oz" },
  { "s", "min", "h", "day" },
  { "b", "kb", "mb", "gb", "tb" },
}) do
  for _, u in ipairs(group) do
    UNIT_DIMENSION[u] = group
  end
end

-- Affine temperature conversions to/from Celsius.
local TEMP_TO_C = {
  c = function(x)
    return x
  end,
  f = function(x)
    return (x - 32) * 5 / 9
  end,
  k = function(x)
    return x - 273.15
  end,
}
local TEMP_FROM_C = {
  c = function(x)
    return x
  end,
  f = function(x)
    return x * 9 / 5 + 32
  end,
  k = function(x)
    return x + 273.15
  end,
}

---@param rates table<string, number> currency code -> rate per base unit
---@return fun(value: number, from: string, to: string): number|nil
local function make_convert(rates)
  local lower_rates = {}
  for code, rate in pairs(rates) do
    lower_rates[code:lower()] = rate
  end
  return function(value, from, to)
    from, to = from:lower(), to:lower()
    if TEMP_TO_C[from] and TEMP_FROM_C[to] then
      return TEMP_FROM_C[to](TEMP_TO_C[from](value))
    end
    if UNIT_FACTORS[from] and UNIT_FACTORS[to] and UNIT_DIMENSION[from] == UNIT_DIMENSION[to] then
      return value * UNIT_FACTORS[from] / UNIT_FACTORS[to]
    end
    if lower_rates[from] and lower_rates[to] then
      return value * lower_rates[from] / lower_rates[to]
    end
    return nil
  end
end

-- Environment ----------------------------------------------------------------
-- Shared radian-mode environment: math fallback plus all custom functions.
local base = {
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
  vec = vec,
  dot = dot,
  cross = cross,
  mag = magnitude,
  magnitude = magnitude,
  norm = normalize,
  normalize = normalize,
  date = function(s)
    return parse_date(s)
  end,
  days = dur_factory(DAY),
  weeks = dur_factory(7 * DAY),
  hours = dur_factory(3600),
  minutes = dur_factory(60),
}
local base_env = setmetatable(base, { __index = math })

local ok_bit, bit = pcall(require, "bit")
if ok_bit then
  base.band, base.bor, base.bxor, base.bnot = bit.band, bit.bor, bit.bxor, bit.bnot
  base.lshift, base.rshift = bit.lshift, bit.rshift
end

local deg_overrides = {
  sin = function(x)
    return math.sin(math.rad(x))
  end,
  cos = function(x)
    return math.cos(math.rad(x))
  end,
  tan = function(x)
    return math.tan(math.rad(x))
  end,
  asin = function(x)
    return math.deg(math.asin(x))
  end,
  acos = function(x)
    return math.deg(math.acos(x))
  end,
  atan = function(x)
    return math.deg(math.atan(x))
  end,
}

---Build the evaluation environment for a single call.
---@param opts? table
---@return table
function M.make_env(opts)
  opts = opts or {}
  local rates = require("blink-calc.currency").resolve(opts)
  local top = { ans = M.ans, convert = make_convert(rates) }
  top.today = start_of_today()
  top.now = top.today
  if opts.angle == "deg" then
    for k, v in pairs(deg_overrides) do
      top[k] = v
    end
  end
  if type(opts.variables) == "table" then
    for k, v in pairs(opts.variables) do
      top[k] = v
    end
  end
  return setmetatable(top, { __index = base_env })
end

---Evaluate `name = expr` assignments from buffer lines into a variable table.
---Earlier assignments are visible to later ones. Breaks the stateless rule, so
---it is opt-in via the `buffer_variables` option.
---@param lines string[]
---@return table<string, number|boolean|table|string>
function M.scan_variables(lines)
  local vars = {}
  for _, line in ipairs(lines) do
    local name, rhs = line:match("^%s*([%a_][%w_]*)%s*=%s*(.-)%s*$")
    if name and rhs ~= "" and not rhs:find("[=<>]") then
      local val = M.evaluate(rhs, { variables = vars })
      if val ~= nil then
        vars[name] = val
      end
    end
  end
  return vars
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

    if not char:match("[%w%+%-%*/%.%(%),=%s%%_!&|~<>]") then
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

-- Infix bitwise operators, lowest precedence first. Each level maps an operator
-- token to the function it rewrites into. Comparison digraphs (`~=`, `<=`, ...)
-- are deliberately left untouched for Lua to evaluate.
local BITWISE_LEVELS = {
  { { "|", "bor" } },
  { { "~", "bxor" } },
  { { "&", "band" } },
  { { "<<", "lshift" }, { ">>", "rshift" } },
}

---Find the right-most top-level operator of a precedence level.
---@param s string
---@param level table
---@return integer? pos, integer? len, string? fn
local function find_split(s, level)
  local depth, i = 0, 1
  local pos, len, fn
  while i <= #s do
    local c = s:sub(i, i)
    if c == "(" then
      depth = depth + 1
    elseif c == ")" then
      depth = depth - 1
    elseif depth == 0 then
      for _, op in ipairs(level) do
        local tok = op[1]
        if s:sub(i, i + #tok - 1) == tok then
          local nxt = s:sub(i + #tok, i + #tok)
          if not (tok == "~" and nxt == "=") then
            pos, len, fn = i, #tok, op[2]
            i = i + #tok - 1
          end
          break
        end
      end
    end
    i = i + 1
  end
  return pos, len, fn
end

---@param expr string
---@return string expr with infix bitwise operators rewritten to function calls
function M.rewrite_bitwise(expr)
  for _, level in ipairs(BITWISE_LEVELS) do
    local pos, len, fn = find_split(expr, level)
    if pos then
      local left = expr:sub(1, pos - 1)
      local right = expr:sub(pos + len)
      return fn .. "(" .. M.rewrite_bitwise(left) .. "," .. M.rewrite_bitwise(right) .. ")"
    end
  end
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
  -- bare date literals (not already inside date("...")) before arithmetic
  -- mistakes them for subtraction. A leading sentinel gives the first token a
  -- preceding character so the "not a quote" guard applies uniformly.
  expr = (" " .. expr):gsub('([^"%w])(%d%d%d%d)%-(%d%d?)%-(%d%d?)', '%1date("%2-%3-%4")')
  expr = expr:sub(2)
  -- natural unit/currency conversion: `5 km to mi`, `100 usd in eur`
  expr = expr:gsub("([%d%.]+)%s*(%a+)%s+[ti][on]%s+(%a+)", 'convert(%1,"%2","%3")')
  -- duration phrases: `3 days` -> days(3)
  expr = expr:gsub("([%d%.]+)%s*(day)s?%f[%A]", "days(%1)")
  expr = expr:gsub("([%d%.]+)%s*(week)s?%f[%A]", "weeks(%1)")
  expr = expr:gsub("([%d%.]+)%s*(hour)s?%f[%A]", "hours(%1)")
  expr = expr:gsub("([%d%.]+)%s*(minute)s?%f[%A]", "minutes(%1)")
  expr = expr:gsub("([%d%.]+)%s*!", "fact(%1)")
  while expr:find("%d_%d") do
    expr = expr:gsub("(%d)_(%d)", "%1%2")
  end
  expr = expr:gsub("%s+", "")
  return M.rewrite_bitwise(expr)
end

---@param n any
---@return boolean
local function finite(n)
  return type(n) == "number" and n == n and math.abs(n) ~= math.huge
end

---Reduce a raw evaluation result to a supported value or nil.
---@param result any
---@return number|boolean|table|string|nil
local function valid(result)
  local t = type(result)
  if t == "number" then
    return finite(result) and result or nil
  elseif t == "boolean" or t == "string" then
    return result
  elseif t == "table" then
    local mt = getmetatable(result)
    if mt == vec_mt then
      for _, c in ipairs(result) do
        if not finite(c) then
          return nil
        end
      end
      return result
    elseif mt == date_mt or mt == dur_mt then
      return result
    end
  end
  return nil
end

---@param expr string raw math expression
---@param opts? table evaluation options (angle, currency_rates)
---@return number|boolean|table|string|nil result nil when not evaluable
function M.evaluate(expr, opts)
  local func = load("return " .. M.preprocess(expr))
  if not func then
    return nil
  end

  setfenv(func, M.make_env(opts))
  local ok, result = pcall(func)
  if not ok then
    return nil
  end

  return valid(result)
end

---@param n number
---@param opts table { precision, notation }
---@return string
local function format_number(n, opts)
  local precision = opts.precision or 10
  local notation = opts.notation or "auto"

  if notation == "scientific" then
    local s = string.format("%." .. precision .. "e", n)
    local mant, exp = s:match("^(.-)[eE]([%+%-]%d+)$")
    if mant then
      mant = mant:gsub("0+$", ""):gsub("%.$", "")
      return mant .. "e" .. exp
    end
    return s
  end

  if n == math.floor(n) and math.abs(n) < 1e15 then
    return string.format("%d", n)
  end
  local s = string.format("%." .. precision .. "f", n)
  return (s:gsub("0+$", ""):gsub("%.$", ""))
end

---@param value number|boolean|table|string
---@param opts? table { precision, notation }
---@return string
function M.format(value, opts)
  opts = opts or {}
  local t = type(value)
  if t == "boolean" then
    return tostring(value)
  elseif t == "string" then
    return value
  elseif t == "table" then
    local mt = getmetatable(value)
    if mt == vec_mt then
      local parts = {}
      for _, c in ipairs(value) do
        parts[#parts + 1] = format_number(c, opts)
      end
      return "[" .. table.concat(parts, ", ") .. "]"
    elseif mt == date_mt then
      return os.date("%Y-%m-%d", value.epoch) --[[@as string]]
    elseif mt == dur_mt then
      return format_number(value.seconds / DAY, opts) .. " days"
    end
    return tostring(value)
  end
  return format_number(value, opts)
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
