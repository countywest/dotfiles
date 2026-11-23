Dotfiles
========

🏠 Personal dotfiles for \*NIX (macOS and Linux) systems, forked from [wookayin/dotfiles](https://github.com/wookayin/dotfiles).

Installation
------------

### Before installing

`install.py` installs everything else, but expects these on the machine first:

* **macOS**
  * The Xcode Command Line Tools (`xcode-select --install`): `git`, `python3` and a C compiler (for the treesitter parsers).
    Running `git` for the first time also offers to install them.
  * An administrator account: Homebrew, which `install.py` installs if missing, and some apps (e.g. Karabiner-Elements) need `sudo`.
* **Linux** (Ubuntu or Debian, tested on Ubuntu 22.04 and 24.04; x86_64 or aarch64)
  * `git` and `python3` (Ubuntu ships `python3`; `sudo apt install git` if git is missing).
  * `sudo`, to install zsh, curl, wget, build-essential, unzip and python3-venv with `apt`.
    Without sudo, ask the administrator to install these packages; everything else goes into your home directory.
  * Desktops: `fontconfig` (installed on desktops by default) for the D2Coding font. Ghostty itself is not installed by `install.py`.
* Both: internet access, and a terminal to answer the prompts (your password for `sudo` and for changing the shell, and the git user name and email).

### Install

```bash
$ git clone --recursive https://github.com/countywest/dotfiles.git ~/.dotfiles
$ cd ~/.dotfiles && python3 install.py
```

`install.py` sets up everything on a new machine, and skips what is already installed when run again:

* Symbolic links (e.g., `~/.vimrc`) to the files in `~/.dotfiles`. An existing regular file is moved to `<file>.bak`;
  an existing directory (e.g. `~/.vim`) is left alone, see Troubleshooting below.
* macOS: [Homebrew](https://brew.sh) (if missing) and the packages and apps in [`Brewfile`](Brewfile), and the [Karabiner-Elements config](config/karabiner).
* Linux: zsh, curl, wget, build-essential, unzip and python3-venv via `apt`,
  then node, ripgrep, fd, bat, delta, tree-sitter, tmux 3.7+ and neovim into `~/.local/bin`, and the D2Coding font on desktops.
* [Miniforge](https://github.com/conda-forge/miniforge) (conda) into `~/miniforge3`, with `pynvim` for neovim.
* fzf (`~/.fzf`), the zsh, tmux and neovim plugins, zsh as the default shell, and the git user name and email (`~/.gitconfig.secret`).

### After installing (by hand)

* macOS, Karabiner-Elements: on its first launch, allow its driver extension and Input Monitoring in System Settings,
  and set the shortcut for switching the input source to F18 (right command, see [config/karabiner](config/karabiner)).
* Linux desktops: install [Ghostty](https://ghostty.org/docs/install/binary) (its config and font are already in place).


`$ dotfiles`
------------

**To update dotfiles** (pull the latest changes and run [`install.py`][install.py] again):

```bash
$ dotfiles update
$ dotfiles update --fast          # fast update mode: skip updating {vim,zsh} plugins
```

On Linux, you can [install some common softwares locally][linux-locals.sh] (into `$HOME/.local/bin`) *without sudo*:

```bash
$ dotfiles install neovim         # -> ~/.local/bin/nvim
$ dotfiles install ripgrep        # -> ~/.local/bin/rg
$ dotfiles install tmux           # -> ~/.local/bin/tmux
$ dotfiles install delta          # -> ~/.local/bin/delta (git diff pager)
```


🆘 Troubleshooting
------------------

*Please read carefully warning messages during installation !!*

* If something goes wrong, please run **[`$ dotfiles update`][dotfiles-update]** (or [install.py]) to make everything up-to-date.
    * If you have your own `~/.zshrc`, `~/.vimrc`, `~/.vim`, etc., that are NOT symbolic links,
      they will not be overwritten by default.
      In such cases you should delete these files *manually*.

* If you are using [**neovim**][neovim] and seeing any startup errors:
    * Use **neovim 0.12.4 or newer**.
      To install/upgrade neovim on your system, you can run `dotfiles install neovim` (linux) or `brew install neovim` (mac).
    * Try `:checkhealth`.
    * Neovim plugins are managed by [lazy.nvim](https://github.com/folke/lazy.nvim), pinned to the versions in [`nvim/lazy-lock.json`](nvim/lazy-lock.json).
      Run `:Lazy restore` (in neovim) or `$ dotfiles update` to install them.
      To update plugins, run `:Lazy update` and commit `nvim/lazy-lock.json`.
      (Vanilla vim uses vim-plug: `:PlugInstall`.)
    * Python plugins need the [`pynvim`](https://pypi.python.org/pypi/pynvim/) package on the python3 that neovim uses
      (`:echo g:python3_host_prog`): the python3 on `$PATH`, or the conda base python (`~/miniforge3`, where install.py puts pynvim)
      if only that has pynvim. Set `$PYTHON3_HOST_PROG` to use another python.
    * LSP servers are installed and started when a file of their language is opened, except those that would run code
      from the project: pyrefly (the project's `.venv` python) and rust-analyzer (cargo build scripts and proc macros).
      Start them with `:lsp enable pyrefly` or `:lsp enable rust_analyzer` in projects you trust.
      ts_ls uses its own bundled TypeScript, not the project's, and lua_ls asks before loading a project's plugin.

* Icons or symbols (e.g. in the prompt, the tmux status bar, or neovim) are not displayed properly? Do you see some weird letters like `⍰`?
  [Ghostty](https://ghostty.org) needs nothing extra: it has the [Nerd Font](https://github.com/ryanoasis/nerd-fonts) symbols,
  including the Powerline ones, built in. In other terminals, install a Nerd Font (e.g. `brew search nerd-font` on mac) and select it.
* Copying in tmux (`y` in copy mode, or right-click after selecting with the mouse) sets the system clipboard via OSC52,
  which works in terminals such as Ghostty, iTerm2 and kitty, even over SSH. On Linux desktops it also uses `xclip` if installed.
* Does vim color look weird (e.g. only black-and-white)?
  * Check whether your terminal emulator supports 24-bit color (e.g. Ghostty, iTerm2, kitty).
  * Mosh older than 1.4 does not support 24-bit colors.
  * Try `:set notermguicolors` to disable 24-bit colors.
* Does tmux look weird? Make sure that tmux version is 3.7 or higher (`<C-a> ?`, searching key bindings, needs 3.7).
    * On Linux, install.py installs tmux into `$HOME/.local/bin` if it is missing or older (or run `$ dotfiles install tmux`).
* If you still have no idea or have found a bug, please feel free to raise an issue.


[neovim]: https://github.com/neovim/neovim
[dotfiles-update]: bin/dotfiles
[linux-locals.sh]: etc/linux-locals.sh
[install.py]: install.py
