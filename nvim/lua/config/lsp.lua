-------------
-- LSP config
-------------
-- See ~/.dotfiles/vim/plugins.vim for Plug directives

local lspconfig = require('lspconfig')

-- lsp_signature
-- https://github.com/ray-x/lsp_signature.nvim#full-configuration
local on_attach_lsp_signature = function(client, bufnr)
  require "lsp_signature".on_attach({
      bind = true, -- This is mandatory, otherwise border config won't get registered.
      floating_window = true,
      handler_opts = {
        border = "single"
      },
      zindex = 99,     -- <100 so that it does not hide completion popup.
      fix_pos = false, -- Let signature window change its position when needed, see GH-53
    })
end

-- Customize LSP behavior
-- [[ A callback executed when LSP engine attaches to a buffer. ]]
local on_attach = function(client, bufnr)
  -- Always use signcolumn for the current buffer
  vim.wo.signcolumn = 'yes:1'

  -- Activate LSP signature.
  on_attach_lsp_signature(client, buffer)

  -- Keybindings
  -- https://github.com/neovim/nvim-lspconfig#keybindings-and-completion
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
  local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end
  local opts = { noremap=true, silent=true }
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  buf_set_keymap('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  if vim.fn.exists(':Telescope') then
    buf_set_keymap('n', 'gr', '<cmd>Telescope lsp_references<CR>', opts)
    buf_set_keymap('n', 'gd', '<cmd>Telescope lsp_definitions<CR>', opts)
    buf_set_keymap('n', 'gi', '<cmd>Telescope lsp_implementations<CR>', opts)
  else
    buf_set_keymap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
    buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
    buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  end
  buf_set_keymap('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
  --buf_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  buf_set_keymap('n', '[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
  buf_set_keymap('n', ']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)
  --buf_set_keymap('n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
  --buf_set_keymap('n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
  --buf_set_keymap('n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
  --buf_set_keymap('n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
  --buf_set_keymap('n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
  --buf_set_keymap('n', '<space>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
  --buf_set_keymap('n', '<space>e', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', opts)
  --buf_set_keymap('n', '<space>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)
  --buf_set_keymap("n", "<space>f", "<cmd>lua vim.lsp.buf.formatting()<CR>", opts)
end

-- Add global keymappings for LSP actions
-- F3, F12: goto definition
vim.cmd [[
  map  <F12>  gd
  imap <F12>  <ESC>gd
  map  <F3>   <F12>
  imap <F3>   <F12>
]]
-- Shift+F12: show usages/references
vim.cmd [[
  map  <F24>  gr
  imap <F24>  <ESC>gr
]]


-- Register and activate LSP servers (managed by nvim-lsp-installer)
-- @see(config):     https://github.com/neovim/nvim-lspconfig/blob/master/CONFIG.md
local builtin_lsp_servers = {
  -- List name of LSP servers that will be automatically installed and managed by :LspInstall.
  -- LSP servers will be installed locally at: ~/.local/share/nvim/lsp_servers
  -- @see(lspinstall): https://github.com/williamboman/nvim-lsp-installer
  'pyright',
  'vimls',
  'tsserver',
}

local lsp_installer = require("nvim-lsp-installer")
lsp_installer.on_server_ready(function(server)
  local opts = {
    on_attach = on_attach,

    -- Suggested configuration by nvim-cmp
    capabilities = require('cmp_nvim_lsp').update_capabilities(
     vim.lsp.protocol.make_client_capabilities()
    ),
  }

  -- (optional) Customize the options passed to the server
  -- if server.name == "tsserver" then
  --     opts.root_dir = function() ... end
  -- end

  -- This setup() function is exactly the same as lspconfig's setup function (:help lspconfig-quickstart)
  server:setup(opts)
  vim.cmd [[ do User LspAttachBuffers ]]
end)

-- Automatically install if a required LSP server is missing.
for _, lsp_name in ipairs(builtin_lsp_servers) do
  local ok, lsp = require('nvim-lsp-installer.servers').get_server(lsp_name)
  if ok and not lsp:is_installed() then
    vim.defer_fn(function()
      -- lsp:install()   -- headless
      lsp_installer.install(lsp_name)   -- with UI (so that users can be notified)
    end, 0)
  end
end


------------------
-- LSP diagnostics
------------------
-- https://github.com/neovim/nvim-lspconfig/wiki/UI-customization

-- Customize how to show diagnostics: Do not use distracting virtual text
-- :help lsp-handler-configuration
vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
    vim.lsp.diagnostic.on_publish_diagnostics, {
      virtual_text = false,     -- disable virtual text
      signs = true,             -- show signs
      update_in_insert = false, -- delay update diagnostics
      -- display_diagnostic_autocmds = { "InsertLeave" },
    }
  )

-- Instead, show line diagnostics in a pop-up window on hover
vim.cmd [[
augroup LSPDiagnosticsOnHover
  autocmd!
  autocmd CursorHold * lua vim.lsp.diagnostic.show_line_diagnostics({focusable = false})
augroup END
]]

-- Redefine signs (:help diagnostic-signs)
vim.fn.sign_define("DiagnosticSignError",  {text = "✘", texthl = "DiagnosticSignError"})
vim.fn.sign_define("DiagnosticSignWarn",   {text = "", texthl = "DiagnosticSignWarn"})
vim.fn.sign_define("DiagnosticSignInfo",   {text = "i", texthl = "DiagnosticSignInfo"})
vim.fn.sign_define("DiagnosticSignHint",   {text = "", texthl = "DiagnosticSignHint"})
vim.cmd [[
hi DiagnosticSignError    guifg=#e6645f ctermfg=167
hi DiagnosticSignWarn     guifg=#b1b14d ctermfg=143
hi DiagnosticSignHint     guifg=#3e6e9e ctermfg=75
]]


---------------------------------
-- nvim-cmp: completion support
---------------------------------
-- https://github.com/hrsh7th/nvim-cmp#recommended-configuration
-- ~/.vim/plugged/nvim-cmp/lua/cmp/config/default.lua

vim.o.completeopt = "menu,menuone,noselect"

local has_words_before = function()
  if vim.api.nvim_buf_get_option(0, 'buftype') == 'prompt' then
    return false
  end
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return col ~= 0 and vim.api.nvim_buf_get_lines(0, line-1, line, true)[1]:sub(col, col):match('%s') == nil
end

local cmp = require('cmp')
cmp.setup {
  snippet = {
    expand = function(args)
      vim.fn["UltiSnips#Anon"](args.body)
    end,
  },
  documentation = {
    border = {'╭', '─', '╮', '│', '╯', '─', '╰', '│'}  -- in a clockwise order
  },
  mapping = {
    ['<C-d>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.close(),
    ['<CR>'] = cmp.mapping.confirm({ select = false }),
    ['<Tab>'] = function(fallback)  -- see GH-231, GH-286
      if cmp.visible() then cmp.select_next_item()
      elseif has_words_before() then cmp.complete()
      else fallback() end
    end,
    ['<S-Tab>'] = function(fallback)
      if cmp.visible() then cmp.select_prev_item()
      else fallback() end
    end,
  },
  formatting = {
    format = function(entry, vim_item)
      -- fancy icons and a name of kind
      vim_item.kind = " " .. require("lspkind").presets.default[vim_item.kind] .. " " .. vim_item.kind
      -- set a name for each source (see the sources section below)
      vim_item.menu = ({
        buffer        = "[Buffer]",
        nvim_lsp      = "[LSP]",
        luasnip       = "[LuaSnip]",
        ultisnips     = "[UltiSnips]",
        nvim_lua      = "[Lua]",
        latex_symbols = "[Latex]",
      })[entry.source.name]
      return vim_item
    end,
  },
  sources = {
    -- Note: make sure you have proper plugins specified in plugins.vim
    -- https://github.com/topics/nvim-cmp
    { name = 'nvim_lsp', priority = 100 },
    { name = 'ultisnips', keyword_length = 2, priority = 50 },  -- workaround '.' trigger
    { name = 'path', priority = 30, },
    { name = 'buffer', priority = 10 },
  },
}

-- Highlights for nvim-cmp's custom popup menu (GH-224)
vim.cmd [[
  " To be compatible with Pmenu (#fff3bf)
  hi CmpItemAbbr           guifg=#111111
  hi CmpItemAbbrMatch      guifg=#f03e3e gui=bold
  hi CmpItemAbbrMatchFuzzy guifg=#fd7e14 gui=bold
  hi CmpItemAbbrDeprecated guifg=#adb5bd
  hi CmpItemKind           guifg=#cc5de8
  hi CmpItemMenu           guifg=#cfa050
]]


------------
-- LSPstatus
------------
local lsp_status = require('lsp-status')
lsp_status.config({
    -- Avoid using use emoji-like or full-width characters
    -- because it can often break rendering within tmux and some terminals
    -- See ~/.vim/plugged/lsp-status.nvim/lua/lsp-status.lua
    indicator_hint = '!',
    status_symbol = ' ',
})
lsp_status.register_progress()

-- LspStatus(): status string for airline
_G.LspStatus = function()
  if #vim.lsp.buf_get_clients() > 0 then
    return lsp_status.status()
  end
  return ''
end

-- :LspStatus (command): display lsp status
vim.cmd [[
command! -nargs=0 LspStatus   echom v:lua.LspStatus()
]]


---------------
-- trouble.nvim
---------------
require("trouble").setup {
    -- https://github.com/folke/trouble.nvim#setup
    mode = "lsp_document_diagnostics",
    auto_preview = false,
}


---------------
-- Telescope
---------------
-- @see  https://github.com/nvim-telescope/telescope.nvim#telescope-setup-structure
local telescope = require("telescope")
telescope.setup {
  defaults = {
    mappings = {
      i = {
        ["<C-u>"] = false,   -- Do not map <C-u>; CTRL-U should be backward-kill-line.
        ["<C-d>"] = false,
        ["<C-y>"] = require("telescope.actions").preview_scrolling_up,
        ["<C-e>"] = require("telescope.actions").preview_scrolling_down,
      }
    }
  }
}

-- Custom Telescope mappings
vim.cmd [[
command! -nargs=0 Highlights    :Telescope highlights
]]

-- Telescope extensions
if vim.fn['HasPlug']('telescope-frecency.nvim') == 1 then
  telescope.load_extension("frecency")
  vim.cmd [[
    command! -nargs=0 Frecency      :Telescope frecency
  ]]
end
