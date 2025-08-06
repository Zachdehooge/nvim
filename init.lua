vim.g.base46_cache = vim.fn.stdpath("data") .. "/nvchad/base46/"
vim.g.mapleader = " "

vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.breakindent = true
vim.opt.showbreak = "↪ "

-- bootstrap lazy and all plugins
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
	local repo = "https://github.com/folke/lazy.nvim.git"
	vim.fn.system({ "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath })
end

vim.opt.rtp:prepend(lazypath)

local lazy_config = require("configs.lazy")

-- load plugins
require("lazy").setup({
	{
		"NvChad/NvChad",
		lazy = false,
		branch = "v2.5",
		import = "nvchad.plugins",
	},

	{ import = "plugins" },
}, lazy_config)

-- load theme
dofile(vim.g.base46_cache .. "defaults")
dofile(vim.g.base46_cache .. "statusline")

require("options")
require("nvchad.autocmds")

vim.schedule(function()
	require("mappings")
end)

-- Load nvtree at directory open
local autocmd = vim.api.nvim_create_autocmd

local function open_nvim_tree(data)
	-- buffer is a directory
	local directory = vim.fn.isdirectory(data.file) == 1

	-- buffer is a [No Name]
	local no_name = data.file == "" and vim.bo[data.buf].buftype == ""

	if not directory and not no_name then
		return
	end

	if directory then
		-- change to the directory
		vim.cmd.cd(data.file)
	end

	-- open the tree
	require("nvim-tree.api").tree.open()
end

autocmd({ "VimEnter" }, { callback = open_nvim_tree })

config = function(_, opts)
	local notify = require("notify")
	notify.setup(opts)
	vim.notify = notify -- global override
end

-- Uncomment below to allow weather notifier to make a notify every 60 seconds
-- local timer = vim.loop.new_timer()
-- timer:start(
-- 	1000,
-- 	60000,
-- 	vim.schedule_wrap(function()
-- 		vim.cmd("silent! WeatherNow")
-- 	end)
-- )

-- require("smear_cursor").setup({
-- 	cursor_color = "#d3cdc3",
-- })

-- require("lsp_lines").setup({})

require("overseer").setup({
	templates = { "builtin", "user.go_run", "user.zig_run", "user.zigbuild_run" },
})

require("lspconfig").zls.setup({})

vim.api.nvim_create_autocmd("BufWritePost", {
	pattern = "*.zig",
	callback = function()
		vim.cmd("silent! !zig fmt %")
	end,
})

local ns = vim.api.nvim_create_namespace("helix_diagnostics")

local function show_helix_diagnostics()
	vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)

	local diagnostics = vim.diagnostic.get(0)
	for _, d in ipairs(diagnostics) do
		local line = d.lnum
		local col = d.col
		local msg = d.message:gsub("\n", " ")
		local severity = vim.diagnostic.severity[d.severity]:gsub("^%u", string.upper)
		local hl_group = "Diagnostic" .. severity

		-- align the arrow under the error
		local indent = string.rep(" ", col)
		local arrow_line = indent .. "└─ " .. msg

		vim.api.nvim_buf_set_extmark(0, ns, line, 0, {
			virt_lines = {
				{ { arrow_line, hl_group } },
			},
			virt_lines_above = false,
		})
	end
end

-- Disable virtual_text diagnostics
vim.diagnostic.config({
	virtual_text = false,
	signs = true,
	underline = true,
	update_in_insert = false,
})

-- Update diagnostics view on relevant events
vim.api.nvim_create_autocmd({ "BufEnter", "DiagnosticChanged", "InsertLeave" }, {
	callback = show_helix_diagnostics,
})

vim.opt.wrap = true

local telescope = require("telescope")

telescope.setup({
	defaults = {
		file_ignore_patterns = {
			"%.git/",
			"%.idea/",
		},
		vimgrep_arguments = {
			"rg",
			"--color=never",
			"--no-heading",
			"--with-filename",
			"--line-number",
			"--column",
			"--smart-case",
			"--hidden", -- include hidden files (dotfiles)
			"--no-ignore", -- don't respect .gitignore
		},
	},
	pickers = {
		find_files = {
			hidden = true,
			no_ignore = true,
		},
	},
})

require("nvim-treesitter.configs").setup({
	highlight = { enable = true },
})

-- require("ibl").setup()

local highlight = {
	"RainbowRed",
	"RainbowYellow",
	"RainbowBlue",
	"RainbowOrange",
	"RainbowGreen",
	"RainbowViolet",
	"RainbowCyan",
}

local hooks = require("ibl.hooks")
-- create the highlight groups in the highlight setup hook, so they are reset
-- every time the colorscheme changes
hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
	vim.api.nvim_set_hl(0, "RainbowRed", { fg = "#E06C75" })
	vim.api.nvim_set_hl(0, "RainbowYellow", { fg = "#E5C07B" })
	vim.api.nvim_set_hl(0, "RainbowBlue", { fg = "#61AFEF" })
	vim.api.nvim_set_hl(0, "RainbowOrange", { fg = "#D19A66" })
	vim.api.nvim_set_hl(0, "RainbowGreen", { fg = "#98C379" })
	vim.api.nvim_set_hl(0, "RainbowViolet", { fg = "#C678DD" })
	vim.api.nvim_set_hl(0, "RainbowCyan", { fg = "#56B6C2" })
end)

require("ibl").setup({
	indent = { highlight = highlight },
})

-- require("nvim-treesitter.configs").setup({
-- 	ensure_installed = { "zig" },
-- 	highlight = { enable = true },
-- 	indent = { enable = true }, -- <-- indent enabled globally or for zig
-- })

require("nvim-treesitter.configs").setup({
	ensure_installed = { "zig" },
	highlight = { enable = true },
	indent = { enable = true },
})

-- Fix Treesitter highlights if the colorscheme doesn't support them
vim.cmd([[
  highlight link @function Function
  highlight link @function.builtin Function
  highlight link @keyword.function Keyword
]])
