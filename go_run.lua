-- /home/zach/.config/nvim/lua/overseer/template/user/go_run.lua - MacOS/Linux
-- C:\Users\username\AppData\Local\nvim-data\lazy\overseer.nvim\lua\overseer\template\user - Windows
return {
	name = "go run",
	builder = function()
		local file = vim.fn.expand("%:p")
		local cmd = { file }
		if vim.bo.filetype == "go" then
			cmd = { "go", "run", file }
		end
		return {
			cmd = cmd,
			components = {
				{ "on_output_quickfix", set_diagnostics = true },
				"on_result_diagnostics",
				"default",
			},
		}
	end,
	condition = {
		filetype = { "sh", "python", "go" },
	},
}
