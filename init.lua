-- Minimal Neovim config (0.12+).
--
--   Files and grep  fff: Rust index, honours .gitignore, frecency ranking
--   Highlighting    tree-sitter parsers from nvim-treesitter, started per buffer
--   Definitions     built-in LSP client; servers are enabled only when installed
--   Completion      built-in 'autocomplete' fed by the LSP
--
-- External tools are listed in README.md.

if vim.fn.has('nvim-0.12') == 0 then
  vim.notify('This config needs Neovim 0.12 or newer', vim.log.levels.ERROR)
  return
end

vim.loader.enable()

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Options ---------------------------------------------------------------------

local o = vim.o
o.number = true
o.signcolumn = 'yes'
o.cursorline = true
o.ignorecase = true
o.smartcase = true
o.undofile = true
o.splitright = true
o.splitbelow = true
o.scrolloff = 4
o.updatetime = 250
o.expandtab = true -- .editorconfig files override indentation per project
o.shiftwidth = 4
o.tabstop = 4
o.list = true
o.listchars = 'tab:» ,trail:·,nbsp:␣'
o.inccommand = 'split'
o.wildoptions = 'pum,tagfile,fuzzy'
o.completeopt = 'menuone,noselect,popup,fuzzy'
o.pumheight = 15
o.winborder = 'rounded'
o.exrc = true -- project .nvim.lua files run only after `:trust`

vim.diagnostic.config({ virtual_text = true, severity_sort = true })

-- Filetypes -------------------------------------------------------------------

vim.filetype.add({
  extension = {
    m = 'objc', -- not MATLAB
    mm = 'objcpp',
    metal = 'metal',
    hlsl = 'hlsl',
    hlsli = 'hlsl',
    fx = 'hlsl',
    fxh = 'hlsl',
    slangh = 'shaderslang',
    mesh = 'glsl',
    task = 'glsl',
  },
})

-- No runtime ftplugin exists for these, so give them C-style comments and indent.
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'hlsl', 'metal', 'wgsl' },
  callback = function(ev)
    vim.bo[ev.buf].commentstring = '// %s'
    vim.bo[ev.buf].cindent = true
  end,
})

-- Plugins ---------------------------------------------------------------------

-- Build hooks have to be registered before vim.pack.add() so they also run on install.
vim.api.nvim_create_autocmd('PackChanged', {
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    if kind ~= 'install' and kind ~= 'update' then
      return
    end
    if not ev.data.active then
      vim.cmd.packadd(name)
    end
    if name == 'fff' then
      require('fff.download').download_or_build_binary()
    elseif name == 'nvim-treesitter' and kind == 'update' then
      vim.cmd('TSUpdate')
    end
  end,
})

vim.pack.add({
  'https://github.com/folke/tokyonight.nvim',
  'https://github.com/neovim/nvim-lspconfig',
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter', version = 'main' },
  'https://github.com/dmtrKovalenko/fff',
}, { confirm = false })

pcall(vim.cmd.colorscheme, 'tokyonight-night')

-- Tree-sitter -----------------------------------------------------------------

local parsers = {
  'c', 'cpp', 'cuda', 'objc', 'python', 'rust',
  'slang', 'hlsl', 'glsl', 'wgsl',
  'cmake', 'bash', 'json', 'yaml', 'toml',
  'lua', 'vim', 'vimdoc', 'query', 'markdown', 'markdown_inline',
}

-- Metal is C++ with attributes; ObjC++ files are mostly message sends.
vim.treesitter.language.register('cpp', 'metal')
vim.treesitter.language.register('objc', 'objcpp')

local installed = require('nvim-treesitter').get_installed()
local missing = vim.tbl_filter(function(p)
  return not vim.list_contains(installed, p)
end, parsers)
if #missing > 0 and vim.fn.executable('tree-sitter') == 1 then
  require('nvim-treesitter').install(missing)
end

vim.api.nvim_create_autocmd('FileType', {
  callback = function(ev)
    local lang = vim.treesitter.language.get_lang(ev.match)
    if not lang or not vim.treesitter.language.add(lang) then
      return
    end
    local stat = vim.uv.fs_stat(vim.api.nvim_buf_get_name(ev.buf))
    if stat and stat.size > 2 * 1024 * 1024 then
      return -- generated or amalgamated sources; regex syntax is cheaper there
    end
    vim.treesitter.start(ev.buf, lang)
  end,
})

-- LSP -------------------------------------------------------------------------

-- rustup may be installed without touching the shell PATH; cargo and rust-analyzer
-- still have to be reachable. Appended, so nothing already on PATH is shadowed.
local cargo_bin = vim.fs.joinpath(vim.env.CARGO_HOME or vim.fs.joinpath(vim.uv.os_homedir(), '.cargo'), 'bin')
if vim.fn.executable('cargo') == 0 and vim.uv.fs_stat(cargo_bin) then
  vim.env.PATH = vim.env.PATH .. (vim.fn.has('win32') == 1 and ';' or ':') .. cargo_bin
end

-- clangd looks for compile_commands.json only in parent directories and their build/
-- subdirectories. Projects with several build trees (build_linux_armv8/, build/Release/,
-- out/build/x64-Debug/, ...) get the most recently written one.
local function compile_commands_dir(root)
  for _, f in ipairs({ 'compile_commands.json', 'build/compile_commands.json' }) do
    if vim.uv.fs_stat(vim.fs.joinpath(root, f)) then
      return nil -- clangd finds these itself
    end
  end
  local best, newest = nil, -1
  for _, pattern in ipairs({
    'build*/compile_commands.json',
    'build*/*/compile_commands.json',
    'cmake-build-*/compile_commands.json',
    'out/build/*/compile_commands.json',
  }) do
    for _, f in ipairs(vim.fn.glob(vim.fs.joinpath(root, pattern), true, true)) do
      local stat = vim.uv.fs_stat(f)
      if stat and stat.mtime.sec > newest then
        best, newest = vim.fs.dirname(f), stat.mtime.sec
      end
    end
  end
  return best
end

local clangd_markers = { '.clangd', '.clang-tidy', '.clang-format', 'compile_commands.json', 'compile_flags.txt', '.git' }

vim.lsp.config('clangd', {
  -- --log=error: Neovim logs server stderr as errors, and indexing progress floods lsp.log.
  cmd = { 'clangd', '--background-index', '--header-insertion=never', '--log=error' },
  filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda' }, -- upstream adds pseudo-filetypes (c.doxygen)
  -- Files inside a running project (its git submodules included) and headers outside any
  -- project (system or package-cache headers reached by go-to-definition) join the clangd
  -- that is already running, so they keep its compile flags and index.
  root_dir = function(bufnr, on_dir)
    local fname = vim.api.nvim_buf_get_name(bufnr)
    local running = vim.lsp.get_clients({ name = 'clangd' })
    for _, client in ipairs(running) do
      if client.root_dir and vim.fs.relpath(client.root_dir, fname) then
        return on_dir(client.root_dir)
      end
    end
    local root = vim.fs.root(bufnr, clangd_markers)
    if not root and #running > 0 then
      root = running[#running].root_dir
    end
    on_dir(root)
  end,
  before_init = function(params, config)
    local dir = config.root_dir and compile_commands_dir(config.root_dir)
    if dir then
      params.initializationOptions = vim.tbl_extend('force', params.initializationOptions or {}, {
        compilationDatabasePath = dir,
      })
    end
  end,
})

-- Upstream lists extensions (vert, frag, ...) as filetypes; Neovim calls them all glsl.
vim.lsp.config('glsl_analyzer', { filetypes = { 'glsl' } })

vim.lsp.config('ty', {
  settings = { ty = {} },
  -- Without $VIRTUAL_ENV ty only looks at .venv. Pick among .venv/, venv/ and env/ at the
  -- root the one with the most packages, so a stray empty .venv does not win.
  before_init = function(_, config)
    if vim.env.VIRTUAL_ENV or not config.root_dir then
      return
    end
    local best, most = nil, -1
    for _, name in ipairs({ '.venv', 'venv', 'env' }) do
      local dir = vim.fs.joinpath(config.root_dir, name)
      if vim.uv.fs_stat(vim.fs.joinpath(dir, 'pyvenv.cfg')) then
        local n = #vim.fn.glob(dir .. '/lib/python*/site-packages/*', true, true)
          + #vim.fn.glob(dir .. '/Lib/site-packages/*', true, true)
        if n > most then
          best, most = dir, n
        end
      end
    end
    if best then
      config.settings.ty.configuration = { environment = { python = best } }
    end
  end,
})

-- Server name (nvim-lspconfig) -> executable. Missing executables are skipped, so the
-- same config works on machines with only part of the toolchain installed.
local servers = {
  clangd = 'clangd', -- C, C++, CUDA, Objective-C, Objective-C++
  rust_analyzer = 'rust-analyzer',
  slangd = 'slangd', -- Slang and HLSL
  glsl_analyzer = 'glsl_analyzer',
  wgsl_analyzer = 'wgsl-analyzer',
}
for name, exe in pairs(servers) do
  if vim.fn.executable(exe) == 1 then
    vim.lsp.enable(name)
  end
end
-- One Python server only, or every request returns duplicates.
for _, py in ipairs({ { 'ty', 'ty' }, { 'basedpyright', 'basedpyright-langserver' }, { 'pyright', 'pyright-langserver' } }) do
  if vim.fn.executable(py[2]) == 1 then
    vim.lsp.enable(py[1])
    break
  end
end

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(ev)
    local client = assert(vim.lsp.get_client_by_id(ev.data.client_id))
    if client:supports_method('textDocument/completion') then
      -- Completion items come through 'omnifunc'; enable() applies their edits on <C-y>.
      vim.lsp.completion.enable(true, client.id, ev.buf)
      vim.bo[ev.buf].autocomplete = true
      vim.bo[ev.buf].complete = 'o' -- buffer words would duplicate the server's items
    end
    if client.name == 'clangd' then
      vim.keymap.set('n', '<leader>h', '<Cmd>LspClangdSwitchSourceHeader<CR>', { buffer = ev.buf, desc = 'Switch header/source' })
    end
  end,
})

-- Keymaps ---------------------------------------------------------------------
-- Built in with an LSP attached: K hover, grn rename, gra code action, grr references,
-- gri implementation, grt type definition, gO document symbols, ]d/[d diagnostics,
-- <C-]> definition, <C-t> back, <C-s> signature help (insert mode).

local map = vim.keymap.set
local fff = function(fn, ...)
  local args = { ... }
  return function()
    require('fff')[fn](unpack(args))
  end
end

map('n', '<Esc>', '<Cmd>nohlsearch<CR><Esc>')
map('n', '<leader>f', fff('find_files'), { desc = 'Find files' })
map('n', '<leader>g', fff('live_grep'), { desc = 'Live grep' })
map({ 'n', 'x' }, '<leader>w', fff('live_grep_under_cursor'), { desc = 'Grep word or selection' })
map('n', '<leader>d', fff('live_grep', { grep = { modes = { 'definition_only', 'plain' } } }), { desc = 'Grep definitions' })
map('n', '<leader>b', ':buffer ', { desc = 'Switch buffer' })
map('n', '<leader>s', vim.lsp.buf.workspace_symbol, { desc = 'Workspace symbols' })
map('n', 'gD', vim.lsp.buf.declaration, { desc = 'Go to declaration' })
map('n', 'gd', function()
  if #vim.lsp.get_clients({ bufnr = 0, method = 'textDocument/definition' }) > 0 then
    vim.lsp.buf.definition()
  else
    require('fff').live_grep_under_cursor() -- no server for this buffer (Metal, ...)
  end
end, { desc = 'Go to definition (grep without LSP)' })
