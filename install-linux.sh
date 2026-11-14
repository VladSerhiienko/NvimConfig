#!/bin/sh
# Installs Neovim, the tree-sitter CLI, tmux and the language servers this config uses into
# $PREFIX/opt/<tool>-<version>, with symlinks in $PREFIX/bin. Needs no root. Rerunning it
# replaces the symlinks, so bump a version below and run it again to upgrade.
#
#   sh install-linux.sh                # PREFIX defaults to ~/.local
#   PREFIX=/opt/tools sh install-linux.sh
#
# Rust (rust-analyzer) is not installed here; see README.md. The Nerd Font goes to
# ~/.local/share/fonts; NERD_FONT picks the family (https://www.nerdfonts.com/font-downloads).

set -eu

NVIM=0.12.6
TREESITTER=0.27.2
TMUX_VERSION=3.8
CLANGD=22.1.1
TY=0.0.101
SLANG=2026.22
GLSL_ANALYZER=1.7.1
WGSL_ANALYZER=2026-11-02
NERD_FONTS=3.5.1
NERD_FONT=${NERD_FONT:-UbuntuSans} # Ubuntu's own terminal font, patched

PREFIX=${PREFIX:-$HOME/.local}
O=$PREFIX/opt
B=$PREFIX/bin
GH=https://github.com

missing=
for c in git curl tar gzip xz unzip python3 cc; do
  command -v $c >/dev/null 2>&1 || missing="$missing $c"
done
if [ -n "$missing" ]; then
  echo "install first:$missing (Debian/Ubuntu: sudo apt install git curl unzip xz-utils python3 build-essential)" >&2
  exit 1
fi

m=$(uname -m)
case $m in
  x86_64) arch=x86_64 ts_arch=x64 ;;
  aarch64) arch=arm64 ts_arch=arm64 ;;
  *) echo "no prebuilt tools for $m" >&2; exit 1 ;;
esac

T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
mkdir -p "$O" "$B"

get() { # get <file in $T> <url>
  echo "  $2"
  curl -fsSL -o "$T/$1" "$2"
}
link() { # link <executable> <name in $B>
  chmod +x "$1"
  ln -sf "$1" "$B/$2"
}

echo "Neovim $NVIM"
get nvim.tar.gz $GH/neovim/neovim/releases/download/v$NVIM/nvim-linux-$arch.tar.gz
rm -rf "$O/nvim-$NVIM" && mkdir -p "$O/nvim-$NVIM"
tar xzf "$T/nvim.tar.gz" -C "$O/nvim-$NVIM" --strip-components=1
link "$O/nvim-$NVIM/bin/nvim" nvim

echo "tree-sitter CLI $TREESITTER"
get tree-sitter.gz $GH/tree-sitter/tree-sitter/releases/download/v$TREESITTER/tree-sitter-linux-$ts_arch.gz
rm -rf "$O/tree-sitter-$TREESITTER" && mkdir -p "$O/tree-sitter-$TREESITTER"
gzip -dc "$T/tree-sitter.gz" > "$O/tree-sitter-$TREESITTER/tree-sitter"
link "$O/tree-sitter-$TREESITTER/tree-sitter" tree-sitter

# tmux's own static builds. Distribution packages lag (Ubuntu 24.04 has 3.4), and
# tmux.conf needs 3.6+.
echo "tmux $TMUX_VERSION"
get tmux.tar.gz $GH/tmux/tmux-builds/releases/download/v$TMUX_VERSION/tmux-$TMUX_VERSION-linux-$arch.tar.gz
rm -rf "$O/tmux-$TMUX_VERSION" && mkdir -p "$O/tmux-$TMUX_VERSION"
tar xzf "$T/tmux.tar.gz" -C "$O/tmux-$TMUX_VERSION"
link "$O/tmux-$TMUX_VERSION/tmux" tmux

# clangd's own GitHub releases are x86_64 only; the PyPI wheel also has aarch64. The binary
# finds its builtin headers relative to itself, so bin/ and lib/ stay together.
echo "clangd $CLANGD"
url=$(curl -fsSL https://pypi.org/pypi/clangd/$CLANGD/json | python3 -I -c "
import json, sys
print(next(f['url'] for f in json.load(sys.stdin)['urls'] if 'manylinux' in f['filename'] and '$m' in f['filename']))")
get clangd.whl "$url"
unzip -q "$T/clangd.whl" 'clangd/data/*' -d "$T"
rm -rf "$O/clangd-$CLANGD" && mv "$T/clangd/data" "$O/clangd-$CLANGD"
link "$O/clangd-$CLANGD/bin/clangd" clangd

echo "ty $TY"
get ty.tar.gz $GH/astral-sh/ty/releases/download/$TY/ty-$m-unknown-linux-gnu.tar.gz
rm -rf "$O/ty-$TY" && mkdir -p "$O/ty-$TY"
tar xzf "$T/ty.tar.gz" -C "$O/ty-$TY" --strip-components=1
link "$O/ty-$TY/ty" ty

# Only slangd is linked, so the slangc a project pins (Conan, the Vulkan SDK) is not shadowed.
# On distributions older than glibc 2.28, use the slang-*-glibc-2.27 archive instead.
echo "slangd (Slang $SLANG)"
get slang.tar.gz $GH/shader-slang/slang/releases/download/v$SLANG/slang-$SLANG-linux-$m.tar.gz
rm -rf "$O/slang-$SLANG" && mkdir -p "$O/slang-$SLANG"
tar xzf "$T/slang.tar.gz" -C "$O/slang-$SLANG"
link "$O/slang-$SLANG/bin/slangd" slangd

echo "glsl_analyzer $GLSL_ANALYZER"
get glsl_analyzer.zip $GH/nolanderc/glsl_analyzer/releases/download/v$GLSL_ANALYZER/$m-linux-musl.zip
rm -rf "$O/glsl_analyzer-$GLSL_ANALYZER"
unzip -q "$T/glsl_analyzer.zip" -d "$O/glsl_analyzer-$GLSL_ANALYZER"
link "$O/glsl_analyzer-$GLSL_ANALYZER/bin/glsl_analyzer" glsl_analyzer

echo "wgsl-analyzer $WGSL_ANALYZER"
get wgsl-analyzer.gz $GH/wgsl-analyzer/wgsl-analyzer/releases/download/$WGSL_ANALYZER/wgsl-analyzer-$m-unknown-linux-gnu.gz
rm -rf "$O/wgsl-analyzer-$WGSL_ANALYZER" && mkdir -p "$O/wgsl-analyzer-$WGSL_ANALYZER"
gzip -dc "$T/wgsl-analyzer.gz" > "$O/wgsl-analyzer-$WGSL_ANALYZER/wgsl-analyzer"
link "$O/wgsl-analyzer-$WGSL_ANALYZER/wgsl-analyzer" wgsl-analyzer

# Only the "Nerd Font Mono" styles: their icons fit one terminal cell. Useful only where the
# terminal runs, not on a machine you ssh into.
echo "$NERD_FONT Nerd Font $NERD_FONTS"
get nerd-font.tar.xz $GH/ryanoasis/nerd-fonts/releases/download/v$NERD_FONTS/$NERD_FONT.tar.xz
F=${XDG_DATA_HOME:-$HOME/.local/share}/fonts/${NERD_FONT}NerdFont
rm -rf "$F" && mkdir -p "$F"
tar xJf "$T/nerd-font.tar.xz" -C "$F" --wildcards '*NerdFontMono-*.ttf'
if command -v fc-cache >/dev/null 2>&1; then fc-cache -f "$F"; fi

echo
for t in nvim tree-sitter tmux clangd ty slangd glsl_analyzer wgsl-analyzer; do
  printf '%-14s -> %s\n' "$t" "$(readlink "$B/$t")"
done
printf '%-14s -> %s\n' fonts "$F"
case ":$PATH:" in
  *":$B:"*) ;;
  *) echo; echo "Add $B to PATH, e.g. in ~/.profile: export PATH=\"$B:\$PATH\"" ;;
esac
