---@module 'luassert'

local Currency = require("blink-calc.currency")

-- A throwaway cache path per call so tests never collide on disk.
local function tmp_path()
  return vim.fn.tempname() .. "-blink-calc-currency.json"
end

-- Run scheduled work inline so the async refresh resolves deterministically
-- within a single `resolve` call. The non-blocking behaviour itself is covered
-- separately with the real scheduler.
local function sync_schedule()
  Currency.reset()
  Currency.clock = os.time
  Currency.schedule = function(fn)
    fn()
  end
end

describe("currency rate resolution", function()
  before_each(sync_schedule)

  it("returns a configured static table unchanged", function()
    local rates = { usd = 1, eur = 2 }
    assert.are.equal(rates, Currency.resolve({ currency_rates = rates }))
  end)

  it("returns an empty table when nothing is configured", function()
    assert.are.same({}, Currency.resolve({}))
  end)

  it("calls a provider function and returns its rates", function()
    local rates = Currency.resolve({
      currency_rates = function(done)
        done({ usd = 1, eur = 2 })
      end,
      currency_cache_path = tmp_path(),
    })
    assert.are.equal(2, rates.eur)
  end)
end)

describe("daily caching", function()
  before_each(sync_schedule)

  it("pulls only once within the TTL window", function()
    local calls = 0
    local opts = {
      currency_rates = function(done)
        calls = calls + 1
        done({ usd = 1 })
      end,
      currency_cache_path = tmp_path(),
      currency_cache_ttl = 86400,
    }
    Currency.clock = function()
      return 1000
    end
    Currency.resolve(opts)
    Currency.resolve(opts)
    Currency.resolve(opts)
    assert.are.equal(1, calls)
  end)

  it("re-pulls after the TTL (a day) elapses", function()
    local calls = 0
    local opts = {
      currency_rates = function(done)
        calls = calls + 1
        done({ usd = calls })
      end,
      currency_cache_path = tmp_path(),
      currency_cache_ttl = 86400,
    }
    Currency.clock = function()
      return 1000
    end
    Currency.resolve(opts)
    Currency.clock = function()
      return 1000 + 86400
    end
    local rates = Currency.resolve(opts)
    assert.are.equal(2, calls)
    assert.are.equal(2, rates.usd)
  end)

  it("respects a custom (shorter) TTL", function()
    local calls = 0
    local opts = {
      currency_rates = function(done)
        calls = calls + 1
        done({ usd = 1 })
      end,
      currency_cache_path = tmp_path(),
      currency_cache_ttl = 60,
    }
    Currency.clock = function()
      return 0
    end
    Currency.resolve(opts)
    Currency.clock = function()
      return 61
    end
    Currency.resolve(opts)
    assert.are.equal(2, calls)
  end)
end)

describe("disk persistence", function()
  before_each(sync_schedule)

  it("serves a same-day cache from disk without re-calling the provider", function()
    local path = tmp_path()
    local calls = 0
    local provider = function(done)
      calls = calls + 1
      done({ usd = 1, eur = 3 })
    end
    Currency.clock = function()
      return 5000
    end
    Currency.resolve({ currency_rates = provider, currency_cache_path = path })
    assert.are.equal(1, calls)

    -- Simulate a Neovim restart: the in-memory memo is gone but the file remains.
    Currency.reset()
    local rates = Currency.resolve({ currency_rates = provider, currency_cache_path = path })
    assert.are.equal(1, calls)
    assert.are.equal(3, rates.eur)
  end)
end)

describe("provider failures", function()
  before_each(sync_schedule)

  it("falls back to a stale disk cache when the provider errors", function()
    local path = tmp_path()
    Currency.clock = function()
      return 0
    end
    Currency.resolve({
      currency_rates = function(done)
        done({ usd = 1, eur = 9 })
      end,
      currency_cache_path = path,
    })

    Currency.reset()
    Currency.clock = function()
      return 10 * 86400
    end
    local rates = Currency.resolve({
      currency_rates = function()
        error("network down")
      end,
      currency_cache_path = path,
    })
    assert.are.equal(9, rates.eur)
  end)

  it("keeps previously cached rates when a refresh yields nothing", function()
    local path = tmp_path()
    Currency.clock = function()
      return 0
    end
    Currency.resolve({
      currency_rates = function(done)
        done({ usd = 1, eur = 8 })
      end,
      currency_cache_path = path,
    })
    Currency.clock = function()
      return 10 * 86400
    end
    local rates = Currency.resolve({
      currency_rates = function(done)
        done({})
      end,
      currency_cache_path = path,
    })
    assert.are.equal(8, rates.eur)
  end)

  it("returns an empty table when the provider errors and no cache exists", function()
    local rates = Currency.resolve({
      currency_rates = function()
        error("nope")
      end,
      currency_cache_path = tmp_path(),
    })
    assert.are.same({}, rates)
  end)

  it("ignores a non-table provider result", function()
    local rates = Currency.resolve({
      currency_rates = function(done)
        done("not a table")
      end,
      currency_cache_path = tmp_path(),
    })
    assert.are.same({}, rates)
  end)
end)

describe("non-blocking refresh", function()
  before_each(function()
    Currency.reset()
    Currency.clock = os.time
    Currency.schedule = vim.schedule
  end)

  it("never runs the provider on the resolve (completion) path", function()
    local calls = 0
    local opts = {
      currency_rates = function(done)
        calls = calls + 1
        done({ usd = 1, eur = 2 })
      end,
      currency_cache_path = tmp_path(),
    }
    -- Cold start: returns immediately with empty rates, provider not yet run.
    assert.are.same({}, Currency.resolve(opts))
    assert.are.equal(0, calls)
    -- The provider runs once control returns to the event loop.
    vim.wait(1000, function()
      return calls > 0
    end)
    assert.are.equal(1, calls)
  end)
end)

describe("built-in providers", function()
  before_each(sync_schedule)

  it("resolves a named built-in provider through M.providers", function()
    local captured
    Currency.providers["test-fixed"] = function(done)
      captured = true
      done({ usd = 1, eur = 4 })
    end
    local rates = Currency.resolve({
      currency_rates = "test-fixed",
      currency_cache_path = tmp_path(),
    })
    Currency.providers["test-fixed"] = nil
    assert.is_true(captured)
    assert.are.equal(4, rates.eur)
  end)

  it("ships the er-api provider", function()
    assert.is_function(Currency.providers["er-api"])
  end)
end)
