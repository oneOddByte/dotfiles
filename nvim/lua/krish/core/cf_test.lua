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

-- Open a real terminal in a floating window for the given shell command string.
local function open_terminal_float(cmd)
	-- If same float is still alive (e.g. a previous run), close it first.
	close()

	local buf = vim.api.nvim_create_buf(false, true)
	local win = vim.api.nvim_open_win(buf, true, float_cfg())

	state.buf = buf
	state.win = win

	-- termopen() spawns a real PTY – interactive prompts, colours, Ctrl-D all work.
	vim.fn.termopen(cmd, {
		on_exit = function(_, code)
			-- After the process finishes, stay in the window so the user can
			-- read the output. Show a small hint at the bottom of the title.
			if vim.api.nvim_win_is_valid(win) then
				local icon = code == 0 and "✓" or "✗"
				vim.api.nvim_win_set_config(win, vim.tbl_extend("force", float_cfg(), {
					title = string.format(" CF Test  %s  exit %d  [q] close ", icon, code),
				}))
			end
		end,
	})

	-- Enter insert/terminal mode immediately so the user can interact.
	vim.cmd("startinsert")

	-- Buffer-local keymaps (normal mode inside the terminal buffer)
	local opts = { buffer = buf, silent = true }
	vim.keymap.set("n", "q", close, opts)
	vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], opts) -- Esc → normal mode in terminal
end

-- ─── public API ──────────────────────────────────────────────────────────────

--- Run the test suite for the current file.
--- If the float is already open, toggle it (hide/show).
function M.run()
	-- Toggle: if the float is alive, just close it.
	if is_alive() then
		close()
		return
	end

	local file = vim.fn.expand("%:p")
	if not file or file == "" then
		vim.notify("CF Test: no source file", vim.log.levels.WARN)
		return
	end

	local dir  = vim.fn.fnamemodify(file, ":h")
	local fname = vim.fn.fnamemodify(file, ":t")

	-- cd into the file's directory so relative paths in the script work.
	local cmd = string.format(
		"cd %s && bash %s %s",
		vim.fn.shellescape(dir),
		vim.fn.shellescape(CF_SCRIPT),
		vim.fn.shellescape(fname)
	)

	open_terminal_float(cmd)
end

--- Add a new test case interactively (-a flag).
function M.add_test()
	local file = vim.fn.expand("%:p")
	if not file or file == "" then
		vim.notify("CF Test: no source file", vim.log.levels.WARN)
		return
	end

	local dir  = vim.fn.fnamemodify(file, ":h")
	local fname = vim.fn.fnamemodify(file, ":t")
	local cmd = string.format(
		"cd %s && bash %s -a %s",
		vim.fn.shellescape(dir),
		vim.fn.shellescape(CF_SCRIPT),
		vim.fn.shellescape(fname)
	)

	open_terminal_float(cmd)
end

--- Reset all cached test cases, then prompt for a new one (-r flag).
function M.reset_tests()
	local file = vim.fn.expand("%:p")
	if not file or file == "" then
		vim.notify("CF Test: no source file", vim.log.levels.WARN)
		return
	end

	local dir  = vim.fn.fnamemodify(file, ":h")
	local fname = vim.fn.fnamemodify(file, ":t")
	local cmd = string.format(
		"cd %s && bash %s -r %s",
		vim.fn.shellescape(dir),
		vim.fn.shellescape(CF_SCRIPT),
		vim.fn.shellescape(fname)
	)

	open_terminal_float(cmd)
end

-- ─── user commands ───────────────────────────────────────────────────────────

vim.api.nvim_create_user_command("CFTest",  M.run,         { desc = "Run CF test cases for current file" })
vim.api.nvim_create_user_command("CFAdd",   M.add_test,    { desc = "Add a CF test case for current file" })
vim.api.nvim_create_user_command("CFReset", M.reset_tests, { desc = "Reset CF test cases for current file" })

return M
