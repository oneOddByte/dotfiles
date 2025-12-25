local vim = vim
local M = {}

-- ==========================
-- 1. TMUX PALETTE AUTOGEN
-- ==========================

local function hl_color(name, attr)
  local ok, hl = pcall(vim.api.nvim_get_hl_by_name, name, true)
  if ok and hl[attr] then
    return string.format("#%06x", hl[attr])
  end
  return nil
end

local function contrast_color(hex)
  if not hex or hex == "" then return "#ffffff" end
  
  hex = hex:gsub("#", "")
  local r = tonumber(hex:sub(1, 2), 16) or 0
  local g = tonumber(hex:sub(3, 4), 16) or 0
  local b = tonumber(hex:sub(5, 6), 16) or 0
  
  -- luminance formula
  local lum = 0.299 * r + 0.587 * g + 0.114 * b
  return (lum > 128) and "#000000" or "#ffffff"
end

local function generate_tmux_palette()
  local normal_bg = hl_color("Normal", "background") or "#1e1e2e"
  local normal_fg = hl_color("Normal", "foreground") or "#cdd6f4"
  
  -- Use bright, visible colors for window index
  -- Try accent colors that pop: String, Function, Keyword, etc.
  local index_bg = hl_color("Function", "foreground")
                or hl_color("Keyword", "foreground")
                or hl_color("String", "foreground")
                or "#89b4fa"  -- fallback to bright blue
  
  -- Always use a contrasting color for the number
  local index_fg = contrast_color(index_bg)

  return {
    status_bg = hl_color("StatusLine", "background") or normal_bg,
    status_fg = hl_color("StatusLine", "foreground") or normal_fg,
    session_name = hl_color("Title", "foreground") or "#89b4fa",
    index_bg = index_bg,
    index_fg = index_fg,
    name_bg = normal_bg,
    name_fg = normal_fg,
    time_date = hl_color("Comment", "foreground") or "#6c7086",
    battery_icon = hl_color("Constant", "foreground") or "#f38ba8",
    inactive_bg = hl_color("StatusLineNC", "background") or normal_bg,
    inactive_fg = hl_color("StatusLineNC", "foreground") or "#6c7086",
  }
end

local function contrast_color(hex)
  if not hex or hex == "" then return "#ffffff" end
  
  hex = hex:gsub("#", "")
  local r = tonumber(hex:sub(1, 2), 16) or 0
  local g = tonumber(hex:sub(3, 4), 16) or 0
  local b = tonumber(hex:sub(5, 6), 16) or 0
  
  -- luminance formula
  local lum = 0.299 * r + 0.587 * g + 0.114 * b
  return (lum > 128) and "#000000" or "#ffffff"
end

local function write_tmux_file(palette)
  local path = os.getenv("HOME") .. "/.config/tmux/tmux_colors.conf"
  local file = io.open(path, "w")
  if not file then return end
  
  for k, v in pairs(palette) do
    file:write(string.format("set -g @color_%s '%s'\n", k, v))
  end
  file:close()
end

local function reload_tmux()
  os.execute("tmux source-file ~/.config/tmux/tmux_colors.conf 2>/dev/null")
end

function M.update_tmux_palette(reload)
  local palette = generate_tmux_palette()
  -- Ensure index has good contrast
  palette.index_fg = contrast_color(palette.index_bg)
  
  write_tmux_file(palette)
  if reload then
    reload_tmux()
  end
end

-- Auto-update when colorscheme changes
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    M.update_tmux_palette(true)
  end,
})

-- Initial palette generation
M.update_tmux_palette(false)

-- ==========================
-- 2. FILETYPE AUTOCMDS
-- ==========================

local function setup_markdown_opts()
  vim.opt_local.wrap = true
  vim.opt_local.listchars = { tab = "▸ ", trail = "·" }
  vim.opt_local.formatoptions:append("r")  -- continue lists/comments
  vim.opt_local.formatoptions:remove("a")  -- prevent auto-formatting
  vim.opt_local.smartindent = true
  vim.opt.conceallevel = 2
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "obsidian" },
  callback = setup_markdown_opts,
})

-- ==========================
-- 3. DAILY NOTE COMMAND
-- ==========================

vim.api.nvim_create_user_command("DailyNote", function()
  local date = os.date("%d-%m-%Y")
  local note_path = "/home/krish/vault/journal/" .. date .. ".md"
  local template_path = "/home/krish/vault/templates/daily-journal.md"

  local file = io.open(note_path, "r")
  if not file then
    local template = io.open(template_path, "r")
    if template then
      local content = template:read("*all")
      template:close()
      content = content:gsub("{{date}}", date)

      local new_note = io.open(note_path, "w")
      if new_note then
        new_note:write(content)
        new_note:close()
      end
    end
  else
    file:close()
  end

  vim.cmd("e " .. note_path)
end, {})

return M
