#!/bin/sh
# Manifa CLI installer. Downloads the right prebuilt `mani` binary from the latest
# GitHub Release and installs it. Usage:
#
#   curl -fsSL https://beta.manifa.dev/install | sh
#
# Override the install dir with MANI_INSTALL_DIR, or a specific version with
# MANI_VERSION=cli-v0.1.1. No Rust toolchain required.
set -eu

# Public releases repo (the source repo is private/closed; binaries + this script
# live here so anonymous users can download them).
REPO="raymond-UI/manifa-cli"

err() { printf 'install: %s\n' "$1" >&2; exit 1; }

# --- detect platform → release target triple -------------------------------
os="$(uname -s)"
arch="$(uname -m)"
case "$os" in
  Darwin) os_part="apple-darwin" ;;
  Linux)  os_part="unknown-linux-musl" ;;
  *) err "unsupported OS '$os' (macOS and Linux only; on Windows use WSL)" ;;
esac
case "$arch" in
  arm64|aarch64) arch_part="aarch64" ;;
  x86_64|amd64)  arch_part="x86_64" ;;
  *) err "unsupported architecture '$arch'" ;;
esac
target="${arch_part}-${os_part}"

# --- resolve the release tag -----------------------------------------------
tag="${MANI_VERSION:-}"
if [ -z "$tag" ]; then
  # Resolve the latest tag from the releases/latest REDIRECT on github.com, NOT
  # the api.github.com endpoint: the API caps anonymous callers at 60 requests/hr
  # PER IP, which a shared/NAT'd network (office, CI, café) can exhaust — turning
  # `curl | sh` into a 403. The web redirect (…/releases/latest →
  # …/releases/tag/<tag>) has no such limit. Fall back to the API only if the
  # redirect yields nothing.
  tag="$(curl -fsSLI -o /dev/null -w '%{url_effective}' \
      "https://github.com/${REPO}/releases/latest" 2>/dev/null \
    | sed -n 's#.*/releases/tag/##p' | tr -d '\r')"
  if [ -z "$tag" ]; then
    tag="$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" \
      | grep '"tag_name"' | head -1 | cut -d'"' -f4)"
  fi
  [ -n "$tag" ] || err "could not find the latest release (set MANI_VERSION to pin one)"
fi

asset="mani-${target}.tar.gz"
url="https://github.com/${REPO}/releases/download/${tag}/${asset}"

# --- download + verify + install -------------------------------------------
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
printf 'Downloading %s (%s)…\n' "$asset" "$tag"
curl -fsSL "$url" -o "$tmp/$asset" || err "download failed: $url"

# Best-effort checksum verification if the .sha256 is published.
if curl -fsSL "${url}.sha256" -o "$tmp/$asset.sha256" 2>/dev/null; then
  ( cd "$tmp" && (sha256sum -c "$asset.sha256" >/dev/null 2>&1 \
      || shasum -a 256 -c "$asset.sha256" >/dev/null 2>&1) ) \
    || err "checksum verification failed"
fi

tar -xzf "$tmp/$asset" -C "$tmp"

# Pick a writable install dir.
dest="${MANI_INSTALL_DIR:-}"
if [ -z "$dest" ]; then
  if [ -w /usr/local/bin ] 2>/dev/null; then dest="/usr/local/bin"; else dest="$HOME/.local/bin"; fi
fi
mkdir -p "$dest"
mv "$tmp/mani-${target}/mani" "$dest/mani"
chmod +x "$dest/mani"

printf '\nInstalled mani %s to %s/mani\n' "$tag" "$dest"
case ":$PATH:" in
  *":$dest:"*) ;;
  *) printf 'Add it to your PATH:  export PATH="%s:$PATH"\n' "$dest" ;;
esac
printf 'Get started:  mani login\n'
