return {
	"kevinhwang91/nvim-ufo",
	dependencies = { "kevinhwang91/promise-async" },
	keys = {
		{
			"zR",
			function()
				require("ufo").openAllFolds()
			end,
			desc = "Open all folds",
		},
		{
			"zM",
			function()
				require("ufo").closeAllFolds()
			end,
			desc = "Close all folds",
		},
		{
			"zf",
			function()
				require("ufo").closeAllFolds()
				-- Open only the absolute top level
				vim.cmd("normal! zr")
			end,
			desc = "Show top-level only",
		},
	},
	opts = {
		provider_selector = function()
			return { "treesitter", "indent" }
		end,
	},
	config = function(_, opts)
		require("ufo").setup(opts)
		vim.o.foldcolumn = "1"
		vim.o.foldlevel = 99
		vim.o.foldlevelstart = 99
		vim.o.foldenable = true
		vim.o.foldmethod = "manual" -- UFO manages folds
	end,
}
