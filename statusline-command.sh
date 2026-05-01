#!/usr/bin/env bash
# Claude Code status line — mirrors Starship prompt style
# Sections: cwd | git branch + status | model | context usage | tokens | rate limits

input=$(cat)

# --- Data extraction ---
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
total_in=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
total_out=$(echo "$input" | jq -r '.context_window.total_output_tokens // empty')
five_hr=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
seven_day=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
vim_mode=$(echo "$input" | jq -r '.vim.mode // empty')
branch=$(git -C "$cwd" --git-dir="$cwd/.git" rev-parse --abbrev-ref HEAD 2>/dev/null)
git_status=$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null)

# --- Colors (ANSI — terminal will dim them slightly) ---
CYAN='\033[1;36m'
PURPLE='\033[1;35m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
GREEN='\033[1;32m'
DIM='\033[2m'
RESET='\033[0m'

# --- Directory (truncate to last 3 segments, like Starship) ---
if [ -n "$cwd" ]; then
  short_dir=$(echo "$cwd" | awk -F'/' '{
    n=NF; if(n<=3) print $0;
    else { out=""; for(i=n-2;i<=n;i++) out=out"/"$i; print substr(out,2) }
  }')
  printf "${CYAN}%s${RESET}" "$short_dir"
fi

# --- Git branch ---
if [ -n "$branch" ]; then
  printf " ${DIM}on${RESET} ${PURPLE} %s${RESET}" "$branch"

  # Git status indicators (mirrors Starship [all_status])
  if [ -n "$git_status" ]; then
    modified=$(echo "$git_status" | grep -c '^ M\|^MM\|^M ' 2>/dev/null || true)
    untracked=$(echo "$git_status" | grep -c '^??' 2>/dev/null || true)
    staged=$(echo "$git_status" | grep -c '^[MADRC]' 2>/dev/null || true)
    indicators=""
    [ "$staged" -gt 0 ]    && indicators="${indicators}+"
    [ "$modified" -gt 0 ]  && indicators="${indicators}!"
    [ "$untracked" -gt 0 ] && indicators="${indicators}?"
    [ -n "$indicators" ]   && printf " ${RED}[%s]${RESET}" "$indicators"
  fi
fi

# --- Model + vim mode ---
if [ -n "$model" ]; then
  if [ -n "$vim_mode" ]; then
    if [ "$vim_mode" = "INSERT" ]; then
      vim_color="$GREEN"
    else
      vim_color="$YELLOW"
    fi
    printf " ${DIM}|${RESET} ${BLUE}%s${RESET} ${vim_color}[%s]${RESET}" "$model" "$vim_mode"
  else
    printf " ${DIM}|${RESET} ${BLUE}%s${RESET}" "$model"
  fi
fi

# --- Context usage ---
if [ -n "$used_pct" ]; then
  used_int=$(printf '%.0f' "$used_pct")
  if [ "$used_int" -ge 80 ]; then
    ctx_color="$RED"
  elif [ "$used_int" -ge 50 ]; then
    ctx_color="$YELLOW"
  else
    ctx_color="$DIM"
  fi
  printf " ${DIM}ctx${RESET} ${ctx_color}%d%%${RESET}" "$used_int"
fi

# --- Token counts (session totals, formatted with k suffix) ---
if [ -n "$total_in" ] && [ -n "$total_out" ]; then
  # Format helper: values >= 1000 shown as e.g. 12.3k, else as integer
  fmt_tokens() {
    local val="$1"
    if [ "$val" -ge 1000 ] 2>/dev/null; then
      printf "%.1fk" "$(echo "scale=1; $val / 1000" | bc)"
    else
      printf "%d" "$val"
    fi
  }
  in_fmt=$(fmt_tokens "$total_in")
  out_fmt=$(fmt_tokens "$total_out")
  printf " ${DIM}in${RESET} ${DIM}%s${RESET} ${DIM}out${RESET} ${DIM}%s${RESET}" "$in_fmt" "$out_fmt"
fi

# --- Rate limits (Claude.ai subscription) ---
rate_parts=""
if [ -n "$five_hr" ]; then
  five_int=$(printf '%.0f' "$five_hr")
  if [ "$five_int" -ge 80 ]; then
    rl_color="$RED"
  elif [ "$five_int" -ge 50 ]; then
    rl_color="$YELLOW"
  else
    rl_color="$GREEN"
  fi
  rate_parts=$(printf "${rl_color}5h:%d%%${RESET}" "$five_int")
fi
if [ -n "$seven_day" ]; then
  seven_int=$(printf '%.0f' "$seven_day")
  if [ "$seven_int" -ge 80 ]; then
    rl_color="$RED"
  elif [ "$seven_int" -ge 50 ]; then
    rl_color="$YELLOW"
  else
    rl_color="$GREEN"
  fi
  wk_part=$(printf "${rl_color}7d:%d%%${RESET}" "$seven_int")
  if [ -n "$rate_parts" ]; then
    rate_parts="$rate_parts ${DIM}/${RESET} $wk_part"
  else
    rate_parts="$wk_part"
  fi
fi
if [ -n "$rate_parts" ]; then
  printf " ${DIM}|${RESET} %b" "$rate_parts"
fi

printf '\n'
