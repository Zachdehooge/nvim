-- Discord Rich Presence (cord.nvim)
-- Line 1 (details): file, cursor, mode, scope, diagnostics
-- Line 2 (state):   project, branch, LSP, buffers, tmux session

local MAX_LEN = 128 -- Discord's per-line limit

local function trim(s)
	if #s <= MAX_LEN then
		return s
	end
	return s:sub(1, MAX_LEN - 1) .. "…"
end

local modes = {
	n = "NORMAL",
	i = "INSERT",
	v = "VISUAL",
	V = "V-LINE",
	["\22"] = "V-BLOCK",
	R = "REPLACE",
	c = "COMMAND",
	t = "TERMINAL",
}

local function mode()
	local m = vim.api.nvim_get_mode().mode
	return modes[m] or modes[m:sub(1, 1)] or m
end

-- Name of the enclosing function/class from treesitter
local function scope()
	local ok, parser = pcall(vim.treesitter.get_parser, 0, nil, { error = false })
	if not ok or not parser then
		return nil
	end
	parser:parse()
	local node = vim.treesitter.get_node()
	while node do
		local t = node:type()
		if t:find("function") or t:find("method") or t:find("class") or t:find("struct") then
			local name = node:field("name")[1] or node:field("declarator")[1]
			-- C/C++ wrap names in declarators, e.g. foo(int x) -> foo
			while name and name:field("declarator")[1] do
				name = name:field("declarator")[1]
			end
			if name then
				local text = vim.treesitter.get_node_text(name, 0):gsub("%(.*", "")
				return text
			end
		end
		node = node:parent()
	end
end

local function diagnostics()
	local sev = vim.diagnostic.severity
	local errs = #vim.diagnostic.get(0, { severity = sev.ERROR })
	local warns = #vim.diagnostic.get(0, { severity = sev.WARN })
	local parts = {}
	if errs > 0 then
		table.insert(parts, errs .. "E")
	end
	if warns > 0 then
		table.insert(parts, warns .. "W")
	end
	return #parts > 0 and table.concat(parts, " ") or nil
end

local function lsp_names()
	local names = {}
	for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
		table.insert(names, c.name)
	end
	return #names > 0 and table.concat(names, ",") or nil
end

local function file_line(verb, opts)
	local parts = {
		string.format(
			"%s %s%s%s",
			verb,
			opts.filename,
			vim.bo.modified and " [+]" or "",
			opts.is_read_only and " [RO]" or ""
		),
		string.format("Ln %d/%d:%d", opts.cursor_line, vim.api.nvim_buf_line_count(0), opts.cursor_char + 1),
		mode(),
	}
	local fn = scope()
	if fn then
		table.insert(parts, "in " .. fn .. "()")
	end
	local diag = diagnostics()
	if diag then
		table.insert(parts, diag)
	end
	return trim(table.concat(parts, " · "))
end

local function workspace_line(opts)
	local parts = { "In " .. opts.workspace }
	local branch = vim.b.gitsigns_head
	if branch and branch ~= "" then
		parts[1] = parts[1] .. " (" .. branch .. ")"
	end
	local lsp = lsp_names()
	if lsp then
		table.insert(parts, lsp)
	end
	table.insert(parts, #vim.fn.getbufinfo({ buflisted = 1 }) .. " bufs")
	if opts.in_tmux and opts.in_tmux() and opts.tmux_session then
		local session = opts.tmux_session()
		if session then
			table.insert(parts, "tmux:" .. session)
		end
	end
	return trim(table.concat(parts, " · "))
end

local extensions = {
	-- Refreshes presence when diagnostics change; text is handled above
	diagnostics = { scope = "buffer", override = false },
	-- Elapsed timer = total time spent in this project across sessions
	-- (local_time / scoped_timestamps also set the timer, so only one can be used)
	persistent_timer = { scope = "workspace", mode = "active" },
	-- No-op outside tmux
	tmux = {},
	-- Hide presence entirely for secret files
	visibility = {
		rules = {
			blacklist = {
				{ type = "glob", value = "*.env" },
				{ type = "glob", value = "*/.env*" },
				{ type = "glob", value = "*/.ssh/*" },
			},
		},
	},
}

-- Shows the current scrobbled track; needs LASTFM_USERNAME and LASTFM_API_KEY
if vim.env.LASTFM_USERNAME and vim.env.LASTFM_API_KEY then
	extensions.lastfm = { override = false }
end

return {
	display = {
		theme = "minecraft",
	},
	text = {
		editing = function(opts)
			return file_line("Editing", opts)
		end,
		viewing = function(opts)
			return file_line("Viewing", opts)
		end,
		workspace = workspace_line,
		file_browser = function(opts)
			return "Browsing files in " .. opts.name
		end,
		plugin_manager = function(opts)
			return "Managing plugins in " .. opts.name
		end,
		lsp = function(opts)
			return "Configuring LSP in " .. opts.name
		end,
		docs = function(opts)
			return "Reading " .. opts.name .. " docs"
		end,
		vcs = function(opts)
			return "Committing changes in " .. opts.name
		end,
		notes = function(opts)
			return "Taking notes in " .. opts.name
		end,
		debug = function(opts)
			return "Debugging in " .. opts.name
		end,
		test = function(opts)
			return "Running tests in " .. opts.name
		end,
		diagnostics = function(opts)
			return "Fixing problems in " .. opts.name
		end,
		terminal = function(opts)
			return "Running commands in " .. opts.name
		end,
		games = function(opts)
			return "Playing " .. opts.name
		end,
		dashboard = "Home",
	},
	buttons = {
		{
			label = "View Repository",
			url = function(opts)
				return opts.repo_url
			end,
		},
	},
	extensions = extensions,
	advanced = {
		plugin = {
			cursor_update = "on_hold", -- or "on_move" to update on every cursor move
		},
	},
}
