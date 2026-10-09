vim.diagnostic.config({
	virtual_text = false,
	virtual_lines = false,
	signs = true,
	underline = true,
	update_in_insert = false,
})

-- load defaults i.e lua_lsp
require("nvchad.configs.lspconfig").defaults()

local nvlsp = require("nvchad.configs.lspconfig")
local util = require("lspconfig.util")

-- lsps with default config
local servers = { "html", "cssls" }
for _, lsp in ipairs(servers) do
	vim.lsp.config(lsp, {
		on_attach = nvlsp.on_attach,
		on_init = nvlsp.on_init,
		capabilities = nvlsp.capabilities,
	})
	vim.lsp.enable(lsp)
end

local tf_capb = vim.lsp.protocol.make_client_capabilities()
tf_capb.textDocument.completion.completionItem.snippetSupport = true

vim.lsp.config("terraformls", {
	on_attach = nvlsp.on_attach,
	flags = { debounce_text_changes = 150 },
	capabilities = tf_capb,
})
vim.lsp.enable("terraformls")

vim.lsp.config("jdtls", {
	on_attach = nvlsp.on_attach,
	on_init = nvlsp.on_init,
	capabilities = nvlsp.capabilities,
	-- use ~/.local/share/jdtls (not mason's copy) with a per-project workspace
	cmd = function(dispatchers, config)
		local data_dir = vim.fn.stdpath("cache") .. "/jdtls/workspace/" .. vim.fn.fnamemodify(config.root_dir or "default", ":p:h:t")
		return vim.lsp.rpc.start({ vim.fn.expand("~/.local/share/jdtls/bin/jdtls"), "-data", data_dir }, dispatchers)
	end,
})
vim.lsp.enable("jdtls")

vim.lsp.config("gopls", {
	on_attach = nvlsp.on_attach,
	capabilities = nvlsp.capabilities,
	cmd = { "gopls" },
	filetypes = { "go", "gomod", "gowork", "gotmpl" },
	root_dir = util.root_pattern("go.work", "go.mod", ".git"),
	settings = {
		gopls = {
			completeUnimported = true,
			usePlaceholders = true,
			analyses = {
				unusedparams = true,
			},
		},
	},
})
vim.lsp.enable("gopls")

vim.lsp.config("pyright", {
	before_init = function(_, config)
		local venv_path = vim.fn.getcwd() .. "/.venv/bin/python"
		if vim.fn.executable(venv_path) == 1 then
			config.settings.python.pythonPath = venv_path
		end
	end,
	settings = {
		python = {
			analysis = {
				typeCheckingMode = "off",
				autoSearchPaths = true,
				useLibraryCodeForTypes = true,
			},
		},
	},
})
vim.lsp.enable("pyright")

vim.lsp.config("pylsp", {
	on_attach = nvlsp.on_attach,
	on_init = nvlsp.on_init,
	capabilities = nvlsp.capabilities,
	settings = {
		pylsp = {
			plugins = {
				-- warnings to omit
				pycodestyle = {
					ignore = { "E501", "W503", "E203", "W293", "E303", "E112", "W291", "E302" },
					maxLineLength = 120,
				},
				pyflakes = { enabled = true },
				mccabe = { enabled = false },
				-- turn off linters you don't use
				pylint = { enabled = false },
				flake8 = { enabled = false },
				autopep8 = { enabled = false },
				yapf = { enabled = false },
			},
		},
	},
})
vim.lsp.enable("pylsp")

vim.lsp.config("rust_analyzer", {
	settings = {
		["rust-analyzer"] = {
			inlayHints = {
				enable = true,
			},
		},
	},
})
vim.lsp.enable("rust_analyzer")

require("mason-lspconfig").setup({
    ensure_installed = { "clangd" },
    handlers = {
        function(server_name)
            require("lspconfig")[server_name].setup({})
        end,
    },
})
vim.lsp.enable("clangd")

-- FORCE disable virtual_text for all buffers on LSP attach
vim.api.nvim_create_autocmd("LspAttach", {
	callback = function()
		vim.diagnostic.config({
			virtual_text = false,
			virtual_lines = false,
			signs = true,
			underline = true,
			update_in_insert = false,
		})
	end,
})

-- Custom diagnostic handler: no virtual_text, only signs/underline
vim.diagnostic.handlers.virtual_text = {
	show = function() end,
	hide = function() end,
}
