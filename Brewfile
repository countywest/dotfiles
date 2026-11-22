# macOS packages and apps used by these dotfiles, installed by install.py (`brew bundle --no-upgrade`) when missing.

# shell, editors and terminal tools
brew "neovim"
brew "vim"
brew "tmux"
brew "tree-sitter-cli"   # nvim-treesitter builds the parsers with it
brew "node"              # LSP servers installed by mason (e.g. pyright) run on node
brew "ripgrep"           # fzf (Ctrl-T), rg.fzf, and grep in neovim
brew "fd"                # file lists in neovim (fzf-lua)
brew "bat"               # previews in fzf and rg.fzf
brew "git-delta"         # git pager, see git/gitconfig
brew "htop"              # `top` runs htop, see zsh/zsh.d/alias.zsh
brew "ffmpeg"            # used by video2gif (~/.local/bin)

# apps and fonts; an app already installed some other way (e.g. from a .dmg) is left alone
cask "ghostty" unless File.exist?("/Applications/Ghostty.app")
cask "karabiner-elements" unless File.exist?("/Applications/Karabiner-Elements.app")   # see config/karabiner
cask "font-d2coding"     # the terminal font, see config/ghostty/config
