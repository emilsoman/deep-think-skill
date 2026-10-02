# Plan

## Goal

Make a skill, `/deep-think`. The skill uses a team of subagents to find solutions to one problem. Each subagent uses one thinking tool from untools.co. The skill uses all the tools for each problem. The subagents talk in a chatroom. The chatroom is a Markdown file.

## Decisions

### Thinking tools: use all of them

untools.co has 25 tools in 4 groups. The skill spawns one subagent for each tool. It does not select tools for the type of problem.

| Group | Tools |
|---|---|
| Decision Making (10) | Six Thinking Hats, Eisenhower Matrix, Second-order Thinking, Decision Matrix, Impact-Effort Matrix, Ladder of Inference, Hard Choice Model, OODA Loop, Cynefin Framework, Confidence Determines Speed vs. Quality |
| Problem Solving (8) | Ishikawa Diagram, Abstraction Laddering, Conflict Resolution Diagram, Zwicky Box, Productive Thinking Model, Inversion, Issue Trees, First Principles |
| Systems Thinking (5) | Iceberg Model, Connection Circles, Concept Map, Balancing Feedback Loop, Reinforcing Feedback Loop |
| Communication (2) | Situation-Behavior-Impact, Minto Pyramid |

Some tools do not fit all problems. Example: Situation-Behavior-Impact is for feedback to a person. If a tool does not fit, its subagent writes a short result: why the tool does not fit, and what the tool can still show about the problem. The subagent still reads the chatroom and replies to the other agents.

The main agent also uses two tools itself: Abstraction Laddering to frame the problem (step 1), and Minto Pyramid to write the report (step 6). The subagents for these two tools still run.

### Chatroom: one Markdown file

The chatroom is `chatroom.md` in the problem folder. All subagents read it and add posts to it. There is no server and no network.

Rules for the file:

- **Append only.** A subagent never edits or deletes a post. It adds new posts at the end.
- **Add posts with a script.** `scripts/post.sh <chatroom> <round> <from> <to>` reads the post text from stdin. It gets a lock (`mkdir <chatroom>.lock`), appends the post in one write, and removes the lock. Two subagents can then post at the same time, and no post is lost. Subagents do not use the Edit or Write tool on `chatroom.md`.
- **Post format.**

  ```markdown
  ## r2 · inversion → first-principles · 2026-10-03T14:05:11Z

  <text>
  ```

  `r2` is the round. `→ first-principles` is the agent that the post replies to. Use `→ all` for a post to all agents.

### Problem folder

Each problem gets a folder in the project where the user runs the skill:

- Claude Code: `.claude/deep-think/<problem-slug>/`
- Other agents that use `.agents/`: `.agents/deep-think/<problem-slug>/`

`<problem-slug>` is the problem statement in kebab case, with a maximum of 6 words. Example: `why-trial-users-stop-after-day-3`. If the folder exists, add `-2`, `-3`, and so on.

```
.claude/deep-think/<problem-slug>/
├── problem.md        # The framed problem statement (step 1)
├── tools/
│   ├── inversion.md  # The full result of one subagent (one file for each tool)
│   └── ...
├── chatroom.md       # The discussion (append only)
├── converge.md       # The comparison of the solutions (step 6)
└── report.md         # The final report (step 6)
```

The skill does not delete the folder. The folder is the record of the session.

## Flow

1. **Frame.** The main agent uses Abstraction Laddering to make the problem statement clear. It asks the user one question if the problem is not clear. It makes the problem folder and writes `problem.md`.
2. **Open the chatroom.** The main agent makes `chatroom.md` with a header: the problem statement, the list of agents, and the rules for posts.
3. **Round 1: apply the tools.** The main agent spawns 25 subagents at the same time, one for each tool. Each subagent:
   - reads `problem.md` and its tool prompt (`tools/<tool>.md` in the skill),
   - applies the tool to the problem,
   - writes its full result to `<problem folder>/tools/<tool>.md`,
   - posts a short summary (maximum 10 lines) to `chatroom.md`, `→ all`.
4. **Rounds 2 to N: discuss.** The main agent starts each round after all subagents finish the round before. It spawns 25 new subagents for each round. The subagents keep no memory between rounds: the result files and the chatroom hold the state. Each subagent:
   - reads its own result `tools/<tool>.md`,
   - reads the new posts in `chatroom.md`,
   - posts replies: agreements, disagreements, questions, and new ideas that come from combining its tool with the posts of other agents,
   - keeps the view of its own tool. It does not only agree.
   - posts `PASS` if it has nothing new to say.
5. **Stop.** The chat stops after N rounds (start with N = 3), or when all agents post `PASS` in one round.
6. **Converge and report.** One more subagent reads `chatroom.md` and all `tools/*.md`. It compares the solutions with Decision Matrix and Second-order Thinking, and writes `converge.md`. Then the main agent writes `report.md` with Minto Pyramid: the answer first, then the reasons, then the details. The main agent shows the report to the user and gives the path to the problem folder.

## Milestones

| # | Milestone | Done when |
|---|---|---|
| M1 | Tool prompts | `tools/*.md` has one prompt for each of the 25 tools. Each prompt has the steps of the tool, the output format, and what to do if the tool does not fit. |
| M2 | Problem folder and round 1 | `/deep-think` makes the problem folder, spawns 25 subagents, and each subagent writes `tools/<tool>.md` and one post. The report works from these files. |
| M3 | Chatroom rounds | `scripts/post.sh` works with 25 agents that post at the same time. Rounds 2 to N work. |
| M4 | Stop rules | The chat stops after N rounds, or when all agents post `PASS`. |
| M5 | `.agents/` support | The skill uses `.agents/deep-think/` when the agent is not Claude Code. |
| M6 | Tests on real problems | Run on 5 real problems. Compare the result with one agent and no tools. Keep the changes that make the result better. |

M2 gives a useful skill before the chat rounds are ready. M3 shows if the chat makes the result better. If the chat does not help, stop at M2.

## Files

| File | Purpose |
|---|---|
| `SKILL.md` | Steps the main agent follows. |
| `agent.md` | Rules for each tool subagent: files, posts, rounds. |
| `converge.md` | Steps for the converge subagent. |
| `tools/*.md` | One prompt for each of the 25 tools. |
| `scripts/new-session.sh` | Make the problem folder, `problem.md`, and `chatroom.md`. |
| `scripts/post.sh` | Add a post to `chatroom.md` with a lock. |
| `scripts/status.sh` | Count the posts and `PASS` posts in a round. Show the agents that did not post. |

## Open questions

- How does the skill know if the agent is Claude Code or an agent that uses `.agents/`? Option: the skill checks which folder exists in the project. If both or none exist, it uses `.claude/` in Claude Code.
- How many rounds give the best result for the cost?
- Must `.claude/deep-think/` go in `.gitignore`?

## Risks

- **Cost.** 25 agents × 3 rounds uses many tokens. Keep posts short (maximum 10 lines). Agents with nothing new post `PASS`. Use a smaller model for the subagents if the result stays good.
- **Long chatroom.** 25 agents × 3 rounds = up to 75 posts. In round 3, a subagent can read only the posts that reply to it, and the summaries from round 1.
- **Same answers.** The agents can agree too quickly. Each tool prompt must tell the agent to keep the view of its tool.
- **Lost posts.** If a subagent writes to `chatroom.md` without the script, two writes at the same time can lose a post. The tool prompts must tell the agents to use only `scripts/post.sh`.
- **Stale lock.** If a subagent stops while it has the lock, the other agents wait. `post.sh` removes a lock that is older than 10 seconds. It uses the age of the lock folder, not a file in it, because an agent can read that file before the owner writes it.
