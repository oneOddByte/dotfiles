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
		cmd = "CustomColorschemeRose",
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
		cmd = "CustomColorschemeKanagawa",
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
		cmd = "CustomColorschemeGruvbox",
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

	{
		"folke/tokyonight.nvim",
		lazy = false,
		priority = 1000,
		opts = {},
	},

	{
		"cdmill/neomodern.nvim",
		lazy = true,
		priority = 1000,
		config = function()
			require("neomodern").setup({
				-----MAIN OPTIONS-----
				--
				-- Can be one of: 'iceclimber' | 'gyokuro' | 'hojicha' | 'roseprime'
				theme = "iceclimber",
				-- Can be one of: 'light' | 'dark', or set via vim.o.background
				variant = "dark",
				-- Use an alternate, darker bg
				alt_bg = false,
				-- If true, docstrings will be highlighted like strings, otherwise they will be
				-- highlighted like comments. Note, behavior is dependent on the language server.
				colored_docstrings = true,
				-- If true, highlights the {sign,fold} column the same as cursorline
				cursorline_gutter = true,
				-- If true, highlights the gutter darker than the bg
				dark_gutter = false,
				-- if true favor treesitter highlights over semantic highlights
				favor_treesitter_hl = false,
				-- Don't set background of floating windows. Recommended for when using floating
				-- windows with borders.
				plain_float = false,
				-- Show the end-of-buffer character
				show_eob = true,
				-- If true, enable the vim terminal colors
				term_colors = true,
				-- Keymap (in normal mode) to toggle between light and dark variants.
				toggle_variant_key = nil,
				-- Don't set background
				transparent = false,

				-----DIAGNOSTICS and CODE STYLE-----
				--
				diagnostics = {
					darker = true, -- Darker colors for diagnostic
					undercurl = true, -- Use undercurl for diagnostics
					background = true, -- Use background color for virtual text
				},
				-- The following table accepts values the same as the `gui` option for normal
				-- highlights. For example, `bold`, `italic`, `underline`, `none`.
				code_style = {
					comments = "italic",
					conditionals = "none",
					functions = "none",
					keywords = "none",
					headings = "bold", -- Markdown headings
					operators = "none",
					keyword_return = "none",
					strings = "none",
					variables = "none",
				},

				-----PLUGINS-----
				--
				-- The following options allow for more control over some plugin appearances.
				plugin = {
					lualine = {
						-- Bold lualine_a sections
						bold = true,
						-- Don't set section/component backgrounds. Recommended to not set
						-- section/component separators.
						plain = false,
					},
					cmp = { -- works for nvim.cmp and blink.nvim
						-- Don't highlight lsp-kind items. Only the current selection will be highlighted.
						plain = false,
						-- Reverse lsp-kind items' highlights in blink/cmp menu.
						reverse = false,
					},
				},

				-- CUSTOM HIGHLIGHTS --
				--
				-- Override default colors
				colors = {},
				-- Override highlight groups
				highlights = {},
			})

			require("neomodern").load()
		end,
	},
}
