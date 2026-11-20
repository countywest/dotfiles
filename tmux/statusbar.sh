#!/usr/bin/env bash
# tmux status-right blocks: CPU / RAM / GPU usage, colored by load.
# Usage (tmux.conf): #(~/.tmux/statusbar.sh cpu|ram|gpu)
# Prints one styled block, or nothing if the metric is unavailable (e.g. no GPU).

# block <percent> <text> <bg for 0-24%> <25-49%> <50-74%> <75%+>
block() {
  local pct=${1%.*} text=$2; shift 2
  [[ $pct =~ ^[0-9]+$ ]] || return 0
  local colors=("$@") i=$(( pct / 25 ))
  (( i > 3 )) && i=3
  printf '#[fg=white,bg=%s] %s #[default]' "${colors[i]}" "$text"
}

cpu() {
  local pct
  if [[ $(uname) == Darwin ]]; then
    # two samples 1s apart; the last line is the live one (the first is since boot)
    pct=$(iostat -n 0 -c 2 -w 1 | awk '
      /us/ { for (i = 1; i <= NF; i++) { if ($i == "us") u = i; if ($i == "sy") s = i } }
      END  { if (u) print $u + $s }')
  else
    pct=$("$HOME/.dotfiles/bin/cpu-usage")
  fi
  block "$pct" "$(printf 'CPU %2.0f%%' "$pct")" '#3a1e1e' '#642121' '#9c2525' '#c92a2a'
}

ram() {
  local used total pct
  if [[ $(uname) == Darwin ]]; then
    # "Memory Used" as in Activity Monitor: app (anonymous - purgeable) + wired + compressed
    total=$(sysctl -n hw.memsize)
    used=$(vm_stat | awk '
      /page size of/            { ps = $8 }
      /^Anonymous pages/        { a = $3 }
      /^Pages purgeable/        { p = $3 }
      /^Pages wired down/       { w = $4 }
      /^Pages occupied by comp/ { c = $5 }
      END { print (a - p + w + c) * ps }')
  else
    read -r used total < <(awk '
      /^MemTotal:/     { t = $2 }
      /^MemAvailable:/ { a = $2 }
      END { print (t - a) * 1024, t * 1024 }' /proc/meminfo)
  fi
  read -r used total pct < <(awk -v u="$used" -v t="$total" \
    'BEGIN { if (t > 0) printf "%.1f %.0f %d\n", u / 2^30, t / 2^30, 100 * u / t }')
  block "$pct" "RAM $used/${total}G" '#35301f' '#755515' '#a86a08' '#d9480f'
}

gpu() {
  local pct
  if [[ $(uname) == Darwin ]]; then
    # Apple Silicon: no sudo needed
    pct=$(ioreg -r -d 1 -c IOAccelerator 2>/dev/null |
      grep -oE '"Device Utilization %"=[0-9]+' | head -n1 | cut -d= -f2)
  elif command -v nvidia-smi >/dev/null; then
    # average over all GPUs
    pct=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null |
      awk '$1 ~ /^[0-9]+$/ { s += $1; n++ } END { if (n) printf "%d", s / n }')
  fi
  [[ $pct =~ ^[0-9]+$ ]] || return 0
  block "$pct" "$(printf 'GPU %2d%%' "$pct")" '#30412a' '#356537' '#2b8a3e' '#2f9e44'
}

case $1 in
  cpu|ram|gpu) "$1" ;;
  *) echo "usage: $0 cpu|ram|gpu" >&2; exit 1 ;;
esac
