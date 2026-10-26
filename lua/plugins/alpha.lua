return {
	{
		"goolord/alpha-nvim",
		event = "VimEnter",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			local alpha = require("alpha")
			local dashboard = require("alpha.themes.dashboard")

			dashboard.section.header.val = {
				[[                  ▄▄▄▄              ]],
				[[                ▄██████▄            ]],
				[[               ▟████████▙           ]],
				[[              ▟██████████▙          ]],
				[[             ▟████████████▙         ]],
				[[    ╲       ▟████▛▀▀▀▀▜████▙       ╱]],
				[[     ╲     ▟████▌ ▄██▄ ▐████▙     ╱ ]],
				[[      ╲   ▟█████▌ ████ ▐█████▙   ╱  ]],
				[[       ╲_▟██████▌ ▀██▀ ▐██████▙_╱   ]],
				[[        ▟████████▙▄▄▄▄▟████████▙    ]],
				[[       ╱                        ╲   ]],
				[[      ╱                          ╲  ]],
				[[     ▕                            ▏ ]],
				[[      ╲__________________________╱  ]],
				[[                                    ]],
				[[                 Duke               ]],
				[[    "write once, debug everywhere"  ]],
			}

			-- Duke in red; re-applied on ColorScheme so base46 reloads don't wipe it
			local function set_duke_hl()
				vim.api.nvim_set_hl(0, "AlphaDuke", { fg = "#E11D21", bold = true })
			end
			set_duke_hl()
			vim.api.nvim_create_autocmd("ColorScheme", { callback = set_duke_hl })
			dashboard.section.header.opts.hl = "AlphaDuke"

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
