-- ~/.config/nvim/LuaSnip/markdown.lua
local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node

return {
	s("meta", {
		t({ "---", "title: " }),
		i(1, "Note Title"),
		t({ "", "tags: [" }),
		i(2),
		t({ "]" }),
		t({ "", "date: " }),
		f(function()
			return os.date("%Y-%m-%d")
		end, {}),
		t({ "", "---", "" }),
		i(0),
	}),
}
