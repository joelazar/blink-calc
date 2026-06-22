---@class BlinkCalc.Currency
local M = {}

-- Seams overridable in tests -------------------------------------------------

---Returns the current epoch time. Swapped out in tests to simulate a day
---rolling over without waiting.
M.clock = os.time

---Defers work to the main loop. The provider and every disk/memo write run
---through this seam so they never execute on the synchronous completion path.
---Tests replace it with a synchronous runner to make caching deterministic.
M.schedule = vim.schedule

---Default on-disk cache location, under Neovim's cache dir.
---@return string
function M.default_path()
  return vim.fs.normalize(vim.fn.stdpath("cache") .. "/blink-calc/currency.json")
end

-- Built-in providers, selectable by name via `currency_rates = "er-api"`. Each
-- is async (P1): it fetches off the main loop with `vim.system` and a hard
-- timeout, then delivers `code -> rate` (in USD per unit) through `done`.
---@type table<string, fun(done: fun(rates: table<string, number>))>
M.providers = {
  ["er-api"] = function(done)
    vim.system(
      { "curl", "-s", "--max-time", "10", "https://open.er-api.com/v6/latest/USD" },
      { text = true },
      function(out)
        local ok, body = pcall(vim.json.decode, out.stdout or "")
        if not ok or type(body) ~= "table" or type(body.rates) ~= "table" then
          return done({})
        end
        -- The API returns "units of <code> per 1 USD"; convert() uses
        -- value * rates[from] / rates[to], so invert to "USD per unit".
        local rates = {}
        for code, per_usd in pairs(body.rates) do
          if type(per_usd) == "number" and per_usd ~= 0 then
            rates[code:lower()] = 1 / per_usd
          end
        end
        done(rates)
      end
    )
  end,
}

-- In-memory memo, keyed by cache path, so we don't touch disk on every
-- keystroke. Cleared by M.reset() (and effectively on Neovim restart).
---@type table<string, { fetched_at: number, rates: table<string, number> }>
local memo = {}

-- Paths with a refresh already scheduled/in flight, so rapid keystrokes do not
-- launch a provider per stroke. Cleared once the provider resolves or errors.
---@type table<string, true>
local inflight = {}

-- Paths we have already warned about an unreadable cache for, so a persistently
-- corrupt file does not notify on every keystroke.
---@type table<string, true>
local notified = {}

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
    -- Corrupt/partial cache: surface it once, then treat as a miss so the
    -- provider re-fetches. A missing file returns above without a warning.
    if not notified[path] then
      notified[path] = true
      require("blink-calc.util").warn("currency cache is unreadable, re-fetching: " .. path)
    end
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

---@param entry { fetched_at: number }?
---@param now number
---@param ttl number
---@return boolean
local function fresh(entry, now, ttl)
  return entry ~= nil and type(entry.fetched_at) == "number" and (now - entry.fetched_at) < ttl
end

---Best currently-available entry: in-memory memo first, then disk (memoized).
---@param path string
---@return { fetched_at: number, rates: table<string, number> }?
local function cached(path)
  if memo[path] then
    return memo[path]
  end
  local disk = read_cache(path)
  if disk then
    memo[path] = disk
  end
  return disk
end

---@param path string
---@param rates any provider payload
local function persist(path, rates)
  if type(rates) ~= "table" then
    return
  end
  -- An empty result means "no fresh data": keep whatever rates we already have
  -- (stale beats nothing), but still record the attempt so we hold off until the
  -- TTL lapses instead of re-fetching on the next keystroke.
  if next(rates) == nil then
    local prior = memo[path] or read_cache(path)
    rates = prior and prior.rates or rates
  end
  local entry = { fetched_at = M.clock(), rates = rates }
  write_cache(path, entry)
  memo[path] = entry
end

---Pull fresh rates off the completion hot path.
---
---The provider is invoked through `M.schedule` (the main loop), never inline,
---so a slow or blocking provider can never freeze the keystroke that triggered
---it. The provider delivers its result by calling the supplied `done(rates)`
---callback, which may fire later (e.g. from a `vim.system` callback); the
---disk/memo write is itself scheduled so `done` is safe to call from a
---fast-event context.
---
---Boundary: the provider is arbitrary user code. A synchronous error is caught
---here and translated into a no-op (stale/empty rates keep being served);
---async failures are the provider's responsibility (it must call `done({})`).
---@param provider fun(done: fun(rates: table<string, number>))
---@param path string
local function refresh(provider, path)
  if inflight[path] then
    return
  end
  inflight[path] = true
  M.schedule(function()
    local ok = pcall(provider, function(rates)
      M.schedule(function()
        persist(path, rates)
        inflight[path] = nil
      end)
    end)
    if not ok then
      inflight[path] = nil
    end
  end)
end

---Drop the in-memory cache. Mainly for tests and `:checkhealth`.
function M.reset()
  memo = {}
  inflight = {}
  notified = {}
end

---Resolve the effective currency-rate table for a single evaluation.
---
---`currency_rates` may be:
---  * a `table` of `code -> rate` (static; returned as-is, the original
---    pure-Lua behaviour),
---  * a `function` provider invoked as `provider(done)`. It must call
---    `done(rates)` with a `code -> rate` table when its (ideally async) fetch
---    completes. The result is cached on disk and reused until
---    `currency_cache_ttl` seconds elapse (default 86400, i.e. pulled at most
---    once per day), or
---  * a `string` naming a built-in provider in `M.providers` (e.g. `"er-api"`),
---    resolved to the provider function above.
---
---This call never blocks: on a cache miss/expiry it schedules a refresh and
---returns the best rates it currently has (stale, or empty on a cold start).
---Fresh rates surface on a later evaluation once the provider resolves.
---@param opts? table { currency_rates, currency_cache_ttl, currency_cache_path }
---@return table<string, number>
function M.resolve(opts)
  opts = opts or {}
  local provider = opts.currency_rates
  if type(provider) == "string" then
    provider = M.providers[provider]
  end
  if type(provider) ~= "function" then
    return type(opts.currency_rates) == "table" and opts.currency_rates or {}
  end

  local ttl = opts.currency_cache_ttl or 86400
  local now = M.clock()
  local path = opts.currency_cache_path or M.default_path()

  local entry = cached(path)
  if not fresh(entry, now, ttl) then
    refresh(provider, path)
    -- A synchronous refresh (the test seam) has populated the memo by now; an
    -- async one has not, so we keep serving whatever we already had.
    entry = memo[path] or entry
  end

  return entry and entry.rates or {}
end

return M
