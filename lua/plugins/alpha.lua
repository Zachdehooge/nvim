return {
	{
		"goolord/alpha-nvim",
		event = "VimEnter",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			local alpha = require("alpha")
			local dashboard = require("alpha.themes.dashboard")

			dashboard.section.header.val = {
				[[            ▟▛ ▟▘             ]],
				[[            ▜▙ ▜▖             ]],
				[[             ▟▛ ▟▘            ]],
				[[         ▄▄▄▄▄▄▄▄▄▄▄▄         ]],
				[[         ████████████▀▀▙      ]],
				[[         ▜██████████▛▄▟▘      ]],
				[[          ▀▀▀▀▀▀▀▀▀▀          ]],
				[[       ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀       ]],
				[[                              ]],
				[[             Java             ]],
				[["write once, debug everywhere"]],
			}

			-- Java logo colors; re-applied on ColorScheme so base46 reloads don't wipe them
			local function set_coffee_hl()
				vim.api.nvim_set_hl(0, "AlphaSteam", { fg = "#E76F00", bold = true })
				vim.api.nvim_set_hl(0, "AlphaCoffee", { fg = "#5382A1", bold = true })
			end
			set_coffee_hl()
			vim.api.nvim_create_autocmd("ColorScheme", { callback = set_coffee_hl })

			-- Top 3 lines are the steam, the rest is the cup and caption
			local header_hl = {}
			for i = 1, #dashboard.section.header.val do
				header_hl[i] = { { i <= 3 and "AlphaSteam" or "AlphaCoffee", 0, -1 } }
			end
			dashboard.section.header.opts.hl = header_hl

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
