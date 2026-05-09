return {
	"sindrets/diffview.nvim",
	cmd = { "DiffviewOpen", "DiffviewFileHistory" },
	keys = {
		{ "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diffview Open" },
		{ "<leader>gh", "<cmd>DiffviewFileHistory %", desc = "Diffview Current File History" },
		{ "<leader>gH", "<cmd>DiffviewFileHistory", desc = "Diffview Project History" },
		{ "<leader>gl", "<cmd>diffget LOCAL<cr>", desc = "Diffget Local (Left)" },
		{ "<leader>gr", "<cmd>diffget REMOTE<cr>", desc = "Diffget Remote (Right)" },
	},
	opts = {
		enhanced_diff_hl = true, -- Better syntax highlighting in diffs
		use_icons = true,
		view = {
			-- Use the "three-way" layout for merge conflicts
			merge_tool = {
				layout = "diff3_mixed",
				disable_diagnostics = true, -- Keep the screen clean during conflicts
			},
		},
		hooks = {
			diff_buf_read = function(bufnr)
				-- Disable folding by default so you can see the code immediately
				vim.opt_local.foldenable = false
			end,
		},
	},
	config = function(_, opts)
		require("diffview").setup(opts)

		-- Custom commands to make life easier
		vim.api.nvim_create_user_command("DiffClose", "DiffviewClose", {})
		vim.api.nvim_create_user_command("DiffReview", "DiffviewOpen origin/main...HEAD", {})
	end,
}
