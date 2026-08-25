-- ============================================================
-- Neovim config
--
-- Sections:
--   1. Options & diagnostics
--   2. Keymaps
--   3. Autocommands
--   4. Plugins (each: installation -> configuration)
-- ============================================================

-- ============================================================
-- 1. Options & diagnostics
-- ============================================================

-- Must be set before plugins are loaded
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.o.number = true
vim.o.mouse = 'a'
vim.o.showmode = false
vim.schedule(function() vim.o.clipboard = 'unnamedplus' end)
vim.o.breakindent = true
vim.o.undofile = true

-- Indent defaults; guess-indent.nvim overrides these per buffer
vim.o.tabstop = 1
vim.o.softtabstop = 1
vim.o.shiftwidth = 1
vim.o.expandtab = true
vim.o.colorcolumn = '120'

vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.hlsearch = false

vim.o.signcolumn = 'yes'
vim.o.updatetime = 50
vim.o.timeoutlen = 200
vim.o.scrolloff = 12
vim.o.cursorline = true
vim.o.confirm = true

vim.o.splitright = true
vim.o.splitbelow = true

vim.o.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

vim.o.inccommand = 'split'

vim.diagnostic.config {
  update_in_insert = false,
  severity_sort = true,
  float = { border = 'rounded', source = 'if_many' },
  underline = { severity = { min = vim.diagnostic.severity.WARN } },
  virtual_text = false,
}

-- ============================================================
-- 2. Keymaps
-- ============================================================

vim.keymap.set('n', '<leader>w', ':wa<CR>', { desc = 'Save all' })
vim.keymap.set('n', '<leader>q', ':q<CR>', { desc = 'Quit' })

-- Move selected line / block in visual mode
vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv")
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv")

-- Keep cursor centered
vim.keymap.set('n', 'J', 'mzJ`z')
vim.keymap.set('n', 'n', 'nzzzv')
vim.keymap.set('n', 'N', 'Nzzzv')

-- Respect wrapped lines when moving vertically
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true })

-- Better indenting
vim.keymap.set('v', '<', '<gv')
vim.keymap.set('v', '>', '>gv')

-- Paste over selection without clobbering register
vim.keymap.set('x', 'p', 'P')

-- Search & replace word under cursor
vim.keymap.set('n', '<leader>r', [[:%s/\<\(<C-r><C-w>\)\>//gI<Left><Left><Left>]], { desc = 'Replace word in file' })

-- Exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

vim.keymap.set('n', '<leader>b', function()
  local cwd = vim.fn.getcwd()
  local cmd
  if vim.fn.has 'win32' == 1 then
    cmd = { 'cmd.exe', '/c', 'build.bat' }
  elseif vim.uv.fs_stat(cwd .. '/build.sh') then
    cmd = { './build.sh' }
  else
    vim.notify('No build.sh found', vim.log.levels.WARN)
    return
  end

  local efm = '%f(%l): %t%*[^ ] %m,%f(%l,%c): %t%*[^ ] %m,%-G%.%#'
  vim.system(cmd, { cwd = cwd, text = true }, function(result)
    vim.schedule(function()
      local lines = vim.split((result.stdout or '') .. '\n' .. (result.stderr or ''), '\n')
      vim.fn.setqflist({}, 'r', { lines = lines, efm = efm })
      if #vim.fn.getqflist() > 0 then
        vim.cmd 'copen 4'
        vim.cmd 'cfirst'
      else
        vim.cmd 'cclose'
        print('Build succeeded')
      end
    end)
  end)
end, { desc = 'Build' })

-- ============================================================
-- 3. Autocommands
-- ============================================================

vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking',
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function() vim.hl.on_yank() end,
})

vim.api.nvim_create_autocmd('BufReadPost', {
  desc = 'Restore cursor position',
  group = vim.api.nvim_create_augroup('last-location', { clear = true }),
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then pcall(vim.api.nvim_win_set_cursor, 0, mark) end
  end,
})

-- ============================================================
-- 4. Plugins
-- ============================================================

---Most plugins are hosted on GitHub
---@param repo string
---@return string
local function gh(repo) return 'https://github.com/' .. repo end

vim.api.nvim_create_autocmd('PackChanged', {
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    if kind ~= 'install' and kind ~= 'update' then return end

    if name == 'fff.nvim' then
      if not ev.data.active then vim.cmd.packadd 'fff.nvim' end
      require('fff.download').download_or_build_binary()
      return
    end

    if name == 'nvim-treesitter' then
      if not ev.data.active then vim.cmd.packadd 'nvim-treesitter' end
      vim.cmd 'TSUpdate'
      return
    end
  end,
})

-- [[ Colorscheme ]]
-- gruvbox-neon is rendered by Noctalia (noctalia msg templates-apply) from the
-- active shell palette; fall back to gruvbox.nvim if it hasn't been rendered yet.
vim.pack.add { gh 'ellisonleao/gruvbox.nvim' }
if not pcall(vim.cmd.colorscheme, 'gruvbox-neon') then
  require('gruvbox').setup { contrast = 'soft' }
  vim.cmd.colorscheme 'gruvbox'
end

-- [[ Which-key ]]
vim.pack.add { gh 'folke/which-key.nvim' }
require('which-key').setup {
  delay = 0,
  icons = { mappings = true },
  spec = {
    { '<leader>c', group = '[C]ode' },
    { '<leader>s', group = '[S]earch' },
  },
}

-- [[ Undo tree ]]
vim.pack.add { gh 'mbbill/undotree' }
vim.keymap.set('n', '<leader>u', vim.cmd.UndotreeToggle, { desc = '[U]ndo tree' })

-- [[ Guess indent ]]
vim.pack.add { gh 'NMAC427/guess-indent.nvim' }
require('guess-indent').setup {}

-- [[ FFF: file finder + live grep ]]
vim.pack.add { gh 'dmtrKovalenko/fff.nvim' }
require('fff').setup {}

vim.keymap.set('n', '<leader>sf', function() require('fff').find_files() end, { desc = '[S]earch [F]iles' })
vim.keymap.set('n', '<leader>g', function() require('fff').live_grep() end, { desc = '[G]rep' })
vim.keymap.set({ 'n', 'v' }, '<leader>sw', function() require('fff').live_grep_under_cursor() end, { desc = '[S]earch [W]ord' })
vim.keymap.set('n', '<leader>sn', function() require('fff').find_files_in_dir(vim.fn.stdpath 'config') end, { desc = '[S]earch [N]eovim files' })

-- [[ TODO comments ]]
vim.pack.add { gh 'folke/todo-comments.nvim' }
require('todo-comments').setup { signs = false }

-- [[ Surround ]]
vim.pack.add { { src = gh 'kylechui/nvim-surround', version = vim.version.range '4.x' } }
require('nvim-surround').setup {}

vim.keymap.set('n', 's', '<Plug>(nvim-surround-normal)', { desc = 'Surround add' })
vim.keymap.set('n', 'ss', '<Plug>(nvim-surround-normal-cur)', { desc = 'Surround current line' })
vim.keymap.set('x', 's', '<Plug>(nvim-surround-visual)', { desc = 'Surround add (visual)' })

-- [[ Treesitter ]]
vim.pack.add { { src = gh 'nvim-treesitter/nvim-treesitter', version = 'main' } }

require('nvim-treesitter').install { 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc' }

local function treesitter_try_attach(buf, language)
  if not vim.treesitter.language.add(language) then return end
  vim.treesitter.start(buf, language)
  if vim.treesitter.query.get(language, 'indents') ~= nil then
    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end
end

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('treesitter-start', { clear = true }),
  callback = function(args)
    local buf, filetype = args.buf, args.match
    local language = vim.treesitter.language.get_lang(filetype)
    if not language then return end

    local installed = require('nvim-treesitter').get_installed 'parsers'
    if vim.tbl_contains(installed, language) then
      treesitter_try_attach(buf, language)
    elseif vim.tbl_contains(require('nvim-treesitter').get_available(), language) then
      require('nvim-treesitter').install(language):await(function() treesitter_try_attach(buf, language) end)
    else
      treesitter_try_attach(buf, language)
    end
  end,
})

-- [[ LSP ]] servers auto-install via Mason (portable across linux/windows)
vim.pack.add {
  gh 'neovim/nvim-lspconfig',
  gh 'mason-org/mason.nvim',
  gh 'mason-org/mason-lspconfig.nvim',
  gh 'WhoIsSethDaniel/mason-tool-installer.nvim',
}

require('mason').setup {}
require('mason-lspconfig').setup {}

---@type table<string, vim.lsp.Config>
local servers = {
  lua_ls = {
    on_init = function(client)
      client.server_capabilities.documentFormattingProvider = false

      if client.workspace_folders then
        local path = client.workspace_folders[1].name
        if path ~= vim.fn.stdpath 'config' and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc')) then return end
      end

      client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
        runtime = { version = 'LuaJIT', path = { 'lua/?.lua', 'lua/?/init.lua' } },
        workspace = {
          checkThirdParty = false,
          library = vim.tbl_extend('force', vim.api.nvim_get_runtime_file('', true), { '${3rd}/luv/library' }),
        },
      })
    end,
    settings = {
      Lua = { format = { enable = false } },
    },
  },
  clangd = {},
  ols = {},
  rust_analyzer = {},
}

for name, server in pairs(servers) do
  vim.lsp.config(name, server)
  vim.lsp.enable(name)
end

require('mason-tool-installer').setup {
  ensure_installed = vim.tbl_keys(servers),
}

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
  callback = function(event)
    local map = function(keys, func, desc) vim.keymap.set('n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc }) end

    map('K', vim.lsp.buf.hover, 'Hover Documentation')
    map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')
    map('<leader>cr', vim.lsp.buf.rename, '[C]ode [R]ename')
    map('<leader>e', vim.diagnostic.open_float, 'Show diagnostic')
    map('ö', function() vim.diagnostic.jump { count = 1 } end, 'Next diagnostic')
    map('ä', function() vim.diagnostic.jump { count = -1 } end, 'Previous diagnostic')

    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client and client:supports_method('textDocument/inlayHint', event.buf) then
      map('<leader>th', function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }) end, '[T]oggle Inlay [H]ints')
    end
  end,
})

-- [[ Completion blink.cmp]]
vim.pack.add { { src = gh 'saghen/blink.cmp', version = vim.version.range '1.*' } }
require('blink.cmp').setup {
  keymap = {
    preset = 'default',
    ['<C-e>'] = { 'hide', 'fallback' },
    ['<C-c>'] = { 'hide', 'fallback' },
  },
  appearance = { nerd_font_variant = 'mono' },
  completion = {
    trigger = { show_on_keyword = false, show_on_trigger_character = false, show_on_insert_on_trigger_character = false },
    list = { selection = { preselect = false, auto_insert = false } },
  },
  fuzzy = {
    implementation = 'prefer_rust', -- required for proximity boosting
    use_proximity = true,           -- boost candidates matching words near the cursor
  },
  signature = { enabled = false },
}
