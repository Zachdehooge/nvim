return {
	{
		"goolord/alpha-nvim",
		event = "VimEnter",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			local alpha = require("alpha")
			local dashboard = require("alpha.themes.dashboard")

			dashboard.section.header.val = {
				"             /\\",
				"            /  \\",
				"           /\\   \\",
				"          /      \\",
				"         /   ,,   \\",
				"        /   |  |  -\\",
				"       /_-''    ''-_\\",
				"",
				"       I use Arch btw ",
			}

			dashboard.section.buttons.val = {
				dashboard.button("f", "  Find file", ":Telescope find_files<CR>"),
				dashboard.button("n", "  New file", ":ene <BAR> startinsert <CR>"),
				-- dashboard.button("r", "  Recent files", ":Telescope oldfiles<CR>"),
				-- dashboard.button("s", "  Restore session", ":SessionManager load_session<CR>"),
				dashboard.button("q", "  Quit", ":qa<CR>"),
			}

			alpha.setup(dashboard.config)
		end,
	},
}
