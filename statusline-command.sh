#!/bin/sh
# Claude Code ステータスライン
# 表示項目: model / effort / git branch / context / 5h利用 / 5hリセット / 週間利用
input=$(cat)

# ---------- モデル ----------
model=$(echo "$input" | jq -r '.model.display_name // "Unknown"')

# ---------- effort ----------
effort=$(echo "$input" | jq -r '.effort.level // empty')

# ---------- git ブランチ ----------
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null \
         || git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)

# ---------- context ----------
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
window_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')

if [ -n "$used_pct" ] && [ -n "$window_size" ]; then
  ctx_label=$(printf "%s %s" "$used_pct" "$window_size" | awk '{
    pct    = $1
    win    = $2
    used   = win * pct / 100
    used_k = used / 1000
    win_k  = int((win + 500) / 1000)
    printf "%.1fk/%dk (%d%%)", used_k, win_k, int(pct + 0.5)
  }')
else
  ctx_label="--"
fi

# ---------- 5時間レート制限 ----------
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_resets=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')

five_label=""
if [ -n "$five_pct" ]; then
  five_pct_int=$(printf "%.0f" "$five_pct")
  five_label="5h:${five_pct_int}%"

  if [ -n "$five_resets" ]; then
    now=$(date +%s)
    diff=$((five_resets - now))
    if [ "$diff" -gt 0 ]; then
      h=$((diff / 3600))
      m=$(( (diff % 3600) / 60 ))
      five_label="${five_label} (reset $(printf '%d:%02d' "$h" "$m"))"
    else
      five_label="${five_label} (reset soon)"
    fi
  fi
fi

# ---------- 週間レート制限 ----------
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
week_label=""
if [ -n "$week_pct" ]; then
  week_pct_int=$(printf "%.0f" "$week_pct")
  week_label="7d:${week_pct_int}%"
fi

# ---------- 出力 ----------
# 1行目: モデル / effort
printf "\033[36m%s\033[0m" "$model"
if [ -n "$effort" ]; then
  printf "  \033[35meffort:%s\033[0m" "$effort"
fi

# 2行目: git ブランチ / context
printf "\n"
if [ -n "$branch" ]; then
  printf "\033[34m %s\033[0m  " "$branch"
fi
printf "\033[33mCtx:%s\033[0m" "$ctx_label"

# 3行目: 5h制限 / 週間制限
if [ -n "$five_label" ] || [ -n "$week_label" ]; then
  printf "\n"
fi

if [ -n "$five_label" ]; then
  if [ -n "$five_pct" ] && [ "$(printf "%.0f" "$five_pct")" -ge 80 ]; then
    printf "\033[31m%s\033[0m" "$five_label"
  else
    printf "\033[32m%s\033[0m" "$five_label"
  fi
fi

if [ -n "$week_label" ]; then
  if [ -n "$five_label" ]; then
    printf "  "
  fi
  if [ -n "$week_pct" ] && [ "$(printf "%.0f" "$week_pct")" -ge 80 ]; then
    printf "\033[31m%s\033[0m" "$week_label"
  else
    printf "\033[32m%s\033[0m" "$week_label"
  fi
fi
