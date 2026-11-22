#!/usr/bin/env python3
# -*- coding: utf-8 -*-

'''
   @wookayin's              ███████╗██╗██╗     ███████╗███████╗
   ██████╗  █████╗ ████████╗██╔════╝██║██║     ██╔════╝██╔════╝
   ██╔══██╗██╔══██╗╚══██╔══╝█████╗  ██║██║     █████╗  ███████╗
   ██║  ██║██║  ██║   ██║   ██╔══╝  ██║██║     ██╔══╝  ╚════██║
   ██████╔╝╚█████╔╝   ██║   ██║     ██║███████╗███████╗███████║
   ╚═════╝  ╚════╝    ╚═╝   ╚═╝     ╚═╝╚══════╝╚══════╝╚══════╝

   https://dotfiles.wook.kr/
'''
print(__doc__)  # print logo.


import argparse
parser = argparse.ArgumentParser()
parser.add_argument('-f', '--force', action="store_true", default=False,
                    help='If set, it will override existing symbolic links')
parser.add_argument('--skip-vimplug', action='store_true',
                    help='If set, do not update vim plugins.')
parser.add_argument('--skip-zplug', action='store_true',
                    help='If set, skip update of zsh plugins.')

args = parser.parse_args()

################# BEGIN OF FIXME #################

# Task Definition
# (path of target symlink) : (location of source file in the repository)
tasks = {
    # SHELLS
    '~/.bashrc' : 'bashrc',
    '~/.screenrc' : 'screenrc',

    # VIM
    '~/.vimrc' : 'vim/vimrc',
    '~/.vim' : 'vim',
    '~/.vim/autoload/plug.vim' : 'vim/bundle/vim-plug/plug.vim',

    # NeoVIM
    '~/.config/nvim' : 'nvim',

    # GIT
    '~/.gitconfig' : 'git/gitconfig',
    '~/.gitignore' : 'git/gitignore',

    # ZSH
    '~/.zsh'      : 'zsh',
    '~/.zlogin'   : 'zsh/zlogin',
    '~/.zlogout'  : 'zsh/zlogout',
    '~/.zpreztorc': 'zsh/zpreztorc',
    '~/.zprofile' : 'zsh/zprofile',
    '~/.zshenv'   : 'zsh/zshenv',
    '~/.zshrc'    : 'zsh/zshrc',

    # Bins
    '~/.local/bin/dotfiles' : 'bin/dotfiles',
    '~/.local/bin/fasd' : 'zsh/fasd/fasd',
    '~/.local/bin/is_mosh' : 'zsh/is_mosh/is_mosh',
    '~/.local/bin/fzf' : dict(src='~/.fzf/bin/fzf', force=True),

    # X
    '~/.Xmodmap' : 'Xmodmap',

    # GTK
    '~/.gtkrc-2.0' : 'gtkrc-2.0',

    # kitty
    '~/.config/kitty/kitty.conf': 'config/kitty/kitty.conf',

    # ghostty (terminal) and herdr
    '~/.config/ghostty/config' : 'config/ghostty/config',
    '~/.config/herdr/config.toml' : 'config/herdr/config.toml',

    # tmux
    '~/.tmux'      : 'tmux',
    '~/.tmux.conf' : 'tmux/tmux.conf',

    # .config (XDG-style)
    '~/.config/terminator' : 'config/terminator',
    '~/.config/pudb/pudb.cfg' : 'config/pudb/pudb.cfg',
    '~/.config/fsh/wook.ini' : 'config/fsh/wook.ini',

    # pip and python
    #'~/.pip/pip.conf' : 'pip/pip.conf',
    '~/.pythonrc.py' : 'python/pythonrc.py',
    '~/.pylintrc' : 'python/pylintrc',
    '~/.condarc' : 'python/condarc',
    '~/.config/pycodestyle' : 'python/pycodestyle',
    '~/.ptpython/config.py' : dict(action="remove"),
    '~/.config/ptpython/config.py' : 'python/ptpython.config.py',
}


import os
import platform

# Make sure the CWD is the root of dotfiles.
__PATH__ = os.path.abspath(os.path.dirname(__file__))
os.chdir(__PATH__)


post_actions = []
post_actions += [  # Check symbolic link at $HOME
    '''#!/bin/bash
    # Check whether ~/.vim and ~/.zsh are well-configured
    for f in ~/.vim ~/.zsh ~/.vimrc ~/.zshrc; do
        if ! readlink $f >/dev/null; then
            echo -e "\033[0;31m\
WARNING: $f is not a symbolic link to ~/.dotfiles.
Please remove your local folder/file $f and try again.\033[0m"
            echo -n "(Press any key to continue) "; read user_confirm
            exit 1;
        else
            echo "$f --> $(readlink $f)"
        fi
    done
''']

post_actions += [  # system packages (linux)
    r'''#!/bin/bash
    # Linux: install the system packages needed by the next steps and by neovim (apt, if missing)
    missing=()
    _need() { eval "$1" >/dev/null 2>&1 || missing+=("$2"); }
    _need 'type zsh'  zsh
    _need 'type curl' curl
    _need 'type wget' wget
    _need 'type make && type cc' build-essential        # nvim-treesitter compiles the parsers
    _need 'type unzip' unzip                            # mason: LSP servers shipped as .zip
    _need 'python3 -c "import ensurepip"' python3-venv  # mason: venvs for pip-based LSP servers
    if [ ${#missing[@]} -eq 0 ]; then
        echo "All installed: zsh, curl, wget, build-essential, unzip, python3-venv"; exit 0
    fi
    if ! type apt-get >/dev/null 2>&1; then
        echo -e "\033[0;33mPlease install these packages yourself: ${missing[*]}\033[0m"; exit 1
    fi
    if [ "$(id -u)" = 0 ]; then
        sudo=""
    elif type sudo >/dev/null 2>&1 && { sudo -n true 2>/dev/null || id -nG | grep -qwE 'sudo|admin|wheel'; }; then
        sudo="sudo"
    else
        echo -e "\033[0;33mNo sudo: ask the administrator to install ${missing[*]}\033[0m"
        type zsh >/dev/null 2>&1 || bin/dotfiles install zsh   # zsh can be built into ~/.local
        exit 1
    fi
    $sudo apt-get update && $sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y "${missing[@]}"
'''] if platform.system() == "Linux" else []

post_actions += [  # macOS
    r'''#!/bin/bash
    # macOS: install Homebrew (if missing) and the packages and apps in Brewfile
    if ! type brew >/dev/null 2>&1; then
        echo "Installing Homebrew (https://brew.sh) ..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || exit 1
        type brew >/dev/null 2>&1 || { echo "Homebrew installation failed"; exit 1; }
    fi
    brew bundle check --no-upgrade --file=Brewfile || brew bundle install --no-upgrade --file=Brewfile || exit 1

    # Karabiner-Elements: copied, not linked (it replaces a symlinked karabiner.json with a copy)
    k=~/.config/karabiner/karabiner.json
    if [ ! -f "$k" ]; then
        mkdir -p ~/.config/karabiner && cp config/karabiner/karabiner.json "$k" && echo "Copied: $k"
    elif ! cmp -s config/karabiner/karabiner.json "$k"; then
        echo -e "\033[0;33m$k differs from config/karabiner/karabiner.json (left as is)\033[0m"
    fi
'''] if platform.system() == "Darwin" else []

post_actions += [  # install some essential packages (linux)
    r'''#!/bin/bash
    # Install node, rg, fd, bat, delta and tree-sitter locally, if missing
    # (Debian's batcat and fdfind do not count: zsh/zsh.d/envs.zsh looks for bat and fd)
    ret=0
    type node  >/dev/null 2>&1 || bin/dotfiles install node    || ret=1
    type rg    >/dev/null 2>&1 || bin/dotfiles install ripgrep || ret=1
    type fd    >/dev/null 2>&1 || bin/dotfiles install fd      || ret=1
    type bat   >/dev/null 2>&1 || bin/dotfiles install bat     || ret=1
    type delta >/dev/null 2>&1 || bin/dotfiles install delta   || ret=1

    # Required by neovim: nvim-treesitter builds parsers with `tree-sitter build` (tree-sitter CLI 0.25+;
    # e.g. Ubuntu 24.04's apt package is 0.20, too old)
    ts_ver=$(tree-sitter --version 2>/dev/null | cut -d' ' -f2)
    if [ "$(printf '%s\n' 0.25.0 "${ts_ver:-0}" | sort -V | head -n1)" != 0.25.0 ]; then
        bin/dotfiles install tree-sitter || ret=1
    else
        echo "tree-sitter $ts_ver"
    fi
    exit $ret
    ''',

    '''#!/bin/bash
    # Install the D2Coding font (the terminal font, see config/ghostty/config) on desktops
    if ! type fc-list >/dev/null 2>&1; then
        echo "fontconfig not found (not a desktop), skipped"
    elif fc-list | grep -qi d2coding; then
        echo "D2Coding is installed."
    else
        bin/dotfiles install d2coding
    fi
    ''',
] if platform.system() == "Linux" else []

post_actions += [  # miniforge
    r'''#!/bin/bash
    # Install miniforge (conda) into ~/miniforge3, with pynvim in its base env (for neovim)
    set -e
    if [ ! -x ~/miniforge3/bin/conda ]; then
        tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
        curl -fL -o "$tmp/miniforge.sh" \
            "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
        bash "$tmp/miniforge.sh" -b -p ~/miniforge3
    fi
    ~/miniforge3/bin/conda --version
    ~/miniforge3/bin/python3 -c 'import pynvim' 2>/dev/null || ~/miniforge3/bin/python3 -m pip install pynvim
    ~/miniforge3/bin/python3 -c 'import pynvim; print("pynvim", pynvim.__version__)'
''']

post_actions += [  # fzf
    r'''#!/bin/bash
    # Install fzf into ~/.fzf (used by zsh and neovim), if missing
    set -e
    [ -d ~/.fzf ] || git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    # the fzf binary and ~/.fzf.zsh (sourced by zsh/zshrc); the shell rc files are left untouched
    [ -x ~/.fzf/bin/fzf ] && [ -f ~/.fzf.zsh ] || ~/.fzf/install --all --no-update-rc
    ~/.fzf/bin/fzf --version
''']

post_actions += [  # video2gif
    '''#!/bin/bash
    # Download command line scripts (if missing)
    mkdir -p "$HOME/.local/bin/"
    _download() {
        [ -x "$1" ] && echo "$1 exists" && return
        curl -fL "$2" > "$1" && chmod +x "$1"
    }
    ret=0
    set -v
    # pinned to a commit: an executable put on $PATH should not change with a branch
    _download "$HOME/.local/bin/video2gif" "https://raw.githubusercontent.com/wookayin/video2gif/f6299b19e6d357602f73177c69be08d70395c3dd/video2gif" || ret=1
    exit $ret;
''']

post_actions += [  # antidote (zsh plugins)
    '''#!/bin/bash
    # Update zsh bundles and cache (the init file)
    zsh -c "
        # source zsh plugin manager and list plugins
        DOTFILES_UPDATE=1 __p9k_instant_prompt_disabled=1 source ${HOME}/.zshrc
        if ! which antidote > /dev/null; then
            echo -e '\033[0;31m\
ERROR: antidote not found. Double check the submodule exists, and you have a valid ~/.zshrc!\033[0m'
            ls -alh ~/.zsh/antidote/
            ls -alh ~/.zshrc
            exit 1;
        fi
        antidote update
        antidote reset
    "
    ''' if not args.skip_zplug else \
        '# zsh plugins update (Skipped)'
]

post_actions += [  # tmux plugins
    r'''#!/bin/bash
    # Check tmux version >= 3.7 (on Linux, installs one into ~/.local/bin if missing or older)
    _version_check() {    # target_ver current_ver
        [ "$1" = "$(echo -e "$1\n$2" | sort -s -t- -k 2,2n | sort -t. -s -k 1,1n -k 2,2n | head -n1)" ]
    }
    if ! type tmux >/dev/null 2>&1 || ! _version_check "3.7" "$(tmux -V | cut -d' ' -f2)"; then
        if [[ `uname` == "Linux" ]]; then
            echo -e "\033[0;33mInstalling tmux into ~/.local/bin ($(tmux -V 2>/dev/null || echo 'tmux not found')).\033[0m"
            bin/dotfiles install tmux || exit 1
        else
            echo -e "\033[0;33m$(tmux -V 2>/dev/null || echo 'tmux not found'): tmux 3.7+ is required (brew upgrade tmux)\033[0m"
            exit 1;
        fi
    fi
    echo "$(which tmux): $(tmux -V)"
''',
    # Install tmux plugins via tpm
    '~/.tmux/plugins/tpm/bin/install_plugins',
]

post_actions += [  # default shell
    r'''#!/bin/bash
    # Change default shell to zsh
    /bin/zsh --version >/dev/null || (\
        echo -e "\033[0;31mError: /bin/zsh not found. Please install zsh.\033[0m"; exit 1)
    if [[ ! "$SHELL" = *zsh ]]; then
        echo -e '\033[0;33mPlease type your password if you wish to change the default shell to ZSH\e[m'
        chsh -s /bin/zsh && echo -e 'Successfully changed the default shell, please re-login'
    else
        echo -e "\033[0;32m\$SHELL is already zsh.\033[0m $(zsh --version)"
    fi
''']

post_actions += [  # neovim
    '''#!/bin/bash
    # check the neovim version (offers a local install on Linux if missing or outdated)
    bash "etc/install-neovim.sh"
''']

post_actions += [  # neovim plugins (lazy.nvim); vanilla vim uses vim-plug via :PlugInstall
    {'update'  : '''# vim plugins: install, and check out the versions in nvim/lazy-lock.json
        # (to update plugins: `:Lazy update` in nvim, then commit nvim/lazy-lock.json)
        # and wait for the treesitter parsers to be built (exiting earlier leaves broken parser dirs)
        nvim --headless \
            -c "lua require('lazy').restore { wait = true }" \
            -c "lua require('config.treesitter').install_parsers_sync()" \
            -c "lua require('config.plugins').report_errors { exit = true }"
        ''',
     'none'    : '# vim plugins: skipped',
     }['update' if not args.skip_vimplug else 'none']
    + '\n' +
    r'''#!/bin/bash
    if [[ -n "~/.vim/plugged/*.cloning(#qN)" ]]; then
        echo "Cleaning up plugin installation artifacts..."
        rm -fv ~/.vim/plugged/*.cloning
    fi
    '''
]

post_actions += [  # gitconfig.secret
    r'''#!/bin/bash
    # Create ~/.gitconfig.secret file and check user configuration
    if [ ! -f ~/.gitconfig.secret ]; then
        cat > ~/.gitconfig.secret <<EOL
# vim: set ft=gitconfig:
EOL
    fi
    if ! git config --file ~/.gitconfig.secret user.name 2>&1 > /dev/null || \
       ! git config --file ~/.gitconfig.secret user.email 2>&1 > /dev/null; then echo -ne '
    \033[1;33m[!!!] Please configure git user name and email:
        git config --file ~/.gitconfig.secret user.name "(YOUR NAME)"
        git config --file ~/.gitconfig.secret user.email "(YOUR EMAIL)"
\033[0m'
        echo -en '\n'
        echo -en "(git config user.name) \033[0;33m Please input your name  : \033[0m"; read git_username
        echo -en "(git config user.email)\033[0;33m Please input your email : \033[0m"; read git_useremail
        if [[ -n "$git_username" ]] && [[ -n "$git_useremail" ]]; then
            git config --file ~/.gitconfig.secret user.name "$git_username"
            git config --file ~/.gitconfig.secret user.email "$git_useremail"
        else
            exit 1;   # error
        fi
    fi

    # get the current config
    echo -en '\033[0;32m';
    echo -en 'user.name  : '; git config --file ~/.gitconfig.secret user.name
    echo -en 'user.email : '; git config --file ~/.gitconfig.secret user.email
    echo -en '\033[0m';
''']


################# END OF FIXME #################


def _wrap_colors(ansicode):
    return (lambda msg: ansicode + str(msg) + '\033[0m')
GRAY   = _wrap_colors("\033[0;37m")
WHITE  = _wrap_colors("\033[1;37m")
RED    = _wrap_colors("\033[0;31m")
GREEN  = _wrap_colors("\033[0;32m")
YELLOW = _wrap_colors("\033[0;33m")
CYAN   = _wrap_colors("\033[0;36m")
BLUE   = _wrap_colors("\033[0;34m")


import os
import sys
import subprocess

from signal import signal, SIGPIPE, SIG_DFL
from sys import stderr

if sys.version_info[0] >= 3:  # python3
    unicode = lambda s, _: str(s)
    from builtins import input
else:  # python2
    input = sys.modules['__builtin__'].raw_input


def log(msg, cr=True):
    stderr.write(msg)
    if cr:
        stderr.write('\n')

def log_boxed(msg, color_fn=WHITE, use_bold=False, len_adjust=0):
    import unicodedata
    pad_msg = (" " + msg + "  ")
    l = sum(not unicodedata.combining(ch) for ch in unicode(pad_msg, 'utf-8')) + len_adjust
    if use_bold:
        log(color_fn("┏" + ("━" * l) + "┓\n" +
                     "┃" + pad_msg   + "┃\n" +
                     "┗" + ("━" * l) + "┛\n"), cr=False)
    else:
        log(color_fn("┌" + ("─" * l) + "┐\n" +
                     "│" + pad_msg   + "│\n" +
                     "└" + ("─" * l) + "┘\n"), cr=False)

def makedirs(target, mode=511, exist_ok=False):
    try:
        os.makedirs(target, mode=mode)
    except OSError as ex:  # py2 has no exist_ok=True
        import errno
        if ex.errno == errno.EEXIST and exist_ok: pass
        else: raise

# get current directory (absolute path)
current_dir = os.path.abspath(os.path.dirname(__file__))
os.chdir(current_dir)

# check if git submodules are loaded properly
stat = subprocess.check_output("git submodule status --recursive",
                               shell=True, universal_newlines=True)
submodule_issues = [(l.split()[1], l[0]) for l in stat.split('\n') if len(l) and l[0] != ' ']

if submodule_issues:
    stat_messages = {'+': 'needs update', '-': 'not initialized', 'U': 'conflict!'}
    for (submodule_name, submodule_stat) in submodule_issues:
        log(RED("git submodule {name} : {status}".format(
            name=submodule_name,
            status=stat_messages.get(submodule_stat, '(Unknown)'))))
    log(YELLOW("Git submodules are not initialized.\n"))

    update_submodule = True
    if update_submodule:
        git_submodule_update_cmd = 'git submodule update --init --recursive'
        # git 2.8+ supports parallel submodule fetching
        try:
            git_version = str(subprocess.check_output("""git --version | awk '{print $3}'""", shell=True))
            if git_version >= '2.8': git_submodule_update_cmd += ' --jobs 8'
        except Exception as ex:
            pass
        log("Running: %s" % CYAN(git_submodule_update_cmd))
        subprocess.call(git_submodule_update_cmd, shell=True)
    else:
        log(RED("Aborted."))
        sys.exit(1)


log_boxed("Creating symbolic links", color_fn=CYAN)
for target, item in sorted(tasks.items()):
    # normalize paths
    if isinstance(item, str):
        item = {'src': item}

    source, force = item.get('src', None), item.get('force', False)

    if source:
        source = os.path.join(current_dir, os.path.expanduser(source))
    target = os.path.expanduser(target)

    if item.get('action', None) == 'remove':
        try:
            os.unlink(target)
        except OSError:  # FileNotFoundError
            pass
        continue

    # bad entry if source does not exists...
    if force:
        pass  # Even if the source does not exist, always make a symlink
    elif not os.path.lexists(source):
        log(RED("source %s : does not exist" % source))
        continue

    # a regular file (e.g. the default ~/.bashrc of a new account) is moved aside to make the link
    if os.path.isfile(target) and not os.path.islink(target) and not os.path.lexists(target + '.bak'):
        os.rename(target, target + '.bak')
        log("{:50s} : {}".format(BLUE(target), YELLOW("moved to %s.bak" % target)))

    # if --force option is given, delete and override the previous symlink
    if os.path.lexists(target):
        is_broken_link = os.path.islink(target) and not os.path.exists(os.readlink(target))

        if args.force or is_broken_link:
            if os.path.islink(target):
                os.unlink(target)
            else:
                log("{:50s} : {}".format(
                    BLUE(target),
                    YELLOW("already exists but not a symbolic link; --force option ignored")
                ))
        else:
            log("{:50s} : {}".format(
                BLUE(target),
                GRAY("already exists, skipped") if os.path.islink(target) \
                    else YELLOW("exists, but not a symbolic link. Check by yourself!!")
            ))

    # make a symbolic link if available
    if not os.path.lexists(target):
        mkdir_target = os.path.split(target)[0]
        if not os.path.isdir(mkdir_target):
            makedirs(mkdir_target)
            log(GREEN('Created directory : %s' % mkdir_target))
        os.symlink(source, target)
        log("{:50s} : {}".format(
            BLUE(target),
            GREEN("symlink created from '%s'" % source)
        ))

# What a step installs (Homebrew, ~/.local/bin) must be found by the later steps,
# before a new shell would put it on $PATH (see zsh/zshenv)
os.environ['PATH'] = os.pathsep.join(
    [os.path.expanduser('~/.local/bin'), os.environ.get('PATH', ''), '/opt/homebrew/bin', '/usr/local/bin'])

errors = []
for action in post_actions:
    if not action:
        continue

    action_title = action.strip().split('\n')[0].strip()
    if action_title == '#!/bin/bash':
        action_title = action.strip().split('\n')[1].strip()

    log("\n", cr=False)
    log_boxed("Executing: " + action_title, color_fn=CYAN)
    ret = subprocess.call(['bash', '-c', action],
                          preexec_fn=lambda: signal(SIGPIPE, SIG_DFL))

    if ret:
        errors.append(action_title)

log("\n")
if errors:
    log_boxed("You have %3d warnings or errors -- check the logs!" % len(errors),
              color_fn=YELLOW, use_bold=True)
    for e in errors:
        log("   " + YELLOW(e))
    log("\n")
else:
    log_boxed("✔  You are all set! ",
              color_fn=GREEN, use_bold=True)

log("- Please restart shell (e.g. " + CYAN("`exec zsh`") + ") if necessary.")
log("- To install some packages locally (e.g. neovim, tmux), try " + CYAN("`dotfiles install <package>`"))
log("- If you want to update dotfiles (or have any errors), try " + CYAN("`dotfiles update`"))
log("\n\n", cr=False)

sys.exit(len(errors))
