local vim = vim

vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	callback = function()
		vim.opt.conceallevel = 2
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = "obsidian",
	callback = function()
		vim.opt.conceallevel = 2
	end,
})

-- Create an autocommand for markdown files to enable continuous bullet points
vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	callback = function()
		vim.opt_local.wrap = true
		vim.opt_local.listchars = { tab = "▸ ", trail = "·" }
		vim.opt_local.formatoptions:append("r") -- "r" continues comments/lists on new lines
		vim.opt_local.formatoptions:remove("a") -- Remove "a" to prevent auto-formatting
		vim.opt_local.smartindent = true
	end,
})

vim.api.nvim_create_user_command("DailyNote", function()
	local date = os.date("%d-%m-%Y")
	local note_path = "/home/krish/vault/journal/" .. date .. ".md"
	local template_path = "/home/krish/vault/templates/daily-journal.md"

	-- Check if the journal note already exists
	local file = io.open(note_path, "r")

	if not file then
		-- Read the template and replace {{date}} with the current date
		local template = io.open(template_path, "r")
		if template then
			local content = template:read("*all")
			template:close()

			-- Replace {{date}} with the actual date
			content = content:gsub("{{date}}", date)

			-- Write the new content into today's journal note
			local new_note = io.open(note_path, "w")
			if new_note then
				new_note:write(content)
				new_note:close()
			end
		end
	else
		file:close()
	end

	-- Open the note in Neovim
	vim.cmd("e " .. note_path)
end, {})
