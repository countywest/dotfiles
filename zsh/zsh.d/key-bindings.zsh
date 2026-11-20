# Custom key bindings for ZSH

# In default settings, we use 'vi-mode' (bindkey -v)

# Bash-compatible (emacs style) key bindings
# ==========================================
# @see http://zsh.sourceforge.net/Doc/Release/Zsh-Line-Editor.html
# @see http://www.gnu.org/software/bash/manual/html_node/Readline-Interaction.html

bindkey '^A' beginning-of-line
bindkey '^E' end-of-line

# For Home and End key support
bindkey "\033[1~" beginning-of-line
bindkey "\033[4~" end-of-line
bindkey "\033[7~" beginning-of-line
bindkey "\033[8~" end-of-line
bindkey "\033[H" beginning-of-line
bindkey "\033[F" end-of-line
bindkey "\033OH" beginning-of-line
bindkey "\033OF" end-of-line

bindkey '^D' delete-char
bindkey '^H' backward-delete-char

bindkey '^N' down-history
bindkey '^P' up-history

if [[ $(bindkey '^R') == *"undefined"* ]]; then
  bindkey '^R' history-incremental-search-backward
fi

bindkey '\e.' insert-last-word # Alt-.


# Vi mode key bindings
# CTRL-X CTRL-E: Edit command in an external editor (even in insert mode)
bindkey -M viins "$key_info[Control]X$key_info[Control]E" edit-command-line

# Shift-Enter: insert a newline (multi-line command) instead of running it.
# Terminals and tmux send a plain Enter for Shift-Enter unless the program asks for
# distinct keys (xterm modifyOtherKeys), so ask only while a command line is being
# edited; programs started from the shell are unaffected.
# Known issue: herdr ignores modifyOtherKeys=1 (honors only 2, which also changes Ctrl-A etc.),
# so there Shift-Enter stays a plain Enter.
function _shift-enter-newline() { LBUFFER+=$'\n' }
zle -N _shift-enter-newline
for keymap in viins vicmd; do   # vicmd too, or the sequence would run as vi commands (e.g. '~')
  bindkey -M $keymap $'\e[27;2;13~' _shift-enter-newline   # modifyOtherKeys format (tmux, xterm)
  bindkey -M $keymap $'\e[13;2u' _shift-enter-newline      # CSI u format
done
unset keymap
function _modify-other-keys-on()  { print -n $'\e[>4;1m' }
function _modify-other-keys-off() { print -n $'\e[>4;0m' }
autoload -Uz add-zle-hook-widget
add-zle-hook-widget line-init _modify-other-keys-on
add-zle-hook-widget line-finish _modify-other-keys-off


# Note: see ~/.zsh/zsh.d/fzf-widgets.zsh
# for more zsh widgets and their keybindings.
