# Plan

## Goal

Make a Claude Code skill, `/deep-think`. The skill uses a team of subagents to find solutions to one problem. Each subagent uses one thinking tool from untools.co. The subagents talk in a temporary chatroom.

## Decisions

### Chatroom: mayfly

| | mayfly | PeerTalk |
|---|---|---|
| Agents in one room | Any number | 2 |
| Self-host | Yes. One Go binary with SQLite. | No information found. |
| Client | One file (Python, Node, or Go). No install. | MCP server, CLI, or web. |
| Encryption | End to end. The URL is the password. | End to end. |
| Room life | Expires after a retention time. Anyone with the URL can delete it. | The room closes after 30 minutes. |

Use mayfly. A session has 3–5 agents, and PeerTalk connects only 2. mayfly can also run on the laptop with `go run ./cmd/mayfly`, so no data goes to a public server.

Read these mayfly docs before step 2: `srv/docs/protocol.md`, `srv/docs/clients.md`, `srv/docs/create.md`, `srv/docs/operations.md`.

### Thinking tools

untools.co has 25 tools in 4 groups. Not all tools help with all problems. The skill selects tools for the type of problem.

| Problem type | Tools |
|---|---|
| Root cause ("why does X happen?") | Ishikawa Diagram, Iceberg Model, Issue Trees, Ladder of Inference |
| Decision ("A or B?") | Six Thinking Hats, Decision Matrix, Second-order Thinking, Hard Choice Model, Cynefin Framework |
| New ideas ("how can we…?") | Zwicky Box, Inversion, First Principles, Productive Thinking Model |
| Systems ("why does this keep getting worse?") | Connection Circles, Reinforcing Feedback Loop, Balancing Feedback Loop, Concept Map |
| Prioritization | Impact-Effort Matrix, Eisenhower Matrix, Confidence Determines Speed vs. Quality |
| Conflict between people or goals | Conflict Resolution Diagram |
| Framing (all problems, step 1) | Abstraction Laddering |
| Final report (all problems, step 5) | Minto Pyramid |

Do not use Situation-Behavior-Impact. It is a tool for feedback to people, not for problem solving. OODA Loop is optional. It is for fast decisions, and deep think is slow.

## Flow

1. **Frame.** The main agent uses Abstraction Laddering to make the problem statement clear. It asks the user one question if the problem is not clear.
2. **Select tools.** The main agent gives the problem a type and selects 3–5 tools from the table. The user can set the tools with `--tools`.
3. **Open the chatroom.** A script starts a local mayfly server if one is not running. The script makes a channel and gives back the channel URL.
4. **Diverge.** The main agent spawns one subagent for each tool. They run at the same time. Each subagent:
   - reads its tool prompt (`tools/<tool>.md`),
   - applies the tool to the problem,
   - posts its result to the channel,
   - reads the posts of the other agents,
   - posts replies: agreements, disagreements, and new ideas,
   - stops after a fixed number of rounds (start with 3).
5. **Converge.** One more subagent reads all the posts. It uses Decision Matrix and Second-order Thinking to compare the solutions.
6. **Report.** The main agent writes the report with Minto Pyramid: the answer first, then the reasons, then the details. It saves the chat transcript. It deletes the channel.

## Milestones

| # | Milestone | Done when |
|---|---|---|
| M1 | Tool prompts | `tools/*.md` has one prompt for each tool in the table. Each prompt has the steps of the tool and the output format. |
| M2 | Single agent, no chat | `/deep-think` runs the subagents in parallel. Each subagent gives its result only to the main agent. The report works. |
| M3 | mayfly chat | Subagents post to and read from a local mayfly channel. The channel is deleted at the end. |
| M4 | Rounds and stop rules | The chat stops after N rounds, or when no agent posts a new idea. |
| M5 | Tests on real problems | Run on 5 real problems. Compare the result with one agent and no tools. Keep the changes that make the result better. |

M2 gives a useful skill before the chatroom is ready. M3 shows if the chat makes the result better. If the chat does not help, stop at M2.

## Open questions

- Can a Claude Code subagent wait for new messages (mayfly long-poll) without a high cost? Or must the main agent run the rounds?
- How many rounds give the best result for the cost?
- Is a local mayfly server or the hosted mayfly.chat better? Local is private, but it needs Go.
- Must the user see the chat while it runs? mayfly has a browser view.
- Where is the transcript saved? Option: the Obsidian vault, `knowledge/`.

## Risks

- **Cost.** 5 agents × 3 rounds uses many tokens. Start with a small number of agents and rounds.
- **Same answers.** The agents can agree too quickly. Each tool prompt must tell the agent to keep its own view.
- **Prompt injection.** Anyone with the channel URL can post. Keep the URL private. Use a local server.
