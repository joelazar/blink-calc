-- Test file for blink-calc plugin
-- Run with: nvim --headless -c "luafile tests/test_calc.lua" -c "qa"

local source_module = require('blink-calc')

-- Helper to create a mock context
local function create_context(line, col)
  return {
    line = line,
    cursor = { 1, col },
    bufnr = 0,
  }
end

-- Test counter
local tests_passed = 0
local tests_failed = 0

-- Test helper
local function test(name, fn)
  print("Testing: " .. name)
  local success, err = pcall(fn)
  if success then
    tests_passed = tests_passed + 1
    print("  ✓ PASSED")
  else
    tests_failed = tests_failed + 1
    print("  ✗ FAILED: " .. tostring(err))
  end
  print()
end

-- Assert helper
local function assert_equal(actual, expected, msg)
  if actual ~= expected then
    error((msg or "Assertion failed") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
  end
end

local function assert_not_nil(value, msg)
  if value == nil then
    error(msg or "Expected non-nil value")
  end
end

-- Initialize the source
print("=== Testing blink-calc ===\n")

test("Source can be instantiated", function()
  local source = source_module.new()
  assert_not_nil(source, "Source should be created")
end)

test("Source has required methods", function()
  local source = source_module.new()
  assert_not_nil(source.get_completions, "Should have get_completions method")
  assert_not_nil(source.get_trigger_characters, "Should have get_trigger_characters method")
  assert_not_nil(source.enabled, "Should have enabled method")
end)

test("Get trigger characters returns expected array", function()
  local source = source_module.new()
  local triggers = source:get_trigger_characters()
  assert_not_nil(triggers, "Should return trigger characters")
  assert_equal(type(triggers), "table", "Should return a table")
end)

test("Source is enabled", function()
  local source = source_module.new()
  local enabled = source:enabled()
  assert_equal(enabled, true, "Source should be enabled")
end)

test("Simple addition: 2+2", function()
  local source = source_module.new()
  local ctx = create_context("2+2", 3)
  local result = nil

  source:get_completions(ctx, function(res)
    result = res
  end)

  assert_not_nil(result, "Should return a result")
  assert_not_nil(result.items, "Should have items")
  assert_equal(#result.items > 0, true, "Should have at least one item")
  assert_equal(result.items[1].label, "4", "Should calculate 2+2=4")
end)

test("Multiplication: 5*3", function()
  local source = source_module.new()
  local ctx = create_context("5*3", 3)
  local result = nil

  source:get_completions(ctx, function(res)
    result = res
  end)

  assert_not_nil(result, "Should return a result")
  assert_not_nil(result.items, "Should have items")
  assert_equal(result.items[1].label, "15", "Should calculate 5*3=15")
end)

test("Complex expression: 10*5+3", function()
  local source = source_module.new()
  local ctx = create_context("10*5+3", 6)
  local result = nil

  source:get_completions(ctx, function(res)
    result = res
  end)

  assert_not_nil(result, "Should return a result")
  assert_not_nil(result.items, "Should have items")
  assert_equal(result.items[1].label, "53", "Should calculate 10*5+3=53")
end)

test("Expression with parentheses: (2+3)*4", function()
  local source = source_module.new()
  local ctx = create_context("(2+3)*4", 7)
  local result = nil

  source:get_completions(ctx, function(res)
    result = res
  end)

  assert_not_nil(result, "Should return a result")
  assert_not_nil(result.items, "Should have items")
  assert_equal(result.items[1].label, "20", "Should calculate (2+3)*4=20")
end)

test("Math function: sqrt(16)", function()
  local source = source_module.new()
  local ctx = create_context("sqrt(16)", 8)
  local result = nil

  source:get_completions(ctx, function(res)
    result = res
  end)

  assert_not_nil(result, "Should return a result")
  assert_not_nil(result.items, "Should have items")
  -- Accept both "4" and "4.0" as valid results
  local label = result.items[1].label
  assert_equal(label == "4" or label == "4.0", true, "Should calculate sqrt(16)=4 or 4.0, got " .. label)
end)

test("Expression with equals sign: 2+2=", function()
  local source = source_module.new()
  local ctx = create_context("2+2=", 4)
  local result = nil

  source:get_completions(ctx, function(res)
    result = res
  end)

  assert_not_nil(result, "Should return a result")
  assert_not_nil(result.items, "Should have items")
  assert_equal(#result.items, 2, "Should have two items with equals sign")
  assert_equal(result.items[1].label, "4", "First item should be just the result")
end)

test("Non-math text should not trigger", function()
  local source = source_module.new()
  local ctx = create_context("hello world", 11)
  local result = nil

  source:get_completions(ctx, function(res)
    result = res
  end)

  -- Should return empty or nil
  assert_equal(result == nil or result.items == nil or #result.items == 0, true, "Should not complete non-math text")
end)

-- Print summary
print("=== Test Summary ===")
print("Passed: " .. tests_passed)
print("Failed: " .. tests_failed)
print("Total:  " .. (tests_passed + tests_failed))

if tests_failed > 0 then
  os.exit(1)
end
