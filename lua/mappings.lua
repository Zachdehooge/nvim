require("nvchad.mappings")

-- add yours here
local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")
map("n", "A-j", "<cmd> TodoTelescope <cr>")

-- Accept current Copilot suggestion
map("i", "<C-l>", function()
	require("copilot.suggestion").accept()
end, { desc = "Accept Copilot suggestion" })

-- Next suggestion
map("i", "<C-]>", function()
	require("copilot.suggestion").next()
end, { desc = "Next Copilot suggestion" })

-- Previous suggestion
map("i", "<C-[>", function()
	require("copilot.suggestion").prev()
end, { desc = "Previous Copilot suggestion" })

-- Dismiss suggestion
map("i", "<C-x>", function()
	require("copilot.suggestion").dismiss()
end, { desc = "Dismiss Copilot suggestion" })

vim.keymap.set("i", "<Esc>", "<Esc>", {
	desc = "Force exit insert mode",
	noremap = true,
	silent = true,
})

vim.api.nvim_set_keymap("n", "<leader>ct", "<cmd>Copilot toggle<cr>", { noremap = true, silent = true })

-- Open compiler
vim.api.nvim_set_keymap("n", "<F5>", "<cmd>OverseerToggle<cr>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<F6>", "<cmd>OverseerRun<cr>", { noremap = true, silent = true })

vim.api.nvim_set_keymap("n", "<leader>rt", "<cmd>OverseerToggle<cr>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>rr", "<cmd>OverseerRun<cr>", { noremap = true, silent = true })

-- Build / build & run (same as Doom's SPC r b / SPC r c)
-- Picks CMake, Maven, Gradle or Python based on the current filetype, falling back to
-- the nearest project marker file.

-- In the file tree, the node under the cursor stands in for the buffer, so you
-- can browse into another project and build it without opening a file there.
local function tree_node()
	if vim.bo.filetype ~= "NvimTree" then
		return nil
	end
	local node = require("nvim-tree.api").tree.get_node_under_cursor()
	if not node or not node.absolute_path then
		return nil
	end
	return node.absolute_path, node.type == "directory"
end

local function context_file()
	local path, is_dir = tree_node()
	if path then
		return not is_dir and path or nil
	end
	return vim.api.nvim_buf_get_name(0)
end

local function buf_dir()
	local path, is_dir = tree_node()
	if path then
		return is_dir and path or vim.fs.dirname(path)
	end
	local start = vim.fs.dirname(vim.api.nvim_buf_get_name(0))
	if start == nil or start == "" or start == "." then
		start = vim.fn.getcwd()
	end
	return start
end

-- Top-most match (CMake subdirectories can have their own CMakeLists.txt)
local function find_root(markers, topmost)
	local found = vim.fs.find(markers, { upward = true, path = buf_dir(), limit = topmost and math.huge or 1 })
	if #found == 0 then
		return nil
	end
	return vim.fs.dirname(found[#found])
end

local function read(path)
	return table.concat(vim.fn.readfile(path), "\n")
end

local function cmake_cmd(root, run)
	local cmd = vim.fn.isdirectory(root .. "/build") == 1 and "cmake --build build"
		or "cmake -B build && cmake --build build && ln -sf build/compile_commands.json compile_commands.json"
	if run then
		local text = read(root .. "/CMakeLists.txt")
		local target = text:match("add_executable%(%s*([^%s%)]+)")
		if not target then
			return nil, "No add_executable() found in CMakeLists.txt"
		end
		-- add_executable(${PROJECT_NAME} ...) names the exe after project()
		local project = text:match("project%(%s*([^%s%)]+)")
		if project then
			target = target:gsub("%${PROJECT_NAME}", project)
		end
		cmd = cmd .. " && ./build/" .. target
	end
	return cmd
end

-- "com.example.App" if the file declares a main method, else nil
local function java_main_class(path)
	local ok, lines = pcall(vim.fn.readfile, path)
	if not ok then
		return nil
	end
	local text = table.concat(lines, "\n")
	if not text:match("static%s+void%s+main%s*%(") and not text:match("void%s+main%s*%(%s*%)") then
		return nil
	end
	local class = vim.fn.fnamemodify(path, ":t:r")
	local pkg = text:match("\n%s*package%s+([%w_.]+)%s*;") or text:match("^%s*package%s+([%w_.]+)%s*;")
	return pkg and (pkg .. "." .. class) or class
end

local function maven_cmd(root, run)
	if not run then
		return "mvn compile"
	end
	local cmd = "mvn -q compile exec:java"
	-- Respect an exec-maven-plugin <mainClass> in the pom; otherwise infer it
	if not read(root .. "/pom.xml"):match("<mainClass>") then
		local main = context_file() and java_main_class(context_file())
		if not main then
			local files = vim.fs.find(function(name)
				return name:match("%.java$")
			end, { path = root .. "/src/main/java", type = "file", limit = math.huge })
			for _, f in ipairs(files) do
				main = java_main_class(f)
				if main then
					break
				end
			end
		end
		if not main then
			return nil, "No main class found (set <mainClass> in pom.xml or open the main file)"
		end
		cmd = cmd .. " -Dexec.mainClass=" .. main
	end
	return cmd
end

-- Uses the wrapper when present. Multi-project builds run every subproject
-- that applies the `application` plugin, from that subproject's directory.
local function gradle_cmd(root, run)
	local gradle = vim.fn.executable(root .. "/gradlew") == 1 and "./gradlew" or "gradle"
	return gradle .. " --console=plain " .. (run and "run" or "classes")
end

local function python_cmd(root, run)
	local python = "python3"
	for _, venv in ipairs({ ".venv", "venv" }) do
		if vim.fn.executable(root .. "/" .. venv .. "/bin/python") == 1 then
			python = root .. "/" .. venv .. "/bin/python"
			break
		end
	end
	local file = context_file() or ""
	if not file:match("%.py$") then
		file = root .. "/main.py"
		if vim.fn.filereadable(file) == 0 then
			return nil, "Not in a Python file and no main.py in " .. root
		end
	end
	return vim.fn.shellescape(python) .. (run and " " or " -m py_compile ") .. vim.fn.shellescape(file)
end

-- Nearest Cargo.toml is the package; the workspace root (where rustc's
-- relative paths start) is the top-most Cargo.toml with a [workspace] table
local function cargo_workspace_root(root)
	local found = vim.fs.find("Cargo.toml", { upward = true, path = root, limit = math.huge })
	for i = #found, 1, -1 do
		if ("\n" .. read(found[i])):match("\n%s*%[workspace%]") then
			return vim.fs.dirname(found[i])
		end
	end
	return root
end

local function cargo_cmd(root, run)
	if not run then
		return "cargo build"
	end
	-- src/bin/foo.rs or src/bin/foo/main.rs: run that binary
	local file = context_file() or ""
	local bin = file:match("/src/bin/([^/]+)%.rs$") or file:match("/src/bin/([^/]+)/main%.rs$")
	return "cargo run" .. (bin and " --bin " .. vim.fn.shellescape(bin) or "")
end

local project_types = {
	cmake = {
		markers = { "CMakeLists.txt" },
		topmost = true,
		filetypes = { c = true, cpp = true, cmake = true },
		cmd = cmake_cmd,
	},
	maven = {
		markers = { "pom.xml" },
		filetypes = { java = true },
		cmd = maven_cmd,
		errorformat = "[ERROR] %f:[%l\\,%c] %m,[WARNING] %f:[%l\\,%c] %m",
	},
	gradle = {
		-- Top-most so a subproject's build.gradle resolves to the root build
		markers = { "settings.gradle", "settings.gradle.kts", "build.gradle", "build.gradle.kts" },
		topmost = true,
		filetypes = { java = true, kotlin = true, groovy = true },
		cmd = gradle_cmd,
		errorformat = "%f:%l: error: %m,%f:%l: warning: %m,e: file://%f:%l:%c %m,w: file://%f:%l:%c %m",
	},
	cargo = {
		markers = { "Cargo.toml" },
		filetypes = { rust = true, toml = true },
		cmd = cargo_cmd,
		file_root = cargo_workspace_root,
		errorformat = table.concat({
			"%-Gerror: could not compile%.%#",
			"%-Gwarning: `%.%#` generated%.%#",
			"%-G%.%#warning%.%# emitted",
			"%Eerror[E%n]: %m",
			"%Eerror: %m",
			"%Wwarning: %m",
			"%C %#--> %f:%l:%c",
			"%Ethread %.%# panicked at %f:%l:%c:",
			"%-G%.%#",
		}, ","),
	},
	python = {
		markers = { "pyproject.toml", "setup.py", "requirements.txt", ".git" },
		filetypes = { python = true },
		cmd = python_cmd,
		errorformat = '%*\\sFile "%f"\\, line %l%.%#',
	},
}

-- Whichever project's marker is closest to the buffer (deepest root wins)
local function closest_project(filter)
	local best, best_len
	for name, p in pairs(project_types) do
		local root = filter(name, p) and find_root(p.markers, p.topmost)
		if root and (not best_len or #root > best_len) then
			best, best_len = { name, p, root }, #root
		end
	end
	if best then
		return unpack(best)
	end
end

local function detect_project()
	local ft = vim.bo.filetype
	if ft == "python" then
		return "python", project_types.python, find_root(project_types.python.markers) or buf_dir()
	end
	-- Several build tools can share a filetype (Java: Maven or Gradle)
	local name, p, root = closest_project(function(_, p)
		return p.filetypes[ft]
	end)
	if root then
		return name, p, root
	end
	-- Unknown filetype (or no matching build file): use any marker
	return closest_project(function(n)
		return n ~= "python"
	end)
end

local function project_task(run)
	local name, p, root = detect_project()
	if not root then
		vim.notify("No CMake, Maven, Gradle, Cargo or Python project found for this buffer", vim.log.levels.ERROR)
		return
	end
	local cmd, err = p.cmd(root, run)
	if not cmd then
		vim.notify(err, vim.log.levels.ERROR)
		return
	end
	vim.cmd("silent! wall")
	local overseer = require("overseer")
	overseer
		.new_task({
			name = name .. (run and " build & run" or " build"),
			cmd = cmd,
			cwd = root,
			components = {
				{
					"on_output_quickfix",
					set_diagnostics = true,
					errorformat = p.errorformat,
					relative_file_root = p.file_root and p.file_root(root),
				},
				"on_result_diagnostics",
				"default",
			},
		})
		:start()
	overseer.open({ enter = false })
end

map("n", "<leader>rb", function()
	project_task(false)
end, { desc = "Build project (CMake/Maven/Gradle/Cargo/Python)" })
map("n", "<leader>rc", function()
	project_task(true)
end, { desc = "Build & run project (CMake/Maven/Gradle/Cargo/Python)" })

vim.keymap.set("t", "<ESC><ESC>", "<C-\\><C-n>", { silent = true })

-- -- Redo last selected option
-- vim.api.nvim_set_keymap(
-- 	"n",
-- 	"<S-F6>",
-- 	"<cmd>CompilerStop<cr>" -- (Optional, to dispose all tasks before redo)
-- 		.. "<cmd>CompilerRedo<cr>",
-- 	{ noremap = true, silent = true }
-- )
--
-- -- Toggle compiler results
-- vim.api.nvim_set_keymap("n", "<S-F7>", "<cmd>CompilerToggleResults<cr>", { noremap = true, silent = true })
