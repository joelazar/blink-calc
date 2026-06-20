vim.env.LAZY_STDPATH = ".repro"
load(vim.fn.system("curl -s https://raw.githubusercontent.com/folke/lazy.nvim/main/bootstrap.lua"))()

local plugins = {
  {
    "saghen/blink.cmp",
    dependencies = {
      {
        "joelazar/blink-calc",
        dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h"),
      },
    },
    version = "*",
    opts = {
      sources = {
        default = { "calc" },
        providers = {
          calc = {
            name = "Calc",
            module = "blink-calc",
          },
        },
      },
    },
  },
}

require("lazy.minit").repro({ spec = plugins })
