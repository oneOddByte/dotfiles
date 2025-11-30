return {
	"nvim-tree/nvim-tree.lua",
	dependencies = "nvim-tree/nvim-web-devicons",
	-- cmd = { "NvimTreeToggle", "NvimTreeFindFile", "NvimTreeCollapse", "NvimTreeRefresh" },
	-- keys = {
	-- 	{ "<leader>ee", "<cmd>NvimTreeToggle<CR>", desc = "Toggle file explorer" },
	-- 	{ "<leader>ef", "<cmd>NvimTreeFindFileToggle<CR>", desc = "Toggle file explorer on current file" },
	-- 	{ "<leader>ec", "<cmd>NvimTreeCollapse<CR>", desc = "Collapse file explorer" },
	-- 	{ "<leader>er", "<cmd>NvimTreeRefresh<CR>", desc = "Refresh file explorer" },
	-- },
	init = function()
		-- CRITICAL: Disable netrw immediately, before any file operations
		vim.g.loaded_netrw = 1
		vim.g.loaded_netrwPlugin = 1

		-- Also disable netrw for directory opening
		vim.api.nvim_create_autocmd("VimEnter", {
			callback = function()
				if vim.fn.argc() == 1 then
					local arg = vim.fn.argv(0)
					if vim.fn.isdirectory(arg) == 1 then
						vim.cmd("bd 1")
						require("lazy").load({ plugins = { "nvim-tree.lua" } })
						vim.cmd("NvimTreeOpen " .. arg)
					end
				end
			end,
		})
	end,
	config = function()
		local nvimtree = require("nvim-tree")

		nvimtree.setup({
			sort_by = "extension",
			view = {
				width = 30,
				relativenumber = false,
				number = false,
			},
			renderer = {
				indent_markers = {
					enable = true,
				},
			},
			actions = {
				open_file = {
					window_picker = {
						enable = false,
					},
				},
			},
			filters = {
				custom = { ".DS_Store" },
			},
			git = {
				ignore = false,
			},
		})

		vim.keymap.set("n", "<leader>fdc", ":Telescope dap commands<CR>", { desc = "Debug: Commands" })

		vim.keymap.set("n", "<leader>ee", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle file explorer" })
		vim.keymap.set(
			"n",
			"<leader>ef",
			"<cmd>NvimTreeFindFileToggle<CR>",
			{ desc = "Toggle file explorer on current file" }
		)
		vim.keymap.set("n", "<leader>ec", "<cmd>NvimTreeCollapse<CR>", { desc = "Collapse file explorer" })
		vim.keymap.set("n", "<leader>er", "<cmd>NvimTreeRefresh<CR>", { desc = "Refresh file explorer" })
	end,
}
