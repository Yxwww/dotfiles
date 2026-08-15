#!/bin/bash

# setup spaceship-prompt https://github.com/denysdovhan/spaceship-prompt
# Faster startup than oh-my-zsh: 70ms vs 400ms
function setup_zsh_prompt() {
  brew install zsh
  brew install starship
  brew install zellij
  brew install eza
  brew install fzf
  brew insatll ripgrep
  git clone https://github.com/chriskempson/base16-shell.git ~/.config/base16-shell
}

setup_zellij() {
  ln -sf ~/.config/zellij/config.kdl ./configs/zellij/config.kdl 
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
        all) install_all ;;
        *) echo "Unknown function: $arg" ;;
    esac
done
