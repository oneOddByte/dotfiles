local vim = vim

return {
	{
		"mfussenegger/nvim-dap",

		cmd = {
			"DapSetLogLevel",
			"DapShowLog",
			"DapContinue",
			"DapToggleBreakpoint",
			"DapToggleRepl",
			"DapStepOver",
			"DapStepInto",
			"DapStepOut",
			"DapTerminate",
		},

		keys = {
			{ "<leader>db", "<cmd>DapToggleBreakpoint<cr>", desc = "Toggle Breakpoint" },
			{ "<leader>dc", "<cmd>DapContinue<cr>", desc = "Continue" },
			{ "<leader>dr", "<cmd>DapToggleRepl<cr>", desc = "Toggle REPL" },
			{ "<leader>ds", "<cmd>DapStepOver<cr>", desc = "Step Over" },
			{ "<leader>di", "<cmd>DapStepInto<cr>", desc = "Step Into" },
			{ "<leader>do", "<cmd>DapStepOut<cr>", desc = "Step Out" },
			{ "<leader>dt", "<cmd>DapTerminate<cr>", desc = "Terminate" },
		},
		dependencies = {
			{ "rcarriga/nvim-dap-ui", lazy = true },
			{ "nvim-neotest/nvim-nio", lazy = true },
			{ "jay-babu/mason-nvim-dap.nvim", lazy = true },
			{ "theHamsta/nvim-dap-virtual-text", lazy = true },
		},

		-- Configure the plugin when it loads
		config = function()
			local dap = require("dap")
			local dapui = require("dapui")
			local dap_virtual_text = require("nvim-dap-virtual-text") -- For inline variable display

			-- --- DAP Adapters Configuration ---
			-- Define how Neovim's DAP client connects to specific debuggers

			-- Python Debugger (debugpy)
			dap.adapters.python = {
				type = "executable",
				command = "python", -- Use 'python' assuming it's in your PATH, or full path to your Python executable
				args = { "-m", "debugpy.adapter" },
				options = {
					initialize_timeout_sec = 30, -- Increase from default 4 seconds
					disconnect_timeout_sec = 30,
				},
			}

			-- C++ Debugger (CodeLLDB) - FIXED VERSION
			dap.adapters.codelldb = {
				type = "server",
				port = "${port}",
				executable = {
					-- Use the correct path for different OS
					command = function()
						local mason_path = vim.fn.stdpath("data") .. "/mason/bin"
						if vim.fn.has("win32") == 1 then
							return mason_path .. "/codelldb.exe"
						else
							return mason_path .. "/codelldb"
						end
					end,
					args = { "--port", "${port}" },
				},
			}

			-- Alternative: Use lldb-vscode if codelldb doesn't work
			dap.adapters.lldb = {
				type = "executable",
				command = function()
					local mason_path = vim.fn.stdpath("data") .. "/mason/bin"
					if vim.fn.has("win32") == 1 then
						return mason_path .. "/lldb-vscode.exe"
					else
						return mason_path .. "/lldb-vscode"
					end
				end,
				name = "lldb",
			}

			-- --- DAP Configurations (Launch/Attach settings for different languages) ---
			-- Define how to launch or attach to a program for debugging

			-- Python Configurations
			dap.configurations.python = {
				{
					type = "python",
					request = "launch",
					name = "Launch Current Python File",
					program = "${file}", -- Debugs the currently open Python file
					pythonPath = function()
						-- Check if we're in a virtual environment
						local venv = os.getenv("VIRTUAL_ENV")
						if venv then
							return venv .. "/bin/python"
						else
							-- Fallback to system python
							return "python"
						end
					end,
				},
				{
					type = "python",
					request = "launch",
					name = "Launch Python Module",
					module = function()
						return vim.fn.input("Module name: ")
					end,
					pythonPath = function()
						local venv = os.getenv("VIRTUAL_ENV")
						if venv then
							return venv .. "/bin/python"
						else
							return "python"
						end
					end,
				},
			}

			-- C++ Configurations - SIMPLIFIED TO AVOID DUPLICATES
			dap.configurations.cpp = {
				{
					name = "Launch Executable (CodeLLDB)",
					type = "codelldb",
					request = "launch",
					program = function()
						-- Try to find common executable patterns first
						local cwd = vim.fn.getcwd()
						local common_paths = {
							cwd .. "/build/main",
							cwd .. "/main",
							cwd .. "/a.out",
							cwd .. "/build/a.out",
						}

						for _, path in ipairs(common_paths) do
							if vim.fn.executable(path) == 1 then
								return path
							end
						end

						-- If no common executable found, prompt user
						return vim.fn.input("Path to executable: ", cwd .. "/", "file")
					end,
					cwd = "${workspaceFolder}",
					stopOnEntry = false,
					args = {},
					runInTerminal = false,
				},
				{
					name = "Launch with Arguments (CodeLLDB)",
					type = "codelldb",
					request = "launch",
					program = function()
						return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
					end,
					cwd = "${workspaceFolder}",
					stopOnEntry = false,
					args = function()
						local args_string = vim.fn.input("Arguments: ")
						if args_string == "" then
							return {}
						end
						return vim.split(args_string, " ")
					end,
					runInTerminal = false,
				},
				-- Fallback configuration using lldb-vscode
				{
					name = "Launch Executable (LLDB)",
					type = "lldb",
					request = "launch",
					program = function()
						return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
					end,
					cwd = "${workspaceFolder}",
					stopOnEntry = false,
					args = {},
				},
			}

			-- C configurations (same as C++)
			dap.configurations.c = dap.configurations.cpp

			-- Function to compile and debug C++ files
			local function compile_and_debug()
				local file = vim.fn.expand("%:p")
				local file_no_ext = vim.fn.expand("%:p:r")
				local compile_cmd = string.format("g++ -g -o %s %s", file_no_ext, file)

				vim.fn.system(compile_cmd)
				if vim.v.shell_error == 0 then
					print("Compilation successful")
					-- Set the program path and start debugging
					dap.configurations.cpp[1].program = file_no_ext
					dap.continue()
				else
					print("Compilation failed")
				end
			end

			-- Add a keybinding for compile and debug
			vim.keymap.set("n", "<leader>dC", compile_and_debug, { desc = "Compile and Debug C++" })

			-- --- nvim-dap-ui Configuration ---
			-- Setup the visual interface for the debugger
			dapui.setup({
				layouts = {
					{
						elements = {
							{ id = "scopes", size = 0.25 }, -- Variables in current scope
							{ id = "breakpoints", size = 0.25 }, -- List of breakpoints
							{ id = "stacks", size = 0.25 }, -- Call stack
							{ id = "watches", size = 0.25 }, -- Custom watch expressions
						},
						size = 40, -- Initial width of the side panel
						position = "right",
					},
					{
						elements = {
							{ id = "repl", size = 0.5 }, -- Debugger REPL
							{ id = "console", size = 0.5 }, -- Debugger console output
						},
						size = 10, -- Initial height of the bottom panel
						position = "bottom",
					},
				},
				-- FIXED: Proper controls configuration
				controls = {
					element = "repl", -- Should be a string, not a table
					enabled = true,
					icons = {
						pause = "",
						play = "",
						step_into = "",
						step_over = "",
						step_out = "",
						step_back = "",
						run_last = "",
						terminate = "",
					},
				},
				render = {
					max_type_length = nil,
					max_value_length = nil,
				},
				-- Additional UI options
				icons = { expanded = "", collapsed = "", current_frame = "" },
				mappings = {
					expand = { "<CR>", "<2-LeftMouse>" },
					open = "o",
					remove = "d",
					edit = "e",
					repl = "r",
					toggle = "t",
				},
				floating = {
					max_height = nil,
					max_width = nil,
					border = "single",
					mappings = {
						close = { "q", "<Esc>" },
					},
				},
			})

			-- --- nvim-dap-virtual-text Configuration ---
			-- Setup inline display of variable values
			dap_virtual_text.setup({
				enabled = true, -- Enable/disable virtual text
				enabled_commands = true, -- Create commands DapVirtualTextEnable, DapVirtualTextDisable, DapVirtualTextToggle
				highlight_changed_variables = true, -- Highlight changed variables
				highlight_new_as_changed = false, -- Highlight new variables as changed
				show_stop_reason = true, -- Show stop reason when stopped
				commented = false, -- Prefix virtual text with comment string
				only_first_definition = true, -- Only show virtual text at first definition
				all_references = false, -- Show virtual text on all references
				clear_on_continue = false, -- Clear virtual text on continue
				display_callback = function(variable, buf, stackframe, node, options)
					if options.virt_text_pos == "inline" then
						return " = " .. variable.value
					else
						return variable.name .. " = " .. variable.value
					end
				end,
				virt_text_pos = vim.fn.has("nvim-0.10") == 1 and "inline" or "eol",
				all_frames = false, -- Show virtual text for all stack frames
				virt_lines = false, -- Show virtual lines instead of virtual text
				virt_text_win_col = nil, -- Position the virtual text at a fixed window column
			})

			-- --- DAP Listeners (Auto-open/close UI on debug session start/end) ---
			dap.listeners.before.attach.dapui_config = function()
				dapui.open()
			end
			dap.listeners.before.launch.dapui_config = function()
				dapui.open()
			end
			dap.listeners.before.event_terminated.dapui_config = function()
				dapui.close()
			end
			dap.listeners.before.event_exited.dapui_config = function()
				dapui.close()
			end

			-- --- User-Friendly Keymaps for Debugging ---
			-- More intuitive and memorable key combinations

			-- Core debugging controls (traditional debugger F-key layout)
			vim.keymap.set("n", "<F5>", dap.continue, { desc = "Debug: Start/Continue" })
			vim.keymap.set("n", "<F9>", dap.toggle_breakpoint, { desc = "Debug: Toggle Breakpoint" })
			vim.keymap.set("n", "<F10>", dap.step_over, { desc = "Debug: Step Over" })
			vim.keymap.set("n", "<F11>", dap.step_into, { desc = "Debug: Step Into" })
			vim.keymap.set("n", "<S-F11>", dap.step_out, { desc = "Debug: Step Out" })
			vim.keymap.set("n", "<S-F5>", dap.terminate, { desc = "Debug: Stop/Terminate" })
			vim.keymap.set("n", "<C-F5>", dap.restart, { desc = "Debug: Restart" })

			-- Primary debug controls (single letter after d)
			vim.keymap.set("n", "<leader>ds", dap.continue, { desc = "Debug: Start/Continue" })
			vim.keymap.set("n", "<leader>dt", dap.terminate, { desc = "Debug: Terminate/Stop" })
			vim.keymap.set("n", "<leader>dr", dap.restart, { desc = "Debug: Restart" })

			-- Breakpoint management (most common)
			vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "Debug: Toggle Breakpoint" })
			vim.keymap.set("n", "<leader>dB", function()
				dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
			end, { desc = "Debug: Conditional Breakpoint" })

			-- Step controls (easy to remember: step + direction)
			vim.keymap.set("n", "<leader>do", dap.step_over, { desc = "Debug: Step Over" })
			vim.keymap.set("n", "<leader>di", dap.step_into, { desc = "Debug: Step Into" })
			vim.keymap.set("n", "<leader>du", dap.step_out, { desc = "Debug: Step Up/Out" })

			-- UI Controls
			vim.keymap.set("n", "<leader>dU", dapui.toggle, { desc = "Debug: Toggle UI" })
			vim.keymap.set("n", "<leader>dO", dapui.open, { desc = "Debug: Open UI" })
			vim.keymap.set("n", "<leader>dX", dapui.close, { desc = "Debug: Close UI" })

			-- REPL and Console
			vim.keymap.set("n", "<leader>dR", dap.repl.toggle, { desc = "Debug: Toggle REPL" })
			vim.keymap.set("n", "<leader>de", function()
				dap.repl.open()
				vim.cmd("wincmd p") -- Return focus to previous window
			end, { desc = "Debug: Open REPL" })

			-- Visual inspection (hover and preview)
			vim.keymap.set({ "n", "v" }, "<leader>dh", function()
				require("dap.ui.widgets").hover()
			end, { desc = "Debug: Hover/Inspect" })
			vim.keymap.set({ "n", "v" }, "<leader>dp", function()
				require("dap.ui.widgets").preview()
			end, { desc = "Debug: Preview Variable" })

			-- Less frequently used keymaps (dd prefix for rare functions)
			-- Advanced breakpoint management
			vim.keymap.set("n", "<leader>ddl", function()
				dap.set_breakpoint(nil, nil, vim.fn.input("Log point message: "))
			end, { desc = "Debug: Log Point" })
			vim.keymap.set("n", "<leader>ddx", dap.clear_breakpoints, { desc = "Debug: Clear All Breakpoints" })

			-- Run controls (less common)
			vim.keymap.set("n", "<leader>ddL", dap.run_last, { desc = "Debug: Run Last Configuration" })
			vim.keymap.set("n", "<leader>ddc", function()
				dap.continue()
			end, { desc = "Debug: Run/Continue" })

			-- Widget windows for detailed inspection (rarely used)
			vim.keymap.set("n", "<leader>ddf", function()
				local widgets = require("dap.ui.widgets")
				widgets.centered_float(widgets.frames)
			end, { desc = "Debug: Show Stack Frames" })
			vim.keymap.set("n", "<leader>dds", function()
				local widgets = require("dap.ui.widgets")
				widgets.centered_float(widgets.scopes)
			end, { desc = "Debug: Show Variable Scopes" })
			vim.keymap.set("n", "<leader>ddt", function()
				local widgets = require("dap.ui.widgets")
				widgets.centered_float(widgets.threads)
			end, { desc = "Debug: Show Threads" })

			vim.keymap.set("n", "<C-F9>", function()
				dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
			end, { desc = "Debug: Conditional Breakpoint" })
			vim.keymap.set("n", "<S-F9>", dap.clear_breakpoints, { desc = "Debug: Clear All Breakpoints" })

			-- Alternative comfortable keymaps for laptop users (no F-keys)
			vim.keymap.set("n", "<leader><leader>c", dap.continue, { desc = "Debug: Continue" })
			vim.keymap.set("n", "<leader><leader>n", dap.step_over, { desc = "Debug: Next (Step Over)" })
			vim.keymap.set("n", "<leader><leader>i", dap.step_into, { desc = "Debug: Into" })
			vim.keymap.set("n", "<leader><leader>o", dap.step_out, { desc = "Debug: Out" })
			vim.keymap.set("n", "<leader><leader>b", dap.toggle_breakpoint, { desc = "Debug: Breakpoint" })

			-- Telescope dap
			vim.keymap.set(
				"n",
				"<leader>fdl",
				":Telescope dap list_breakpoints<CR>",
				{ desc = "Debug: List Breakpoints" }
			)

			-- Additional useful telescope-dap commands
			vim.keymap.set("n", "<leader>fdc", ":Telescope dap commands<CR>", { desc = "Debug: Commands" })
			vim.keymap.set("n", "<leader>fdC", ":Telescope dap configurations<CR>", { desc = "Debug: Configurations" })
			vim.keymap.set("n", "<leader>fdv", ":Telescope dap variables<CR>", { desc = "Debug: Variables" })
			vim.keymap.set("n", "<leader>fdf", ":Telescope dap frames<CR>", { desc = "Debug: Frames" })
		end, -- <-- This was missing! The config function needs to be properly closed

		-- --- Lazy Loading Configuration ---
		-- Tell lazy.nvim to load this plugin when specific filetypes are opened
		ft = { "python", "cpp", "c" },
	},
	-- For easier debugger installation (requires mason.nvim to be installed and configured separately)
	{
		"jay-babu/mason-nvim-dap.nvim",
		dependencies = { "mason.nvim", "nvim-dap" },
		opts = {
			-- List of debuggers to ensure are installed via Mason for nvim-dap
			ensure_installed = { "python", "codelldb" }, -- Use "codelldb" for C++ (better than cppdbg)
			handlers = {}, -- This will use default handlers for all installed debuggers
		},
		config = function(_, opts)
			require("mason-nvim-dap").setup(opts)
		end,
	},
}
