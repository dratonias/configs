-- block-hints.lua
--
-- Always-on virtual text at closing braces. Shows the header of the block
-- (if/for/while/switch/function, else/catch/finally) at the line of its
-- closing brace, so you never have to scroll up to see what a `}` belongs to:
--
--   if (a && b) {
--       ...
--   } if (a && b)      <- virtual text
--
-- Treesitter-based: the header text is taken from the *statement start* to the
-- block start, so brace style (same line / Allman) and multi-line conditions
-- don't matter. Only brace blocks are annotated; languages that close with
-- `end` / `fi` are naturally skipped.

local M = {}

M.namespace = vim.api.nvim_create_namespace('block-hints')

local enabled = true

local defaults = {
  max_lines = 5000,  -- skip refresh on larger buffers
  max_len = 50,      -- truncate header to this many chars
  highlight = 'Comment',
  exclude_filetypes = {
    'help', 'man', 'checkhealth', 'gitcommit', 'TelescopePrompt', 'TelescopeResults',
    'TelescopePreviewer', 'lazy', 'nvimtree', 'neo-tree', '', '',
  },
}

M.opts = defaults

-- Statement / function node types whose header should be annotated at the
-- closing brace, keyed by treesitter language.
local HEADER_TYPES = {
  c = { 'if_statement', 'for_statement', 'while_statement', 'do_statement', 'switch_statement', 'try_statement', 'function_definition' },
  cpp = { 'if_statement', 'for_statement', 'while_statement', 'do_statement', 'switch_statement', 'try_statement', 'function_definition' },
  rust = { 'if_expression', 'for_expression', 'while_expression', 'loop_expression', 'match_expression', 'function_item', 'impl_item', 'mod_item', 'trait_item' },
  go = { 'if_statement', 'for_statement', 'switch_statement', 'type_switch_statement', 'select_statement', 'function_declaration', 'method_declaration', 'type_declaration' },
  java = { 'if_statement', 'for_statement', 'enhanced_for_statement', 'while_statement', 'do_statement', 'switch_statement', 'try_statement', 'method_declaration', 'constructor_declaration', 'class_declaration' },
  javascript = { 'if_statement', 'for_statement', 'for_in_statement', 'while_statement', 'do_statement', 'switch_statement', 'try_statement', 'function_declaration', 'method_definition', 'arrow_function', 'class_declaration' },
  typescript = { 'if_statement', 'for_statement', 'for_in_statement', 'while_statement', 'do_statement', 'switch_statement', 'try_statement', 'function_declaration', 'method_definition', 'arrow_function', 'class_declaration' },
  tsx = { 'if_statement', 'for_statement', 'for_in_statement', 'while_statement', 'do_statement', 'switch_statement', 'try_statement', 'function_declaration', 'method_definition', 'arrow_function', 'class_declaration' },
  jsx = { 'if_statement', 'for_statement', 'for_in_statement', 'while_statement', 'do_statement', 'switch_statement', 'try_statement', 'function_declaration', 'method_definition', 'arrow_function', 'class_declaration' },
  c_sharp = { 'if_statement', 'for_statement', 'for_each_statement', 'while_statement', 'do_statement', 'switch_statement', 'try_statement', 'method_declaration', 'constructor_declaration', 'class_declaration', 'namespace_declaration' },
  zig = { 'if_expression', 'for_expression', 'while_expression', 'switch_expression' },
  kotlin = { 'if_expression', 'when_expression', 'for_statement', 'while_statement', 'do_statement', 'try_statement', 'function_declaration', 'class_declaration' },
  swift = { 'if_statement', 'for_statement', 'guard_statement', 'while_statement', 'switch_statement', 'repeat_statement', 'func_declaration', 'class_declaration' },
  php = { 'if_statement', 'for_statement', 'foreach_statement', 'while_statement', 'do_statement', 'switch_statement', 'try_statement', 'function_definition' },
  dart = { 'if_statement', 'for_statement', 'for_in_statement', 'while_statement', 'do_statement', 'switch_statement', 'try_statement', 'function_declaration', 'class_declaration' },
}

-- Wrapper nodes whose block gets a header taken from the wrapper start
-- (yields `else`, `catch (...)`, `finally`).
local WRAPPERS = { else_clause = true, catch_clause = true, finally_clause = true }

local function is_block(t)
  return t == 'compound_statement' or t:match('block$') ~= nil
end

-- Extract the single-line header between (start_row,start_col) and
-- (end_row,end_col), collapsing whitespace. Returns nil when empty.
local function header_for(bufnr, start_row, start_col, end_row, end_col)
  local lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row + 1, false)
  if #lines == 0 then return nil end

  if #lines == 1 then
    lines[1] = string.sub(string.sub(lines[1], start_col + 1), 1, end_col - start_col)
  else
    lines[1] = string.sub(lines[1], start_col + 1)
    lines[#lines] = string.sub(lines[#lines], 1, end_col)
  end

  local text = table.concat(lines, ' ')
  text = text:gsub('%s+', ' ') -- collapse runs of whitespace/newlines
  text = text:gsub('%s*{%s*$', '') -- drop a trailing { (block start)
  text = text:gsub('^%s+', '')
  text = text:gsub('%s+$', '')
  return text == '' and nil or text
end

local function truncate(s, n)
  if #s <= n then return s end
  return string.sub(s, 1, n - 1) .. '…'
end

local function put(bufnr, row, text)
  vim.api.nvim_buf_set_extmark(bufnr, M.namespace, row, 0, {
    virt_text_pos = 'eol',
    virt_text = { { text, 'BlockHints' } },
    hl_mode = 'combine',
  })
end

local function visit(bufnr, types, node, out, budget)
  if budget.n <= 0 then return end
  budget.n = budget.n - 1

  local t = node:type()
  if not node:has_error() then
    if is_block(t) then
      local parent = node:parent()
      if parent then
        local pt = parent:type()
        local sr, sc = parent:start()
        local er, ec = node:start()
        local hdr
        if types[pt] then
          -- JS/TS arrow bodies: widen to the declarator so header reads
          -- `h = () =>` instead of just `() =>`.
          if pt == 'arrow_function' then
            local grand = parent:parent()
            if grand and grand:type() == 'variable_declarator' then
              sr, sc = grand:start()
            end
          end
          hdr = header_for(bufnr, sr, sc, er, ec)
        elseif WRAPPERS[pt] then
          hdr = header_for(bufnr, sr, sc, er, ec)
        end
        local erow = node:end_()
        if hdr then out[#out + 1] = { row = erow, text = truncate(hdr, M.opts.max_len) } end
      end
    end
  end

  for child in node:iter_children() do
    visit(bufnr, types, child, out, budget)
  end
end

local function refresh(bufnr)
  if not enabled or not vim.api.nvim_buf_is_valid(bufnr) then return end
  if vim.bo[bufnr].buftype ~= '' then return end
  if vim.tbl_contains(M.opts.exclude_filetypes, vim.bo[bufnr].filetype) then return end

  local lang = vim.treesitter.language.get_lang(vim.bo[bufnr].filetype)
  local types = lang and HEADER_TYPES[lang]
  if not types then return end
  if vim.api.nvim_buf_line_count(bufnr) > M.opts.max_lines then return end

  local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
  if not ok or not parser then return end

  vim.api.nvim_buf_clear_namespace(bufnr, M.namespace, 0, -1)
  local roots = parser:parse()
  if not roots[1] then return end

  local typeset = {}
  for _, t in ipairs(types) do
    typeset[t] = true
  end

  local out = {}
  visit(bufnr, typeset, roots[1]:root(), out, { n = 20000 })
  for _, e in ipairs(out) do
    put(bufnr, e.row, e.text)
  end
end

-- Debounce: only the latest scheduled refresh for a buffer runs.
local pending = 0
local function schedule_refresh(bufnr)
  pending = pending + 1
  local id = pending
  vim.defer_fn(function()
    if id ~= pending then return end
    refresh(bufnr)
  end, 80)
end

function M.attach(bufnr)
  refresh(bufnr)
end

function M.toggle()
  enabled = not enabled
  if not enabled then
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) then
        vim.api.nvim_buf_clear_namespace(buf, M.namespace, 0, -1)
      end
    end
  else
    refresh(vim.api.nvim_get_current_buf())
  end
  vim.notify(enabled and 'Block hints: on' or 'Block hints: off', vim.log.levels.INFO)
end

function M.setup(opts)
  M.opts = vim.tbl_deep_extend('force', defaults, opts or {})
  vim.api.nvim_set_hl(0, 'BlockHints', { link = M.opts.highlight })
  vim.keymap.set('n', '<leader>tb', M.toggle, { desc = '[T]oggle [B]lock hints' })

  vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
    group = vim.api.nvim_create_augroup('block-hints', { clear = true }),
    desc = 'Refresh block hints after edits',
    callback = function(ev)
      if vim.bo[ev.buf].buftype == '' then schedule_refresh(ev.buf) end
    end,
  })
end

return M