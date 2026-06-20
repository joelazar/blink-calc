---@diagnostic disable: lowercase-global

local _MODREV, _SPECREV = "scm", "-1"
rockspec_format = "3.0"
version = _MODREV .. _SPECREV

local user = "joelazar"
package = "blink-calc"

description = {
	summary = "A blink.cmp source for math calculations",
	detailed = [[
blink-calc is a blink.cmp completion source that evaluates math expressions
as you type, similar to cmp-calc.
  ]],
	labels = { "neovim", "blink.cmp", "completion", "calc", "lua" },
	homepage = "https://github.com/" .. user .. "/" .. package,
	license = "MIT",
}

dependencies = {
	"lua >= 5.1",
}

source = {
	url = "git://github.com/" .. user .. "/" .. package,
}

build = {
	type = "builtin",
}
