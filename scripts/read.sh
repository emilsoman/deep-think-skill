#!/usr/bin/env bash
# Print a chatroom without the posts of the current round and later rounds.
# All agents in one round then see the same posts, when they start does not matter.
#
# Usage: read.sh <chatroom.md> <round>
set -euo pipefail

chat=${1:?chatroom path required}
round=${2:?round required}
case $round in ''|*[!0-9]*) echo "round must be a number" >&2; exit 1 ;; esac

awk -v r="$round" '
  /^## r[0-9]+ · / { in_posts = 1; show = (substr($2, 2) + 0 < r) }
  !in_posts || show { print }
' "$chat"
