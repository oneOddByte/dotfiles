return {

	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 10000,
		lazy = false,
		config = function()
			require("catppuccin").setup({ flavor = "mocha" }) -- Choose flavor
			vim.cmd("colorscheme catppuccin")
		end,
	},

	-- rose pine main looks sexy
	{
		"rose-pine/neovim",
		name = "rose-pine",
		lazy = true,
		-- priority = 1000,
		config = function()
			require("rose-pine").setup({ variant = "moon" })
			-- vim.cmd("colorscheme rose-pine")
		end,
		vim.opt.fillchars:append({ eob = " " }),
	},

	-- kanagawava waves is good
	{
		"rebelot/kanagawa.nvim",

		lazy = true,
		-- priority = 1000,
		config = function()
			require("kanagawa").setup({
				transparent = false,
				colors = { theme = { all = { ui = { bg_gutter = "none" } } } },
			})
			-- vim.cmd("colorscheme kanagawa")
		end,
	},

	{
		"sainnhe/gruvbox-material",
		lazy = true,
		-- priority = 1000, -- Load before other UI plugins
		config = function()
			vim.g.gruvbox_material_background = "hard" -- 'soft', 'medium', 'hard'
			vim.g.gruvbox_material_foreground = "original"
			vim.g.gruvbox_material_better_performance = 1
			-- vim.g.gruvbox_material_enable_italic = 1
			vim.g.gruvbox_material_enable_bold = 1

			vim.g.gruvbox_material_ui_contrast = "high" -- Options: 'low', 'medium', 'high'
			vim.g.gruvbox_material_disable_italic_comment = 0
			vim.g.gruvbox_material_diagnostic_text_highlight = 1
			vim.g.gruvbox_material_diagnostic_line_highlight = 1
			vim.g.gruvbox_material_diagnostic_virtual_text = "colored"

			-- Apply the colorscheme
			vim.cmd("colorscheme gruvbox-material")
		end,
	},
}
