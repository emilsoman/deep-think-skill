#!/usr/bin/env bash
# Record a progress event and update the progress page.
#
# Usage:
#   event.sh <session> round <n> <max-rounds>   main agent, before it spawns round n
#   event.sh <session> start <n> <tool-slug>    tool agent, first step
#   event.sh <session> finish <n> <tool-slug>   tool agent, last step
#   event.sh <session> stage <name>             main agent: converge, report, done
set -euo pipefail

session=${1:?session dir required}
type=${2:?event type required}
case $type in
  round|start|finish) round=${3:?round required}; arg=${4:?argument required} ;;
  stage) round=0; arg=${3:?stage name required} ;;
  *) echo "unknown event type: $type" >&2; exit 1 ;;
esac

# One short line in one write, so lines from many agents do not mix.
printf '%s\t%s\t%s\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$type" "$round" "$arg" >> "$session/events.log"
python3 "$(dirname "$0")/render.py" "$session" || echo "progress page not updated" >&2
