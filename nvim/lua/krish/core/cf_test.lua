-- cf_test.lua
-- Runs ~/.dotfiles/codeforces_test.sh against the current buffer's source file
-- in a floating window, following the same pattern as compile_run.lua.

local M = {}

local CF_SCRIPT = vim.fn.expand("~/.dotfiles/codeforces_test.sh")

local state = {
	win = nil,
	buf = nil,
	job_id = nil,
	visible = false,
}

-- ─── helpers ─────────────────────────────────────────────────────────────────

local function open_float(buf)
	local width = math.floor(vim.o.columns * 0.8)
	local height = math.min(24, vim.o.lines - 4)
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)
	return vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "rounded",
		focusable = true,
		title = " CF Test ",
		title_pos = "center",
	})
end

local function toggle_window()
	if state.visible then
		if state.win and vim.api.nvim_win_is_valid(state.win) then
			vim.api.nvim_win_hide(state.win)
		end
		state.visible = false
	else
		if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
			state.win = open_float(state.buf)
			state.visible = true
		else
			vim.notify("CF Test: no output buffer to show", vim.log.levels.WARN)
		end
	end
end

local function close_and_reset()
	if state.job_id and vim.fn.jobwait({ state.job_id }, 0)[1] == -1 then
		vim.fn.jobstop(state.job_id)
	end
	if state.win and vim.api.nvim_win_is_valid(state.win) then
		vim.api.nvim_win_close(state.win, true)
	end
	state = { win = nil, buf = nil, job_id = nil, visible = false }
end

-- Append lines to the output buffer (strips empty trailing lines from chunks)
local function append_lines(buf, lines)
	if not (lines and vim.api.nvim_buf_is_valid(buf)) then
		return
	end
	local filtered = vim.tbl_filter(function(l)
		return l ~= ""
	end, lines)
	if #filtered == 0 then
		return
	end
	vim.api.nvim_buf_set_option(buf, "modifiable", true)
	vim.api.nvim_buf_set_lines(buf, -1, -1, false, filtered)
	vim.api.nvim_buf_set_option(buf, "modifiable", false)
	-- Scroll to bottom if the window is still open
	if state.win and vim.api.nvim_win_is_valid(state.win) then
		local line_count = vim.api.nvim_buf_line_count(buf)
		vim.api.nvim_win_set_cursor(state.win, { line_count, 0 })
	end
end

-- ─── public API ──────────────────────────────────────────────────────────────

--- Run codeforces_test.sh for the current file (or toggle the window if a job
--- is already running / the output is already visible).
---
--- @param extra_args string?  Optional extra flags forwarded to the script
---                            (e.g. "-a" to add a test case, "-r" to reset).
function M.run(extra_args)
	-- If a job is running, just toggle the output window.
	if state.job_id and vim.fn.jobwait({ state.job_id }, 0)[1] == -1 then
		toggle_window()
		return
	end

	-- Resolve source file
	local ft = vim.bo.filetype
	local file

	if ft == "NvimTree" then
		local ok, api = pcall(require, "nvim-tree.api")
		if ok then
			local node = api.tree.get_node_under_cursor()
			if node and node.type ~= "directory" and node.name ~= ".." then
				file = node.absolute_path
			end
		end
	end
	file = file or vim.fn.expand("%:p")

	if not file or file == "" then
		vim.notify("CF Test: no source file found", vim.log.levels.WARN)
		return
	end

	-- Build shell command:  cd <dir> && bash <script> [flags] <file>
	local dir = vim.fn.fnamemodify(file, ":h")
	local fname = vim.fn.fnamemodify(file, ":t")
	local args = extra_args and (extra_args .. " ") or ""
	local cmd = string.format(
		"cd %s && bash %s %s%s",
		vim.fn.shellescape(dir),
		vim.fn.shellescape(CF_SCRIPT),
		args,
		vim.fn.shellescape(fname)
	)

	-- Create output buffer
	local buf = vim.api.nvim_create_buf(false, true)
	state.buf = buf
	state.visible = true
	state.job_id = nil

	vim.api.nvim_buf_set_option(buf, "filetype", "cf_output")
	vim.api.nvim_buf_set_option(buf, "modifiable", false)

	-- Open the float
	state.win = open_float(buf)

	-- Seed with a header
	vim.api.nvim_buf_set_option(buf, "modifiable", true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
		"  Running: " .. fname,
		"  Script:  " .. CF_SCRIPT,
		string.rep("─", math.floor(vim.o.columns * 0.8) - 2),
		"",
	})
	vim.api.nvim_buf_set_option(buf, "modifiable", false)

	-- Launch the job
	state.job_id = vim.fn.jobstart(cmd, {
		shell = true,
		on_stdout = function(_, data)
			append_lines(buf, data)
		end,
		on_stderr = function(_, data)
			if not (data and vim.api.nvim_buf_is_valid(buf)) then
				return
			end
			local filtered = vim.tbl_filter(function(l)
				return l ~= ""
			end, data)
			if #filtered == 0 then
				return
			end
			vim.api.nvim_buf_set_option(buf, "modifiable", true)
			for _, line in ipairs(filtered) do
				vim.api.nvim_buf_set_lines(buf, -1, -1, false, { "  " .. line })
			end
			vim.api.nvim_buf_set_option(buf, "modifiable", false)
		end,
		on_exit = function(_, code)
			if not vim.api.nvim_buf_is_valid(buf) then
				return
			end
			local status_icon = code == 0 and "✓" or "✗"
			vim.api.nvim_buf_set_option(buf, "modifiable", true)
			vim.api.nvim_buf_set_lines(buf, -1, -1, false, {
				"",
				string.rep("─", math.floor(vim.o.columns * 0.8) - 2),
				string.format("  %s  Exited with code %d", status_icon, code),
				"  [q] close  [<leader>ct] toggle  [<leader>ca] add test  [<leader>cr] reset",
			})
			vim.api.nvim_buf_set_option(buf, "modifiable", false)
			-- Scroll to the exit message
			if state.win and vim.api.nvim_win_is_valid(state.win) then
				local lc = vim.api.nvim_buf_line_count(buf)
				vim.api.nvim_win_set_cursor(state.win, { lc, 0 })
			end
		end,
	})

	-- Buffer-local keymaps
	if vim.api.nvim_buf_is_valid(buf) then
		local opts = { buffer = buf, silent = true }
		vim.keymap.set("n", "q", close_and_reset, opts)
		vim.keymap.set("n", "<C-Up>", function()
			if state.win and vim.api.nvim_win_is_valid(state.win) then
				vim.api.nvim_win_set_height(state.win, vim.api.nvim_win_get_height(state.win) - 1)
			end
		end, opts)
		vim.keymap.set("n", "<C-Down>", function()
			if state.win and vim.api.nvim_win_is_valid(state.win) then
				vim.api.nvim_win_set_height(state.win, vim.api.nvim_win_get_height(state.win) + 1)
			end
		end, opts)
		vim.keymap.set("n", "<C-Left>", function()
			if state.win and vim.api.nvim_win_is_valid(state.win) then
				vim.api.nvim_win_set_width(state.win, vim.api.nvim_win_get_width(state.win) - 2)
			end
		end, opts)
		vim.keymap.set("n", "<C-Right>", function()
			if state.win and vim.api.nvim_win_is_valid(state.win) then
				vim.api.nvim_win_set_width(state.win, vim.api.nvim_win_get_width(state.win) + 2)
			end
		end, opts)
	end
end

--- Add a test case interactively (passes -a to the script).
--- Note: the script uses stdin prompts so this opens a real terminal split instead.
function M.add_test()
	local file = vim.fn.expand("%:p")
	if not file or file == "" then
		vim.notify("CF Test: no source file", vim.log.levels.WARN)
		return
	end
	local dir = vim.fn.fnamemodify(file, ":h")
	local fname = vim.fn.fnamemodify(file, ":t")
	local cmd = string.format(
		"cd %s && bash %s -a %s; echo; read -n1 -p '[Press any key to close]'",
		vim.fn.shellescape(dir),
		vim.fn.shellescape(CF_SCRIPT),
		vim.fn.shellescape(fname)
	)
	-- Open a horizontal terminal split so the user can type input/expected output
	vim.cmd("botright 14split | terminal " .. cmd)
end

--- Reset test cases then immediately prompt for a new one.
function M.reset_tests()
	local file = vim.fn.expand("%:p")
	if not file or file == "" then
		vim.notify("CF Test: no source file", vim.log.levels.WARN)
		return
	end
	local dir = vim.fn.fnamemodify(file, ":h")
	local fname = vim.fn.fnamemodify(file, ":t")
	local cmd = string.format(
		"cd %s && bash %s -r %s; echo; read -n1 -p '[Press any key to close]'",
		vim.fn.shellescape(dir),
		vim.fn.shellescape(CF_SCRIPT),
		vim.fn.shellescape(fname)
	)
	vim.cmd("botright 14split | terminal " .. cmd)
end

-- ─── user commands ───────────────────────────────────────────────────────────

vim.api.nvim_create_user_command("CFTest", M.run, { desc = "Run CF test cases for current file" })
vim.api.nvim_create_user_command("CFAdd", M.add_test, { desc = "Add a CF test case for current file" })
vim.api.nvim_create_user_command("CFReset", M.reset_tests, { desc = "Reset CF test cases for current file" })

return M
