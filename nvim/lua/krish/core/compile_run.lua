local M = {}
local state = {
    win = nil,
    buf = nil,
    job_id = nil,
    visible = false,
}

local function toggle_window()
    if state.visible then
        if state.win and vim.api.nvim_win_is_valid(state.win) then
            vim.api.nvim_win_hide(state.win)
        end
        state.visible = false
    else
        if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
            local width = math.floor(vim.o.columns * 0.8)
            local height = math.min(20, vim.o.lines - 4)
            local row = math.floor((vim.o.lines - height) / 2)
            local col = math.floor((vim.o.columns - width) / 2)
            state.win = vim.api.nvim_open_win(state.buf, true, {
                relative = "editor",
                width = width,
                height = height,
                row = row,
                col = col,
                style = "minimal",
                border = "rounded",
                focusable = true,
            })
            state.visible = true
        else
            vim.notify("No active output buffer to show", vim.log.levels.WARN)
        end
    end
end

local function quit_process()
    -- Stop the job if it's running
    if state.job_id and vim.fn.jobwait({ state.job_id }, 0)[1] == -1 then
        vim.fn.jobstop(state.job_id)
    end
    -- Close the window if it's open
    if state.win and vim.api.nvim_win_is_valid(state.win) then
        vim.api.nvim_win_close(state.win, true)
    end
    -- Reset state
    state = { win = nil, buf = nil, job_id = nil, visible = false }
end

function M.compile_and_run()
    -- 1. Identify the file and context
    local file
    local filetype = vim.bo.filetype

    -- Check if we are in nvim-tree
    if filetype == "NvimTree" then
        local api = require("nvim-tree.api")
        local node = api.tree.get_node_under_cursor()

        if not node or node.name == ".." or node.type == "directory" then
            vim.notify("Not a valid file in NvimTree", vim.log.levels.WARN)
            return
        end
        file = node.absolute_path
    else
        file = vim.fn.expand("%:p")
    end

    -- 2. Derived properties
    local ext = file:match("^.+(%..+)$") and file:match("^.+(%..+)$"):sub(2):lower() or ""
    local name = file:match("(.+)%..+$") or file -- fallback if no extension

    -- 3. Immediate UI/State Checks
    if filetype == "output" then
        toggle_window()
        return
    end

    if filetype == "log" then
        vim.notify("CompileRun: Ignored log buffer", vim.log.levels.INFO)
        return
    end

    if state.job_id and vim.fn.jobwait({ state.job_id }, 0)[1] == -1 then
        toggle_window()
        return
    end

    -- 4. Define Execution Command
    local cmd = ({
        c = string.format(
            "gcc %s -o %s && %s",
            vim.fn.shellescape(file),
            vim.fn.shellescape(name),
            vim.fn.shellescape(name)
        ),
        cpp = string.format(
            "g++ %s -o %s && %s",
            vim.fn.shellescape(file),
            vim.fn.shellescape(name),
            vim.fn.shellescape(name)
        ),
        py = "python3 " .. vim.fn.shellescape(file),
        java = string.format("javac %s && java %s", vim.fn.shellescape(file), vim.fn.shellescape(name)),
        rs = string.format("rustc %s && ./%s", vim.fn.shellescape(file), vim.fn.shellescape(name)),
        sh = "bash " .. vim.fn.shellescape(file),
        lua = "lua " .. vim.fn.shellescape(file),
    })[ext]

    -- 5. Media Handling (Images/Video/PDF)
    local is_image = (ext == "png" or ext == "jpg" or ext == "jpeg" or ext == "webp" or ext == "gif")
    local is_video = (ext == "mp4" or ext == "mkv" or ext == "mov")

    if not cmd then
        if is_image then
            -- vim.fn.jobstart({ "mpv", "--keep-open", "--ontop", file }, { detach = true })
            vim.fn.jobstart({ "xdg-open", file }, { detach = true })
            return
        elseif is_video then
            vim.fn.jobstart({ "xdg-open", file }, { detach = true })
            return
        elseif ext == "pdf" then
            vim.fn.jobstart({ "xdg-open", file }, { detach = true })
            return
        elseif ext == "xlsx" or ext == "docx" or ext == "csv" then
            vim.fn.jobstart({ "onlyoffice-desktopeditors", file }, { detach = true })
            return
        else
            vim.notify("Unsupported filetype: " .. ext, vim.log.levels.WARN)
            return
        end
    end

    -- 6. Setup Output Buffer (for code execution only)
    state.buf = vim.api.nvim_create_buf(false, true)
    state.visible = true
    state.job_id = nil
    local buf = state.buf

    if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_set_option(buf, "filetype", "output")
        vim.api.nvim_buf_set_option(buf, "modifiable", false)
    end

    -- Window UI
    local width = math.floor(vim.o.columns * 0.8)
    local height = math.min(20, vim.o.lines - 4)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    state.win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        style = "minimal",
        border = "rounded",
        focusable = true,
    })

    -- Start job
    state.job_id = vim.fn.jobstart(cmd, {
        on_stdout = function(_, data)
            if not (data and vim.api.nvim_buf_is_valid(buf)) then
                return
            end
            vim.api.nvim_buf_set_option(buf, "modifiable", true)
            vim.api.nvim_buf_set_lines(
                buf,
                -1,
                -1,
                false,
                vim.tbl_filter(function(l)
                    return l ~= ""
                end, data)
            )
            vim.api.nvim_buf_set_option(buf, "modifiable", false)
        end,
        on_stderr = function(_, data)
            if not (data and vim.api.nvim_buf_is_valid(buf)) then
                return
            end
            vim.api.nvim_buf_set_option(buf, "modifiable", true)
            for _, line in ipairs(data) do
                if line ~= "" then
                    vim.api.nvim_buf_set_lines(buf, -1, -1, false, { "ERROR: " .. line })
                end
            end
            vim.api.nvim_buf_set_option(buf, "modifiable", false)
        end,
        on_exit = function(_, code)
            if vim.api.nvim_buf_is_valid(buf) then
                vim.api.nvim_buf_set_option(buf, "modifiable", true)
                vim.api.nvim_buf_set_lines(buf, -1, -1, false, {
                    "",
                    "[Process exited with code " .. code .. "]",
                    "[Press q to close | <leader>rr to toggle]",
                })
                vim.api.nvim_buf_set_option(buf, "modifiable", false)
            end
        end,
    })

    -- Keymaps (conditionally applied)
    if vim.api.nvim_buf_is_valid(buf) then
        local opts = { buffer = buf, silent = true }

        -- Window resize keymaps
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

        -- Quit keymap - kills process and closes window
        vim.keymap.set("n", "q", quit_process, opts)
    end
end

-- Create user command
vim.api.nvim_create_user_command("CompileRun", M.compile_and_run, {})

return M

-- local M = {}
-- local state = {
-- 	win = nil,
-- 	buf = nil,
-- 	job_id = nil,
-- 	visible = false,
-- }
--
-- local function toggle_window()
-- 	if state.visible then
-- 		if state.win and vim.api.nvim_win_is_valid(state.win) then
-- 			vim.api.nvim_win_hide(state.win)
-- 		end
-- 		state.visible = false
-- 	else
-- 		if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
-- 			local width = math.floor(vim.o.columns * 0.8)
-- 			local height = math.min(20, vim.o.lines - 4)
-- 			local row = math.floor((vim.o.lines - height) / 2)
-- 			local col = math.floor((vim.o.columns - width) / 2)
-- 			state.win = vim.api.nvim_open_win(state.buf, true, {
-- 				relative = "editor",
-- 				width = width,
-- 				height = height,
-- 				row = row,
-- 				col = col,
-- 				style = "minimal",
-- 				border = "rounded",
-- 				focusable = true,
-- 			})
-- 			state.visible = true
-- 		else
-- 			vim.notify("No active output buffer to show", vim.log.levels.WARN)
-- 		end
-- 	end
-- end
--
-- local function quit_process()
-- 	if state.job_id and vim.fn.jobwait({ state.job_id }, 0)[1] == -1 then
-- 		vim.fn.jobstop(state.job_id)
-- 	end
-- 	if state.win and vim.api.nvim_win_is_valid(state.win) then
-- 		vim.api.nvim_win_close(state.win, true)
-- 	end
-- 	state = { win = nil, buf = nil, job_id = nil, visible = false }
-- end
--
-- function M.compile_and_run()
-- 	if vim.bo.filetype == "output" then
-- 		toggle_window()
-- 		return
-- 	end
--
-- 	if vim.bo.filetype == "log" then
-- 		vim.notify("CompileRun: Ignored buffer of filetype '" .. vim.bo.filetype .. "'", vim.log.levels.INFO)
-- 		return
-- 	end
--
-- 	if state.job_id and vim.fn.jobwait({ state.job_id }, 0)[1] == -1 then
-- 		toggle_window()
-- 		return
-- 	end
--
-- 	local ext = vim.fn.expand("%:e")
-- 	local filetype = vim.bo.filetype
-- 	local file = vim.fn.expand("%:p")
-- 	local name = vim.fn.expand("%:t:r")
--
-- 	local cmd = ({
-- 		c = string.format("gcc -fno-diagnostics-color %s -o %s && ./%s", file, name, name),
-- 		cpp = string.format("g++ -fno-diagnostics-color %s -o %s && ./%s", file, name, name),
-- 		py = "python3 " .. file,
-- 		java = string.format("javac %s && java %s", file, name),
-- 		rs = string.format("rustc %s && ./%s", file, name),
-- 		sh = "bash " .. file,
-- 		lua = "lua " .. file,
-- 	})[ext]
--
-- 	if not cmd and (filetype == "audio" or filetype == "video" or ext == "mp4") then
-- 		vim.fn.jobstart("mpv " .. vim.fn.shellescape(file), { detach = true })
-- 		return
-- 	elseif not cmd and (filetype == "png" or filetype == "jpg" or filetype == "jpeg") then
-- 		vim.fn.jobstart("mpv " .. vim.fn.shellescape(file) .. " --keep-open --ontop", { detach = true })
-- 		return
-- 	elseif not cmd then
-- 		vim.notify("Unsupported filetype: " .. ext .. " (" .. filetype .. ")", vim.log.levels.WARN)
-- 		return
-- 	end
--
-- 	state.buf = vim.api.nvim_create_buf(false, true)
-- 	state.visible = true
-- 	state.job_id = nil
-- 	local buf = state.buf
--
-- 	if vim.api.nvim_buf_is_valid(buf) then
-- 		vim.api.nvim_buf_set_option(buf, "filetype", "output")
-- 		vim.api.nvim_buf_set_option(buf, "modifiable", true)
-- 		vim.api.nvim_buf_set_lines(buf, 0, -1, false, { ">> " })
-- 	end
--
-- 	local width = math.floor(vim.o.columns * 0.8)
-- 	local height = math.min(20, vim.o.lines - 4)
-- 	local row = math.floor((vim.o.lines - height) / 2)
-- 	local col = math.floor((vim.o.columns - width) / 2)
--
-- 	state.win = vim.api.nvim_open_win(buf, true, {
-- 		relative = "editor",
-- 		width = width,
-- 		height = height,
-- 		row = row,
-- 		col = col,
-- 		style = "minimal",
-- 		border = "rounded",
-- 		focusable = true,
-- 	})
--
-- 	state.job_id = vim.fn.jobstart(cmd, {
-- 		stderr_buffered = true,
-- 		stdout_buffered = true,
-- 		pty = true, -- enable stdin
-- 		on_stdout = function(_, data)
-- 			if not (data and vim.api.nvim_buf_is_valid(buf)) then
-- 				return
-- 			end
-- 			local filtered = vim.tbl_filter(function(l)
-- 				return l ~= ""
-- 			end, data)
-- 			if #filtered > 0 then
-- 				vim.api.nvim_buf_set_lines(buf, -2, -2, false, filtered)
-- 			end
-- 		end,
-- 		on_stderr = function(_, data)
-- 			if not (data and vim.api.nvim_buf_is_valid(buf)) then
-- 				return
-- 			end
-- 			for _, line in ipairs(data) do
-- 				if line ~= "" then
-- 					vim.api.nvim_buf_set_lines(buf, -2, -2, false, { "ERROR: " .. line })
-- 				end
-- 			end
-- 		end,
-- 		on_exit = function(_, code)
-- 			if vim.api.nvim_buf_is_valid(buf) then
-- 				vim.api.nvim_buf_set_lines(buf, -1, -1, false, {
-- 					"",
-- 					"[Process exited with code " .. code .. "]",
-- 					"[Press q to close | <leader>rr to toggle]",
-- 				})
-- 			end
-- 		end,
-- 	})
--
-- 	if vim.api.nvim_buf_is_valid(buf) then
-- 		local opts = { buffer = buf, silent = true }
--
-- 		vim.keymap.set("n", "<C-Up>", function()
-- 			if state.win and vim.api.nvim_win_is_valid(state.win) then
-- 				vim.api.nvim_win_set_height(state.win, vim.api.nvim_win_get_height(state.win) - 1)
-- 			end
-- 		end, opts)
--
-- 		vim.keymap.set("n", "<C-Down>", function()
-- 			if state.win and vim.api.nvim_win_is_valid(state.win) then
-- 				vim.api.nvim_win_set_height(state.win, vim.api.nvim_win_get_height(state.win) + 1)
-- 			end
-- 		end, opts)
--
-- 		vim.keymap.set("n", "<C-Left>", function()
-- 			if state.win and vim.api.nvim_win_is_valid(state.win) then
-- 				vim.api.nvim_win_set_width(state.win, vim.api.nvim_win_get_width(state.win) - 2)
-- 			end
-- 		end, opts)
--
-- 		vim.keymap.set("n", "<C-Right>", function()
-- 			if state.win and vim.api.nvim_win_is_valid(state.win) then
-- 				vim.api.nvim_win_set_width(state.win, vim.api.nvim_win_get_width(state.win) + 2)
-- 			end
-- 		end, opts)
--
-- 		vim.keymap.set("n", "q", quit_process, opts)
--
-- 		vim.keymap.set("n", "<CR>", function()
-- 			if not state.job_id then
-- 				return
-- 			end
-- 			local cursor = vim.api.nvim_win_get_cursor(0)
-- 			local line = vim.api.nvim_buf_get_lines(buf, cursor[1] - 1, cursor[1], false)[1]
-- 			if line and line:match("^>>") then
-- 				local input = line:gsub("^>>%s*", "")
-- 				vim.fn.chansend(state.job_id, input .. "\n")
-- 				vim.api.nvim_buf_set_lines(buf, -1, -1, false, { ">> " })
-- 				vim.api.nvim_win_set_cursor(0, { vim.api.nvim_buf_line_count(buf), 0 })
-- 			end
-- 		end, opts)
-- 	end
-- end
--
-- vim.api.nvim_create_user_command("CompileRun", M.compile_and_run, {})
-- return M
