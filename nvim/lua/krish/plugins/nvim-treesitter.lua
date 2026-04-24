return {
	{
		"nvim-treesitter/nvim-treesitter",
		lazy = false,
		branch = "main",
		build = ":TSUpdate",
		dependencies = {
			"windwp/nvim-ts-autotag",
			"nvim-treesitter/nvim-treesitter-textobjects",
		},
		init = function()
			-- Enable highlighting + indentation for every filetype
			vim.api.nvim_create_autocmd("FileType", {
				callback = function()
					pcall(vim.treesitter.start)
					vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end,
			})

			-- Install parsers if missing (replaces ensure_installed)
			local wanted = {
				"json",
				"html",
				"css",
				"bash",
				"lua",
				"vim",
				"gitignore",
				"vimdoc",
				"c",
				"cpp",
				"java",
				"yaml",
				"markdown",
				"markdown_inline",
				"python",
			}
			local installed = require("nvim-treesitter.config").get_installed()
			local to_install = vim.iter(wanted)
				:filter(function(p)
					return not vim.tbl_contains(installed, p)
				end)
				:totable()
			if #to_install > 0 then
				require("nvim-treesitter").install(to_install)
			end
		end,

		config = function()
			-- nvim-ts-autotag is now configured standalone
			require("nvim-ts-autotag").setup()

			-- Incremental selection is now built into Neovim; set it up via the API
			vim.keymap.set("n", "<C-space>", function()
				vim.treesitter.node_select()
			end, { desc = "Init treesitter selection" })
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter-context",
		event = "VeryLazy",
		config = function()
			require("treesitter-context").setup({
				enable = true,
				max_lines = 1,
				mode = "cursor",
			})
		end,
	},
}
