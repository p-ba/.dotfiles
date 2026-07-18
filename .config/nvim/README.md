# Vim config

## Installation:

    mkdir -p ~/.config/nvim && \
    git clone https://github.com/p-ba/vimrc.git ~/.config/nvim && \
    nvim

## LSP servers

On an interactive Neovim startup, Mason installs and enables `clangd`, `gopls`,
`vtsls`, `lua_ls`, and `eslint` automatically. The first run requires network
access and the toolchains needed by individual servers. Headless Neovim does
not provision missing Mason packages; provision those separately for CI.

`sourcekit` and `phpantom` remain local opt-in servers because they depend on
platform- or project-specific executables.
