#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract data from JSON
current_dir=$(echo "$input" | jq -r '.workspace.current_dir')
vim_mode=$(echo "$input" | jq -r '.vim.mode // empty')
model_name=$(echo "$input" | jq -r '.model.display_name // empty')
context_used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Get basic info
username=$(whoami)
hostname=$(hostname -s)

# Use full path for directory display
directory="$current_dir"
# Shorten home directory to ~
directory="${directory/#$HOME/\~}"

# Git information (with error handling, skip optional locks)
git_info=""
git_status_info=""
if git -c core.useBuiltinFSMonitor=false rev-parse --git-dir > /dev/null 2>&1; then
    # Get branch name
    branch=$(git -c core.useBuiltinFSMonitor=false rev-parse --abbrev-ref HEAD 2>/dev/null)

    # Get git status with minimal output (skip optional locks)
    status_output=$(git -c core.useBuiltinFSMonitor=false status --porcelain 2>/dev/null)

    # Count different types of changes
    modified=$(echo "$status_output" | grep -E '^.M|^ M' | wc -l | tr -d ' ')
    staged=$(echo "$status_output" | grep -E '^M|^A|^D|^R' | wc -l | tr -d ' ')
    untracked=$(echo "$status_output" | grep '^??' | wc -l | tr -d ' ')

    # Build git status symbols (matching Starship format)
    git_symbols=""
    if [ "$modified" -gt 0 ] || [ "$staged" -gt 0 ] || [ "$untracked" -gt 0 ]; then
        git_symbols="*"
    fi

    if [ -n "$branch" ]; then
        # Branch name in bright-black (dim)
        git_info=$(printf " \033[2m[%s]\033[0m" "$branch")

        # Git status in cyan (if there are changes)
        if [ -n "$git_symbols" ]; then
            git_status_info=$(printf " \033[36m[%s]\033[0m" "$git_symbols")
        fi
    fi
fi

# Node.js version (if available)
node_info=""
if command -v node > /dev/null 2>&1; then
    node_version=$(node --version 2>/dev/null | sed 's/v//' | cut -d. -f1)
    if [ -n "$node_version" ]; then
        # Bright-black (dim) for node version
        node_info=$(printf " \033[2mvia [n(%s)]\033[0m" "$node_version")
    fi
fi

# Package version (if package.json exists)
package_info=""
if [ -f "$current_dir/package.json" ]; then
    package_version=$(jq -r '.version' "$current_dir/package.json" 2>/dev/null)
    if [ -n "$package_version" ] && [ "$package_version" != "null" ]; then
        # Bold orange (208) for package version
        package_info=$(printf " \033[1;38;5;208m[v%s]\033[0m" "$package_version")
    fi
fi

# Model name
model_info=""
if [ -n "$model_name" ]; then
    model_info=$(printf " \033[2m[%s]\033[0m" "$model_name")
fi

# Context window usage
context_info=""
if [ -n "$context_used" ]; then
    # Round to nearest integer
    pct=$(printf "%.0f" "$context_used")
    # Color: green <50%, yellow 50-79%, red >=80%
    if [ "$pct" -ge 80 ]; then
        color="\033[31m"
    elif [ "$pct" -ge 50 ]; then
        color="\033[33m"
    else
        color="\033[32m"
    fi
    context_info=$(printf " ${color}[ctx:%s%%]\033[0m" "$pct")
fi

# Python virtual environment
python_info=""
if [ -n "$VIRTUAL_ENV" ]; then
    venv_name=$(basename "$VIRTUAL_ENV")
    # Bright-black (dim) for python venv
    python_info=$(printf "\n\033[2m[%s]\033[0m " "$venv_name")
fi

# Character indicator (matching Starship's character module with vim mode support)
character=""
if [ "$vim_mode" = "NORMAL" ]; then
    character=$(printf "\n\033[32m❮\033[0m ")
else
    # Default to success symbol (purple ❯)
    character=$(printf "\n\033[35m❯\033[0m ")
fi

# Build the status line with colors matching Starship theme
# Format: username@hostname directory git_branch git_status node package model ctx
#         python (if present)
#         character
printf "\033[2m%s@%s\033[0m \033[34m%s\033[0m%s%s%s%s%s%s%s%s" \
    "$username" \
    "$hostname" \
    "$directory" \
    "$git_info" \
    "$git_status_info" \
    "$node_info" \
    "$package_info" \
    "$model_info" \
    "$context_info" \
    "$python_info" \
    "$character"