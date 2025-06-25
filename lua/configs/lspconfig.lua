-- load defaults i.e lua_lsp
require("nvchad.configs.lspconfig").defaults()

local lspconfig = require "lspconfig"

-- EXAMPLE
local servers = { "html", "cssls" }
local nvlsp = require "nvchad.configs.lspconfig"
local util = require "lspconfig/util"

-- lsps with default config
for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = nvlsp.on_attach,
    on_init = nvlsp.on_init,
    capabilities = nvlsp.capabilities,
  }
end

local tf_capb = vim.lsp.protocol.make_client_capabilities()
tf_capb.textDocument.completion.completionItem.snippetSupport = true

lspconfig.terraformls.setup({
  on_attach = nvlsp.on_attach,
  flags = { debounce_text_changes = 150 },
  capabilities = tf_capb,
})

lspconfig.gopls.setup{
  on_attach = nvlsp.on_attach,
  capabilities = nvlsp.capabilities,
  cmd = {"gopls"},
  filetypes = {"go", "gomod", "gowork", "gotmpl"},
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

}

-- In your lua/configs/lspconfig.lua or similar file
local on_attach = function(client, bufnr)
  -- Your existing on_attach code...
  
  -- Enable inlay hints if supported
  if client.server_capabilities.inlayHintProvider then
    vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
  end
end

-- Or enable globally for all buffers
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client.server_capabilities.inlayHintProvider then
      vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
    end
  end,
})

-- Optional: Add a keybinding to toggle inlay hints
vim.keymap.set('n', '<leader>ih', function()
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
end, { desc = 'Toggle inlay hints' })

require('lspconfig').rust_analyzer.setup({
  settings = {
    ['rust-analyzer'] = {
      inlayHints = {
        enable = true,
      },
    },
  },
})

-- configuring single server, example: typescript
-- lspconfig.tsserver.setup {
--   on_attach = nvlsp.on_attach,
--   on_init = nvlsp.on_init,
--   capabilities = nvlsp.capabilities,
--
