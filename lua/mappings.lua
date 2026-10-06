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

-- CMake build / build & run (same as Doom's SPC r b / SPC r c)
local function cmake_root()
	local start = vim.fs.dirname(vim.api.nvim_buf_get_name(0))
	if start == nil or start == "" or start == "." then
		start = vim.fn.getcwd()
	end
	-- Top-most CMakeLists.txt (subdirectories can have their own)
	local found = vim.fs.find("CMakeLists.txt", { upward = true, path = start, limit = math.huge })
	if #found == 0 then
		return nil
	end
	return vim.fs.dirname(found[#found])
end

local function cmake_task(run)
	local root = cmake_root()
	if not root then
		vim.notify("No CMakeLists.txt found above this file", vim.log.levels.ERROR)
		return
	end
	local cmd = vim.fn.isdirectory(root .. "/build") == 1 and "cmake --build build"
		or "cmake -B build && cmake --build build && ln -sf build/compile_commands.json compile_commands.json"
	if run then
		local text = table.concat(vim.fn.readfile(root .. "/CMakeLists.txt"), "\n")
		local target = text:match("add_executable%(%s*([^%s%)]+)")
		if not target then
			vim.notify("No add_executable() found in CMakeLists.txt", vim.log.levels.ERROR)
			return
		end
		cmd = cmd .. " && ./build/" .. target
	end
	vim.cmd("silent! wall")
	local overseer = require("overseer")
	overseer
		.new_task({
			name = run and "cmake build & run" or "cmake build",
			cmd = cmd,
			cwd = root,
			components = {
				{ "on_output_quickfix", set_diagnostics = true },
				"on_result_diagnostics",
				"default",
			},
		})
		:start()
	overseer.open({ enter = false })
end

map("n", "<leader>rb", function()
	cmake_task(false)
end, { desc = "Build CMake project" })
map("n", "<leader>rc", function()
	cmake_task(true)
end, { desc = "Build & run CMake project" })

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
