---@module 'luassert'

local Calc = require("blink-calc.calc")
local source = require("blink-calc")

local function complete_with(opts, line, col)
  local s = source.new(opts)
  local result
  s:get_completions({ line = line, cursor = { 1, col or #line }, bufnr = 0 }, function(res)
    result = res
  end)
  return result
end

local function first_with(opts, line, col)
  local r = complete_with(opts, line, col)
  return r and r.items and r.items[1] and r.items[1].label
end

-- #2 Comparison / boolean expressions ----------------------------------------
describe("booleans", function()
  it("evaluates a comparison to true", function()
    assert.are.equal(true, Calc.evaluate("2+2 >= 3"))
  end)

  it("evaluates equality", function()
    assert.are.equal(true, Calc.evaluate("5 == 5"))
    assert.are.equal(false, Calc.evaluate("5 == 6"))
  end)

  it("evaluates inequality with ~=", function()
    assert.are.equal(true, Calc.evaluate("5 ~= 6"))
  end)

  it("formats booleans", function()
    assert.are.equal("true", Calc.format(true, {}))
    assert.are.equal("false", Calc.format(false, {}))
  end)

  it("surfaces a boolean result through the source", function()
    assert.are.equal("true", first_with({}, "5 == 5"))
  end)

  it("does not crash base/group logic on a boolean", function()
    local r = complete_with({ show_bases = true, group_digits = "," }, "2 < 3")
    assert.are.equal("true", r.items[1].label)
  end)
end)

-- #6 Trig in degrees ---------------------------------------------------------
describe("degree mode", function()
  it("computes sin(30) = 0.5 in degrees", function()
    assert.is_true(math.abs(Calc.evaluate("sin(30)", { angle = "deg" }) - 0.5) < 1e-9)
  end)

  it("computes cos(60) = 0.5 in degrees", function()
    assert.is_true(math.abs(Calc.evaluate("cos(60)", { angle = "deg" }) - 0.5) < 1e-9)
  end)

  it("returns degrees from inverse trig", function()
    assert.is_true(math.abs(Calc.evaluate("asin(0.5)", { angle = "deg" }) - 30) < 1e-9)
  end)

  it("still uses radians by default", function()
    assert.is_true(math.abs(Calc.evaluate("sin(pi/2)") - 1) < 1e-9)
  end)

  it("honors angle = deg through the source", function()
    assert.are.equal("0.5", first_with({ angle = "deg" }, "sin(30)"))
  end)
end)

-- #5 Scientific-notation output ----------------------------------------------
describe("notation", function()
  it("renders scientific notation on demand", function()
    assert.are.equal("1.235e+04", Calc.format(12345, { notation = "scientific", precision = 3 }))
  end)

  it("trims trailing mantissa zeros in scientific", function()
    assert.are.equal("1e+03", Calc.format(1000, { notation = "scientific", precision = 4 }))
  end)

  it("fixed notation never switches to scientific", function()
    assert.are.equal("100000", Calc.format(100000, { notation = "fixed", precision = 2 }))
  end)

  it("auto notation keeps integers bare", function()
    assert.are.equal("42", Calc.format(42, { notation = "auto", precision = 4 }))
  end)

  it("emits scientific result through the source", function()
    assert.are.equal("1.5e+06", first_with({ notation = "scientific", precision = 4 }, "1500000"))
  end)
end)

-- #4 Infix bitwise operators -------------------------------------------------
describe("infix bitwise", function()
  it("and: 5 & 3", function()
    assert.are.equal(1, Calc.evaluate("5 & 3"))
  end)

  it("or: 12 | 3", function()
    assert.are.equal(15, Calc.evaluate("12 | 3"))
  end)

  it("xor: 12 ~ 10", function()
    assert.are.equal(6, Calc.evaluate("12 ~ 10"))
  end)

  it("left shift: 1 << 4", function()
    assert.are.equal(16, Calc.evaluate("1 << 4"))
  end)

  it("right shift: 16 >> 2", function()
    assert.are.equal(4, Calc.evaluate("16 >> 2"))
  end)

  it("respects & over | precedence: 1 | 2 & 3", function()
    assert.are.equal(3, Calc.evaluate("1 | 2 & 3"))
  end)

  it("shift binds looser than arithmetic: 1 + 2 << 3", function()
    assert.are.equal(24, Calc.evaluate("1 + 2 << 3"))
  end)

  it("does not mistake ~= for xor", function()
    assert.are.equal(true, Calc.evaluate("5 ~= 6"))
  end)

  it("surfaces an infix bitwise result through the source", function()
    assert.are.equal("16", first_with({}, "1 << 4"))
  end)
end)

-- #1 ans / previous result ---------------------------------------------------
describe("ans", function()
  before_each(function()
    Calc.set_ans(0)
  end)

  it("references the last stored result", function()
    Calc.set_ans(15)
    assert.are.equal(17, Calc.evaluate("ans+2"))
  end)

  it("defaults ans to 0", function()
    Calc.set_ans(0)
    assert.are.equal(5, Calc.evaluate("ans+5"))
  end)

  it("updates ans on accept via source:execute", function()
    local s = source.new()
    local r
    s:get_completions({ line = "5*3", cursor = { 1, 3 }, bufnr = 0 }, function(res)
      r = res
    end)
    s:execute(nil, r.items[1], function() end, function() end)
    assert.are.equal(17, Calc.evaluate("ans+2"))
  end)
end)

-- #10 Vectors ----------------------------------------------------------------
describe("vectors", function()
  it("dot product", function()
    assert.are.equal(32, Calc.evaluate("dot(vec(1,2,3), vec(4,5,6))"))
  end)

  it("magnitude", function()
    assert.are.equal(5, Calc.evaluate("mag(vec(3,4))"))
  end)

  it("formats a vector", function()
    assert.are.equal("[1, 2, 3]", Calc.format(Calc.evaluate("vec(1,2,3)"), {}))
  end)

  it("cross product", function()
    assert.are.equal("[0, 0, 1]", Calc.format(Calc.evaluate("cross(vec(1,0,0), vec(0,1,0))"), {}))
  end)

  it("normalize yields a unit vector", function()
    assert.are.equal(1, Calc.evaluate("mag(norm(vec(3,4)))"))
  end)

  it("rejects a vector with non-finite components (norm of the zero vector)", function()
    assert.are.equal(nil, Calc.evaluate("norm(vec(0,0))"))
  end)

  it("does not surface a non-finite vector through the source", function()
    assert.are.equal(nil, first_with({}, "norm(vec(0,0))"))
  end)
end)

-- #3 Rich documentation popup ------------------------------------------------
describe("documentation popup", function()
  it("surfaces alternate forms for an integer result", function()
    local r = complete_with({ show_documentation = true }, "255")
    local doc = r.items[1].documentation
    assert.is_not_nil(doc)
    assert.is_truthy(doc.value:find("0xFF"))
    assert.is_truthy(doc.value:find("0b11111111"))
    assert.is_truthy(doc.value:find("sci:"))
  end)

  it("is omitted when disabled", function()
    local r = complete_with({ show_documentation = false }, "255")
    assert.is_nil(r.items[1].documentation)
  end)
end)

-- #7 Per-filetype / context control ------------------------------------------
describe("filetype and context gating", function()
  it("disables the source in configured filetypes", function()
    _G.__bo[0] = { filetype = "markdown" }
    local s = source.new({ disabled_filetypes = { "markdown" } })
    assert.is_false(s:enabled())
    _G.__bo[0] = { filetype = "lua" }
    assert.is_true(s:enabled())
    _G.__bo[0] = { filetype = "" }
  end)

  it("comment_only skips non-comment lines", function()
    assert.are.equal(nil, first_with({ comment_only = true }, "2+2"))
  end)

  it("comment_only allows commented lines", function()
    assert.are.equal("4", first_with({ comment_only = true }, "-- 2+2"))
    assert.are.equal("4", first_with({ comment_only = true }, "# 2+2"))
  end)
end)

-- #8 Trigger gating ----------------------------------------------------------
describe("trigger gating", function()
  it("min_length suppresses short expressions", function()
    assert.are.equal(nil, first_with({ min_length = 3 }, "5"))
    assert.are.equal("4", first_with({ min_length = 3 }, "2+2"))
  end)

  it("require_operator rejects bare numbers", function()
    assert.are.equal(nil, first_with({ require_operator = true }, "5"))
    assert.are.equal(nil, first_with({ require_operator = true }, "55"))
    assert.are.equal("4", first_with({ require_operator = true }, "2+2"))
    local label = first_with({ require_operator = true }, "sqrt(16)")
    assert.is_true(label == "4" or label == "4.0")
  end)
end)

-- #9 Copy to register --------------------------------------------------------
describe("copy on accept", function()
  it("yanks the accepted result to the configured register", function()
    _G.__registers = {}
    local s = source.new({ copy_register = "+" })
    local r
    s:get_completions({ line = "2+2", cursor = { 1, 3 }, bufnr = 0 }, function(res)
      r = res
    end)
    s:execute(nil, r.items[1], function() end, function() end)
    assert.are.equal("4", vim.fn.getreg("+"))
  end)
end)

-- #11 Buffer variables -------------------------------------------------------
describe("buffer variables", function()
  it("resolves assignments from earlier buffer lines", function()
    _G.__buffers[0] = { "x = 2+2", "y = x*3" }
    local s = source.new({ buffer_variables = true })
    local r
    s:get_completions({ line = "y+1", cursor = { 3, 3 }, bufnr = 0 }, function(res)
      r = res
    end)
    _G.__buffers[0] = {}
    assert.are.equal("13", r.items[1].label)
  end)

  it("is off by default", function()
    _G.__buffers[0] = { "x = 99" }
    assert.are.equal(nil, first_with({}, "x+1"))
    _G.__buffers[0] = {}
  end)
end)

-- #12 Date / time math -------------------------------------------------------
describe("date math", function()
  it("subtracts two dates into a day count", function()
    assert.are.equal(9, Calc.evaluate('date("2024-01-10") - date("2024-01-01")'))
  end)

  it("parses bare date literals", function()
    assert.are.equal(9, Calc.evaluate("2024-01-10 - 2024-01-01"))
  end)

  it("adds a duration to a date", function()
    assert.are.equal("2024-01-04", Calc.format(Calc.evaluate('date("2024-01-01") + 3 days'), {}))
  end)

  it("today minus today is zero", function()
    assert.are.equal(0, Calc.evaluate("today - today"))
  end)
end)

-- #13 Unit & currency conversion ---------------------------------------------
describe("unit conversion", function()
  it("converts length with a function call", function()
    assert.is_true(math.abs(Calc.evaluate('convert(5, "km", "mi")') - 3.106856) < 1e-3)
  end)

  it("converts with natural 'to' syntax", function()
    assert.are.equal(1, Calc.evaluate("100 cm to m"))
  end)

  it("converts with natural 'in' syntax", function()
    assert.are.equal(1, Calc.evaluate("100 cm in m"))
  end)

  it("converts temperature affinely", function()
    assert.are.equal(212, Calc.evaluate('convert(100, "c", "f")'))
  end)

  it("converts currency from a configured rate table", function()
    assert.are.equal(5, Calc.evaluate('convert(10, "usd", "eur")', { currency_rates = { usd = 1, eur = 2 } }))
  end)

  it("converts currency case-insensitively against uppercase rate keys", function()
    assert.are.equal(5, Calc.evaluate('convert(10, "USD", "EUR")', { currency_rates = { USD = 1, EUR = 2 } }))
    assert.are.equal(5, Calc.evaluate("10 usd in eur", { currency_rates = { USD = 1, EUR = 2 } }))
  end)

  it("offers a currency result through the source", function()
    assert.are.equal("5", first_with({ currency_rates = { usd = 1, eur = 2 } }, "10 usd in eur"))
  end)

  it("resolves currency from a provider function", function()
    local Currency = require("blink-calc.currency")
    Currency.reset()
    Currency.schedule = function(fn)
      fn()
    end
    local opts = {
      currency_rates = function(done)
        done({ usd = 1, eur = 2 })
      end,
      currency_cache_path = vim.fn.tempname(),
    }
    assert.are.equal(5, Calc.evaluate("10 usd in eur", opts))
  end)
end)
