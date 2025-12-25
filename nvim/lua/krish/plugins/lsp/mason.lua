return {
	"williamboman/mason.nvim",
	cmd = "Mason",
	-- event = { "BufReadPre", "BufNewFile" },
	config = function()
		local mason = require("mason")
		local mason_lspconfig = require("mason-lspconfig")
		local mason_tool_installer = require("mason-tool-installer")

		mason.setup()

		mason_lspconfig.setup({
			ensure_installed = {
				"jdtls",
				"black",
				"clangd",
				"codelldb",
				"debugpy",
				"eslint_d",
				"html-lsphtml,html",
				"isort",
				"lua-language-server",
				"pylint",
				"pyright",
				"ruff",
			},
			automatic_installation = true,
		})

		mason_tool_installer.setup({
			ensure_installed = {
				"prettier",
				"stylua",
				"eslint_d",
			},
			auto_update = false,
			run_on_start = true,
		})
	end,
}
