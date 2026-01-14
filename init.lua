--[[
  Neovim 0.11 Native Configuration
  "The Fixed Init" + Old Theme/Tabs + Clean ASCII + Fixed Float Widths
  
  Changes:
  - Added Max Width constraints to LSP Hover & Signature windows
  - Added Max Width constraints to nvim-cmp documentation
]]

-- ========================================================================== --
-- ==                           PREAMBLE & OPTIONS                         == --
-- ========================================================================== --
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Tab / Indentation Config
vim.opt.tabstop = 4      
vim.opt.shiftwidth = 4   
vim.opt.expandtab = false 

-- UI Options
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = 'a'
vim.opt.termguicolors = true
vim.opt.clipboard = 'unnamedplus' 
vim.opt.breakindent = true
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.signcolumn = 'yes'
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.inccommand = 'split'
vim.opt.cursorline = true
vim.opt.scrolloff = 10

-- CLEAN UI: Disable special chars for whitespace
vim.opt.list = false 

-- ========================================================================== --
-- ==                        PLUGIN MANAGER (Lazy.nvim)                    == --
-- ========================================================================== --
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath
  })
end
vim.opt.rtp:prepend(lazypath)

-- ========================================================================== --
-- ==                           PLUGIN CONFIGURATION                       == --
-- ========================================================================== --
require("lazy").setup({
  -- UI Enhancements
  { "folke/which-key.nvim", event = "VeryLazy", opts = {} },
  
  -- Notification Status
  { "j-hui/fidget.nvim", opts = {} },

  -- THEME: Rose Pine
  { 
    'rose-pine/neovim', 
    name = 'rose-pine',
    priority = 1000, 
    config = function()
        require('rose-pine').setup({
            variant = "main", 
            dark_variant = "main", 
            dim_inactive_windows = false,
            extend_background_behind_borders = true,

            styles = {
                bold = true,
                italic = false, 
                transparency = false,
            },

            groups = {
                border = "muted",
                link = "iris",
                panel = "surface",
                headings = {
                    h1 = "iris", h2 = "foam", h3 = "rose",
                    h4 = "gold", h5 = "pine", h6 = "foam",
                },
            },
        })
        vim.cmd('colorscheme rose-pine')
    end
  },

  -- LUA DEVELOPMENT
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
    },
  },

  -- AUTOCOMPLETION (Fixed Widths)
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-buffer",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        -- FIX: Limit documentation window width
        window = {
            completion = cmp.config.window.bordered(),
            documentation = cmp.config.window.bordered({
                max_width = 80,
                max_height = 20,
            }),
        },
        completion = { completeopt = 'menu,menuone,noinsert' },
        mapping = cmp.mapping.preset.insert({
          ['<C-n>'] = cmp.mapping.select_next_item(),
          ['<C-p>'] = cmp.mapping.select_prev_item(),
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }),
          ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_locally_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { 'i', 's' }),
          ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.locally_jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { 'i', 's' }),
        }),
        sources = {
          { name = 'lazydev', group_index = 0 },
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
          { name = 'path' },
        },
      })
    end,
  },

  -- LSP CONFIGURATION (Fixed Widths)
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      require("mason").setup()

      -- FIX: Global override for floating window borders and size
      local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
      function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
        opts = opts or {}
        opts.border = opts.border or "rounded"
        opts.max_width = opts.max_width or 80 -- Global max width for all LSP floats
        return orig_util_open_floating_preview(contents, syntax, opts, ...)
      end
      
      local servers = {
        lua_ls = {
          settings = {
            Lua = {
              completion = { callSnippet = "Replace" },
              diagnostics = { globals = { 'vim' } }
            }
          }
        },
        ts_ls = {}, 
        rust_analyzer = {},
        clangd = {},
        pyright = {},
      }

      require("mason-lspconfig").setup({
        ensure_installed = vim.tbl_keys(servers),
      })

      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())

      for name, config in pairs(servers) do
        config.capabilities = capabilities
        vim.lsp.config(name, config)
        vim.lsp.enable(name)
      end

      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('UserLspConfig', { clear = true }),
        callback = function(args)
          local bufnr = args.buf
          local opts = { buffer = bufnr }

          vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
          vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
          vim.keymap.set('n', 'gI', vim.lsp.buf.implementation, opts)
          vim.keymap.set('n', '<leader>D', vim.lsp.buf.type_definition, opts)
          vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
          vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
          vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)

          vim.keymap.set('n', ']d', function() 
             vim.diagnostic.jump({ count = 1, float = true }) 
          end, opts)
          
          vim.keymap.set('n', '[d', function() 
             vim.diagnostic.jump({ count = -1, float = true }) 
          end, opts)
        end,
      })
    end,
  },

  -- TREESITTER
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "markdown", "markdown_inline" },
        auto_install = true,
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },
})

-- ========================================================================== --
-- ==                        DIAGNOSTIC CONFIGURATION                      == --
-- ========================================================================== --
vim.diagnostic.config({
  virtual_text = false,
  virtual_lines = { current_line = true },
  float = {
    border = 'rounded',
    source = 'always',
    max_width = 80, -- Constraint for diagnostic floats
  },
})
