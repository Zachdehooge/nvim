-- This file needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v2.5/lua/nvconfig.lua
vim.g.tokyonight_style = "night"

---@type ChadrcConfig
local M = {}
M.base46 = {
	--theme = "cappuccin2",
	--theme = "bearded-arc",
	--theme = "doomchad",
	--theme = "gruvchad",
	theme = "tokyonight",
	-- theme = "catppuccin2",
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
		vim.g._weather_last_temp = "⏳" -- nothing until first success
		weather:subscribe("lualine_persist", function(update)
			if update.success and update.success.data then
				local d = update.success.data
				-- vim.g._weather_last_temp = (d.condition_icon or "") .. (d.temp or "")
				vim.g._weather_last_temp = (d.temp or "")
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

local function time_component()
	return os.date("%H:%M") -- 24-hour format like 21:45
end

M.ui = {
	statusline = {
		theme = "default",
		separator_style = "default",
		order = { "mode", "file", "git", "%=", "time", "%=", "weather", "lsp", "cwd" },
		modules = {
			weather = weather_component,
			time = time_component,
		},
	},
}

return M
