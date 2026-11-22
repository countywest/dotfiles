#!/bin/bash

# A collection of bash scripts for installing some libraries/packages in
# user namespaces (e.g. ~/.local/), without having root privileges.

PREFIX="$HOME/.local/"

COLOR_NONE="\033[0m"
COLOR_RED="\033[0;31m"
COLOR_GREEN="\033[0;32m"
COLOR_YELLOW="\033[0;33m"
COLOR_WHITE="\033[1;37m"


#---------------------------------------------------------------------------------------------------

_private_tmpdir() {
  # _private_tmpdir {name}: a fresh, private (0700) dir with an unpredictable name. A fixed
  # /tmp/$USER/... path on a shared machine could be pre-created (e.g. as a symlink) by another
  # user to swap the downloaded files before they are built or copied.
  mktemp -d "${TMPDIR:-/tmp}/$1.XXXXXX"
}

_template_github_latest() {
  set -e
  local name="$1"
  local repo="$2"
  local filename="$3"
  if [[ -z "$name" ]] || [[ -z "$repo" ]] || [[ -z "$filename" ]]; then
    echo "Wrong usage"; return 1;
  fi

  echo -e "${COLOR_YELLOW}Installing $name from $repo ... ${COLOR_NONE}"
  # releases/latest: the newest non-prerelease. Print the first asset matching the glob.
  local download_url=$(\
    curl -fsSL https://api.github.com/repos/${repo}/releases/latest | \
    python3 -c "\
import json, sys, fnmatch;
for asset in json.load(sys.stdin)['assets']:
  if fnmatch.fnmatch(asset['name'], '$filename'):
    print(asset['browser_download_url']); break
")
  echo -e "${COLOR_YELLOW}download_url = ${COLOR_NONE}$download_url"
  test -n "$download_url"

  local tmpdir; tmpdir=$(_private_tmpdir "$name")
  local filename="$(basename "$download_url")"
  curl -fL -o "$tmpdir/$filename" "$download_url"

  echo -e "${COLOR_YELLOW}Extracting to: $tmpdir${COLOR_NONE}"
  cd "$tmpdir" && tar -xzf "$filename"

  echo -e "${COLOR_YELLOW}Copying ...${COLOR_NONE}"
}

_glibc_version() {
  # https://stackoverflow.com/questions/71070969/how-to-extract-and-compare-the-libc-versions-at-runtime
  local libcfile="$(grep -azm1 '/libc.so.6$' /etc/ld.so.cache | tr -d '\0')"
  grep -aoP 'GNU C Library [^\n]* release version \K[0-9]*.[0-9]*' "$libcfile"
}
_version_check() {
  # _version_check {curver} {targetver}: exit code is 0 if curver >= targetver
  local curver="$1"; local targetver="$2";
  [ "$targetver" = "$(echo -e "$curver\n$targetver" | sort -V | head -n1)" ]
}

_linux_arch() {
  # CPU name as used in Rust-style release assets (e.g. <name>-<ver>-aarch64-unknown-linux-musl)
  case "$(uname -m)" in
    x86_64|amd64)  echo x86_64 ;;
    aarch64|arm64) echo aarch64 ;;
    *) echo "unsupported CPU architecture: $(uname -m)" >&2; return 1 ;;
  esac
}

#---------------------------------------------------------------------------------------------------

install_git() {
    # installs a modern version of git locally.
    set -e

    local GIT_LATEST_VERSION=$(\
        curl -L https://api.github.com/repos/git/git/tags 2>/dev/null | \
        python3 -c 'import json, sys; print(json.load(sys.stdin)[0]["name"])'\
    )  # e.g. "v2.38.1"
    test  -n "$GIT_LATEST_VERSION"

    local TMP_GIT_DIR; TMP_GIT_DIR=$(_private_tmpdir git)
    wget -N -O $TMP_GIT_DIR/git.tar.gz "https://github.com/git/git/archive/${GIT_LATEST_VERSION}.tar.gz"
    tar -xvzf $TMP_GIT_DIR/git.tar.gz -C $TMP_GIT_DIR --strip-components 1

    cd $TMP_GIT_DIR
    make configure
    ./configure --prefix="$PREFIX" --with-curl --with-expat

    # requires libcurl-dev (mandatory to make https:// work)
    if grep -q 'cannot find -lcurl' config.log; then
        echo -e "${COLOR_RED}Error: libcurl not found. Please install libcurl-dev and try again.${COLOR_NONE}"
        echo -e "${COLOR_YELLOW}e.g., sudo apt install libcurl4-openssl-dev${COLOR_NONE}"
        return 1;
    fi

    make clean
    make -j8 && make install
    ~/.local/bin/git --version

    if [[ ! -f "$(~/.local/bin/git --exec-path)/git-remote-https" ]]; then
        echo -e "${COLOR_YELLOW}Warning: $(~/.local/bin/git --exec-path)/git-remote-https not found. "
        echo -e "https:// git url will not work. Please install libcurl-dev and try again.${COLOR_NONE}"
        return 2;
    fi
}

install_gh() {
    # github CLI: https://github.com/cli/cli/releases
    set -e

    local version="2.20.2"
    local url="https://github.com/cli/cli/releases/download/v$version/gh_${version}_linux_amd64.tar.gz"

    local tmpdir; tmpdir=$(_private_tmpdir gh)

    wget -N -O $tmpdir/gh.tar.gz "$url"
    tar -xvzf $tmpdir/gh.tar.gz -C $tmpdir --strip-components 1
    mkdir -p $HOME/.local/bin
    mv $tmpdir/bin/gh $HOME/.local/bin/gh

    $HOME/.local/bin/gh --version
}

install_ncurses() {
    # installs ncurses (shared libraries and headers) into local namespaces.
    set -e

    TMP_NCURSES_DIR=$(_private_tmpdir ncurses)
    NCURSES_DOWNLOAD_URL="https://invisible-mirror.net/archives/ncurses/ncurses-6.5.tar.gz";

    wget -nc -O $TMP_NCURSES_DIR/ncurses-6.5.tar.gz $NCURSES_DOWNLOAD_URL
    tar -xvzf $TMP_NCURSES_DIR/ncurses-6.5.tar.gz -C $TMP_NCURSES_DIR --strip-components 1
    cd $TMP_NCURSES_DIR

    # compile as shared library, at ~/.local/lib/libncurses.so (as well as static lib)
    export CPPFLAGS="-P"
    ./configure --prefix="$PREFIX" --with-shared

    make clean && make -j4 && make install
}

install_zsh() {
    set -e

    ZSH_VER="5.9.2"
    TMP_ZSH_DIR=$(_private_tmpdir zsh)

    wget -nc -O $TMP_ZSH_DIR/zsh.tar.xz "https://sourceforge.net/projects/zsh/files/zsh/${ZSH_VER}/zsh-${ZSH_VER}.tar.xz/download"
    tar xvJf $TMP_ZSH_DIR/zsh.tar.xz -C $TMP_ZSH_DIR --strip-components 1
    cd $TMP_ZSH_DIR

    if [[ -d "$PREFIX/include/ncurses" ]]; then
        export CFLAGS="-I$PREFIX/include -I$PREFIX/include/ncurses"
        export LDFLAGS="-L$PREFIX/lib/"
    fi

    ./configure --prefix="$PREFIX"
    make clean && make -j8 && make install

    ~/.local/bin/zsh --version
}

install_node() {
    # Install node.js LTS at ~/.local
    set -e
    curl -fsSL https://install-node.vercel.app/lts | bash -s -- --prefix=$HOME/.local --verbose --yes

    echo -e "\n$(which node) : $(node --version)"
    node --version

    # install some useful nodejs based utility (~/.local/lib/node_modules)
    $HOME/.local/bin/npm install -g yarn
    which yarn && yarn --version
    $HOME/.local/bin/npm install -g http-server || true;
}

install_tree-sitter() {
  # tree-sitter CLI (via npm), used by nvim-treesitter to build parsers
  if ! type "npm" >/dev/null 2>&1; then
    echo 'node/npm required. run `dotfiles install node`' && return 1;
  fi

  local TREESITTER_VERSION
  if _version_check "$(_glibc_version)" 2.39; then
    # Ubuntu 24+, tree-sitter-cli 0.26+ requires glibc 2.39+
    TREESITTER_VERSION=">=0.26.0"
  else
    TREESITTER_VERSION="~0.25.0"
  fi

  set -x
  PATH="$PATH:$HOME/.local/bin" \
    npm install -g tree-sitter-cli"@${TREESITTER_VERSION}"

  tree-sitter --version
}

install_tmux() {
    # tmux: the official static builds (no libevent/ncurses needed), for x86_64 and arm64
    # see https://github.com/tmux/tmux-builds/releases
    # tmux before 3.4 counts VS16 emoji (e.g. ✖️) as one cell while most
    # terminals draw them as two, which leaves stray characters on screen.
    set -e
    TMUX_VER="3.8"
    local arch; arch=$(_linux_arch); [[ "$arch" == aarch64 ]] && arch=arm64

    TMUX_URL="https://github.com/tmux/tmux-builds/releases/download/v${TMUX_VER}/tmux-${TMUX_VER}-linux-${arch}.tar.gz"
    # Download aside and rename: a running tmux keeps its file busy,
    # so writing over it in place fails with "Text file busy".
    mkdir -p $HOME/.local/bin
    wget -O - $TMUX_URL | tar -xzO tmux > $HOME/.local/bin/tmux.download
    chmod +x $HOME/.local/bin/tmux.download
    mv -f $HOME/.local/bin/tmux.download $HOME/.local/bin/tmux

    ~/.local/bin/tmux -V
}

install_bazel() {
    set -e

    # install the 'latest' stable release (no pre-releases.)
    BAZEL_LATEST_VERSION=$(\
        curl -L https://api.github.com/repos/bazelbuild/bazel/releases/latest 2>/dev/null | \
        python3 -c 'import json, sys; print(json.load(sys.stdin)["name"])'\
    )
    test -n "$BAZEL_LATEST_VERSION"
    BAZEL_VER="${BAZEL_LATEST_VERSION}"
    echo -e "${COLOR_YELLOW}Installing Bazel ${BAZEL_VER} ...${COLOR_NONE}"

    BAZEL_URL="https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VER}/bazel-${BAZEL_VER}-installer-linux-x86_64.sh"

    TMP_BAZEL_DIR=$(_private_tmpdir bazel)
    wget -O $TMP_BAZEL_DIR/bazel-installer.sh $BAZEL_URL

    # zsh completion
    mkdir -p $HOME/.local/share/zsh/site-functions
    wget -O $HOME/.local/share/zsh/site-functions/_bazel https://raw.githubusercontent.com/bazelbuild/bazel/master/scripts/zsh_completion/_bazel

    # install bazel
    bash $TMP_BAZEL_DIR/bazel-installer.sh \
        --bin=$HOME/.local/bin \
        --base=$HOME/.bazel

    # print bazel version
    echo -e "\n\n${COLOR_YELLOW}Bazel at $(which bazel): ${COLOR_NONE}"
    bazel 2>/dev/null | grep release | xargs
    echo ""
}

install_miniforge() {
    # Miniforge3.
    # https://github.com/conda-forge/miniforge
    set -e
    local URL="https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"

    local TMP_DIR; TMP_DIR=$(_private_tmpdir miniforge) && cd "$TMP_DIR"
    wget -nc "$URL"

    local MINIFORGE_PREFIX="$HOME/miniforge3"
    bash "Miniforge3-$(uname)-$(uname -m).sh" -b -p ${MINIFORGE_PREFIX}
    $MINIFORGE_PREFIX/bin/python3 --version
}

install_vim() {
    # install latest vim
    set -e

    # check python3-config
    local PYTHON3_CONFIGDIR=$(python3-config --configdir)
    echo -e "${COLOR_YELLOW}$ python3-config --configdir =${COLOR_NONE} $PYTHON3_CONFIGDIR"
    if [[ "$PYTHON3_CONFIGDIR" =~ (conda|virtualenv|venv) ]]; then
      echo -e "${COLOR_RED}Error: python3-config reports a conda/virtual environment. Deactivate and try again."
      return 1;
    fi

    # grab the lastest vim tarball and build it
    local TMP_VIM_DIR; TMP_VIM_DIR=$(_private_tmpdir vim)
    local VIM_LATEST_VERSION=$(\
        curl -L https://api.github.com/repos/vim/vim/tags 2>/dev/null | \
        python3 -c 'import json, sys; print(json.load(sys.stdin)[0]["name"])'\
    )
    test -n "$VIM_LATEST_VERSION"
    local VIM_LATEST_VERSION=${VIM_LATEST_VERSION/v/}    # (e.g) 8.0.1234
    echo -e "${COLOR_GREEN}Installing vim $VIM_LATEST_VERSION ...${COLOR_NONE}"
    sleep 1

    local VIM_DOWNLOAD_URL="https://github.com/vim/vim/archive/v${VIM_LATEST_VERSION}.tar.gz"

    wget -nc ${VIM_DOWNLOAD_URL} -P ${TMP_VIM_DIR} || true;
    cd ${TMP_VIM_DIR} && tar -xvzf v${VIM_LATEST_VERSION}.tar.gz
    cd "vim-${VIM_LATEST_VERSION}/src"

    ./configure --prefix="$PREFIX" \
        --with-features=huge \
        --enable-python3interp \
        --with-python3-config-dir="$PYTHON3_CONFIGDIR"

    make clean && make -j8 && make install
    ~/.local/bin/vim --version | head -n2

    # make sure that all necessary features are shipped
    if ! (vim --version | grep -q '+python3'); then
        echo "vim: python is not enabled"
        exit 1;
    fi
}

install_neovim() {
    # install neovim stable or nightly
    set -e

    local NEOVIM_VERSION=$(\
        curl -L https://api.github.com/repos/neovim/neovim/releases/latest 2>/dev/null | \
        python3 -c 'import json, sys; print(json.load(sys.stdin)["tag_name"])'\
    )   # starts with "v", e.g. "v0.7.0"
    test -n "$NEOVIM_VERSION"

    local VERBOSE=""
    for arg in "$@"; do
      if [ "$arg" == "--nightly" ]; then
        NEOVIM_VERSION="nightly";
      elif [ "$arg" == "-v" ] || [ "$arg" == "--verbose" ]; then
        VERBOSE="--verbose"
      fi
    done

    if [ "${NEOVIM_VERSION}" == "nightly" ]; then
      echo -e "${COLOR_YELLOW}Installing neovim nightly. ${COLOR_NONE}"
    else
      echo -e "${COLOR_YELLOW}Installing neovim stable ${NEOVIM_VERSION}. ${COLOR_NONE}"
      echo -e "${COLOR_YELLOW}To install a nightly version, add flag: --nightly ${COLOR_NONE}"
    fi
    sleep 1;  # allow users to read above comments

    local NVIM_ARCH=$(uname -m); [ "$NVIM_ARCH" = aarch64 ] && NVIM_ARCH=arm64   # asset names since v0.10.4
    local TMP_NVIM_DIR; TMP_NVIM_DIR=$(_private_tmpdir neovim)
    local NVIM_DOWNLOAD_URL="https://github.com/neovim/neovim/releases/download/${NEOVIM_VERSION}/nvim-linux-${NVIM_ARCH}.tar.gz"

    cd "$TMP_NVIM_DIR"
    wget "$NVIM_DOWNLOAD_URL"
    tar $VERBOSE -xzf "nvim-linux-${NVIM_ARCH}.tar.gz"
    ls --color -d "$TMP_NVIM_DIR/nvim-linux-${NVIM_ARCH}"

    # copy and merge into ~/.local/bin
    echo -e "${COLOR_GREEN}[*] Copying to $PREFIX ... ${COLOR_NONE}"
    mkdir -p "$PREFIX/bin/"
    cp $VERBOSE "nvim-linux-${NVIM_ARCH}/bin/nvim" $PREFIX/bin/nvim \
        || (echo -e "${COLOR_RED}Copy failed, please kill all nvim instances. (killall nvim)${COLOR_NONE}"; exit 1)
    cp -RT $VERBOSE "nvim-linux-${NVIM_ARCH}/" "$PREFIX"

    $PREFIX/bin/nvim --version
}

install_exa() {
    # https://github.com/ogham/exa/releases
    EXA_VERSION="0.10.1"
    EXA_BINARY_SHA1SUM="7bbd4be0bf44a0302970e7596f5753a0f31e85ac"
    EXA_DOWNLOAD_URL="https://github.com/ogham/exa/releases/download/v$EXA_VERSION/exa-linux-x86_64-v$EXA_VERSION.zip"
    TMP_EXA_DIR=$(_private_tmpdir exa)

    wget -nc ${EXA_DOWNLOAD_URL} -P ${TMP_EXA_DIR} || exit 1;
    cd ${TMP_EXA_DIR} && unzip -o "exa-linux-x86_64-v$EXA_VERSION.zip" || exit 1;
    if [[ "$EXA_BINARY_SHA1SUM" != "$(sha1sum bin/exa | cut -d' ' -f1)" ]]; then
        echo -e "${COLOR_RED}SHA1 checksum mismatch, aborting!${COLOR_NONE}"
        exit 1;
    fi
    cp "bin/exa" "$PREFIX/bin/exa" || exit 1;
    cp "completions/exa.zsh" "$PREFIX/share/zsh/site-functions/_exa" || exit 1;
    echo "$(which exa) : $(exa --version)"
}

install_fd() {
    # https://github.com/sharkdp/fd/releases
    set -e
    local arch; arch=$(_linux_arch)
    _template_github_latest "fd" "sharkdp/fd" "fd-*-${arch}-unknown-linux-musl.tar.gz"
    mkdir -p "$PREFIX/bin" "$PREFIX/share/zsh/site-functions"
    cp fd-*/fd "$PREFIX/bin"
    cp fd-*/autocomplete/_fd "$PREFIX/share/zsh/site-functions"
    "$PREFIX/bin/fd" --version
}

install_ripgrep() {
    # https://github.com/BurntSushi/ripgrep/releases
    set -e
    local arch; arch=$(_linux_arch)
    _template_github_latest "ripgrep" "BurntSushi/ripgrep" "ripgrep-*-${arch}-unknown-linux-musl.tar.gz"
    mkdir -p "$PREFIX/bin" "$PREFIX/share/zsh/site-functions"
    cp ripgrep-*/rg "$PREFIX/bin"
    cp ripgrep-*/complete/_rg "$PREFIX/share/zsh/site-functions"
    "$PREFIX/bin/rg" --version
}

install_xsv() {
    XSV_VERSION="0.13.0"

    set -e; set -x
    mkdir -p $PREFIX/bin && cd $PREFIX/bin
    curl -L "https://github.com/BurntSushi/xsv/releases/download/${XSV_VERSION}/xsv-${XSV_VERSION}-x86_64-unknown-linux-musl.tar.gz" | tar zxf -
    $PREFIX/bin/xsv
}

install_bat() {
    # https://github.com/sharkdp/bat/releases
    set -e
    local arch; arch=$(_linux_arch)
    _template_github_latest "bat" "sharkdp/bat" "bat-*-${arch}-unknown-linux-musl.tar.gz"
    mkdir -p "$PREFIX/bin" "$PREFIX/share/man/man1"
    cp bat-*/bat "$PREFIX/bin"
    cp bat-*/bat.1 "$PREFIX/share/man/man1"
    "$PREFIX/bin/bat" --version
}

install_delta() {
    # https://github.com/dandavison/delta/releases (git pager with syntax highlighting)
    set -e
    local arch libc; arch=$(_linux_arch)
    if [[ "$arch" == x86_64 ]]; then libc=musl; else libc=gnu; fi   # static musl build: x86_64 only
    _template_github_latest "delta" "dandavison/delta" "delta-*-${arch}-unknown-linux-${libc}.tar.gz"
    mkdir -p "$PREFIX/bin"
    cp delta-*/delta "$PREFIX/bin"
    "$PREFIX/bin/delta" --version
}

install_go() {
    # install go lang into ~/.go
    # https://golang.org/dl/
    set -e
    if [[ -d $HOME/.go ]]; then
        echo -e "${COLOR_RED}Error: $HOME/.go already exists.${COLOR_NONE}"
        exit 1;
    fi

    GO_DOWNLOAD_URL="https://dl.google.com/go/go1.9.3.linux-amd64.tar.gz"
    TMP_GO_DIR=$(_private_tmpdir go)

    wget -nc ${GO_DOWNLOAD_URL} -P ${TMP_GO_DIR} || exit 1;
    cd ${TMP_GO_DIR} && tar -xvzf "go1.9.3.linux-amd64.tar.gz" || exit 1;
    mv go $HOME/.go

    echo ""
    echo -e "${COLOR_GREEN}Installed at $HOME/.go${COLOR_NONE}"
    $HOME/.go/bin/go version
}

install_lazydocker() {
  set -e
  local arch; arch=$(_linux_arch); [ "$arch" = aarch64 ] && arch=arm64
  _template_github_latest "lazydocker" "jesseduffield/lazydocker" "lazydocker_*_Linux_${arch}.tar.gz"

  mkdir -p "$PREFIX/bin"
  cp -v "./lazydocker" "$PREFIX/bin"

  echo -e "\n\n${COLOR_WHITE}$(which lazydocker)${COLOR_NONE}"
  $PREFIX/bin/lazydocker --version
}

install_lazygit() {
  set -e
  local arch; arch=$(_linux_arch); [ "$arch" = aarch64 ] && arch=arm64
  _template_github_latest "lazygit" "jesseduffield/lazygit" "lazygit_*_linux_${arch}.tar.gz"   # lowercase 'linux' (unlike lazydocker)

  mkdir -p "$PREFIX/bin"
  cp -v "./lazygit" "$PREFIX/bin"

  echo -e "\n\n${COLOR_WHITE}$(which lazygit)${COLOR_NONE}"
  $PREFIX/bin/lazygit --version
}

install_rsync() {
  set -e

  local URL="https://www.samba.org/ftp/rsync/src/rsync-3.5.0.tar.gz"
  local TMP_DIR; TMP_DIR=$(_private_tmpdir rsync)

  wget -N -O $TMP_DIR/rsync.tar.gz "$URL"
  tar -xvzf $TMP_DIR/rsync.tar.gz -C $TMP_DIR --strip-components 1
  cd $TMP_DIR

  ./configure --prefix="$PREFIX"
  make install
  $PREFIX/bin/rsync --version
}

install_mosh() {
  set -e; set -x
  cd "$(_private_tmpdir mosh)"
  git clone https://github.com/mobile-shell/mosh --depth=1
  cd mosh

  # bump up mosh version to indicate this is a HEAD version
  sed -i -e 's/1\.3\.2/1.4.0/g' configure.ac

  ./autogen.sh
  ./configure --prefix="$PREFIX"
  make install
  $PREFIX/bin/mosh-server --version
}

install_mujoco() {
  # https://github.com/deepmind/mujoco/
  # Note: If pre-built wheel is available, just do `pip install mujoco` and it's done
  set -e; set -x
  local mujoco_version="2.3.0"

  local MUJOCO_ROOT=$HOME/.mujoco/mujoco-$mujoco_version
  if [[ -d "$MUJOCO_ROOT" ]]; then
    echo -e "${COLOR_YELLOW}Error: $MUJOCO_ROOT already exists.${COLOR_NONE}"
    return 1;
  fi

  local tmpdir; tmpdir=$(_private_tmpdir mujoco) && cd "$tmpdir"
  mkdir -p $HOME/.mujoco

  local download_url="https://github.com/deepmind/mujoco/releases/download/${mujoco_version}/mujoco-${mujoco_version}-linux-x86_64.tar.gz"
  local filename="$(basename $download_url)"
  wget -N -O $tmpdir/$filename "$download_url"
  tar -xvzf "$filename" -C $tmpdir

  mv $tmpdir/mujoco-$mujoco_version $HOME/.mujoco/
  test -d $MUJOCO_ROOT

  $MUJOCO_ROOT/bin/testspeed $MUJOCO_ROOT/model/scene.xml 1000
  set +x

  echo -e "${COLOR_GREEN}MUJOCO_ROOT = $MUJOCO_ROOT${COLOR_NONE}"
  echo -e "${COLOR_WHITE}Done. Please don't forget to set LD_LIBRARY_PATH \
   (should include $MUJOCO_ROOT/bin).${COLOR_NONE}\n"
}


# entrypoint script
if [ `uname` != "Linux" ]; then
    echo "Run on Linux (not on Mac OS X)"; exit 1
fi
if [[ -n "$1" && "$1" != "--help" ]] && declare -f "$1"; then
    $@
else
    echo "Usage: $0 [command], where command is one of the following:"
    declare -F | cut -d" " -f3 | grep -v '^_'
    exit 1;
fi
