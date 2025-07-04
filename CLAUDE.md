# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This repository contains dotfiles and configurations for a development environment on macOS. It includes configurations for:

- Shell environment (zsh with starship prompt)
- Text editors (Neovim, VS Code, Zed, Cursor)
- Terminal configurations (ghostty, tmux)
- Git configurations
- Development tools and utilities

## Key Commands

### Setup and Installation

- `./setup.sh <function_name>` - Run specific setup functions (e.g., `setup_zsh_prompt`, `setup_neovim`, etc.)
- `./linkdotfiles.sh` - Symlink configuration files to their appropriate locations

### Terminal and Shell

- Zellij (terminal multiplexer) layouts:
  - `zellijsimple` - Basic layout
  - `zellijvs` - VS Code terminal layout
  - `zellijstd` - Standard 3-pane layout

### Tmux Italic Setup

To set up italics and true color support in tmux:
1. `tic -x ./scripts/xterm-256color-italic.terminfo`
2. `tic -x ./scripts/tmux-256color.terminfo`

### Vim/Neovim

- Neovim configuration is located in `configs/nvim/`
- Using LazyVim with custom plugins defined in `lua/plugins/`

### Git Workflows

- `fco` - Interactive branch checkout using FZF
- `fbr` - Checkout git branch sorted by most recent commit
- `viewPR` - Interactive GitHub PR view and checkout

## Repository Structure

- `configs/` - Contains configuration files for various applications
  - `Code/` - VS Code configurations
  - `cursor/` - Cursor editor configurations
  - `ghostty/` - Ghostty terminal configurations
  - `git/` - Git configurations
  - `nvim/` - Neovim configurations
  - `zed/` - Zed editor configurations
- `dotfiles/` - Shell configuration files (`.zshrc`, etc.)
- `scripts/` - Utility scripts
- `setup.sh` - Main setup script
- `linkdotfiles.sh` - Script to create symbolic links to configuration files

## Configuration Notes

### Shell Environment

The zsh configuration includes:
- Vim mode with custom keybindings
- FZF integration for fuzzy finding
- Git workflow optimizations
- Zoxide for directory navigation
- Starship prompt

### Development Tools

This environment supports various development tools and languages:
- JavaScript/TypeScript (node, yarn, pnpm, bun)
- Rust
- C/C++
- Zellij for terminal multiplexing
- Ripgrep and FZF for searching

### Editor Features

The Neovim configuration uses LazyVim with custom plugins for:
- Git integration
- AI coding assistance
- Enhanced editing features
- Custom UI elements

## Updating Configurations

When adding new configurations:
1. Add the configuration file to the appropriate directory in `configs/`
2. Update `linkdotfiles.sh` to create the symbolic link
3. If necessary, update `setup.sh` to install required dependencies
