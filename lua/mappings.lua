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
-- Picks C/C++ or Java (single file), CMake, Maven, Gradle, Cargo, Go, Zig or Python based on the current filetype, falling back to
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
		local vars = { CMAKE_CURRENT_SOURCE_DIR = root, CMAKE_SOURCE_DIR = root }
		-- Simple variables: set(x value) and get_filename_component(x <path> NAME)
		for name, value in text:gmatch("set%(%s*([%w_]+)%s+([^%s%)]+)%s*%)") do
			vars[name] = value
		end
		for name, path in text:gmatch("get_filename_component%(%s*([%w_]+)%s+([^%s%)]+)%s+NAME%s*%)") do
			vars[name] = { name_of = path }
		end
		-- add_executable(${PROJECT_NAME} ...) names the exe after project()
		local project = text:match("project%(%s*([^%s%)]+)")
		if project then
			vars.PROJECT_NAME = project
		end
		local function expand(s, depth)
			return (s:gsub("%${([%w_]+)}", function(name)
				local v = vars[name]
				if v == nil or depth > 5 then
					return nil
				elseif type(v) == "table" then
					return vim.fs.basename(expand(v.name_of, depth + 1))
				end
				return expand(v, depth + 1)
			end))
		end
		target = expand(target, 0)
		if target:find("${", 1, true) then
			return nil, "Couldn't resolve executable name " .. target
		end
		cmd = cmd .. " && ./build/" .. vim.fn.shellescape(target)
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
	-- Java 25 also allows instance mains: void main() / void main(String[] args)
	if not text:match("void%s+main%s*%(") then
		return nil
	end
	local class = vim.fn.fnamemodify(path, ":t:r")
	local pkg = text:match("\n%s*package%s+([%w_.]+)%s*;") or text:match("^%s*package%s+([%w_.]+)%s*;")
	return pkg and (pkg .. "." .. class) or class
end

-- JDK used when the build (or a .java-version file) doesn't name one
local DEFAULT_JAVA = 25

-- "1.8" -> 8, "21" -> 21, "25.0.2" -> 25
local function java_major(v)
	return v and tonumber(v:match("^1%.(%d+)") or v:match("^(%d+)"))
end

-- From the JDK's `release` file, else its directory name (java-25-openjdk-amd64)
local function jdk_major(home)
	local ok, lines = pcall(vim.fn.readfile, home .. "/release")
	for _, line in ipairs(ok and lines or {}) do
		local v = line:match('^JAVA_VERSION="([^"]+)"')
		if v then
			return java_major(v)
		end
	end
	return java_major(vim.fs.basename(home):match("(%d[%d.]*)"))
end

-- JAVA_HOME of an installed JDK with that major version (JAVA_HOME first)
local function find_jdk(version)
	local homes = { vim.env.JAVA_HOME }
	for _, pattern in ipairs({
		"/usr/lib/jvm/*",
		"/home/linuxbrew/.linuxbrew/opt/openjdk*/libexec",
		"~/.sdkman/candidates/java/*",
		"~/.jdks/*",
		"~/.gradle/jdks/*",
	}) do
		vim.list_extend(homes, vim.fn.glob(pattern, true, true))
	end
	for _, home in ipairs(homes) do
		if home ~= "" and vim.fn.executable(home .. "/bin/javac") == 1 and jdk_major(home) == version then
			return home
		end
	end
end

-- Puts that JDK first for mvn/gradle; nil (inherit the shell's) if not installed
local function jdk_env(version)
	local home = find_jdk(version)
	if home then
		return { JAVA_HOME = home, PATH = home .. "/bin:" .. vim.env.PATH }
	end
end

local function maven_java_version(root)
	local pom = read(root .. "/pom.xml")
	for _, prop in ipairs({ "maven.compiler.release", "release", "maven.compiler.source", "java.version" }) do
		local v = pom:match("<" .. prop:gsub("%.", "%%.") .. ">%s*([%d.]+)%s*</")
		if v then
			return java_major(v)
		end
	end
end

local function maven_env(root)
	return jdk_env(maven_java_version(root) or DEFAULT_JAVA)
end

local function maven_cmd(root, run)
	-- Maven's default target is ancient; compile for the fallback JDK instead
	local release = maven_java_version(root) and "" or " -Dmaven.compiler.release=" .. DEFAULT_JAVA
	if not run then
		return "mvn compile" .. release
	end
	local cmd = "mvn -q compile exec:java" .. release
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

-- Java version from the root and subproject build files: (version, from_toolchain)
local function gradle_java_version(root)
	local compat
	local skip = function(dir)
		local name = vim.fs.basename(dir)
		return name ~= "build" and name ~= "node_modules" and not name:match("^%.")
	end
	for name, kind in vim.fs.dir(root, { depth = 2, skip = skip }) do
		if kind == "file" and (name:match("%.gradle$") or name:match("%.gradle%.kts$")) then
			local text = read(root .. "/" .. name)
			local v = text:match("JavaLanguageVersion%.of%(%s*(%d+)") or text:match("jvmToolchain%s*%(?%s*(%d+)")
			if v then
				return java_major(v), true
			end
			compat = compat
				or text:match("sourceCompatibility%s*=%s*JavaVersion%.VERSION_([%d_]+)")
				or text:match("sourceCompatibility%s*=%s*['\"]?([%d.]+)")
		end
	end
	return java_major(compat and compat:gsub("_", ".")), false
end

-- A toolchain picks (or downloads) its own JDK; otherwise run Gradle itself
-- on the sourceCompatibility JDK, or the fallback one
local function gradle_env(root)
	local version, toolchain = gradle_java_version(root)
	if not toolchain then
		return jdk_env(version or DEFAULT_JAVA)
	end
end

-- Registers :nvimRunMain on every Java project so any main class can run,
-- with or without the `application` plugin (classpath + toolchain included)
local gradle_init_script = [[
beforeProject { project ->
    project.plugins.withId('java') {
        project.tasks.register('nvimRunMain', JavaExec) {
            classpath = project.sourceSets[project.findProperty('nvimSourceSet') ?: 'main'].runtimeClasspath
            mainClass = project.findProperty('nvimMain')
            standardInput = System.in
        }
    }
}
]]

local function gradle_init_path()
	local path = vim.fn.stdpath("cache") .. "/nvim-run-main.gradle"
	if vim.fn.filereadable(path) == 0 or read(path) ~= vim.trim(gradle_init_script) then
		vim.fn.writefile(vim.split(vim.trim(gradle_init_script), "\n"), path)
	end
	return path
end

-- Uses the wrapper when present. Running from a file with a main method runs
-- that class in its subproject; otherwise `run` runs every subproject that
-- applies the `application` plugin.
local function gradle_cmd(root, run)
	local gradle = (vim.fn.executable(root .. "/gradlew") == 1 and "./gradlew" or "gradle") .. " --console=plain"
	local file = context_file()
	local main = run and file and java_main_class(file)
	if not main then
		return gradle .. (run and " run" or " classes")
	end
	-- Subproject path from the nearest build file, e.g. application/ -> :application
	local build = vim.fs.find({ "build.gradle", "build.gradle.kts" }, { upward = true, path = vim.fs.dirname(file), limit = 1 })[1]
	local rel = build and vim.fs.relpath(root, vim.fs.dirname(build)) or "."
	local task = (rel == "." and "" or ":" .. rel:gsub("/", ":")) .. ":nvimRunMain"
	return gradle
		.. " --init-script "
		.. vim.fn.shellescape(gradle_init_path())
		.. " "
		.. task
		.. " -PnvimMain="
		.. main
		.. " -PnvimSourceSet="
		.. (file:match("/src/([^/]+)/java/") or "main")
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

-- Builds every package in the module; runs the current file's package if it
-- is a main package, otherwise the module root
local function go_cmd(root, run)
	if not run then
		return "go build ./..."
	end
	local file = context_file() or ""
	if file:match("%.go$") then
		local ok, lines = pcall(vim.fn.readfile, file)
		if ok and ("\n" .. table.concat(lines, "\n")):match("\n%s*package%s+main%f[%W]") then
			local rel = vim.fs.relpath(root, vim.fs.dirname(file))
			if rel then
				return "go run ./" .. (rel == "." and "" or rel)
			end
		end
	end
	return "go run ."
end

-- `zig build` / `zig build run` when build.zig has a run step; otherwise
-- builds or runs the current file on its own (single-file programs, Ziglings)
local function zig_cmd(root, run)
	local has_build = vim.fn.filereadable(root .. "/build.zig") == 1
	if has_build and (not run or read(root .. "/build.zig"):match('%.step%(%s*"run"')) then
		return run and "zig build run" or "zig build"
	end
	local file = context_file() or ""
	if not file:match("%.zig$") then
		return nil, "Not in a Zig file and no run step in " .. root .. "/build.zig"
	end
	return "zig " .. (run and "run " or "build-exe ") .. vim.fn.shellescape(file)
end

-- A lone .c/.cpp file with no CMakeLists.txt: compile just that file (like
-- `python foo.py`). The binary goes in the cache dir so nothing lands next to
-- the source; build only compiles, so you see the warnings and errors.
local function c_source(path)
	local ext = (path or ""):match("%.([%w+]+)$")
	if ext == "c" then
		return "c"
	elseif ext == "cpp" or ext == "cc" or ext == "cxx" or ext == "c++" or ext == "C" then
		return "cpp"
	end
end

-- Follow local `#include "foo.h"` lines (recursively) and pick up the
-- matching foo.c/foo.cpp next to each header, so hello.h pulls in hello.c
local function c_sources(file)
	local sources, seen = { file }, { [file] = true }
	local queue = { file }
	while #queue > 0 do
		local path = table.remove(queue)
		local dir = vim.fs.dirname(path)
		local ok, lines = pcall(vim.fn.readfile, path)
		for _, line in ipairs(ok and lines or {}) do
			local inc = line:match('^%s*#%s*include%s*"([^"]+)"')
			local header = inc and vim.fs.normalize(dir .. "/" .. inc)
			if header and not seen[header] and vim.fn.filereadable(header) == 1 then
				seen[header] = true
				table.insert(queue, header)
				local stem = vim.fn.fnamemodify(header, ":r")
				for _, ext in ipairs({ "c", "cpp", "cc", "cxx" }) do
					local src = stem .. "." .. ext
					if not seen[src] and vim.fn.filereadable(src) == 1 then
						seen[src] = true
						table.insert(sources, src)
						table.insert(queue, src)
						break
					end
				end
			end
		end
	end
	return sources
end

local function single_c_cmd(_, run)
	local file = context_file() or ""
	local lang = c_source(file)
	if not lang then
		return nil, "Not in a C/C++ source file and no CMakeLists.txt found"
	end
	file = vim.fs.normalize(vim.fn.fnamemodify(file, ":p"))
	local out_dir = vim.fn.stdpath("cache") .. "/c_run"
	vim.fn.mkdir(out_dir, "p")
	-- Hash the path so same-named files in different dirs don't clobber each other
	local exe = out_dir .. "/" .. vim.fn.fnamemodify(file, ":t:r") .. "-" .. vim.fn.sha256(file):sub(1, 8)
	local compiler = lang == "c" and "cc -std=c17" or "c++ -std=c++20"
	local cmd = compiler
		.. " -Wall -Wextra -g "
		.. table.concat(vim.tbl_map(vim.fn.shellescape, c_sources(file)), " ")
		.. " -o "
		.. vim.fn.shellescape(exe)
		.. (lang == "c" and " -lm" or "")
	return run and (cmd .. " && " .. vim.fn.shellescape(exe)) or cmd
end

local single_c = {
	cmd = single_c_cmd,
	errorformat = "%f:%l:%c: %trror: %m,%f:%l:%c: %tarning: %m,%f:%l: %trror: %m,%-G%.%#",
}

local function java_file(path)
	return (path or ""):match("%.java$") ~= nil
end

-- A lone .java file with no pom.xml/build.gradle. The source root comes from
-- the package declaration, and javac's -sourcepath compiles every class the
-- file references from that tree (the Java take on c_sources). The JDK comes
-- from the nearest .java-version file, else DEFAULT_JAVA.
local function single_java_cmd(_, run)
	local file = context_file() or ""
	if not java_file(file) then
		return nil, "Not in a Java file and no pom.xml or build.gradle found"
	end
	file = vim.fs.normalize(vim.fn.fnamemodify(file, ":p"))
	local src_root = vim.fs.dirname(file)
	local ok, lines = pcall(vim.fn.readfile, file)
	local pkg = ("\n" .. table.concat(ok and lines or {}, "\n")):match("\n%s*package%s+([%w_.]+)%s*;")
	if pkg then
		local suffix = "/" .. pkg:gsub("%.", "/")
		if src_root:sub(-#suffix) == suffix then
			src_root = src_root:sub(1, -#suffix - 1)
		end
	end
	local version_file = vim.fs.find(".java-version", { upward = true, path = src_root, limit = 1 })[1]
	local version = version_file and java_major(vim.trim(read(version_file))) or DEFAULT_JAVA
	local home = find_jdk(version)
	local bin = home and (home .. "/bin/") or ""
	-- Fresh output dir per source tree so deleted classes can't linger
	local out = vim.fn.stdpath("cache") .. "/java_run/" .. vim.fn.fnamemodify(file, ":t:r") .. "-" .. vim.fn.sha256(src_root):sub(1, 8)
	local cmd = "rm -rf "
		.. vim.fn.shellescape(out)
		.. " && "
		.. vim.fn.shellescape(bin .. "javac")
		.. " --release "
		.. version
		.. " -g -sourcepath "
		.. vim.fn.shellescape(src_root)
		.. " -d "
		.. vim.fn.shellescape(out)
		.. " "
		.. vim.fn.shellescape(file)
	if not run then
		return cmd
	end
	local main = java_main_class(file)
	if not main then
		return nil, vim.fs.basename(file) .. " has no main method"
	end
	return cmd .. " && " .. vim.fn.shellescape(bin .. "java") .. " -cp " .. vim.fn.shellescape(out) .. " " .. main
end

local single_java = {
	cmd = single_java_cmd,
	errorformat = "%f:%l: %trror: %m,%f:%l: %tarning: %m,%-G%.%#",
}

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
		env = maven_env,
		errorformat = "[ERROR] %f:[%l\\,%c] %m,[WARNING] %f:[%l\\,%c] %m",
	},
	gradle = {
		-- Top-most so a subproject's build.gradle resolves to the root build
		markers = { "settings.gradle", "settings.gradle.kts", "build.gradle", "build.gradle.kts" },
		topmost = true,
		filetypes = { java = true, kotlin = true, groovy = true },
		cmd = gradle_cmd,
		env = gradle_env,
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
	go = {
		markers = { "go.mod" },
		filetypes = { go = true, gomod = true, gowork = true },
		cmd = go_cmd,
		errorformat = "%-G#%.%#,%f:%l:%c: %m,%f:%l: %m",
	},
	zig = {
		markers = { "build.zig" },
		filetypes = { zig = true, zon = true },
		cmd = zig_cmd,
		errorformat = "%f:%l:%c: %trror: %m,%f:%l:%c: %tarning: %m,%-G%.%#",
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
	-- A lone .zig file needs no build.zig
	if ft == "zig" then
		return "zig", project_types.zig, find_root(project_types.zig.markers) or buf_dir()
	end
	-- A lone .c/.cpp file needs no CMakeLists.txt
	if ft == "c" or ft == "cpp" or c_source(context_file()) then
		local root = find_root(project_types.cmake.markers, true)
		if root then
			return "cmake", project_types.cmake, root
		end
		return c_source(context_file()) or ft, single_c, buf_dir()
	end
	-- A lone .java file needs no pom.xml or build.gradle
	if ft == "java" or java_file(context_file()) then
		local name, p, root = closest_project(function(n)
			return n == "maven" or n == "gradle"
		end)
		if root then
			return name, p, root
		end
		return "java", single_java, buf_dir()
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
		vim.notify("No C/C++, Java, CMake, Maven, Gradle, Cargo, Go, Zig or Python project found for this buffer", vim.log.levels.ERROR)
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
			env = p.env and p.env(root),
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
end, { desc = "Build project (C/C++/Java/CMake/Maven/Gradle/Cargo/Go/Zig/Python)" })
map("n", "<leader>rc", function()
	project_task(true)
end, { desc = "Build & run project (C/C++/Java/CMake/Maven/Gradle/Cargo/Go/Zig/Python)" })

-- Clear stale LSP diagnostics (e.g. clangd "unused variable" that's actually used)
map("n", "<leader>rl", "<cmd>silent! edit<cr>", { desc = "Reload buffer (recheck diagnostics)" })
map("n", "<leader>rL", "<cmd>LspRestart<cr>", { desc = "Restart LSP" })

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
