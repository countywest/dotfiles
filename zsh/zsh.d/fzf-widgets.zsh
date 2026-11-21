# More fzf widgets
# ================

# This script should be sourced AFTER fzf.zsh
# @seealso ~/.fzf/shell/key-bindings.zsh for fzf mappings (Ctrl-T, Alt-C, Ctrl-R, etc.)

# More Shortcuts
bindkey '^ ' fzf-file-widget          # Ctrl-SPACE, Ctrl-T

# Ctrl-X ?: search key bindings and aliases (incl. git aliases) with fzf, like <C-a> ? in tmux
# (Ctrl-X works as a prefix here). A key binding runs as if typed; an alias is inserted at the
# cursor (not run), so arguments can follow.
function fzf-help-widget() {
  setopt localoptions pipefail
  local k v w name choice
  local -A keys
  # insert-mode bindings worth knowing: the fzf widgets and a few editing helpers
  bindkey -M viins | while read -r k w; do
    [[ $w == (fzf-*|edit-command-line|prepend-sudo|push-line-or-edit|insert-last-word|_expand_alias|_shift-enter-newline) ]] || continue
    [[ $w == fzf-help-widget ]] && continue
    k=$(_fzf_help_key_name "${(Q)k}") || continue
    [[ -z ${keys[$w]} || ${#k} -lt ${#keys[$w]} ]] && keys[$w]=$k   # the shortest key per widget
  done
  choice=$(
    { for w in ${(ko)keys}; do printf 'key\t%-24s\t%s\n' "${keys[$w]}" "$w"; done
      for k in ${(ko)aliases}; do printf 'alias\t%-24s\t%s\n' "$k" "${aliases[$k]}"; done
      git config --get-regexp '^alias\.' 2>/dev/null | while read -r k v; do
        printf 'alias\t%-24s\t%s\n' "git ${k#alias.}" "$v"
      done
    } | fzf --height=50% --reverse --delimiter='\t' --with-nth=2.. --prompt='keys/aliases> ' \
            --header='Enter: run the key binding / insert the alias' \
            --preview='printf "%s\\n" {3..}' --preview-window=down:3:wrap
  )
  zle reset-prompt
  [[ -n "$choice" ]] || return 0
  if [[ $choice == key$'\t'* ]]; then
    zle "${choice##*$'\t'}"   # run the widget
    return
  fi
  name="${${choice#*$'\t'}%%$'\t'*}"; name="${name%"${name##*[! ]}"}"   # 2nd field, without the padding
  [[ -n "$LBUFFER" && "$LBUFFER" != *' ' ]] && LBUFFER+=' '
  LBUFFER+="$name "
}
# bindkey notation -> readable: "^G^B" -> "Ctrl-G Ctrl-B", "^[." -> "Alt-.", "^@" -> "Ctrl-Space"
function _fzf_help_key_name() {
  local s="$1"; local -a out
  while [[ -n $s ]]; do
    case $s in
      '^[[27;2;13~'*) out+=(Shift-Enter); s=${s:11} ;;
      '^[['*)         return 1 ;;   # other escape sequences (function keys, ...)
      '^['?*)         out+=("Alt-${s[3]}"); s=${s:3} ;;
      '^@'*)          out+=(Ctrl-Space); s=${s:2} ;;
      '^I'*)          out+=(Tab); s=${s:2} ;;
      '^?'*)          out+=(Backspace); s=${s:2} ;;
      '^'?*)          out+=("Ctrl-${s[2]}"); s=${s:2} ;;
      *)              out+=("${s[1]}"); s=${s:1} ;;
    esac
  done
  print -r -- "${(j: :)out}"
}
zle -N fzf-help-widget
bindkey -M viins '^X?' fzf-help-widget
bindkey -M vicmd '^X?' fzf-help-widget
