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
