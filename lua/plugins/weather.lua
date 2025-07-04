return {
	"athar-qadri/weather.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"rcarriga/nvim-notify",
		"athar-qadri/scratchpad.nvim",
	},
	event = "VeryLazy",

	config = function()
		-- 1. Start weather backend
		local weather = require("weather")
		weather:setup({
			settings = {
				update_interval = 15 * 60 * 1000, -- 15 minutes
				temperature_unit = "fahrenheit", -- or "celsius"
			},
		})
		require("weather.notify").start()

		-- 2. After NvChad's lualine is set up, patch in weather
		vim.api.nvim_create_autocmd("User", {
			pattern = "LualineAfterSetup", -- NvChad triggers this
			callback = function()
				local lualine = require("lualine")
				local config = lualine.get_config()
				local weather_component = require("weather.lualine").default_c()

				-- Insert into the beginning of the first right-hand section available
				for _, section in ipairs({ "lualine_x", "lualine_y", "lualine_z" }) do
					if config.sections[section] then
						table.insert(config.sections[section], 1, weather_component)
						break
					end
				end

				lualine.setup(config)
			end,
		})
	end,
}
