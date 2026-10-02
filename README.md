# deep-think

A Claude Code skill that thinks about a hard problem with many agents at the same time.

Each agent uses a different thinking tool from [untools](https://untools.co/). The agents talk to each other in a temporary chatroom. Then the skill gives one report with the solutions.

> Status: idea. Nothing works yet. See [PLAN.md](PLAN.md).

## How it works

```
  /deep-think "<problem>"
          │
          ▼
  ┌──────────────────┐
  │ 1. Frame         │  Make the problem statement clear.
  └────────┬─────────┘
           ▼
  ┌──────────────────┐
  │ 2. Select tools  │  Select 3–5 untools tools for this type of problem.
  └────────┬─────────┘
           ▼
  ┌──────────────────┐     ┌──────────────────────────┐
  │ 3. Diverge       │────▶│ Temporary mayfly channel │
  │ 1 subagent/tool  │◀────│ (agents read and post)   │
  └────────┬─────────┘     └──────────────────────────┘
           ▼
  ┌──────────────────┐
  │ 4. Converge      │  Compare the options. Find the risks.
  └────────┬─────────┘
           ▼
  ┌──────────────────┐
  │ 5. Report        │  Answer first (Minto Pyramid). Delete the channel.
  └──────────────────┘
```

## Usage (planned)

```
/deep-think Why do our trial users stop after day 3?
/deep-think --tools inversion,first-principles,zwicky-box "Name for a new product"
```

## Parts

| Part | Purpose |
|---|---|
| `SKILL.md` | Steps the main agent follows. |
| `tools/*.md` | One prompt for each untools tool. |
| `scripts/` | Start mayfly, make a channel, delete the channel. |

## Links

- Thinking tools: https://untools.co/
- Chatroom: https://github.com/josharian/mayfly (hosted at https://mayfly.chat/)
- Other chatroom option: https://peertalk.ai/
- Vault note: `~/Personal/obsidian/projects/deep-think-skill.md`
