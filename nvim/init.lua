-- ===========================================
-- 基本設定
-- ===========================================
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- mac標準のEmacs風キーバインドを使用（インサート・コマンドラインモード）
local emacs_modes = {'i', 'c'}  -- i: インサート, c: コマンドライン
for _, mode in ipairs(emacs_modes) do
  vim.keymap.set(mode, '<C-b>', '<Left>')   -- 左に移動
  vim.keymap.set(mode, '<C-f>', '<Right>')  -- 右に移動
  vim.keymap.set(mode, '<C-a>', '<Home>')   -- 行頭へ
  vim.keymap.set(mode, '<C-e>', '<End>')    -- 行末へ
  vim.keymap.set(mode, '<C-n>', '<Down>')   -- 下に移動
  vim.keymap.set(mode, '<C-p>', '<Up>')     -- 上に移動
  vim.keymap.set(mode, '<C-d>', '<Del>')    -- 前方削除
end
-- インサートモード専用: カーソルから行末まで削除
vim.keymap.set('i', '<C-k>', '<Esc>ld$a')

-- ノーマルモード: Emacs風カーソル移動（1文字単位）
vim.keymap.set('n', '<C-f>', 'l', { noremap = true, desc = '1文字前に進む' })
vim.keymap.set('n', '<C-b>', 'h', { noremap = true, desc = '1文字後ろに戻る' })

vim.opt.number = true
-- vim.opt.relativenumber = true  -- 相対行番号（無効化）
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 250
vim.opt.clipboard = "unnamedplus"
vim.opt.undofile = true
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.autoread = true

-- 外部でファイルが変更された場合に自動リロード
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
  command = "checktime",
})

-- ===========================================
-- lazy.nvim ブートストラップ
-- ===========================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- ===========================================
-- プラグイン設定
-- ===========================================
require("lazy").setup({
  -- カラースキーム
  {
    "sainnhe/sonokai",
    lazy = false,
    priority = 1000,
    config = function()
      vim.g.sonokai_transparent_background = "1"
      vim.cmd.colorscheme("sonokai")
    end,
  },

  -- ファイルエクスプローラー
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    keys = {
      { "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Toggle Neo-tree" },
    },
    config = function()
      -- Neo-treeの背景を透過
      vim.api.nvim_set_hl(0, "NeoTreeNormal", { bg = "NONE", ctermbg = "NONE" })
      vim.api.nvim_set_hl(0, "NeoTreeNormalNC", { bg = "NONE", ctermbg = "NONE" })
      vim.api.nvim_set_hl(0, "NeoTreeEndOfBuffer", { bg = "NONE", ctermbg = "NONE" })
      require("neo-tree").setup({})
    end,
  },

  -- ファジーファインダー
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
      },
    },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live grep" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help tags" },
    },
    config = function()
      local telescope = require("telescope")
      telescope.setup({
        defaults = {
          file_ignore_patterns = { "node_modules", ".git" },
        },
        extensions = {
          fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case",
          },
        },
      })
      telescope.load_extension("fzf")
    end,
  },

  -- Treesitter (シンタックスハイライト)
  -- パーサーは初回のみ手動でインストール: :TSInstall typescript tsx javascript html css json lua markdown markdown_inline yaml graphql prisma
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    main = "nvim-treesitter",
    opts = {
      highlight = { enable = true },
      indent = { enable = true },
    },
  },

  -- 自動タグ閉じ
  { "windwp/nvim-ts-autotag" },

  -- 自動括弧閉じ
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = true,
  },

  -- Mason (LSPサーバー管理)
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "ts_ls",
          "eslint",
          "tailwindcss",
          "html",
          "cssls",
          "jsonls",
          "lua_ls",
        },
      })
    end,
  },

  -- LSP (nvim-cmp連携用)
  { "hrsh7th/cmp-nvim-lsp" },

  -- 自動補完
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
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
        mapping = cmp.mapping.preset.insert({
          -- Ctrl+B/F/N/P/A/Eはカーソル移動に使うためfallback
          ["<C-b>"] = cmp.mapping(function(fallback) fallback() end, { "i", "s" }),
          ["<C-f>"] = cmp.mapping(function(fallback) fallback() end, { "i", "s" }),
          ["<C-n>"] = cmp.mapping(function(fallback) fallback() end, { "i", "s" }),
          ["<C-p>"] = cmp.mapping(function(fallback) fallback() end, { "i", "s" }),
          ["<C-a>"] = cmp.mapping(function(fallback) fallback() end, { "i", "s" }),
          ["<C-e>"] = cmp.mapping(function(fallback) fallback() end, { "i", "s" }),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
        }),
      })
    end,
  },

  -- フォーマッター
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
      { "<leader>f", function() require("conform").format({ async = true }) end, desc = "Format buffer" },
    },
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          javascript = { "prettierd", "prettier", stop_after_first = true },
          typescript = { "prettierd", "prettier", stop_after_first = true },
          javascriptreact = { "prettierd", "prettier", stop_after_first = true },
          typescriptreact = { "prettierd", "prettier", stop_after_first = true },
          json = { "prettierd", "prettier", stop_after_first = true },
          html = { "prettierd", "prettier", stop_after_first = true },
          css = { "prettierd", "prettier", stop_after_first = true },
          markdown = { "prettierd", "prettier", stop_after_first = true },
        },
        format_on_save = {
          timeout_ms = 500,
          lsp_fallback = true,
        },
      })
    end,
  },

  -- Git統合
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup({
        signs = {
          add = { text = "│" },
          change = { text = "│" },
          delete = { text = "_" },
          topdelete = { text = "‾" },
          changedelete = { text = "~" },
        },
      })
    end,
  },

  -- ステータスライン
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({
        options = { theme = "sonokai" },
      })
    end,
  },

  -- インデントガイド
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    config = function()
      require("ibl").setup()
    end,
  },

  -- コメントトグル
  {
    "numToStr/Comment.nvim",
    config = true,
  },

  -- サラウンド (括弧・クォート操作)
  {
    "kylechui/nvim-surround",
    event = "VeryLazy",
    config = true,
  },
})

-- ===========================================
-- LSP設定 (Neovim 0.11+ vim.lsp.config)
-- ===========================================
local capabilities = require("cmp_nvim_lsp").default_capabilities()

-- TypeScript
vim.lsp.config.ts_ls = { capabilities = capabilities }
vim.lsp.enable("ts_ls")

-- ESLint
vim.lsp.config.eslint = { capabilities = capabilities }
vim.lsp.enable("eslint")

-- Tailwind CSS
vim.lsp.config.tailwindcss = { capabilities = capabilities }
vim.lsp.enable("tailwindcss")

-- HTML
vim.lsp.config.html = { capabilities = capabilities }
vim.lsp.enable("html")

-- CSS
vim.lsp.config.cssls = { capabilities = capabilities }
vim.lsp.enable("cssls")

-- JSON
vim.lsp.config.jsonls = { capabilities = capabilities }
vim.lsp.enable("jsonls")

-- Lua
vim.lsp.config.lua_ls = {
  capabilities = capabilities,
  settings = {
    Lua = {
      diagnostics = { globals = { "vim" } },
    },
  },
}
vim.lsp.enable("lua_ls")

-- LSP キーマップ
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local opts = { buffer = args.buf }
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
    vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts)
  end,
})

