#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract data from JSON
current_dir=$(echo "$input" | jq -r '.workspace.current_dir')
vim_mode=$(echo "$input" | jq -r '.vim.mode // empty')
model_name=$(echo "$input" | jq -r '.model.display_name // empty')
context_used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Compact pwd: shorten each parent segment to 1 char, keep last segment full
_compact_pwd() {
    local path="${1/#$HOME/~}"
    # Split on /
    local IFS='/'
    read -ra parts <<< "$path"
    local result=""
    local count=${#parts[@]}
    for (( i=0; i<count-1; i++ )); do
        local seg="${parts[$i]}"
        if [ -z "$seg" ]; then
            # leading slash
            result+="/"
        elif [ "$seg" = "~" ]; then
            result+="~/"
        else
            result+="${seg:0:1}/"
        fi
    done
    result+="${parts[$((count-1))]}"
    echo "$result"
}
directory=$(_compact_pwd "$current_dir")

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
        # Strip common branch prefixes
        branch_short="$branch"
        for prefix in feature/ fix/ bugfix/ hotfix/ chore/ refactor/ feat/; do
            branch_short="${branch_short#$prefix}"
        done
        # Truncate to 20 chars with ellipsis
        if [ "${#branch_short}" -gt 20 ]; then
            branch_short="${branch_short:0:20}…"
        fi
        # Branch name in bright-black (dim)
        git_info=$(printf " \033[2m[%s]\033[0m" "$branch_short")

        # Git status in cyan (if there are changes)
        if [ -n "$git_symbols" ]; then
            git_status_info=$(printf " \033[36m[%s]\033[0m" "$git_symbols")
        fi
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

# Model name (compact short codes)
model_info=""
if [ -n "$model_name" ]; then
    case "$model_name" in
        *opus-4-6*|*opus*)   model_short="o4.6" ;;
        *sonnet-4-6*)        model_short="s4.6" ;;
        *haiku-4-5*|*haiku*) model_short="h4.5" ;;
        *sonnet-3-5*|*sonnet-3.5*) model_short="s3.5" ;;
        *) # fallback: first letter of tier + version number
           stripped="${model_name#claude-}"
           first="${stripped:0:1}"
           version=$(echo "$stripped" | grep -oE '[0-9]+[-\.][0-9]+' | head -1 | tr '-' '.')
           model_short="${first}${version:-$stripped}" ;;
    esac
    model_info=$(printf " \033[2m[%s]\033[0m" "$model_short")
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
    context_info=$(printf " ${color}[%s%%]\033[0m" "$pct")
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
# Format: directory git_branch git_status package model ctx
#         python (if present)
#         character
printf "\033[34m%s\033[0m%s%s%s%s%s%s%s" \
    "$directory" \
    "$git_info" \
    "$git_status_info" \
    "$package_info" \
    "$model_info" \
    "$context_info" \
    "$python_info" \
    "$character"