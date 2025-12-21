return {
	"lukas-reineke/indent-blankline.nvim",
	-- event = { "BufReadPre", "BufNewFile" },
	event = "VeryLazy",
	main = "ibl",
	opts = {
		indent = { char = "┊" },
	},
}
