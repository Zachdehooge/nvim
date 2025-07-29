return {
	{
		"stevearc/conform.nvim",
		-- event = 'BufWritePre', -- uncomment for format on save
		opts = require("configs.conform"),
	},

	-- These are some examples, uncomment them if you want to see them work!
	{
		"neovim/nvim-lspconfig",
		config = function()
			require("configs.lspconfig")
		end,
	},

	{
		"vyfor/cord.nvim",
		build = "./build",
		event = "VeryLazy",
		opts = {},
	},

	{
		"wakatime/vim-wakatime",
		lazy = false,
	},

	{
		"stevearc/conform.nvim",
		opts = {
			formatters_by_ft = {
				lua = { "stylua" },
			},
		},
	},

	{
		"folke/todo-comments.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = {
			-- your configuration comes here
			-- or leave it empty to use the default settings
			-- refer to the configuration section below
		},
	},

	-- lua/plugins/todo-comments.lua
	{
		"folke/todo-comments.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		-- fire as soon as you open or create a file
		event = { "BufReadPost", "BufNewFile" },
		config = true, -- runs require("todo-comments").setup({})
	},

	{
		"folke/trouble.nvim",
		opts = {}, -- for default options, refer to the configuration section for custom setup.
		cmd = "Trouble",
		keys = {
			{
				"<leader>xx",
				"<cmd>TodoTelescope<cr>",
				desc = "Diagnostics (Trouble)",
			},
		},
	},

	-- {
	-- 	"rachartier/tiny-inline-diagnostic.nvim",
	-- 	event = "VeryLazy", -- Or `LspAttach`
	-- 	priority = 1000, -- needs to be loaded in first
	-- 	config = function()
	-- 		require("tiny-inline-diagnostic").setup()
	-- 		vim.diagnostic.config({ virtual_text = false }) -- Only if needed in your configuration, if you already have native LSP diagnostics
	-- 	end,
	-- },

	{
		"mason-org/mason-lspconfig.nvim",
		opts = {},
		dependencies = {
			{ "mason-org/mason.nvim", opts = {} },
			"neovim/nvim-lspconfig",
		},
	},

	{
		"lukas-reineke/indent-blankline.nvim",
		main = "ibl",
		---@module "ibl"
		---@type ibl.config
		opts = {},
	},
	-- {
	-- 	"rachartier/tiny-inline-diagnostic.nvim",
	-- 	event = "VeryLazy",
	-- 	config = function()
	-- 		require("tiny-inline-diagnostic").setup({
	-- 			signs = {
	-- 				left = "",
	-- 				right = "",
	-- 				diag = "●",
	-- 				arrow = "    ",
	-- 				up_arrow = "    ",
	-- 				vertical = " │",
	-- 				vertical_end = " └",
	-- 			},
	-- 			hi = {
	-- 				error = "DiagnosticError",
	-- 				warn = "DiagnosticWarn",
	-- 				info = "DiagnosticInfo",
	-- 				hint = "DiagnosticHint",
	-- 				arrow = "NonText",
	-- 				background = "CursorLine", -- Can be a highlight or a hexadecimal color (#RRGGBB)
	-- 				mixing_color = "None", -- Can be None or a hexadecimal color (#RRGGBB). Used to blend the background color with the diagnostic background color with another color.
	-- 			},
	-- 			blend = {
	-- 				factor = 0.27,
	-- 			},
	-- 			options = {
	-- 				-- Show the source of the diagnostic
	-- 				show_source = false,
	-- 				-- Throttle the update of the diagnostic when moving cursor, in milliseconds.
	-- 				-- You can increase it if you have performance issues.
	-- 				-- Or set it to 0 to have better visuals.
	-- 				throttle = 20,
	-- 				-- The minimum length of the message, otherwise it will be on a new line.
	-- 				softwrap = 15,
	-- 				-- If multiple diagnostics are under the cursor, display all of them.
	-- 				multiple_diag_under_cursor = false,
	-- 				-- Enable diagnostic message on all lines.
	-- 				multilines = false,
	-- 				-- Show all diagnostics on the cursor line.
	-- 				show_all_diags_on_cursorline = false,
	-- 			},
	-- 		})
	-- 	end,
	-- },

	{
		"stevearc/conform.nvim",
		opts = {},
	},

	{
		"folke/noice.nvim",
		dependencies = {
			"MunifTanjim/nui.nvim",
			"rcarriga/nvim-notify",
		},
		config = function()
			require("noice").setup({
				presets = {
					bottom_search = true,
					command_palette = true,
					long_message_to_split = true,
					inc_rename = false,
					lsp_doc_border = true,
				},
			})
		end,
	},

	{
		"ray-x/go.nvim",
		dependencies = { -- optional packages
			"ray-x/guihua.lua",
			"neovim/nvim-lspconfig",
			"nvim-treesitter/nvim-treesitter",
		},
		opts = {
			-- lsp_keymaps = false,
			-- other options
		},
		config = function(lp, opts)
			require("go").setup(opts)
			local format_sync_grp = vim.api.nvim_create_augroup("GoFormat", {})
			vim.api.nvim_create_autocmd("BufWritePre", {
				pattern = "*.go",
				callback = function()
					require("go.format").goimports()
				end,
				group = format_sync_grp,
			})
		end,
		event = { "CmdlineEnter" },
		ft = { "go", "gomod" },
		build = ':lua require("go.install").update_all_sync()', -- if you need to install/update all binaries
	},
	{
		"sphamba/smear-cursor.nvim",
		opts = {
			stiffness = 0.5,
			trailing_stiffness = 0.5,
			damping = 0.67,
			matrix_pixel_threshold = 0.5,
		},
	},
	{
		"stevearc/overseer.nvim",
		opts = {},
	},
	-- {
	-- 	"zbirenbaum/copilot.lua",
	-- 	opts = {},
	-- },

	-- Uncomment below to enable Copilot
	-- {
	-- 	"zbirenbaum/copilot.lua",
	-- 	event = "InsertEnter",
	-- 	cmd = "Copilot",
	-- 	build = ":Copilot auth",
	-- 	config = function()
	-- 		require("copilot").setup({
	-- 			suggestion = { enabled = true, auto_trigger = true },
	-- 			panel = { enabled = false },
	-- 		})
	-- 	end,
	-- },

	{
		"folke/tokyonight.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			require("tokyonight").setup({
				style = "night", -- explicitly set the variant you want
			})
		end,
	},

	{
		"nvim-tree/nvim-tree.lua",
		opts = {
			filters = {
				dotfiles = false,
				git_ignored = false,
				custom = { "^\\.git$", "^\\.idea$" },
			},
		},
	},
}
