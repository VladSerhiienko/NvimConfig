# Neovim and tmux guide

How to get around in tmux and in this Neovim config, and how to run Claude Code
and Codex next to them. The keys below were checked against tmux 3.8, Neovim
0.12 and this repository's `init.lua` and `tmux.conf`.

- [Notation](#notation)
- [Linux, Windows and macOS](#linux-windows-and-macos)
- [A working layout](#a-working-layout)
- [tmux](#tmux): [sessions](#sessions), [windows](#windows), [panes](#panes),
  [floating panes](#floating-panes), [copy mode](#copy-mode-and-scrollback),
  [other keys](#other-tmux-keys)
- [Neovim](#neovim): [modes](#modes), [moving](#moving-in-a-file),
  [search](#search-and-replace), [jumps](#jumps-and-marks),
  [files](#files-and-buffers), [fff picker](#the-fff-picker),
  [project search](#searching-the-project), [code navigation](#code-navigation-lsp),
  [diagnostics](#diagnostics), [completion](#completion), [editing](#editing),
  [windows and tabs](#windows-and-tabs), [command line](#command-line),
  [terminal](#terminal-inside-neovim)
- [Claude Code and Codex](#claude-code-and-codex)
- [Between Neovim, tmux and the agents](#between-neovim-tmux-and-the-agents)

## Notation

| Written | Press |
| --- | --- |
| `C-b c` (tmux) | <kbd>Ctrl</kbd>+<kbd>b</kbd>, release, then <kbd>c</kbd>. `C-b` is the tmux prefix. |
| `C-b M-1` | Prefix, then <kbd>Alt</kbd>+<kbd>1</kbd> (<kbd>Option</kbd>+<kbd>1</kbd> on macOS) |
| `<C-w>v` (Neovim) | <kbd>Ctrl</kbd>+<kbd>w</kbd>, then <kbd>v</kbd> |
| `<leader>f` | <kbd>Space</kbd>, then <kbd>f</kbd> (leader is Space in this config) |
| `<S-Tab>`, `<M-Enter>`, `<CR>` | <kbd>Shift</kbd>+<kbd>Tab</kbd>, <kbd>Alt</kbd>+<kbd>Enter</kbd>, <kbd>Enter</kbd> |
| `gd`, `]q` | Type the characters in order, in Normal mode |
| `:w` | Type it on Neovim's command line and press <kbd>Enter</kbd> |

A count in front repeats most Neovim commands: `5j` moves five lines down,
`3dd` deletes three lines.

Inside tmux, a program never sees <kbd>Ctrl</kbd>+<kbd>b</kbd> directly. Press
`C-b C-b` to send it: Neovim's page up, Claude Code's "background this task".

## Linux, Windows and macOS

The keys in this guide are the same on all three systems. The differences come
from the keyboard and from the terminal, which handles some keys itself before
tmux, Neovim or an agent sees them.

### Modifier keys

| Written | Linux | Windows | macOS |
| --- | --- | --- | --- |
| `C-…`, `<C-…>` | <kbd>Ctrl</kbd> | <kbd>Ctrl</kbd> | <kbd>Control</kbd> (⌃), not <kbd>Command</kbd> (⌘) |
| `M-…`, `<M-…>`, `<A-…>` | <kbd>Alt</kbd> | <kbd>Alt</kbd> | <kbd>Option</kbd> (⌥), once the terminal sends it as Meta (below) |
| `S-…`, `<S-…>` | <kbd>Shift</kbd> | <kbd>Shift</kbd> | <kbd>Shift</kbd> |

On macOS, <kbd>Command</kbd> shortcuts belong to the terminal app (copy, paste,
tabs); tmux, Neovim and the agents never receive them.

By default, macOS terminals turn <kbd>Option</kbd> into special characters
(<kbd>Option</kbd>+<kbd>1</kbd> types `¡`), so the `M-` keys do nothing until
<kbd>Option</kbd> is set to act as Meta:

- **Terminal:** Settings › Profiles › Keyboard › Use Option as Meta key.
- **iTerm2:** Settings › Profiles › Keys › General › Left Option key: Esc+.
- **Ghostty:** `macos-option-as-alt = true` in its config file.
- **kitty:** `macos_option_as_alt yes` in `kitty.conf`.
- **WezTerm:** the left <kbd>Option</kbd> key already sends Alt.

### The terminal's own keys

| | Linux (GNOME Terminal) | Windows (Windows Terminal) | macOS |
| --- | --- | --- | --- |
| Copy the terminal's selection | <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>c</kbd> | <kbd>Ctrl</kbd>+<kbd>c</kbd> (only while text is selected) or <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>c</kbd> | <kbd>⌘</kbd>+<kbd>c</kbd> |
| Paste | <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>v</kbd> | <kbd>Ctrl</kbd>+<kbd>v</kbd> or <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>v</kbd> | <kbd>⌘</kbd>+<kbd>v</kbd> |
| Select text while tmux or Neovim has the mouse | <kbd>Shift</kbd>+drag | <kbd>Shift</kbd>+drag | Terminal: <kbd>Fn</kbd>+drag; iTerm2: <kbd>Option</kbd>+drag; Ghostty, kitty, WezTerm: <kbd>Shift</kbd>+drag |
| PgUp, PgDn, Home, End | The keys | The keys | <kbd>Fn</kbd>+<kbd>↑</kbd> <kbd>↓</kbd> <kbd>←</kbd> <kbd>→</kbd>; in Terminal also hold <kbd>Shift</kbd>, or it scrolls its own window |
| F1 … F12 | The keys | The keys | <kbd>Fn</kbd>+<kbd>F1</kbd> … unless the F keys are set to act as standard function keys |
| Full screen | <kbd>F11</kbd> | <kbd>F11</kbd> or <kbd>Alt</kbd>+<kbd>Enter</kbd> | <kbd>⌃</kbd>+<kbd>⌘</kbd>+<kbd>f</kbd> (iTerm2: <kbd>⌘</kbd>+<kbd>Enter</kbd>) |

Text pasted with these keys arrives as a bracketed paste, so a multi-line paste
into Claude Code or Codex doesn't submit the prompt.

### Keys taken before they arrive

| Key in this guide | Taken by | Use instead |
| --- | --- | --- |
| `C-b M-1` … `C-b M-7` (tmux layouts) | GNOME Terminal: <kbd>Alt</kbd>+<kbd>1</kbd> … <kbd>Alt</kbd>+<kbd>0</kbd> switch its tabs | `C-b Space`, or clear them in Preferences › Shortcuts |
| `<M-Enter>` (new line in Claude Code and Codex) | Windows Terminal and WezTerm, on every system: full screen | `<C-j>`, or <kbd>Shift</kbd>+<kbd>Enter</kbd> |
| `C-b M-↑` … (resize by 5), fff's `<A-↓>` / `<A-↑>` | Windows Terminal: <kbd>Alt</kbd>+arrows and <kbd>Alt</kbd>+<kbd>Shift</kbd>+arrows move between and resize its own panes | `C-b C-↑` …; in fff, `<C-A-n>` / `<C-A-p>` |
| `<C-v>` (Neovim block selection, fff's vertical split, tmux's block selection) | Windows Terminal: paste | Neovim's `<C-q>` also starts a block selection; or delete Windows Terminal's <kbd>Ctrl</kbd>+<kbd>v</kbd> binding (Settings › Actions) and paste with <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>v</kbd> |
| `C-b C-↑` … (resize by 1), fff's `<C-↑>` / `<C-↓>` (query history) | macOS: <kbd>⌃</kbd>+arrows switch Mission Control and Spaces | `C-b M-↑` …, or turn them off in System Settings › Keyboard › Keyboard Shortcuts › Mission Control |

### The clipboard

| | Linux (GNOME Terminal) | Windows | macOS |
| --- | --- | --- | --- |
| Neovim's `"+y` / `"+p` | Inside tmux, tmux's buffer. The desktop clipboard once `xclip` (X11) or `wl-clipboard` (Wayland) is installed | Native Neovim: the Windows clipboard. In WSL inside tmux: tmux's buffer, and the Windows clipboard through Windows Terminal | The macOS clipboard, inside tmux too |
| tmux copies (`y`, mouse drag) | tmux's buffer only: GNOME Terminal ignores OSC 52 | In WSL: tmux's buffer and the Windows clipboard | tmux's buffer and the macOS clipboard (`tmux.conf` pipes copies to `pbcopy`) |
| Paste into an agent's pane | `C-b ]` from tmux's buffer, <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>v</kbd> from the desktop | `C-b ]`, or <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>v</kbd> | `C-b ]`, or <kbd>⌘</kbd>+<kbd>v</kbd> |

### Claude Code and Codex keys

| | Linux (GNOME Terminal) | Windows (Windows Terminal) | macOS |
| --- | --- | --- | --- |
| New line in the prompt | `<C-j>` or <kbd>Alt</kbd>+<kbd>Enter</kbd> | `<C-j>` or <kbd>Shift</kbd>+<kbd>Enter</kbd> | `<C-j>`; <kbd>Shift</kbd>+<kbd>Enter</kbd> in Ghostty, iTerm2, kitty and WezTerm; <kbd>Option</kbd>+<kbd>Enter</kbd> once Option acts as Meta, except in WezTerm |
| Paste an image | <kbd>Ctrl</kbd>+<kbd>v</kbd> | Claude Code: <kbd>Alt</kbd>+<kbd>v</kbd>. Codex: <kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>v</kbd>, in WSL too | <kbd>Ctrl</kbd>+<kbd>v</kbd> (Claude Code in iTerm2: <kbd>⌘</kbd>+<kbd>v</kbd>) |

Inside tmux, <kbd>Shift</kbd>+<kbd>Enter</kbd> works only if the terminal
reports it to tmux as a key of its own; if it submits instead, use `<C-j>`.

### tmux on Windows

tmux runs only inside WSL: open the Ubuntu (WSL) profile in Windows Terminal and
follow the Linux setup there; everything in this guide then applies. To run
Neovim and the agents on Windows itself, use Windows Terminal's panes instead.
They close with the window, since there is nothing to detach from.

| Windows Terminal | Does |
| --- | --- |
| <kbd>Alt</kbd>+<kbd>Shift</kbd>+<kbd>d</kbd> | Split the pane |
| <kbd>Alt</kbd>+<kbd>Shift</kbd>+<kbd>-</kbd> / <kbd>Alt</kbd>+<kbd>Shift</kbd>+<kbd>+</kbd> | Split below / to the right |
| <kbd>Alt</kbd>+arrows | Move to the pane in that direction |
| <kbd>Alt</kbd>+<kbd>Shift</kbd>+arrows | Resize the pane |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>w</kbd> | Close the pane |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>t</kbd>, <kbd>Ctrl</kbd>+<kbd>Tab</kbd> | New tab, next tab |

## A working layout

```sh
tmux new -A -s coq -c ~/Projects/Coquelicot   # attach to session "coq", or create it there
```

1. Run `nvim` in the first pane.
2. `C-b %` splits it side by side; run `claude` in the new pane.
3. `C-b c` opens a second window; run `codex` there.
4. Move with `C-b ←`/`C-b →` between panes, `C-b 0`/`C-b 1` between the two
   windows (numbering starts at 0), and `C-b ;` back to the previous pane.
   `C-b z` zooms the current pane to the full window and back.
5. `C-b d` detaches. Everything keeps running, also when the terminal closes or
   an SSH connection drops. `tmux new -A -s coq` (or `tmux a -t coq`) brings it
   back.

## tmux

tmux runs a server that holds **sessions**; a session has **windows** (the tabs in
the status bar), and a window is split into **panes**. `C-b ?` lists every key,
`C-b /` then a key explains that key, and `C-b :` opens the command prompt.

### Sessions

From a shell:

| Command | Does |
| --- | --- |
| `tmux new -s name -c dir` | New session `name`, starting in `dir` |
| `tmux new -A -s name` | Attach to `name` if it exists, else create it |
| `tmux ls` | List sessions |
| `tmux a` / `tmux a -t name` | Attach to the last session / to `name` |
| `tmux kill-session -t name` | End a session and everything running in it |
| `tmux kill-server` | End all sessions |

Inside tmux:

| Key | Does |
| --- | --- |
| `C-b d` | Detach |
| `C-b s` | Session and window tree: arrows move, <kbd>Enter</kbd> switches, `x` kills, `q` leaves |
| `C-b S-Tab` | Quick session switcher (a small floating pane) |
| `C-b (` / `C-b )` | Previous / next session |
| `C-b L` | Last session |
| `C-b $` | Rename the session |

### Windows

| Key | Does |
| --- | --- |
| `C-b c` | New window, in the current pane's directory |
| `C-b ,` | Rename the window |
| `C-b n` / `C-b p` | Next / previous window |
| `C-b 0` … `C-b 9` | Window by number; `C-b '` asks for a number |
| `C-b l` | Last window |
| `C-b w` | Pick a window from a tree with previews |
| `C-b Tab` | Quick window switcher (a small floating pane) |
| `C-b f` | Find a window by the text in its panes |
| `C-b .` | Move the window to another number |
| `C-b &` | Kill the window (asks first) |
| Mouse | Click a name in the status bar; wheel over the status bar cycles windows |

### Panes

| Key | Does |
| --- | --- |
| `C-b %` | Split side by side (new pane on the right) |
| `C-b "` | Split top and bottom (new pane below) |
| `C-b ←` `↑` `→` `↓` | Move to the pane in that direction |
| `C-b ;` | Back to the previous pane |
| `C-b o` | Next pane |
| `C-b q` | Show pane numbers; press a number while they show to jump there |
| `C-b z` | Zoom the pane to the whole window, and back |
| `C-b x` | Kill the pane (asks first) |
| `C-b !` | Move the pane out to its own window |
| `C-b {` / `C-b }` | Swap with the previous / next pane |
| `C-b C-o` | Rotate the panes |
| `C-b Space` | Next layout; `C-b M-1` … `C-b M-7` pick one directly |
| `C-b E` | Spread the panes out evenly |
| `C-b C-↑` … / `C-b M-↑` … | Resize by 1 / by 5 cells |
| `C-b T` | Set the pane's title |
| Mouse | Click a pane to focus it, drag a border to resize, <kbd>Alt</kbd>+drag a pane to move it |

Splits (`C-b %`, `C-b "`) and new windows (`C-b c`) start in the current pane's
directory, so a split next to Neovim opens a shell in the project.

The arrow and resize keys repeat for half a second after one prefix: `C-b → →`
moves two panes. That also means an <kbd>↑</kbd> pressed right after
`C-b ↑` moves panes again instead of reaching the shell. Wait a moment, or
switch with `C-b ;`.

To bring a pane back from another window, run `C-b :` then `join-pane -s 2`
(window 2's pane joins the current window).

### Floating panes

tmux 3.8 can float panes over the tiled ones.

| Key | Does |
| --- | --- |
| `C-b *` | New floating pane |
| `C-b @` | Turn the pane floating or back to tiled |
| `C-b g` then `←` `↑` `→` `↓` | Move the floating pane to that edge |
| `C-b g` then `1` … `4` | Move it to a corner; `M-1` … `M-4` also make it a quarter of the window |
| `C-b g` then `0` | Fill the window |
| <kbd>Ctrl</kbd>+drag | Draw a new floating pane with the mouse |

### Copy mode and scrollback

Each pane keeps 50,000 lines of history. Copy mode moves through it with Vim
keys.

| Key | Does |
| --- | --- |
| `C-b [` | Enter copy mode |
| `C-b PgUp` | Enter copy mode one page up |
| Mouse wheel | Scroll up into copy mode (programs that take the mouse themselves, such as Neovim and Codex, get the wheel instead) |
| `h` `j` `k` `l`, `w` `b` `e`, `0` `^` `$` | Move as in Vim |
| `<C-u>` / `<C-d>`, `PgUp` / `PgDn` | Half page / page |
| `g` / `G` | Top of the history / bottom |
| `H` `M` `L` | Top / middle / bottom of the screen |
| `/` / `?`, then `n` / `N` | Search down / up, next / previous match |
| `*` / `#` | Search for the word under the cursor |
| `f` `t` `F` `T`, `;` `,` | Jump to a character on the line |
| `:` | Go to a line |
| `v` | Start a selection; `<C-v>` then makes it a block |
| `V` | Select whole lines |
| `o` | Jump to the other end of the selection |
| `y` or <kbd>Enter</kbd> | Copy the selection and leave copy mode |
| <kbd>Esc</kbd> | Clear the selection |
| `q` | Leave copy mode |

Pasting:

| Key | Does |
| --- | --- |
| `C-b ]` | Paste the last copy (as a bracketed paste, so Claude Code and Codex don't submit at its first newline) |
| `C-b =` | Choose one of the earlier copies |
| Middle click | Paste the last copy |

With the mouse: drag to select (the copy happens when you release),
double-click copies a word and triple-click a line.

**Clipboard.** Copies land in tmux's buffers. In terminals that support OSC 52
(Ghostty, kitty, WezTerm, Windows Terminal; iTerm2 once clipboard access is
allowed in its settings), and on macOS through `pbcopy`, they also reach the
system clipboard. GNOME Terminal ignores OSC 52. To bypass tmux and select
with the terminal itself, see [the terminal's own
keys](#the-terminals-own-keys).

### Other tmux keys

| Key | Does |
| --- | --- |
| `C-b ?` | List all keys |
| `C-b /` | Describe one key |
| `C-b :` | Command prompt |
| `C-b C` | Browse and change options |
| `C-b r` | Redraw the screen |
| `C-b ~` | Show recent messages |
| `C-b t` | Big clock |
| `C-b C-b` | Send <kbd>Ctrl</kbd>+<kbd>b</kbd> to the program in the pane |

After editing `tmux.conf`, `tmux source ~/.config/tmux/tmux.conf` applies it to
the running server.

## Neovim

### Modes

| Mode | Enter with | Leave with |
| --- | --- | --- |
| Normal | <kbd>Esc</kbd> from any other mode | |
| Insert | `i` before the cursor, `a` after it, `I` / `A` at line start / end, `o` / `O` on a new line below / above | <kbd>Esc</kbd> |
| Visual | `v` characters, `V` lines, `<C-v>` a block | <kbd>Esc</kbd> |
| Command line | `:` | <kbd>Enter</kbd> runs it, <kbd>Esc</kbd> cancels |

<kbd>Esc</kbd> in Normal mode also clears search highlighting in this config.

| Command | Does |
| --- | --- |
| `:w` | Save |
| `:q` / `:q!` | Close the window / close it and discard changes |
| `:wq` or `ZZ` | Save and close |
| `:qa` / `:wqa` | Quit everything / save everything and quit |
| `u` / `<C-r>` | Undo / redo (undo history survives restarts) |
| `.` | Repeat the last change |

### Moving in a file

| Key | Moves |
| --- | --- |
| `h` `j` `k` `l` | Left, down, up, right |
| `w` / `b` / `e` | Next word / previous word / end of word (`W` `B` `E` count only spaces as separators) |
| `0` / `^` / `$` | Line start / first non-blank / line end |
| `f{c}` / `t{c}` | To / just before the next `{c}` on the line; `F` `T` go backwards; `;` `,` repeat |
| `gg` / `G` | First / last line; `42G` or `:42` goes to line 42 |
| `%` | Matching bracket |
| `{` / `}` | Previous / next blank line (paragraph) |
| `H` / `M` / `L` | Top / middle / bottom of the window |
| `<C-d>` / `<C-u>` | Half page down / up |
| `<C-f>` / `<C-b>` | Page down / up (`<C-b>` is `C-b C-b` inside tmux) |
| `<C-e>` / `<C-y>` | Scroll one line without moving the cursor |
| `zz` / `zt` / `zb` | Put the cursor line in the middle / top / bottom of the window |

The mouse works too: click to place the cursor, scroll with the wheel, drag a
window border to resize.

### Search and replace

| Key | Does |
| --- | --- |
| `/text` / `?text` | Search forward / backward (case-insensitive unless the search has capitals) |
| `n` / `N` | Next / previous match |
| `*` / `#` | Search for the word under the cursor, forward / backward; in Visual mode, for the selection |
| <kbd>Esc</kbd> or `<C-l>` | Clear the highlighting |
| `:%s/old/new/g` | Replace in the whole file; the effect shows live in a split while you type |
| `:%s//new/g` | Replace the last search |
| `&` | Repeat the last `:s` on the current line |

### Jumps and marks

| Key | Does |
| --- | --- |
| `<C-o>` / `<C-i>` | Back / forward through jumps (searches, `gd`, `G`, file switches) |
| ` `` ` | Back to where the cursor was before the last jump |
| `g;` / `g,` | Older / newer change positions |
| `` `. `` | Last change |
| `gi` | Insert where you last stopped inserting |
| `ma` then `` `a `` | Set mark `a`, jump to it (`'a` jumps to its line) |
| `mA` then `` `A `` | Capital marks work across files |
| `:jumps`, `:marks` | List them |

### Files and buffers

Every open file is a buffer, whether or not a window shows it.

| Key | Does |
| --- | --- |
| `<leader>f` | Find a file (fff) |
| `<leader>b` | Switch buffer: type part of a name, <kbd>Tab</kbd> completes fuzzily, <kbd>Enter</kbd> |
| `]b` / `[b` | Next / previous buffer |
| `<C-^>` | The previous buffer |
| `:e path` | Open a file (<kbd>Tab</kbd> completes) |
| `gf` | Open the file whose name is under the cursor |
| `gx` | Open the URL under the cursor in the browser |
| `:Ex` | Browse the current file's directory: <kbd>Enter</kbd> opens, `-` goes up |
| `:ls` | List buffers |
| `:bd` | Close the buffer |

### The fff picker

`<leader>f` (files), `<leader>g` (grep) and friends open fff. Type to filter.
Files you open often rank higher.

| Key | Does |
| --- | --- |
| `<C-n>` / `<C-p>` or arrows | Move in the list |
| <kbd>Enter</kbd> | Open |
| `<C-s>` / `<C-v>` / `<C-t>` | Open in a split / vertical split / tab |
| `<C-u>` / `<C-d>` | Scroll the preview |
| <kbd>Tab</kbd> | Mark a result |
| `<C-q>` | Send the marked results to the quickfix list |
| `<S-Tab>` | Grep only: cycle plain / regex / fuzzy / definitions |
| `<A-↓>` / `<A-↑>`, or `<C-A-n>` / `<C-A-p>` | Grep only: jump to the next / previous file's results |
| `<C-↑>` / `<C-↓>` | Earlier / later queries |
| <kbd>Esc</kbd> | Close |

Tokens narrow a query, and mix freely with the search text:

| Token | Means |
| --- | --- |
| `src/` | Only under `src/` |
| `!test/`, `!mock` | Leave these out |
| `git:modified` | Only modified files (also `staged`, `untracked`, `deleted`, `renamed`) |
| `src/**/*.{h,cc}` | A glob |
| `*.cc` | Grep only: files with this extension |

For example, `git:modified *.cc ResourceHeap` greps `ResourceHeap` in the `.cc`
files you have changed.

### Searching the project

| Key | Does |
| --- | --- |
| `<leader>g` | Live grep |
| `<leader>w` | Grep the word under the cursor, or the Visual selection |
| `<leader>d` | Grep definitions only (functions, types, classes) |
| `:copen` / `:cclose` | Open / close the quickfix list |
| `]q` / `[q` | Next / previous quickfix entry; `]Q` / `[Q` the last / first |

To change every match: in the grep, mark results with <kbd>Tab</kbd>, send them
with `<C-q>`, then run `:cdo s/old/new/g | update`.

### Code navigation (LSP)

These work once a language server has attached; `:checkhealth vim.lsp` shows
which one did.

| Key | Does |
| --- | --- |
| `gd` | Definition. Greps the word instead when no server knows it (Metal, some HLSL) |
| `gD` | Declaration |
| `<C-]>` / `<C-t>` | Definition through the tag stack / pop back |
| `<C-w>]` | Definition in a split |
| `K` | Hover documentation; `K` again moves into the popup |
| `grr` | References (into the quickfix list) |
| `gri` | Implementations |
| `grt` | Type definition |
| `gO` | Symbols in this file |
| `<leader>s` | Symbols in the whole project |
| `<leader>h` | Switch between header and source (C, C++, CUDA, ObjC) |
| `grn` | Rename the symbol everywhere |
| `gra` | Code actions (fixes, refactorings) |
| `grx` | Run the code lens on this line |
| `<C-s>` | Insert mode: signature help for the call you are typing |
| `:lsp restart` | Restart the servers for this buffer |

After a jump, `<C-o>` comes back.

### Diagnostics

Errors and warnings show at the end of their line, with an underline.

| Key | Does |
| --- | --- |
| `]d` / `[d` | Next / previous diagnostic |
| `]D` / `[D` | Last / first diagnostic in the file |
| `<C-w>d` | Show the full message in a popup |
| `:lua vim.diagnostic.setqflist()` | All diagnostics into the quickfix list |

### Completion

The menu opens by itself while you type in a buffer with a language server.

| Key | Does |
| --- | --- |
| `<C-n>` / `<C-p>` | Next / previous item |
| `<C-y>` | Accept the item (and its imports or edits) |
| `<C-e>` | Close the menu |
| <kbd>Tab</kbd> / `<S-Tab>` | Inside an accepted snippet: next / previous placeholder |
| `<C-x><C-o>` | Open the menu by hand |

### Editing

An operator followed by a motion or a text object edits that much text:

| Operator | | Text object | |
| --- | --- | --- | --- |
| `d` | delete | `iw` / `aw` | word / word and its space |
| `c` | change (delete, then Insert mode) | `i(` / `a(` | inside / around parentheses (also `[` `{` `<`) |
| `y` | copy ("yank") | `i"` / `a"` | inside / around quotes (also `'` and `` ` ``) |
| `>` / `<` | indent / outdent | `ip` | paragraph |
| `=` | re-indent | `it` / `at` | inside / around a tag |
| `gc` | comment / uncomment | | |

For example `ciw` changes a word, `di(` empties the parentheses, `yap` copies a
paragraph, `gcip` comments it out. Doubling an operator acts on the line: `dd`,
`cc`, `yy`, `>>`, `gcc`.

| Key | Does |
| --- | --- |
| `x` | Delete the character |
| `r{c}` | Replace the character with `{c}` |
| `D` / `C` / `Y` | Delete / change / copy to the end of the line |
| `p` / `P` | Paste after / before the cursor |
| `J` | Join the next line onto this one |
| `[<Space>` / `]<Space>` | Add a blank line above / below |
| `qa` … `q` | Record a macro into register `a` |
| `@a` / `@@` / `Q` | Play macro `a` / the last played / the last recorded |
| `"ay`, `"ap` | Copy into / paste from register `a` |
| `"+y`, `"+p` | Copy to / paste from the clipboard (see [below](#between-neovim-tmux-and-the-agents)) |
| `:reg` | Show the registers |

In Visual mode, select first, then press an operator: `d`, `c`, `y`, `>`, `gc`.
`an` grows the selection to the enclosing syntax node (an argument, then the call,
then the statement…), `in` shrinks it again, and `]n` / `[n` move it to the next /
previous node.

In Insert mode: `<C-w>` deletes the word before the cursor, `<C-u>` the line,
`<C-r>a` inserts register `a`, and `<C-o>` runs one Normal-mode command.

### Windows and tabs

A window is a view of a buffer; a tab holds a layout of windows.

| Key | Does |
| --- | --- |
| `<C-w>s` / `:sp file` | Split below |
| `<C-w>v` / `:vs file` | Split to the right |
| `<C-w>h` `j` `k` `l` | Move to the window in that direction |
| `<C-w>w` / `<C-w>p` | Next window / previous window |
| `<C-w>c` or `:q` | Close the window |
| `<C-w>o` | Close all other windows |
| `<C-w>=` | Make all windows the same size |
| `<C-w>_` / `<C-w>\|` | Maximize height / width |
| `<C-w>+` `-` `<` `>` | Grow / shrink height, width (with a count: `10<C-w>>`) |
| `<C-w>H` `J` `K` `L` | Move the window to the far left / bottom / top / right |
| `<C-w>x` | Swap with the next window |
| `<C-w>T` | Move the window to a new tab |
| `gt` / `gT`, `2gt` | Next / previous tab, tab 2 |
| `:tabnew`, `:tabclose` | Open / close a tab |

### Command line

| Key | Does |
| --- | --- |
| <kbd>Tab</kbd> | Complete commands, files, buffers, options (fuzzy, with a menu) |
| `<C-r><C-w>` | Insert the word under the cursor |
| <kbd>↑</kbd> / <kbd>↓</kbd> | Earlier commands starting with what you typed |
| `q:` | Edit the command history in a window |
| `@:` | Repeat the last command |
| `:h topic` | Help, e.g. `:h gd`, `:h text-objects` (`<C-]>` follows links, `<C-o>` goes back) |
| `:checkhealth` | Check the setup |

### Terminal inside Neovim

`:terminal` (or `:vs | terminal`) opens a shell in a window. Press `i` to type in
it and `<C-\><C-n>` to get back to Normal mode, where it scrolls and copies like
any buffer. Inside tmux, a pane is usually simpler.

## Claude Code and Codex

| | Claude Code | Codex |
| --- | --- | --- |
| New line in the prompt | `<C-j>` or `<M-Enter>`; also `\` then <kbd>Enter</kbd> ([per system](#claude-code-and-codex-keys)) | `<C-j>` or `<M-Enter>` |
| Stop the current turn | <kbd>Esc</kbd> | <kbd>Esc</kbd> |
| Commands, file mentions, shell | `/`, `@`, `!` at the start | `/`, `@`, `!` at the start |
| Edit the prompt in an editor | `<C-g>` | `<C-g>` |
| Search prompt history | `<C-r>` | `<C-r>` |
| Change mode | `<S-Tab>` cycles permission modes and plan mode | `<S-Tab>` |
| Full transcript | `<C-o>` | `<C-t>` |
| Paste an image | `<C-v>` (Windows: `<M-v>`) | `<C-v>` (Windows and WSL: `<C-M-v>`) |
| Show all shortcuts | `?` on an empty prompt | `?` on an empty prompt |
| Quit | `<C-c>` twice, or `<C-d>` twice | `<C-c>` on an empty prompt |

- **Shift+Enter** also makes a new line, but only in terminals that report it as
  a separate key, which GNOME Terminal doesn't. `<M-Enter>` is full screen in
  Windows Terminal and WezTerm. `<C-j>` works everywhere.
- **Claude Code's `<C-b>`** (move a running task to the background) is `C-b C-b`
  inside tmux.
- **Scrolling.** Claude Code prints into the pane, so scroll it with tmux: the
  wheel or `C-b [`. Codex draws its own full-screen view: `<C-t>` opens its
  transcript, where `PgUp`/`PgDn` scroll and `F3` searches.
- **Copying out.** Select with the terminal itself (<kbd>Shift</kbd>+drag on
  Linux and Windows; see [the terminal's own keys](#the-terminals-own-keys) for
  macOS) and copy with the terminal's copy key, or use tmux copy mode.
- **`<C-g>` opens `$EDITOR`.** Add `export EDITOR=nvim` to `~/.bashrc` to write
  long prompts in Neovim: save and quit (`:wq`) to hand the text back.

## Between Neovim, tmux and the agents

- **Two kinds of split.** Neovim's `<C-w>h`/`l` move between its own windows;
  tmux's `C-b ←`/`→` move between panes. `C-b z` zooms Neovim to the full screen while
  you read, and the same keys zoom back.
- **Code into a prompt.** In Neovim, select the lines and press `"+y`, then
  `C-b ;` to the agent's pane. On Linux without `xclip` and in WSL, paste with
  `C-b ]` (tmux's buffer); on macOS, or once `xclip` is installed, with the
  terminal's paste key. Either way the newlines stay intact. Shorter still: type
  `@path/to/file` in the prompt and the agent reads the file itself.
- **A file an agent mentions.** In Neovim, `<leader>f` and paste or type part of
  its path; for `file.cc:120`, open it and type `120G`.
- **Agent output into Neovim.** `C-b [` in the agent's pane, select with `v` and
  copy with `y`. Back in Neovim, `"+p` pastes it: tmux's copy and Neovim's `"+`
  register are the same buffer (or, on macOS, the same clipboard).
- **The desktop clipboard on Linux.** Out of the box, nothing in tmux or Neovim
  reaches it under GNOME Terminal. `sudo apt install xclip` connects Neovim's
  `"+` register to it; [the clipboard table](#the-clipboard) has the details for
  each system.
