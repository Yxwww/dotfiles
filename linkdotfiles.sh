# link dotfiles to ~/
ln -sf "$(pwd)"/dotfiles/{*,.[^.],.??*} ~/

# Shared shell aliases (single source of truth for zsh + pi/bash). Link explicitly
# and verify bash can actually load them before doing the rest of the install.
ln -sfn "$(pwd)"/dotfiles/.aliases ~/.aliases
if [ ! -f ~/.aliases ] || ! bash -c 'shopt -s expand_aliases; source ~/.aliases; alias -p | grep -q .' >/dev/null 2>&1; then
  echo "linkdotfiles: ERROR — ~/.aliases is missing or failed to load in bash. Aborting." >&2
  exit 1
fi
echo "linkdotfiles: ~/.aliases installed and verified (loads in non-interactive bash)."

CONFIG_HOME=~
GHOSTTY_CONFIG=$CONFIG_HOME/ghostty/config
# git ignore
CONFIG_DIR=~/.config
GIT_CONFIG_DIR=$CONFIG_DIR/git
mkdir -p $GIT_CONFIG_DIR

ln -snf "$(pwd)"/configs/ghostty $CONFIG_DIR

ln -sf "$(pwd)"/configs/git/ignore $GIT_CONFIG_DIR/

# zed
ln -snf "$(pwd)"/configs/zed/keymap.json $CONFIG_DIR/zed
ln -snf "$(pwd)"/configs/zed/settings.json $CONFIG_DIR/zed

# nvim
ln -snf "$(pwd)"/configs/nvim ~/.config

# tmux helper scripts
mkdir -p ~/.tmux
ln -snf "$(pwd)"/scripts ~/.tmux/scripts

# Claude
ln -snf "$(pwd)"/configs/claude/personal.md ~/.claude/CLAUDE.md
ln -snf "$(pwd)"/configs/claude/statusline-command.sh ~/.claude/statusline-command.sh
mkdir -p ~/.claude/skills
ln -snf "$(pwd)"/apps/ports ~/.claude/skills/pf

# pi (https://github.com/earendil-works/pi-coding-agent)
mkdir -p ~/.pi/agent/extensions ~/.pi/agent/npm ~/.agents
ln -sf "$(pwd)"/configs/claude/personal.md ~/.pi/agent/AGENTS.md
ln -sf "$(pwd)"/configs/pi/agent/settings.json ~/.pi/agent/settings.json
ln -sf "$(pwd)"/configs/pi/agent/models.json ~/.pi/agent/models.json
ln -sf "$(pwd)"/configs/pi/agent/extensions/prompt-stash.ts ~/.pi/agent/extensions/prompt-stash.ts
ln -sf "$(pwd)"/configs/pi/agent/extensions/rise-against-header.ts ~/.pi/agent/extensions/rise-against-header.ts
ln -sf "$(pwd)"/configs/pi/agent/extensions/search.json ~/.pi/agent/extensions/search.json
ln -sf "$(pwd)"/configs/pi/agent/extensions/git-workflow-gates.ts ~/.pi/agent/extensions/git-workflow-gates.ts
ln -sf "$(pwd)"/configs/pi/agent/extensions/skill-session-name.ts ~/.pi/agent/extensions/skill-session-name.ts
ln -sf "$(pwd)"/configs/pi/agent/npm/package.json ~/.pi/agent/npm/package.json
ln -sf "$(pwd)"/configs/pi/agent/npm/package-lock.json ~/.pi/agent/npm/package-lock.json
# skill manifest shared across agents; skill dirs themselves are installed by
# the skill manager / sparse-checked-out (see setup_pi in setup.sh)
ln -sf "$(pwd)"/configs/pi/agents/skill-lock.json ~/.agents/.skill-lock.json
mkdir -p ~/.agents/skills
# hand-backed custom skills shared across agents (pre-commit, pre-push,
# pr-catchup, tmux-fanout, ...). Glob the dir so new skills are picked up
# without editing this loop.
for s in "$(pwd)"/configs/pi/agents/skills/*/; do
  ln -snf "$s" ~/.agents/skills/"$(basename "$s")"
done

# pf: build compiled binary
(cd "$(pwd)"/apps/ports && bun install && bun run build)

# iterm2
ln -snf "$(pwd)"/configs/iterm/com.googlecode.iterm2.plist ~/Library/Preferences/com.googlecode.iterm2.plist

# node
# ln -sf "$(pwd)"/configs/node/package.json ~/.config/yarn/global/
# ln -sf "$(pwd)"/configs/node/yarn.lock ~/.config/yarn/global/

# node
# ln -sf "$(pwd)"/configs/node/package.json ~/
# ln -sf "$(pwd)"/configs/node/yarn.lock ~/

# starship
ln -sf "$(pwd)"/configs/starship.toml ~/.config

# code
# ln -sf "$(pwd)"/configs/Code/keybindings.json ~/Library/Application\ Support/Code/User/
# ln -sf "$(pwd)"/configs/Code/settings.json ~/Library/Application\ Support/Code/User/

if [ -d ~/Library/Application\ Support/Cursor ]; then
  ln -sf "$(pwd)"/configs/Cursor/settings.json ~/Library/Application\ Support/Cursor/User/
else
  echo "Directory ~/Library/Application Support/Cursor/User/ does not exist. Skip cursor config linking"
fi
