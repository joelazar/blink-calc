local source = {}

-- Collect all math function names from Lua's math library
local math_keys = {}
for k, _ in pairs(math) do
  table.insert(math_keys, k)
end

function source.new(opts)
  local self = setmetatable({}, { __index = source })
  self.opts = opts or {}
  return self
end

-- Get trigger characters for math expressions
function source:get_trigger_characters()
  return { '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '+', '-', '*', '/', '=', '(', ')' }
end

-- Check if the source should be enabled
function source:enabled()
  return true
end

-- Find the start of a math expression by looking backwards from cursor
local function find_expression_start(line, col)
  local paren_count = 0
  local i = col

  while i > 0 do
    local char = line:sub(i, i)

    -- When moving backwards: increment on '(', decrement on ')'
    if char == '(' then
      paren_count = paren_count + 1
    elseif char == ')' then
      paren_count = paren_count - 1
    end

    -- Check if we've reached a boundary
    -- If paren_count > 1, we've gone past a complete function/group
    if paren_count > 1 then
      break
    end

    -- Check if character is part of a math expression
    -- Allow: digits, operators, parentheses, dot, comma, equals, spaces, and letters (for function names)
    if not char:match('[%w%+%-%*/%.%(%),=%s]') then
      if paren_count == 0 then
        break
      end
    end

    i = i - 1
  end

  return i + 1
end

-- Resolve math function names to their full qualified names
local function resolve_math_functions(expr)
  -- Handle all standard math functions (skip those already prefixed with math.)
  for _, key in ipairs(math_keys) do
    -- Replace function calls in the middle of expression (but not if already math.xxx)
    expr = expr:gsub('([^%w_%.])(' .. key .. ')%(', '%1math.%2(')
    -- Replace function calls at the start of expression
    expr = expr:gsub('^(' .. key .. ')%(', 'math.%1(')
  end

  -- Then handle common aliases
  expr = expr:gsub('([^%w_])(ln)%(', '%1math.log(')
  expr = expr:gsub('^(ln)%(', 'math.log(')

  return expr
end

-- Evaluate a mathematical expression
local function evaluate_expression(expr)
  -- Remove trailing '=' if present
  expr = expr:gsub('=$', '')

  -- Remove all spaces
  expr = expr:gsub('%s+', '')

  -- Resolve math functions
  expr = resolve_math_functions(expr)

  -- Try to evaluate the expression
  local func, err = load('return ' .. expr)
  if not func then
    return nil
  end

  local success, result = pcall(func)
  if not success then
    return nil
  end

  return result
end

-- Main completion function
function source:get_completions(ctx, callback)
  local line = ctx.line
  local col = ctx.cursor[2]

  -- Find the start of the expression
  local start_col = find_expression_start(line, col)
  local raw_expr = line:sub(start_col, col)

  -- Track the number of characters removed from the start
  local chars_removed = 0
  local expr = raw_expr

  -- Remove leading whitespace and track it
  local leading_spaces = expr:match('^(%s*)')
  if leading_spaces then
    chars_removed = chars_removed + #leading_spaces
    expr = expr:sub(#leading_spaces + 1)
  end

  -- Remove leading comment characters (-- or #) and track them
  local before_len = #expr
  expr = expr:gsub('^%-%-+%s*', '')
  expr = expr:gsub('^#+%s*', '')
  chars_removed = chars_removed + (before_len - #expr)

  -- Remove trailing whitespace (but don't track it)
  expr = expr:match('^(.-)%s*$') or expr

  -- Calculate the actual start position of the math expression (after comments/spaces)
  local expr_start_col = start_col + chars_removed

  -- If expression already contains "= <number>", ignore it (already calculated)
  if expr:match('=%s*[%d%.]+$') then
    callback()
    return
  end

  -- Check if we have a potential math expression
  -- Must contain at least one digit or operator (after removing trailing =)
  local expr_without_eq = expr:gsub('=$', '')
  if not expr_without_eq:match('[%d%+%-%*/%.%(%)]') then
    callback()
    return
  end

  -- Try to evaluate the expression
  local result = evaluate_expression(expr)

  if not result then
    callback()
    return
  end

  -- Format the result
  local result_str = tostring(result)

  -- Create completion items
  local items = {}

  -- Calculate the range to replace (from start of math expression to cursor)
  -- This excludes leading comments/spaces
  local range = {
    start = {
      line = ctx.cursor[1] - 1,  -- 0-indexed for LSP
      character = expr_start_col - 1,  -- 0-indexed for LSP
    },
    ['end'] = {
      line = ctx.cursor[1] - 1,
      character = col,
    },
  }

  -- Item 1: Just the result (replaces the entire expression)
  table.insert(items, {
    label = result_str,
    kind = require('blink.cmp.types').CompletionItemKind.Value,
    textEdit = {
      newText = result_str,
      range = range,
    },
  })

  -- Item 2: Expression with result (if expression ends with '=')
  if line:sub(col, col) == '=' or (col > 0 and line:sub(col - 1, col - 1) == '=') then
    local clean_expr = expr:gsub('=$', ''):gsub('%s+', ' '):match('^%s*(.-)%s*$')
    table.insert(items, {
      label = clean_expr .. ' = ' .. result_str,
      kind = require('blink.cmp.types').CompletionItemKind.Value,
      textEdit = {
        newText = clean_expr .. ' = ' .. result_str,
        range = range,
      },
    })
  end

  callback({ items = items })
end

return source
