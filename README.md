Dotfiles
========

🏠 Personal dotfiles for \*NIX (macOS and Linux) systems, forked from [wookayin/dotfiles](https://github.com/wookayin/dotfiles).

Installation
------------

```bash
$ git clone --recursive https://github.com/countywest/dotfiles.git ~/.dotfiles
$ cd ~/.dotfiles && python3 install.py
```

<br>


The installation script creates symbolic links (e.g., `~/.vimrc`) to the files in `~/.dotfiles`, and installs the zsh and (neo)vim plugins.
If target files already exist (e.g. `~/.vim`, `~/.vimrc`), you will need to manually resolve the conflict (delete the old one or just ignore). See Troubleshooting below for details.


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
      (`:echo g:python3_host_prog`): the python3 on `$PATH`, or the conda base python if only that has pynvim.
      Set `$PYTHON3_HOST_PROG` to use another python.
      * pynvim is installed with pip automatically when missing. If that fails (e.g. Debian/Ubuntu's python3 without pip),
        install it yourself, e.g. `conda install pynvim` or `python3 -m pip install --user pynvim`.

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
    * Run `$ dotfiles install tmux` to install `tmux` into `$HOME/.local/bin`, if you do not have sudo.
* If you still have no idea or have found a bug, please feel free to raise an issue.


[neovim]: https://github.com/neovim/neovim
[dotfiles-update]: bin/dotfiles
[linux-locals.sh]: etc/linux-locals.sh
[install.py]: install.py
