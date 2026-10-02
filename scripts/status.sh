#!/usr/bin/env bash
# Show the state of one round in a chatroom.
#
# Usage: status.sh <chatroom.md> <round>
# Prints:
#   posts=<n> agents=<n> active=<n agents with a non-PASS post>
#   silent: <slugs with no post in this round>
set -euo pipefail

chat=${1:?chatroom path required}
round=${2:?round required}
skill_dir=$(cd "$(dirname "$0")/.." && pwd)

# One line for each post: "<from> <1 if PASS, else 0>"
rows=$(awk -v r="r$round" '
  function flush() { if (from != "") print from, (body == "PASS" ? 1 : 0); from = "" }
  /^## r[0-9]+ · / { flush(); if ($2 == r) { from = $4; body = "" } next }
  from != "" && NF { gsub(/^[[:space:]]+|[[:space:]]+$/, ""); body = (body == "" ? $0 : body " " $0) }
  END { flush() }
' "$chat")

posts=$(printf '%s\n' "$rows" | grep -c . || true)
active=$(printf '%s\n' "$rows" | awk '$2 == 0 { a[$1] = 1 } END { print length(a) }')

silent=""
total=0
for f in "$skill_dir"/tools/*.md; do
  s=$(basename "$f" .md)
  total=$((total + 1))
  printf '%s\n' "$rows" | awk -v s="$s" '$1 == s { found = 1 } END { exit !found }' || silent="$silent $s"
done

echo "posts=$posts agents=$total active=$active"
echo "silent:${silent:- none}"
