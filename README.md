# NvimConfig

A minimal Neovim setup for C++, CUDA, Objective-C/C++, Metal, Python, Rust, and
the shading languages (Slang, HLSL, GLSL, WGSL). It's one `init.lua` with four
plugins:

| Plugin | Job |
| --- | --- |
| [fff](https://github.com/dmtrKovalenko/fff) | File search and live grep from a Rust index. Honors `.gitignore`, so build trees and venvs never show up. Ranks files by frecency. |
| [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) (`main`) | Installs the tree-sitter parsers; highlighting itself is Neovim's built-in `vim.treesitter`. |
| [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) | Server defaults for Neovim's built-in LSP client (`vim.lsp.enable`). |
| [tokyonight.nvim](https://github.com/folke/tokyonight.nvim) | Colorscheme with tree-sitter and semantic-token groups. |

Plugins are managed by the built-in `vim.pack`. Their exact revisions are pinned
in `nvim-pack-lock.json`. Completion is built in too: `'autocomplete'` is fed by
the language server through `omnifunc`.

## Install

Requires Neovim **0.12+**, `git`, `curl`, `tar`, a C compiler, and the
[`tree-sitter` CLI](https://github.com/tree-sitter/tree-sitter/releases) 0.26.1+
(nvim-treesitter's `main` branch builds parsers with it; don't install it from npm).

```sh
git clone https://github.com/VladSerhiienko/NvimConfig ~/.config/nvim   # Windows: %LOCALAPPDATA%\nvim
nvim
```

The first start installs the plugins at their locked revisions and downloads
fff's prebuilt binary (`libfff_nvim`). It also compiles the parsers in the
background; they apply to files opened after that finishes. To do everything in
one blocking step:

```sh
nvim --headless "+lua require('nvim-treesitter').install({'c','cpp','cuda','objc','python','rust','slang','hlsl','glsl','wgsl'}):wait(600000)" +qa
```

## Language servers

Each server is enabled only when its executable is found, so a machine with half
the toolchain still starts cleanly. Check what attached with `:checkhealth vim.lsp`.

| Language | Highlighting | Definitions | Get the server |
| --- | --- | --- | --- |
| C, C++, CUDA, ObjC, ObjC++ | `c` `cpp` `cuda` `objc` | `clangd` | `brew install llvm`, or the PyPI wheel (`uv tool install clangd`), which has arm64 Linux builds |
| Python | `python` | `ty`, else `basedpyright`, else `pyright` | `brew install ty`, `uv tool install ty`, or a [release](https://github.com/astral-sh/ty/releases) |
| Rust | `rust` | `rust-analyzer` | `rustup component add rust-analyzer rust-src` |
| Slang, HLSL | `slang` `hlsl` | `slangd` | `bin/slangd` from a [Slang release](https://github.com/shader-slang/slang/releases) |
| GLSL | `glsl` | `glsl_analyzer` | [release](https://github.com/nolanderc/glsl_analyzer/releases) |
| WGSL | `wgsl` | `wgsl-analyzer` | `brew install wgsl-analyzer` or a [release](https://github.com/wgsl-analyzer/wgsl-analyzer/releases) |
| Metal | `cpp` parser | none; `gd` greps with fff | |

If `cargo` isn't on `PATH`, `~/.cargo/bin` (or `$CARGO_HOME/bin`) is appended to
Neovim's own `PATH`, which covers rustup installs made with `--no-modify-path`.

### Project details handled automatically

- **Compile database.** clangd itself only checks parent directories and their
  `build/` subdirectories. When neither has a `compile_commands.json`, the newest
  one under `build*/`, `build*/*/`, `cmake-build-*/` or `out/build/*/` is passed
  to clangd. To pin one, put `compile_commands.json` (or a symlink) at the root.
- **One clangd per project.** Files in git submodules, and headers outside the
  project (system headers, Conan or vcpkg caches) reached with go-to-definition,
  join the clangd that is already running. They keep its flags and index instead
  of starting a server that has neither.
- **Python environment.** Unless `$VIRTUAL_ENV` is set, ty is pointed at
  whichever of `.venv/`, `venv/` and `env/` at the root has the most packages.
- **Filetypes.** `.m` is Objective-C (not MATLAB) and `.mm` is Objective-C++
  (parsed with the `objc` grammar, which fails on far fewer lines than `cpp`).
  `.metal` uses the `cpp` grammar. `.hlsl`, `.hlsli`, `.fx` and `.fxh` are HLSL,
  `.slangh` is Slang, and `.mesh`/`.task` are GLSL.
- Tree-sitter is skipped for files over 2 MB, which are usually generated.

### Per-project settings

`'exrc'` is on, so a `.nvim.lua` in the directory Neovim starts in (or any
parent) runs at startup. Neovim asks before running one it hasn't seen, and again
after every edit; review it and answer, or open it and run `:trust`. Use it for
project-specific LSP settings. For example, slangd resolves `#include` and
`import` only relative to the file and the workspace, so shaders that include
SDK headers need search paths and macros
([options](https://github.com/shader-slang/slang-vscode-extension#configurations)):

```lua
vim.lsp.config('slangd', { settings = { slang = {
  additionalSearchPaths = { '/path/to/sdk/include' },
  predefinedMacros = { 'MY_MACRO=1' },
} } })
```

## Keys

Leader is <kbd>Space</kbd>.

| Key | Action |
| --- | --- |
| `<leader>f` | Find files (fff) |
| `<leader>g` | Live grep (fff); <kbd>Shift-Tab</kbd> cycles plain / regex / fuzzy / definitions |
| `<leader>w` | Grep the word under the cursor, or the visual selection |
| `<leader>d` | Grep definitions only (C/C++/ObjC/CUDA, Rust, Python, ...) |
| `<leader>b` | `:buffer ` with fuzzy completion |
| `<leader>s` | Workspace symbols (LSP) |
| `<leader>h` | Switch header/source (clangd) |
| `gd` / `gD` | Definition / declaration; `gd` greps when the buffer has no server |
| `<C-]>` / `<C-t>` | Definition through the tag stack / jump back |
| `K` | Hover |
| `grr` `gri` `grt` | References, implementations, type definition |
| `grn` `gra` | Rename, code action |
| `gO` | Document symbols |
| `]d` `[d` `<C-w>d` | Next / previous / show diagnostic |
| `<C-y>` `<C-e>` | Accept / dismiss completion; <kbd>Ctrl-n</kbd>/<kbd>Ctrl-p</kbd> move |

In the fff picker: `<C-s>`/`<C-v>`/`<C-t>` open in split/vsplit/tab, `<Tab>` marks,
`<C-q>` sends marked files to quickfix.

## Updating

- `:lua vim.pack.update()` reviews plugin updates in a tab; `:w` applies them.
  Updates rerun the fff binary download and `:TSUpdate`. Commit
  `nvim-pack-lock.json` afterwards.
- fff follows its `main` branch, and every commit there gets a prebuilt binary
  within about half an hour. If an update lands before that, the download falls
  back to `cargo build`. Rerun later with
  `:lua require('fff.download').download_or_build_binary()`.
