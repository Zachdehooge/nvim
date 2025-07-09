-- This file needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v2.5/lua/nvconfig.lua
---@type ChadrcConfig
local M = {}
M.base46 = {
	theme = "bearded-arc",
	--theme = "doomchad",
	dashboard = true,
	-- hl_override = {
	-- 	Comment = { italic = true },
	-- 	["@comment"] = { italic = true },
	-- },
}

-- -------------------------------------------------------------------- --
-- 2.  Weather component that never goes blank
-- -------------------------------------------------------------------- --
local ok_weather, weather = pcall(require, "weather")
if ok_weather then
	-- Subscribe only once per NVim session
	if not vim.g._weather_subscribed then
		vim.g._weather_last_temp = "" -- nothing until first success
		weather:subscribe("lualine_persist", function(update)
			if update.success and update.success.data then
				vim.g._weather_last_temp = update.success.data.temp or vim.g._weather_last_temp
			end
			-- trigger an immediate status‑line refresh
			vim.schedule(function()
				vim.cmd("redrawstatus!")
			end)
		end)
		vim.g._weather_subscribed = true
	end
end

-- The Lualine component
local function weather_component()
	return vim.g._weather_last_temp or "" -- never nil/empty
end

M.ui = {
	statusline = {
		theme = "default",
		separator_style = "default",
		order = { "mode", "file", "git", "%=", "weather", "lsp", "cwd" },
		modules = {
			weather = weather_component,
		},
	},
}

return M
