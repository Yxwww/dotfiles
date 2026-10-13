#!/bin/bash

# setup spaceship-prompt https://github.com/denysdovhan/spaceship-prompt
# Faster startup than oh-my-zsh: 70ms vs 400ms
function setup_zsh_prompt() {
  brew install zsh
  brew install starship
  brew install eza
  brew install fzf
  brew insatll ripgrep
  git clone https://github.com/chriskempson/base16-shell.git ~/.config/base16-shell
}

# herdr (https://herdr.dev) — the multiplexer that replaced zellij here.
# Installs the binary, the agent integrations this machine uses, and the
# vim<->herdr ctrl+hjkl navigation plugin.
#
# Every step is failure-checked: `herdr plugin link` exits 1 on a bad path, and
# a failed clone leaves the ctrl+hjkl feature silently missing, so a swallowed
# error here reports success on a machine where navigation does not work.
setup_herdr() {
  local failed=0

  if ! command -v herdr >/dev/null 2>&1; then
    curl -fsSL https://herdr.dev/install.sh | sh || { echo "setup_herdr: herdr install failed" >&2; return 1; }
  fi

  # agent integrations: session resume + state reporting (regenerated in place)
  for agent in pi claude opencode cursor; do
    herdr integration install "$agent" || { echo "setup_herdr: integration install $agent failed" >&2; failed=1; }
  done

  # ctrl+h/j/k/l across vim/neovim splits and herdr panes.
  # Pinned to a known-good revision: this repo is on the critical path for pane
  # navigation, and tracking upstream master means a force-push or compromise
  # propagates on the next re-run. Bump deliberately.
  local nav_repo=~/git/vim-herdr-navigation
  local nav_ref=742db891e7d1f9a550b16c01dc8a6763f2b1493a
  if [ ! -d "$nav_repo/.git" ]; then
    git clone https://github.com/paulbkim-dev/vim-herdr-navigation.git "$nav_repo" \
      || { echo "setup_herdr: clone of vim-herdr-navigation failed" >&2; return 1; }
  fi
  git -C "$nav_repo" fetch --quiet origin || echo "setup_herdr: WARNING — could not fetch; using local checkout" >&2
  git -C "$nav_repo" checkout --quiet "$nav_ref" \
    || { echo "setup_herdr: checkout of pinned ref $nav_ref failed" >&2; failed=1; }
  herdr plugin link "$nav_repo" || { echo "setup_herdr: plugin link failed; ctrl+hjkl will not work" >&2; failed=1; }

  link_dotfiles || { echo "setup_herdr: link_dotfiles failed" >&2; failed=1; }

  # reload-config is a socket call. On a fresh machine no server exists yet:
  # that exits 1 with server_not_running, which is benign (herdr picks the
  # config up when it next starts). Any other failure is real.
  local rc_out
  rc_out=$(herdr server reload-config 2>&1) || {
    case "$rc_out" in
      *server_not_running*) : ;;
      *) echo "setup_herdr: reload-config failed: $rc_out" >&2; failed=1 ;;
    esac
  }

  [ "$failed" -eq 0 ] || { echo "setup_herdr: completed WITH ERRORS (see above)" >&2; return 1; }
  echo "setup_herdr: ok"
}

setup_js() {
  brew install yarn
}

setup_rust() {
  # https://www.rust-lang.org/tools/install
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
}

# echo "Setup nvim"
setup_neovim() {
  brew install neovim
  yarn global add neovim
}

# echo "link dotfiles"
link_dotfiles() {
  ./linkdotfiles.sh
}

function setup_zsh_autosuggestions() {
  git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
}

function setup_cpp_dev() {
  ln -sf ./configs/coc-settings.json ~/.vim/
  brew install ctags
  brew install ninja

  ## Setup llvm+clang & ccls follows https://github.com/MaskRay/ccls/wiki/Build step by step

  ## SYSTEM HEADER SETUP on OSX :
  ## 1. if missing system headers run: open /Library/Developer/CommandLineTools/Packages/macOS_SDK_headers_for_macOS_10.14. pkg

  ## 2. Use shell script wrapper to wrap ccls to explicitly use the correct CommandLineTools c++ lib instead of the default one
  ## to provide proper c++ lib linting support: https://github.com/MaskRay/ccls/issues/191#issuecomment-453809905
  #!/bin/sh
  #exec /path/to/ccls/Release/ccls -init='{"clang":{"extraArgs":["-isystem", "/Library/Developer/CommandLineTools/usr/include/c++/v1"]}}' "$@"
  ##
}

install_eslint_prettier() {
  yarn global install eslint prettier
  cd ~ && yarn
}

zshrcDeps() {
  brew install reattach-to-user-namespace
}

# pi coding agent — installs pi, links config from this repo, restores the
# skill-creator sparse checkout, and re-adds the global skills recorded in
# configs/pi/agents/skill-lock.json (-> ~/.agents/.skill-lock.json).
#
# Skills are managed by the `skills` CLI (vercel-labs/skills, the "open agent
# skills" ecosystem; npx skills add -g ...). v1.5.7 has no "restore global from
# .skill-lock.json" command (experimental_install only reads a project-level
# skills-lock.json), so we re-add each skill by name. Already-present skills
# are skipped.
setup_pi() {
  npm install -g @earendil-works/pi-coding-agent
  link_dotfiles

  # skill-creator: blob-less sparse checkout of anthropics/skills.
  if [ ! -d ~/.agents/skills/skill-creator-repo ]; then
    git clone --filter=blob:none --sparse https://github.com/anthropics/skills.git ~/.agents/skills/skill-creator-repo
    (cd ~/.agents/skills/skill-creator-repo && git sparse-checkout set skills/skill-creator)
    ln -snf ~/.agents/skills/skill-creator-repo/skills/skill-creator ~/.agents/skills/skill-creator
  fi

  # Re-add global skills listed in ~/.agents/.skill-lock.json (idempotent:
  # skip any whose folder already exists).
  if [ -f ~/.agents/.skill-lock.json ]; then
    node -e '
      const fs = require("fs"), os = require("os"), p = require("path");
      const lock = JSON.parse(fs.readFileSync(p.join(os.homedir(), ".agents", ".skill-lock.json"), "utf8"));
      const skillsDir = p.join(os.homedir(), ".agents", "skills");
      for (const name of Object.keys(lock.skills || {})) {
        if (fs.existsSync(p.join(skillsDir, name))) continue;
        const src = lock.skills[name].source;
        if (!src) continue;
        console.error("[skills] add -g", src, "(" + name + ")");
        const { spawnSync } = require("child_process");
        spawnSync("npx", ["-y", "skills@1.5.7", "add", src, "-g", "-y"], { stdio: "inherit" });
      }
    '
  fi
}

function setup_gh_autocompletion() {
  gh completion -s zsh > ~/.config/zsh/completions/_gh
}

function local_dotfiles() {
  touch ~/.bash_profile
  touch ~/.zshrc_profile
  mkdir -p ~/.zsh/zsh-autosuggestions
  touch ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
}


if [ "$#" -eq 0 ]; then
    echo "Please specify a function to run, or 'all' to run all installation functions."
    exit 1
fi

for arg in "$@"; do
    case $arg in
        local_dotfiles) local_dotfiles ;;
        install_zsh) install_zsh ;;
        setup_pi) setup_pi ;;
        setup_herdr) setup_herdr ;;
        all) install_all ;;
        *) echo "Unknown function: $arg" ;;
    esac
done
