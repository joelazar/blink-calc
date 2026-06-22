---@class BlinkCalc.Currency
local M = {}

-- Seams overridable in tests -------------------------------------------------

---Returns the current epoch time. Swapped out in tests to simulate a day
---rolling over without waiting.
M.clock = os.time

---Default on-disk cache location, under Neovim's cache dir.
---@return string
function M.default_path()
  return vim.fs.normalize(vim.fn.stdpath("cache") .. "/blink-calc/currency.json")
end

-- In-memory memo, keyed by cache path, so we don't touch disk on every
-- keystroke. Cleared by M.reset() (and effectively on Neovim restart).
---@type table<string, { fetched_at: number, rates: table<string, number> }>
local memo = {}

---@param path string
---@return { fetched_at: number, rates: table<string, number> }?
local function read_cache(path)
  local fd = io.open(path, "r")
  if not fd then
    return nil
  end
  local content = fd:read("*a")
  fd:close()
  local ok, data = pcall(vim.json.decode, content)
  if not ok or type(data) ~= "table" or type(data.rates) ~= "table" then
    return nil
  end
  return data
end

---@param path string
---@param entry { fetched_at: number, rates: table<string, number> }
local function write_cache(path, entry)
  local dir = path:match("^(.*)[/\\][^/\\]+$")
  if dir then
    vim.fn.mkdir(dir, "p")
  end
  local ok, encoded = pcall(vim.json.encode, entry)
  if not ok then
    return
  end
  local fd = io.open(path, "w")
  if not fd then
    return
  end
  fd:write(encoded)
  fd:close()
end

---Drop the in-memory cache. Mainly for tests and `:checkhealth`.
function M.reset()
  memo = {}
end

---Resolve the effective currency-rate table for a single evaluation.
---
---`currency_rates` may be either:
---  * a `table` of `code -> rate` (static; returned as-is, the original
---    pure-Lua behaviour), or
---  * a `function` returning such a table (a provider). Provider results are
---    cached on disk and reused until `currency_cache_ttl` seconds elapse
---    (default 86400, i.e. pulled at most once per day).
---@param opts? table { currency_rates, currency_cache_ttl, currency_cache_path }
---@return table<string, number>
function M.resolve(opts)
  opts = opts or {}
  local provider = opts.currency_rates
  if type(provider) ~= "function" then
    return type(provider) == "table" and provider or {}
  end

  local ttl = opts.currency_cache_ttl or 86400
  local now = M.clock()
  local path = opts.currency_cache_path or M.default_path()

  local function fresh(entry)
    return entry ~= nil and type(entry.fetched_at) == "number" and (now - entry.fetched_at) < ttl
  end

  -- 1. In-memory memo (cheapest; hit on every keystroke within a session).
  if fresh(memo[path]) then
    return memo[path].rates
  end

  -- 2. On-disk cache (survives restarts; the once-per-day guarantee).
  local disk = read_cache(path)
  if fresh(disk) then
    memo[path] = disk
    return disk.rates
  end

  -- 3. Cache miss/expiry: pull fresh rates from the provider.
  local ok, rates = pcall(provider)
  if ok and type(rates) == "table" then
    local entry = { fetched_at = now, rates = rates }
    write_cache(path, entry)
    memo[path] = entry
    return rates
  end

  -- 4. Provider failed: prefer stale rates over nothing.
  if disk then
    memo[path] = disk
    return disk.rates
  end
  if memo[path] then
    return memo[path].rates
  end
  return {}
end

return M
