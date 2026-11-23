-- extends $VIMPLUG/nvim-lspconfig/lsp/ts_ls.lua
return {
  init_options = {
    tsserver = {
      -- The TypeScript bundled with the server (mason). By default it prefers the project's
      -- node_modules/typescript, i.e. it would run code from any repo whose files are opened.
      path = vim.fn.stdpath('data') .. '/mason/packages/typescript-language-server/node_modules/typescript/lib',
    },
  },
}
