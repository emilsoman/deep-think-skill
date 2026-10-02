#!/usr/bin/env bash
# Append one post to a chatroom. Safe when many agents post at the same time.
#
# Usage: post.sh <chatroom.md> <round> <from> <to> < text
#   <to>  a tool slug, or "all"
#   stdin the post text. "PASS" means "nothing new this round".
set -euo pipefail

chat=${1:?chatroom path required}
round=${2:?round required}
from=${3:?from required}
to=${4:?to required}

[ -f "$chat" ] || { echo "no chatroom at $chat" >&2; exit 1; }
case $round in ''|*[!0-9]*) echo "round must be a number" >&2; exit 1 ;; esac

text=$(cat)
[ -n "${text//[[:space:]]/}" ] || { echo "post text on stdin is empty" >&2; exit 1; }

lock="$chat.lock"
age() { echo $(( $(date +%s) - $(stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null || date +%s) )); }
tries=0
while ! mkdir "$lock" 2>/dev/null; do
  # A lock older than 10 seconds belongs to an agent that stopped. Move it
  # away first (only one agent can win the move), then delete it.
  if [ -d "$lock" ] && [ "$(age "$lock")" -gt 10 ]; then
    mv "$lock" "$lock.stale.$$" 2>/dev/null && rm -rf "$lock.stale.$$"
    continue
  fi
  tries=$((tries + 1))
  [ $tries -lt 300 ] || { echo "could not get lock $lock" >&2; exit 1; }
  sleep 0.1
done
trap 'rmdir "$lock" 2>/dev/null' EXIT

post=$(printf '## r%s · %s → %s · %s\n\n%s\n\n' \
  "$round" "$from" "$to" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$text")
printf '%s\n\n' "$post" >> "$chat"
