return {
	{
		"ojroques/nvim-osc52",
		lazy = false,
		opts = {
			silent = true,
			trim = true,
		},
		config = function()
			-- Set up OSC 52 clipboard globally
			local osc52 = require('osc52')
			
			-- Set up clipboard provider
			vim.g.clipboard = {
				name = 'OSC 52',
				copy = {
					["+"] = function(lines)
						osc52.copy(table.concat(lines, '\n'))
					end,
					["*"] = function(lines)
						osc52.copy(table.concat(lines, '\n'))
					end,
				},
				paste = {
					["+"] = function()
						return vim.fn.split(vim.fn.getreg('+'), '\n')
					end,
					["*"] = function()
						return vim.fn.split(vim.fn.getreg('*'), '\n')
					end,
				},
			}
			
			-- Auto-copy on yank to + register
			local function copy_on_yank()
				if vim.v.event.operator == 'y' and vim.v.event.regname == '+' then
					osc52.copy_register('+')
				end
			end
			
			vim.api.nvim_create_autocmd('TextYankPost', {
				callback = copy_on_yank,
				group = vim.api.nvim_create_augroup('OSCYank', { clear = true }),
			})
			
			-- Set up key mappings
			vim.keymap.set('n', '<leader>c', '"+yy', { desc = 'Copy line to clipboard' })
			vim.keymap.set('v', '<leader>c', '"+y', { desc = 'Copy selection to clipboard' })
			vim.keymap.set('n', '<leader>cc', '"+yy', { desc = 'Copy line to clipboard' })
		end,
	},
}