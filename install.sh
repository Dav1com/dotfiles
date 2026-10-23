#!/usr/bin/env bash
# Devcontainer dotfiles installer: fish (as the interactive shell), Claude Code
# CLI, and Helix (with grammars).
#
# Devcontainers run install.sh from the dotfiles repo automatically.
# Override the Helix release with HELIX_VERSION=25.07.1 ./install.sh
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_BIN="$HOME/.local/bin"
HELIX_DIR="$HOME/.local/lib/helix"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

if [ "$(id -u)" -eq 0 ]; then
	SUDO=""
elif command -v sudo >/dev/null 2>&1; then
	SUDO="sudo"
else
	echo "Need root or sudo to install packages" >&2
	exit 1
fi

# --- System packages ----------------------------------------------------------
# fish, plus what Helix needs to fetch (git) and build (C/C++ compiler) grammars.
install_packages() {
	if command -v apt-get >/dev/null 2>&1; then
		export DEBIAN_FRONTEND=noninteractive
		$SUDO apt-get update
		$SUDO apt-get install -y --no-install-recommends \
			fish git curl ca-certificates xz-utils tar build-essential
	elif command -v dnf >/dev/null 2>&1; then
		$SUDO dnf install -y fish git curl ca-certificates xz tar gcc gcc-c++
	elif command -v apk >/dev/null 2>&1; then
		# musl: the upstream Helix tarball is glibc-only, so use Alpine's package.
		# helix-tree-sitter-vendor provides the runtime queries Alpine splits out.
		# libgcc/libstdc++/ripgrep are required by Claude Code's native build.
		$SUDO apk add --no-cache fish git curl ca-certificates bash build-base \
			libgcc libstdc++ ripgrep helix helix-tree-sitter-vendor
	elif command -v pacman >/dev/null 2>&1; then
		$SUDO pacman -Sy --noconfirm --needed fish git curl ca-certificates xz tar base-devel
	else
		echo "Unsupported package manager" >&2
		exit 1
	fi
}

# --- Claude Code --------------------------------------------------------------
install_claude() {
	if command -v claude >/dev/null 2>&1; then
		log "Claude Code already installed"
		return
	fi
	log "Installing Claude Code"
	curl -fsSL https://claude.ai/install.sh | bash
}

# --- Helix --------------------------------------------------------------------
install_helix() {
	if command -v hx >/dev/null 2>&1; then
		log "Helix already installed"
		return
	fi

	local arch
	case "$(uname -m)" in
		x86_64 | amd64) arch="x86_64" ;;
		aarch64 | arm64) arch="aarch64" ;;
		*)
			echo "Unsupported architecture for Helix: $(uname -m)" >&2
			exit 1
			;;
	esac

	local version="${HELIX_VERSION:-}"
	if [ -z "$version" ]; then
		# /releases/latest redirects to /releases/tag/<version>
		version="$(curl -fsSLI -o /dev/null -w '%{url_effective}' \
			https://github.com/helix-editor/helix/releases/latest)"
		version="${version##*/}"
	fi

	log "Installing Helix $version ($arch)"
	local tmp
	tmp="$(mktemp -d)"
	curl -fsSL -o "$tmp/helix.tar.xz" \
		"https://github.com/helix-editor/helix/releases/download/${version}/helix-${version}-${arch}-linux.tar.xz"
	tar -xJf "$tmp/helix.tar.xz" -C "$tmp"

	rm -rf "$HELIX_DIR"
	mkdir -p "$(dirname "$HELIX_DIR")" "$LOCAL_BIN"
	mv "$tmp/helix-${version}-${arch}-linux" "$HELIX_DIR"
	rm -rf "$tmp"

	# hx finds runtime/ next to its resolved executable, so a symlink is enough.
	ln -sf "$HELIX_DIR/hx" "$LOCAL_BIN/hx"
}

# --- Config files -------------------------------------------------------------
# Symlink a repo file into $HOME, backing up any real file already there.
link_file() {
	local source="$DOTFILES_DIR/$1" target="$2"
	mkdir -p "$(dirname "$target")"
	if [ -e "$target" ] && [ ! -L "$target" ]; then
		mv "$target" "$target.bak"
	fi
	ln -sfn "$source" "$target"
}

link_configs() {
	# languages.toml restricts which grammars get fetched/built, so it must be
	# in place before build_helix_grammars runs.
	link_file helix/languages.toml "$HOME/.config/helix/languages.toml"
	link_file fish/conf.d/local-bin.fish "$HOME/.config/fish/conf.d/local-bin.fish"
}

# Append to the image's existing rc files rather than replacing them, so any
# setup the devcontainer image ships with is kept.
hook_fish_into_rc_files() {
	local line=". \"$DOTFILES_DIR/shell/start-fish.sh\""
	local rc
	for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
		if [ "$rc" = "$HOME/.zshrc" ] && ! command -v zsh >/dev/null 2>&1; then
			continue
		fi
		if ! grep -qsF "$line" "$rc"; then
			log "Starting fish from $rc"
			printf '\n# Switch to fish (see %s/shell/start-fish.sh)\n%s\n' \
				"$DOTFILES_DIR" "$line" >>"$rc"
		fi
	done
}

build_helix_grammars() {
	# A few upstream grammar repos occasionally vanish or go private; don't let
	# one bad grammar abort the install, and never block on a credential prompt.
	export GIT_TERMINAL_PROMPT=0
	log "Fetching Helix grammars"
	hx --grammar fetch || log "Warning: some grammars failed to fetch"
	log "Building Helix grammars"
	hx --grammar build || log "Warning: some grammars failed to build"
}

main() {
	install_packages
	export PATH="$LOCAL_BIN:$PATH"
	install_claude
	install_helix
	link_configs
	hook_fish_into_rc_files
	build_helix_grammars
	log "Done. Open a new terminal to start fish."
}

main "$@"
