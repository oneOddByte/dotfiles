-- cf_test.lua
-- Runs ~/.dotfiles/codeforces_test.sh in a real PTY terminal inside a
-- floating window. Uses termopen() so interactive prompts (cat, Ctrl-D) work
-- exactly like a normal terminal.

local M = {}

local CF_SCRIPT = vim.fn.expand("~/.dotfiles/codeforces_test.sh")

-- Track the float so we can toggle it
local state = {
	win = nil,
	buf = nil,
}

local function float_cfg()
	local width = math.floor(vim.o.columns * 0.8)
	local height = math.min(24, vim.o.lines - 4)
	return {
		relative = "editor",
		width = width,
		height = height,
		row = math.floor((vim.o.lines - height) / 2),
		col = math.floor((vim.o.columns - width) / 2),
		style = "minimal",
		border = "rounded",
		focusable = true,
		title = " CF Test ",
		title_pos = "center",
	}
end

local function is_alive()
	return state.buf and vim.api.nvim_buf_is_valid(state.buf)
		and state.win and vim.api.nvim_win_is_valid(state.win)
end

local function close()
	if state.win and vim.api.nvim_win_is_valid(state.win) then
		vim.api.nvim_win_close(state.win, true)
	end
	state.win = nil
	state.buf = nil
end

-- Open a real terminal in a floating window.
-- argv: list of strings passed directly to termopen (no shell interpretation).
-- cwd:  working directory for the process.
local function open_terminal_float(argv, cwd)
	close()

	local buf = vim.api.nvim_create_buf(false, true)
	local win = vim.api.nvim_open_win(buf, true, float_cfg())

	state.buf = buf
	state.win = win

	-- Pass a LIST so termopen never invokes a shell – no escaping issues.
	-- The cwd option sets the process CWD directly; no `cd` needed in the cmd.
	vim.fn.termopen(argv, {
		cwd = cwd,
		on_exit = function(_, code)
			if vim.api.nvim_win_is_valid(win) then
				local icon = code == 0 and "✓" or "✗"
				vim.api.nvim_win_set_config(win, vim.tbl_extend("force", float_cfg(), {
					title = string.format(" CF Test  %s  exit %d  [q] close ", icon, code),
				}))
			end
		end,
	})

	vim.cmd("startinsert")

	local opts = { buffer = buf, silent = true }
	vim.keymap.set("n", "q", close, opts)
	vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], opts)
end

-- ─── public API ──────────────────────────────────────────────────────────────

--- Run the test suite for the current file.
--- Invoking again while the float is open toggles it closed.
function M.run()
	if is_alive() then
		close()
		return
	end

	local file = vim.fn.expand("%:p")
	if not file or file == "" then
		vim.notify("CF Test: no source file", vim.log.levels.WARN)
		return
	end

	local dir   = vim.fn.fnamemodify(file, ":h")
	local fname = vim.fn.fnamemodify(file, ":t")

	open_terminal_float({ "bash", CF_SCRIPT, fname }, dir)
end

--- Add a new test case interactively (-a flag).
function M.add_test()
	local file = vim.fn.expand("%:p")
	if not file or file == "" then
		vim.notify("CF Test: no source file", vim.log.levels.WARN)
		return
	end

	local dir   = vim.fn.fnamemodify(file, ":h")
	local fname = vim.fn.fnamemodify(file, ":t")

	open_terminal_float({ "bash", CF_SCRIPT, "-a", fname }, dir)
end

--- Reset all cached test cases, then prompt for a new one (-r flag).
function M.reset_tests()
	local file = vim.fn.expand("%:p")
	if not file or file == "" then
		vim.notify("CF Test: no source file", vim.log.levels.WARN)
		return
	end

	local dir   = vim.fn.fnamemodify(file, ":h")
	local fname = vim.fn.fnamemodify(file, ":t")

	open_terminal_float({ "bash", CF_SCRIPT, "-r", fname }, dir)
end

-- ─── user commands ───────────────────────────────────────────────────────────

vim.api.nvim_create_user_command("CFTest",  M.run,         { desc = "Run CF test cases for current file" })
vim.api.nvim_create_user_command("CFAdd",   M.add_test,    { desc = "Add a CF test case for current file" })
vim.api.nvim_create_user_command("CFReset", M.reset_tests, { desc = "Reset CF test cases for current file" })

return M
