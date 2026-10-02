# deep-think

A Claude Code skill that thinks about a hard problem with many agents at the same time.

Each agent uses a different thinking tool from [untools](https://untools.co/). The skill uses all 25 tools for each problem. The agents talk to each other in a chatroom. The chatroom is a Markdown file. Then the skill gives one report with the solutions.

> Status: first build. Not yet tested on a full run with 25 agents. See [PLAN.md](PLAN.md).

## How it works

```
  /deep-think "<problem>"
          │
          ▼
  ┌──────────────────┐
  │ 1. Frame         │  Make the problem statement clear.
  │                  │  Make .claude/deep-think/<problem-slug>/
  └────────┬─────────┘
           ▼
  ┌──────────────────┐
  │ 2. Open chatroom │  Make chatroom.md in the problem folder.
  └────────┬─────────┘
           ▼
  ┌──────────────────┐     ┌──────────────────────────┐
  │ 3. Round 1       │────▶│ chatroom.md              │
  │ 25 subagents,    │     │ (append only, posts are  │
  │ 1 tool each      │     │  added with post.sh)     │
  └────────┬─────────┘     │                          │
           ▼               │                          │
  ┌──────────────────┐     │                          │
  │ 4. Rounds 2..N   │◀───▶│                          │
  │ Read and reply   │     └──────────────────────────┘
  └────────┬─────────┘
           ▼
  ┌──────────────────┐
  │ 5. Stop          │  After N rounds, or when all agents post PASS.
  └────────┬─────────┘
           ▼
  ┌──────────────────┐
  │ 6. Report        │  Compare the solutions. Write report.md.
  │                  │  Answer first (Minto Pyramid).
  └──────────────────┘
```

## Usage

```
/deep-think Why do our trial users stop after day 3?
```

## Problem folder

Claude Code uses `.claude/deep-think/<problem-slug>/`. Other agents that use `.agents/` use `.agents/deep-think/<problem-slug>/`.

```
<problem-slug>/
├── problem.md     # The framed problem statement
├── tools/*.md     # The full result of each subagent
├── chatroom.md    # The discussion
├── converge.md    # The comparison of the solutions
└── report.md      # The final report
```

## Parts

| Part | Purpose |
|---|---|
| `SKILL.md` | Steps the main agent follows. |
| `agent.md` | Rules for each tool subagent. |
| `converge.md` | Steps for the subagent that compares the solutions. |
| `tools/*.md` | One prompt for each of the 25 untools tools. |
| `scripts/new-session.sh` | Make the problem folder and the chatroom. |
| `scripts/post.sh` | Add a post to `chatroom.md` with a lock. |
| `scripts/status.sh` | Show the state of a round. |

## Install

```
ln -s "$PWD" ~/.claude/skills/deep-think
```

## Links

- Thinking tools: https://untools.co/
- Vault note: `~/Personal/obsidian/projects/deep-think-skill.md`
