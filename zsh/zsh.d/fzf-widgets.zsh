# More fzf widgets
# ================

# This script should be sourced AFTER fzf.zsh
# @seealso ~/.fzf/shell/key-bindings.zsh for fzf mappings (Ctrl-T, Alt-C, Ctrl-R, etc.)

# More Shortcuts
bindkey '^ ' fzf-file-widget          # Ctrl-SPACE, Ctrl-T

# Ctrl-X ?: search aliases (and git aliases) with fzf. The chosen one is inserted at the cursor
# (not run), so arguments can follow. Ctrl-X works as a prefix here, like <C-a> ? in tmux.
function fzf-alias-widget() {
  setopt localoptions pipefail
  local k v name choice
  choice=$(
    { for k in ${(ko)aliases}; do printf '%-16s\t%s\n' "$k" "${aliases[$k]}"; done
      git config --get-regexp '^alias\.' 2>/dev/null | while read -r k v; do
        printf '%-16s\t%s\n' "git ${k#alias.}" "$v"
      done
    } | fzf --height=50% --reverse --delimiter='\t' --prompt='alias> ' \
            --preview='printf "%s\\n" {2..}' --preview-window=down:3:wrap
  )
  if [[ -n "$choice" ]]; then
    name="${choice%%$'\t'*}"; name="${name%"${name##*[! ]}"}"   # drop the padding
    [[ -n "$LBUFFER" && "$LBUFFER" != *' ' ]] && LBUFFER+=' '
    LBUFFER+="$name "
  fi
  zle reset-prompt
}
zle -N fzf-alias-widget
bindkey -M viins '^X?' fzf-alias-widget
bindkey -M vicmd '^X?' fzf-alias-widget
