---@module 'luassert'

local source = require("blink-calc")

local function complete(line, col)
  local s = source.new()
  local result
  s:get_completions({ line = line, cursor = { 1, col or #line }, bufnr = 0 }, function(res)
    result = res
  end)
  return result
end

local function complete_with(opts, line, col)
  local s = source.new(opts)
  local result
  s:get_completions({ line = line, cursor = { 1, col or #line }, bufnr = 0 }, function(res)
    result = res
  end)
  return result
end

local function first(line, col)
  local r = complete(line, col)
  return r and r.items and r.items[1] and r.items[1].label
end

local function labels(line, col)
  local r = complete(line, col)
  local out = {}
  if r and r.items then
    for _, item in ipairs(r.items) do
      out[item.label] = true
    end
  end
  return out
end

describe("source contract", function()
  it("instantiates with required methods", function()
    local s = source.new()
    assert.is_not_nil(s)
    assert.is_function(s.get_completions)
    assert.is_function(s.get_trigger_characters)
    assert.is_function(s.enabled)
  end)

  it("is enabled", function()
    assert.is_true(source.new():enabled())
  end)

  it("exposes trigger characters", function()
    assert.are.equal("table", type(source.new():get_trigger_characters()))
  end)
end)

describe("evaluation", function()
  it("adds: 2+2", function()
    assert.are.equal("4", complete("2+2").items[1].label)
  end)

  it("multiplies: 5*3", function()
    assert.are.equal("15", complete("5*3").items[1].label)
  end)

  it("respects precedence: 10*5+3", function()
    assert.are.equal("53", complete("10*5+3").items[1].label)
  end)

  it("handles parentheses: (2+3)*4", function()
    assert.are.equal("20", complete("(2+3)*4").items[1].label)
  end)

  it("resolves math functions: sqrt(16)", function()
    local label = complete("sqrt(16)").items[1].label
    assert.is_true(label == "4" or label == "4.0")
  end)
end)

describe("equation item", function()
  it("offers result and equation when typing '='", function()
    local result = complete("2+2=")
    assert.are.equal(2, #result.items)
    assert.are.equal("4", result.items[1].label)
  end)

  it("is suppressed when show_equation = false", function()
    local s = source.new({ show_equation = false })
    local result
    s:get_completions({ line = "2+2=", cursor = { 1, 4 }, bufnr = 0 }, function(res)
      result = res
    end)
    assert.are.equal(1, #result.items)
  end)
end)

describe("non-math input", function()
  it("does not complete plain text", function()
    local result = complete("hello world")
    assert.is_true(result == nil or result.items == nil or #result.items == 0)
  end)
end)

describe("item matching", function()
  it("sets filterText to the covered expression so blink keeps word-ending exprs", function()
    local item = complete("ln(2) + pi").items[1]
    assert.are.equal("ln(2) + pi", item.filterText)
  end)

  it("sets filterText for digit-ending expressions too", function()
    assert.are.equal("2+2", complete("2+2").items[1].filterText)
  end)
end)

describe("constants and aliases", function()
  it("knows pi: 2*pi", function()
    assert.is_truthy(first("2*pi"):match("^6%.28"))
  end)

  it("knows e via ln: ln(e)", function()
    assert.are.equal("1", first("ln(e)"))
  end)

  it("knows phi: 2*phi", function()
    assert.is_truthy(first("2*phi"):match("^3%.24"))
  end)

  it("knows tau: tau/2", function()
    assert.is_truthy(first("tau/2"):match("^3%.14"))
  end)

  it("computes log2(8)", function()
    assert.are.equal("3", first("log2(8)"))
  end)

  it("computes log10(1000)", function()
    assert.are.equal("3", first("log10(1000)"))
  end)
end)

describe("factorial and combinatorics", function()
  it("factorial operator: 5!", function()
    assert.are.equal("120", first("5!"))
  end)

  it("factorial function: fact(6)", function()
    assert.are.equal("720", first("fact(6)"))
  end)

  it("gcd(12,18)", function()
    assert.are.equal("6", first("gcd(12,18)"))
  end)

  it("lcm(4,6)", function()
    assert.are.equal("12", first("lcm(4,6)"))
  end)

  it("comb(5,2)", function()
    assert.are.equal("10", first("comb(5,2)"))
  end)

  it("perm(5,2)", function()
    assert.are.equal("20", first("perm(5,2)"))
  end)
end)

describe("statistics", function()
  it("avg(2,4,6)", function()
    assert.are.equal("4", first("avg(2,4,6)"))
  end)

  it("mean(2,4)", function()
    assert.are.equal("3", first("mean(2,4)"))
  end)

  it("sum(1,2,3,4)", function()
    assert.are.equal("10", first("sum(1,2,3,4)"))
  end)

  it("median(3,1,2)", function()
    assert.are.equal("2", first("median(3,1,2)"))
  end)

  it("max(3,9,2)", function()
    assert.are.equal("9", first("max(3,9,2)"))
  end)

  it("min(3,9,2)", function()
    assert.are.equal("2", first("min(3,9,2)"))
  end)
end)

describe("percentages", function()
  it("X% of Y: 20% of 150", function()
    assert.are.equal("30", first("20% of 150"))
  end)

  it("addition: 150 + 20%", function()
    assert.are.equal("180", first("150 + 20%"))
  end)

  it("subtraction: 150 - 10%", function()
    assert.are.equal("135", first("150 - 10%"))
  end)

  it("standalone: 50%", function()
    assert.are.equal("0.5", first("50%"))
  end)
end)

describe("bitwise functions", function()
  it("band(12,10)", function()
    assert.are.equal("8", first("band(12,10)"))
  end)

  it("bor(12,10)", function()
    assert.are.equal("14", first("bor(12,10)"))
  end)

  it("bxor(12,10)", function()
    assert.are.equal("6", first("bxor(12,10)"))
  end)

  it("lshift(1,4)", function()
    assert.are.equal("16", first("lshift(1,4)"))
  end)

  it("rshift(16,2)", function()
    assert.are.equal("4", first("rshift(16,2)"))
  end)
end)

describe("base input", function()
  it("hex literal: 0xFF", function()
    assert.is_true(labels("0xFF")["255"])
  end)

  it("binary literal: 0b1010", function()
    assert.is_true(labels("0b1010")["10"])
  end)
end)

describe("base output", function()
  it("offers hex and binary when show_bases", function()
    local s = source.new({ show_bases = true })
    local result
    s:get_completions({ line = "255", cursor = { 1, 3 }, bufnr = 0 }, function(res)
      result = res
    end)
    local found = {}
    for _, item in ipairs(result.items) do
      found[item.label] = true
    end
    assert.is_true(found["0xFF"])
    assert.is_true(found["0b11111111"])
  end)

  it("is suppressed by default", function()
    assert.is_nil(labels("255")["0xFF"])
  end)
end)

describe("digit grouping", function()
  it("accepts underscores in input: 1_000 + 1", function()
    assert.are.equal("1001", first("1_000 + 1"))
  end)

  it("offers grouped item when enabled", function()
    local s = source.new({ group_digits = "," })
    local result
    s:get_completions({ line = "1000000", cursor = { 1, 7 }, bufnr = 0 }, function(res)
      result = res
    end)
    local found = {}
    for _, item in ipairs(result.items) do
      found[item.label] = true
    end
    assert.is_true(found["1,000,000"])
  end)

  it("is suppressed by default", function()
    assert.is_nil(labels("1000000")["1,000,000"])
  end)
end)

describe("precision", function()
  it("tames float noise: 0.1+0.2", function()
    assert.are.equal("0.3", first("0.1+0.2"))
  end)

  it("honors configured precision: 1/3", function()
    assert.are.equal("0.33", complete_with({ precision = 2 }, "1/3").items[1].label)
  end)
end)

describe("separator", function()
  it("uses configured separator in equation", function()
    local result = complete_with({ separator = " => " }, "2+2=")
    assert.are.equal("2+2 => 4", result.items[2].label)
  end)
end)

describe("comment prefixes", function()
  it("strips C++ line comment: // 2+2", function()
    assert.are.equal("4", first("// 2+2"))
  end)

  it("strips block comment: /* 2+2", function()
    assert.are.equal("4", first("/* 2+2"))
  end)

  it("strips lisp comment: ; 2+2", function()
    assert.are.equal("4", first("; 2+2"))
  end)
end)
