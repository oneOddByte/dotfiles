return {
	"stevearc/aerial.nvim",
	ft = { "markdown" },
	cmd = { "AerialToggle", "AerialOpen", "AerialClose" },
	config = function()
		require("aerial").setup()

		vim.keymap.set("n", "<leader>a", "<cmd>AerialToggle<CR>")
	end,
}
