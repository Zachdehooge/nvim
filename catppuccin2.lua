-- The following is a cappuccin and gruvbox mesh
-- This needs to go in the 
-- /Users/username/.local/share/nvim/lazy/base46/lua/base46/themes on Macos/Linux
-- C:\Users\username\AppData\Local\nvim-data\lazy\base46\lua\base46\themes on Windows
-- lua/themes/catppuccin.lua

local M = {}

M.base_30 = {
  white = "#ebdbb2",
  darker_black = "#141617",
  black = "#1d2021", -- nvim bg
  black2 = "#191b1c",
  one_bg = "#292929",
  one_bg2 = "#404040",
  one_bg3 = "#4d4d4d",
  grey = "#595959",
  grey_fg = "#928374",
  grey_fg2 = "#a89984",
  light_grey = "#bdae93",
  red = "#ea6962",
  baby_pink = "#d3869b",
  pink = "#d3869b",
  line = "#404040",
  green = "#a9b665",
  vibrant_green = "#b0c16e",
  nord_blue = "#7daea3",
  blue = "#7daea3",
  yellow = "#d8a657",
  sun = "#e0b966",
  purple = "#d3869b",
  dark_purple = "#b16286",
  teal = "#89b482",
  orange = "#e78a4e",
  cyan = "#89b482",
  statusline_bg = "#1d2021",
  lightbg = "#292929",
  pmenu_bg = "#a9b665",
  folder_bg = "#7daea3",
  lavender = "#7daea3",
}

M.base_16 = {
  base00 = "#1d2021",
  base01 = "#191b1c",
  base02 = "#292929",
  base03 = "#404040",
  base04 = "#595959",
  base05 = "#ebdbb2",
  base06 = "#f0ebce",
  base07 = "#f9f5d7",
  base08 = "#ea6962",
  base09 = "#e78a4e",
  base0A = "#d8a657",
  base0B = "#a9b665",
  base0C = "#89b482",
  base0D = "#7daea3",
  base0E = "#d3869b",
  base0F = "#ea6962",
}

M.polish_hl = {
  treesitter = {
    ["@variable"] = { fg = M.base_30.white },
    ["@property"] = { fg = M.base_30.teal },
    ["@variable.builtin"] = { fg = M.base_30.red },
  },
  highlights = {
    FloatBorder = { bg = M.base_16.base00, fg = M.base_16.base03 },
    Pmenu = { bg = M.base_30.lightbg, fg = M.base_30.white },
    PmenuSel = { bg = M.base_30.one_bg2 },
    TelescopePromptBorder = { fg = M.base_30.one_bg3, bg = M.base_30.one_bg3 },
    TelescopeResultsBorder = { fg = M.base_30.one_bg, bg = M.base_30.one_bg },
    TelescopePreviewBorder = { fg = M.base_30.one_bg2, bg = M.base_30.one_bg2 },
    NeoTreeNormal = { bg = M.base_16.base01 },
    NeoTreeNormalNC = { bg = M.base_16.base01 },
    NeoTreeWinSeparator = { fg = M.base_16.base00, bg = M.base_16.base00 },
    IblIndent = { fg = M.base_30.one_bg3 },
    IblScope = { fg = M.base_30.grey },
    LineNr = { fg = M.base_30.grey_fg },
    CursorLineNr = { fg = M.base_30.white },
  },
}

M.type = "dark"

M = require("base46").override_theme(M, "catppuccin")

return M
