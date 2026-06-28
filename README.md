# Manifa CLI (`mani`)

Zero-knowledge, end-to-end-encrypted file & `.env` sync for developers. File
contents and filenames are encrypted on your machine — the server only ever
stores ciphertext and never holds your keys.

This repository hosts the **downloadable CLI binaries and the installer**. The
CLI source is closed.

## Install

**macOS / Linux:**

```sh
curl -fsSL https://raw.githubusercontent.com/raymond-UI/manifa-cli/main/install.sh | sh
```

Then:

```sh
mani login      # sign in (points at Manifa production by default)
```

The installer picks the right prebuilt binary for your OS/architecture, verifies
its checksum, and installs `mani` to `/usr/local/bin` (or `~/.local/bin`).
Override the location with `MANI_INSTALL_DIR`, or pin a version with
`MANI_VERSION=cli-v0.1.0`.

On Windows, install under WSL.

## Quick start

```sh
mani login
mani init                 # first machine: creates your keys + recovery code
mani vault create myproj  # encrypt-sync a folder
mani env push myproj .env # encrypt-sync a .env
mani sync                 # push your changes, pull everyone else's
```

Run `mani --help` for the full surface (`clone`, `device`, `watch`, `repair`, …).
