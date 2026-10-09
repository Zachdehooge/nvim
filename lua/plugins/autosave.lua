return {
	{
		"okuuva/auto-save.nvim",
		event = { "InsertLeave", "TextChanged" },
		opts = {
			enabled = true,
			-- only save real, modifiable files
			condition = function(buf)
				local fn = vim.fn
				return fn.getbufvar(buf, "&modifiable") == 1 and fn.getbufvar(buf, "&buftype") == ""
			end,
			write_all_buffers = false,
			debounce_delay = 1000,
		},
		init = function()
			-- flag auto-saves so the "Saved <file>" popup in notify.lua can skip them
			local group = vim.api.nvim_create_augroup("AutoSaveFlag", { clear = true })
			vim.api.nvim_create_autocmd("User", {
				group = group,
				pattern = "AutoSaveWritePre",
				callback = function()
					vim.g.auto_save_in_progress = true
				end,
			})
			vim.api.nvim_create_autocmd("User", {
				group = group,
				pattern = "AutoSaveWritePost",
				callback = function()
					vim.g.auto_save_in_progress = false
				end,
			})
		end,
	},
}
