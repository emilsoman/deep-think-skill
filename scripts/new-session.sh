#!/usr/bin/env bash
# Make a deep-think session folder and start its chatroom.
#
# Usage: new-session.sh <base-dir> "<short title>" < problem.md
#   <base-dir>  the user's deep-think folder if one is given, else
#               .claude/deep-think or .agents/deep-think (in the user's project)
#   stdin       the framed problem statement (Markdown)
#
# Prints the absolute path of the new session folder.
set -euo pipefail

base=${1:?base dir required}
title=${2:?short title required}
skill_dir=$(cd "$(dirname "$0")/.." && pwd)

problem=$(cat)
[ -n "$problem" ] || { echo "problem statement on stdin is empty" >&2; exit 1; }

slug=$(printf '%s' "$title" \
  | tr '[:upper:]' '[:lower:]' \
  | sed -E 's/[^a-z0-9]+/ /g' \
  | awk '{ n = (NF < 6 ? NF : 6); s = $1; for (i = 2; i <= n; i++) s = s "-" $i; print s }')
[ -n "$slug" ] || slug=problem

mkdir -p "$base"
dir="$base/$slug"
n=2
while ! mkdir "$dir" 2>/dev/null; do
  dir="$base/$slug-$n"
  n=$((n + 1))
done
mkdir "$dir/tools"
dir=$(cd "$dir" && pwd)

printf '%s\n' "$problem" > "$dir/problem.md"

{
  echo "# Chatroom: $slug"
  echo
  echo "## Problem"
  echo
  printf '%s\n' "$problem"
  echo
  echo "## Agents"
  echo
  for f in "$skill_dir"/tools/*.md; do
    echo "- $(basename "$f" .md)"
  done
  echo
  echo "## Rules"
  echo
  echo "- Add posts only with \`scripts/post.sh\`. Never edit this file."
  echo "- Header: \`## r<round> · <from> → <to|all> · <UTC time>\`."
  echo "- Maximum 10 lines in each post. Post \`PASS\` if you have nothing new."
  echo
  echo "---"
  echo
} > "$dir/chatroom.md"

echo "$dir"
