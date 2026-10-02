---
name: deep-think
description: Think about one hard problem with a team of 25 subagents. Each subagent applies one thinking tool from untools.co (Inversion, First Principles, Iceberg Model, Six Thinking Hats, and the others). The subagents discuss in a Markdown chatroom, and the skill gives one report. Use when the user runs /deep-think, or asks to "think deeply", "use all thinking tools", or "use untools" on a problem.
argument-hint: "<problem>"
---

# deep-think

`SKILL_DIR` is the folder that holds this file. Use absolute paths in all subagent prompts.

The tools are the files in `SKILL_DIR/tools/`. There are 25. Each tool gets one subagent. Use all of them, for every problem.

## 1. Frame

Use Abstraction Laddering (`SKILL_DIR/tools/abstraction-laddering.md`) to make the problem statement clear. If the problem is not clear, ask the user one question, then continue.

Write the framed problem: the problem statement, the goal, the known facts, and the constraints.

## 2. Make the session

Select the base folder in the user's current project:

- Claude Code: `.claude/deep-think`
- Other agents that use the `.agents/` folder: `.agents/deep-think`

```bash
"SKILL_DIR/scripts/new-session.sh" <base> "<short title, max 6 words>" <<'PROBLEM'
<framed problem>
PROBLEM
```

The script prints the absolute session folder, `SESSION`. It makes `problem.md`, `tools/`, and `chatroom.md`.

If the host does not let you or the subagents write in the project (example: a background session), make a git worktree of the project and use its base folder. Tell the user the worktree path at the end.

## 3. Round 1

Spawn one subagent for each tool. Start as many at the same time as the host lets you. If the host has a limit (example: 20), start the other agents when slots become free. The start order has no effect: each agent sees only the posts from the rounds before its round. Prompt for each:

```
You are the <tool-slug> agent in a deep-think session.
Read SKILL_DIR/agent.md and follow it.
TOOL=<tool-slug>
SKILL_DIR=<absolute path>
SESSION=<absolute path>
ROUND=1
```

Wait until all 25 finish. Then check:

```bash
"SKILL_DIR/scripts/status.sh" "SESSION/chatroom.md" 1
```

If an agent is in `silent`, spawn it again one time.

## 4. Rounds 2 to 3

For each round, spawn 25 new subagents with the same prompt and the new `ROUND`, in the same way as round 1. Start a round only after all agents of the round before finish. The agents keep no memory between rounds. Their result files and the chatroom hold the state.

After each round, run `status.sh` for that round. Stop the discussion when one of these is true:

- Round 3 is complete.
- `active=0`: all agents posted only `PASS`.

The user can ask for a different number of rounds.

## 5. Converge

Spawn one subagent:

```
You are the converge agent in a deep-think session.
Read SKILL_DIR/converge.md and follow it.
SKILL_DIR=<absolute path>
SESSION=<absolute path>
```

## 6. Report

Read `SESSION/converge.md`. Read parts of `chatroom.md` and `tools/*.md` when you need the evidence.

Write `SESSION/report.md` with Minto Pyramid (`SKILL_DIR/tools/minto-pyramid.md`):

1. The answer, in 1 to 2 sentences.
2. 2 to 4 key arguments, each with evidence from the agents. Name the tool that gave the evidence.
3. The first step to take, and the main risk.
4. Open disagreements, and the data that can decide them.

Show the report to the user. Give the path to `SESSION`. Do not delete the session folder.
