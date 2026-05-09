return {
	"ThePrimeagen/harpoon",
	branch = "harpoon2",
	dependencies = { "nvim-lua/plenary.nvim" },
	-- This ensures the plugin loads only when you hit the prefix
	keys = function()
		local harpoon = require("harpoon")
		local keys = {
			-- Main Menu & Adding
			{
				"<leader>hh",
				function()
					harpoon:list():add()
				end,
				desc = "Harpoon Add File",
			},
			{
				"<leader>he",
				function()
					harpoon.ui:toggle_quick_menu(harpoon:list())
				end,
				desc = "Harpoon Menu",
			},
		}

		-- Map h + a, s, d, f, g to harpoon slots 1-5
		-- (Adjust the chars string if you want a different order)
		local chars = { "a", "s", "d", "f", "g" }
		for i, char in ipairs(chars) do
			table.insert(keys, {
				"<leader>h" .. char,
				function()
					harpoon:list():select(i)
				end,
				desc = "Harpoon to Slot " .. i,
			})
		end

		return keys
	end,
	config = function()
		require("harpoon"):setup()
	end,
}
