return {
	{
		"rcarriga/nvim-notify",
		lazy = false, -- ← loads during startup, no events/ft/cond
		priority = 1000, -- (optional) load early
		opts = {
			stages = "fade",
			timeout = 3000,
			background_colour = "#000000",
		},
		config = function(_, opts)
			local notify = require("notify")
			notify.setup(opts)
			vim.notify = notify -- global override

			-- Register the save‑popup autocmd **here** so it only runs once
			vim.api.nvim_create_autocmd("BufWritePost", {
				callback = function(args)
					local file = vim.fn.fnamemodify(args.file, ":.")
					notify("Saved " .. file, "info", { title = "File Save" })
				end,
			})
		end,
	},
}
