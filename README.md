# NvimConfig

A minimal Neovim setup for C++, CUDA, Objective-C/C++, Metal, Python, Rust, and
the shading languages (Slang, HLSL, GLSL, WGSL). It's one `init.lua` with five
plugins:

| Plugin | Job |
| --- | --- |
| [fff](https://github.com/dmtrKovalenko/fff) | File search and live grep from a Rust index. Honors `.gitignore`, so build trees and venvs never show up. Ranks files by frecency. |
| [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) (`main`) | Installs the tree-sitter parsers; highlighting itself is Neovim's built-in `vim.treesitter`. |
| [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) | Server defaults for Neovim's built-in LSP client (`vim.lsp.enable`). |
| [tokyonight.nvim](https://github.com/folke/tokyonight.nvim) | Colorscheme with tree-sitter and semantic-token groups. |
| [mini.icons](https://github.com/nvim-mini/mini.icons) | Nerd Font icons for fff's file list and the completion menu's item kinds. |

Plugins are managed by the built-in `vim.pack`. Their exact revisions are pinned
in `nvim-pack-lock.json`. Completion is built in too: `'autocomplete'` is fed by
the language server through `omnifunc`.

`tmux.conf` sets up tmux for running Neovim next to Claude Code or Codex (see
[tmux](#tmux)). [GUIDE.md](GUIDE.md) is a guide to the keys of Neovim, tmux and
both agents.

## What to install

The plugins install themselves. Everything else comes from outside Neovim:

| Tool | Used for | |
| --- | --- | --- |
| Neovim 0.12+ | | required |
| `git` | `vim.pack` clones the plugins | required |
| `curl`, `tar` | fff's binary download, parser sources | required |
| C compiler | building the tree-sitter parsers | for highlighting |
| [`tree-sitter` CLI](https://github.com/tree-sitter/tree-sitter/releases) 0.26.1+ | building the parsers (don't install it from npm) | for highlighting |
| Language servers (below) | definitions, references, completion, diagnostics | each optional |
| Rust (`cargo`) | building fff, only when no prebuilt binary matches the platform | optional |
| A [Nerd Font](https://www.nerdfonts.com) in the terminal | icons; without one they show as boxes | optional |
| [tmux](https://github.com/tmux/tmux) 3.6+ | panes for Neovim, Claude Code and Codex ([tmux](#tmux)) | optional |

Not needed: ripgrep, fd, fzf or Node.js.

Each server is enabled only when its executable is found, so a machine with half
the toolchain still starts cleanly. Check what attached with `:checkhealth vim.lsp`.

| Language | Highlighting | Definitions | Tested with |
| --- | --- | --- | --- |
| C, C++, CUDA, ObjC, ObjC++ | `c` `cpp` `cuda` `objc` | `clangd` | 22.1.1 |
| Python | `python` | `ty`, else `basedpyright`, else `pyright` | ty 0.0.101 |
| Rust | `rust` | `rust-analyzer` | rustup component |
| Slang, HLSL | `slang` `hlsl` | `slangd` | Slang 2026.22 |
| GLSL | `glsl` | `glsl_analyzer` | 1.7.1 |
| WGSL | `wgsl` | `wgsl-analyzer` | 2026-11-02 |
| Metal | `cpp` parser | none; `gd` greps the word with fff | |

The same set was tested with Neovim 0.12.6 and tree-sitter 0.27.2.

## Install

Install the tools for your platform, then clone the config and start Neovim
once.

### Linux

`install-linux.sh` installs Neovim, the tree-sitter CLI, clangd, ty, slangd,
glsl_analyzer and wgsl-analyzer at the versions above, and tmux 3.8 from
[tmux's static builds](https://github.com/tmux/tmux-builds). Each tool goes to
`~/.local/opt/<tool>-<version>` and is linked into `~/.local/bin`, so no root
is needed. Set `PREFIX` to install somewhere else. It also installs a Nerd Font
into `~/.local/share/fonts` (see [Nerd Font](#nerd-font)).
It was tested on Ubuntu 24.04 aarch64. On x86_64 it downloads the matching
archives, which were not tested. Distribution packages are usually too old for
Neovim 0.12, tree-sitter 0.26 and tmux 3.6.

The script lives in the config, so on Linux clone it first:

```sh
sudo apt install git curl unzip xz-utils python3 build-essential   # or your distribution's equivalents
git clone https://github.com/VladSerhiienko/NvimConfig ~/.config/nvim
sh ~/.config/nvim/install-linux.sh
```

`~/.local/bin` has to be on `PATH`; Ubuntu's `~/.profile` adds it at login once
the directory exists. To upgrade a tool, change its version at the top of the
script and run it again.

For Rust, install [rustup](https://rustup.rs) and add the server:

```sh
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
rustup component add rust-analyzer rust-src
```

If `cargo` isn't on `PATH`, `~/.cargo/bin` (or `$CARGO_HOME/bin`) is appended to
Neovim's own `PATH`, which covers rustup installs made with `--no-modify-path`.

### macOS (best effort, untested)

With [Homebrew](https://brew.sh):

```sh
xcode-select --install   # git and clang; curl and tar ship with macOS
brew install neovim tree-sitter-cli llvm ty wgsl-analyzer tmux
ln -sf "$(brew --prefix llvm)/bin/clangd" "$(brew --prefix)/bin/clangd"   # llvm is keg-only; expose clangd alone
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
rustup component add rust-analyzer rust-src
```

Slang and glsl_analyzer aren't in Homebrew; take the release builds:

```sh
m=$(uname -m | sed s/arm64/aarch64/)   # aarch64 or x86_64
mkdir -p ~/.local/opt/slang-2026.22 ~/.local/opt/glsl_analyzer-1.7.1 && cd ~/.local/opt
curl -fsSL https://github.com/shader-slang/slang/releases/download/v2026.22/slang-2026.22-macos-$m.tar.gz | tar xz -C slang-2026.22
curl -fsSLo glsl_analyzer.zip https://github.com/nolanderc/glsl_analyzer/releases/download/v1.7.1/$m-macos.zip
unzip -q glsl_analyzer.zip -d glsl_analyzer-1.7.1 && rm glsl_analyzer.zip
echo 'export PATH="$PATH:$HOME/.local/opt/slang-2026.22/bin:$HOME/.local/opt/glsl_analyzer-1.7.1/bin"' >> ~/.zprofile
```

Slang's `bin/` goes at the end of `PATH`, so a `slangc` installed elsewhere still
wins. Files fetched with `curl` aren't quarantined. If you download them in a
browser instead, run `xattr -dr com.apple.quarantine` on the folder.

### Windows (best effort, untested)

In PowerShell, with [Scoop](https://scoop.sh) (no admin rights needed). The
Visual Studio Build Tools provide the C compiler for the parsers and the linker
for Rust. Windows 10 and later already ship `curl.exe` and `tar.exe`.

```powershell
winget install Microsoft.VisualStudio.BuildTools --override "--wait --passive --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"
scoop install git neovim tree-sitter llvm ty slang rustup
rustup component add rust-analyzer rust-src
```

Scoop's `llvm` puts all of LLVM's `bin` on `PATH` (clang and lld too); its
`slang` exposes only `slangd`. glsl_analyzer and wgsl-analyzer come from their
releases:

```powershell
$opt = "$env:LOCALAPPDATA\Programs"
Invoke-WebRequest https://github.com/nolanderc/glsl_analyzer/releases/download/v1.7.1/x86_64-windows.zip -OutFile $env:TEMP\glsl_analyzer.zip
Expand-Archive $env:TEMP\glsl_analyzer.zip $opt\glsl_analyzer-1.7.1
Invoke-WebRequest https://github.com/wgsl-analyzer/wgsl-analyzer/releases/download/2026-11-02/wgsl-analyzer-x86_64-pc-windows-msvc.zip -OutFile $env:TEMP\wgsl-analyzer.zip
Expand-Archive $env:TEMP\wgsl-analyzer.zip $opt\wgsl-analyzer-2026-11-02
$path = [Environment]::GetEnvironmentVariable('Path', 'User')
[Environment]::SetEnvironmentVariable('Path', "$path;$opt\glsl_analyzer-1.7.1\bin;$opt\wgsl-analyzer-2026-11-02", 'User')
```

Open a new terminal afterwards so `PATH` is reread. Both projects publish arm64
builds as well. winget also has `Neovim.Neovim`, `tree-sitter.tree-sitter-cli`,
`LLVM.LLVM`, `astral-sh.ty` and `Rustlang.Rustup`, but not Slang. If you use it,
make sure LLVM's `bin` ends up on `PATH`.

tmux has no Windows build. Under WSL, follow the Linux steps.

### Nerd Font

The file icons in fff and the item-kind icons in the completion menu are Nerd
Font glyphs. Ghostty, kitty and WezTerm bundle them, so any font works there.
Other terminals need a patched font: pick its "Nerd Font Mono" family, whose
icons fit one cell.

- **Linux:** `install-linux.sh` installs Ubuntu Sans Mono, patched: the Ubuntu
  terminal's default font, with icons. Set `NERD_FONT` to another family from
  [nerdfonts.com](https://www.nerdfonts.com/font-downloads), e.g.
  `NERD_FONT=JetBrainsMono`. To select it in GNOME Terminal:

  ```sh
  p=org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'")/
  gsettings set $p font 'UbuntuSansMono Nerd Font Mono 13'
  gsettings set $p use-system-font false   # true goes back to the system font
  ```

- **macOS:** `brew install --cask font-jetbrains-mono-nerd-font`, then choose
  JetBrainsMono Nerd Font Mono in the Terminal or iTerm2 profile.
- **Windows:** `scoop bucket add nerd-fonts`, then `scoop install JetBrainsMono-NF-Mono`
  (or `winget install DEVCOM.JetBrainsMonoNerdFont`). Then choose it in Windows
  Terminal under Settings > your profile > Appearance > Font face.

### Config and first start

```sh
git clone https://github.com/VladSerhiienko/NvimConfig ~/.config/nvim   # Windows: $env:LOCALAPPDATA\nvim; Linux: already cloned
nvim --headless +qa
```

The headless run installs the plugins at their locked revisions, downloads
fff's prebuilt binary (`libfff_nvim`) and compiles the parsers. A plain `nvim`
does the same, but compiles the parsers in the background; they apply to files
opened after that finishes.

### tmux

Link the config where tmux looks for it:

```sh
mkdir -p ~/.config/tmux && ln -s ~/.config/nvim/tmux.conf ~/.config/tmux/tmux.conf
```

It needs tmux 3.6 or later. Beyond tmux's defaults, it turns on focus events
(Neovim's autoread, Claude Code's notifications), extended keys, passthrough for
desktop notifications and OSC 52 copying, a 50,000-line scrollback, vi keys in
copy mode (`v` selects, `y` copies), the terminal title from the active pane,
and new windows and splits in the current directory. The prefix stays
<kbd>Ctrl-b</kbd>; reload with `tmux source ~/.config/tmux/tmux.conf`.

- **Newline in Claude Code or Codex:** <kbd>Ctrl-j</kbd> works in every terminal.
  So does <kbd>Alt-Enter</kbd>, except in Windows Terminal and WezTerm (where it
  is full screen) and on macOS until Option is set to act as Meta.
  <kbd>Shift-Enter</kbd> works only if the terminal reports it to tmux as a
  different key from Enter (xterm's modifyOtherKeys), which GNOME Terminal
  doesn't. Codex doesn't ask tmux for extended keys, so a binding hands it
  Shift-Enter in the form it reads; other programs get the key as they asked
  for it.
- **Selecting text in GNOME Terminal:** tmux takes the mouse, so hold
  <kbd>Shift</kbd> while dragging to select, then copy with <kbd>Ctrl-Shift-c</kbd>.
  GNOME Terminal ignores OSC 52, so copies made in tmux and Neovim's `"+`
  register stay inside tmux there. On macOS, tmux copies also go through
  `pbcopy`.
- **Other systems and terminals:** [GUIDE.md](GUIDE.md#linux-windows-and-macos)
  lists the keys per system, and the ones terminals take for themselves.

## Project details handled automatically

- **Compile database.** clangd itself only checks parent directories and their
  `build/` subdirectories. When neither has a `compile_commands.json`, the newest
  one under `build*/`, `build*/*/`, `cmake-build-*/` or `out/build/*/` is passed
  to clangd. To pin one, put `compile_commands.json` (or a symlink) at the root.
  CMake writes it only with the Ninja and Makefile generators
  (`-DCMAKE_EXPORT_COMPILE_COMMANDS=ON`), not with the Visual Studio or Xcode ones.
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

## Per-project settings

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

Leader is <kbd>Space</kbd>. These are the keys this config adds or changes;
[GUIDE.md](GUIDE.md) covers Neovim's built-in keys and tmux as well.

| Key | Action |
| --- | --- |
| `<leader>f` | Find files (fff) |
| `<leader>g` | Live grep (fff); <kbd>Shift-Tab</kbd> cycles plain / regex / fuzzy / definitions |
| `<leader>w` | Grep the word under the cursor, or the visual selection |
| `<leader>d` | Grep definitions only (C/C++/ObjC/CUDA, Rust, Python, ...) |
| `<leader>b` | `:buffer ` with fuzzy completion |
| `<leader>s` | Workspace symbols (LSP) |
| `<leader>h` | Switch header/source (clangd) |
| `gd` / `gD` | Definition / declaration; `gd` greps the word when no server finds a definition (Metal, HLSL slangd can't parse) |
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
- External tools: bump the versions in `install-linux.sh` and rerun it, or
  `brew upgrade` / `scoop update *`; `rustup update` covers rust-analyzer.
