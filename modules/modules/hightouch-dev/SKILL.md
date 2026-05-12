---
name: hightouch-dev
description: Full development workflow for the Hightouch repo (hightouchio/hightouch). Orchestrates everything from picking a Linear ticket to opening a PR with passing CI. Use this when starting or resuming work on a Hightouch issue, creating a branch for a Linear ticket, gathering context for a bug or feature, investigating Datadog errors, looking up destination API behavior, or getting ready to ship. Trigger on phrases like "let's work on a ticket", "pick up a Linear issue", "start a Hightouch branch", "resume my ticket", "open a PR for this", or any time the user is working in the Hightouch codebase. Also trigger on "serve the people" — this is a shorthand invocation that goes directly to Phase 1 ticket selection.
---

# Hightouch Development Workflow

End-to-end dev loop for the Hightouch repo: ticket selection → branch → context → investigation → implementation → PR → CI.

## Configuration

Adjust these if your local paths differ:

```
HIGHTOUCH_REPO=~/Software/hightouch
DESTINATIONS_CONTEXT=~/Software/destinations-context
TICKET_MEMORY_ROOT=~/.claude/tickets
```

---

## Phase 0: MCP Health Check

Before starting, probe each required MCP with a lightweight call. Retry slow-to-connect ones (slack, circleci) once before marking unavailable.

| MCP | Probe |
|-----|-------|
| linear | list teams |
| slack | list channels |
| github | get authenticated user |
| git | git status in HIGHTOUCH_REPO |
| datadog | get active hosts count |
| circleci | list followed projects |
| context7 | resolve-library-id with libraryName: "react", query: "hooks" |
| memory | read_graph |

Show a summary. Flag any failures with the MCP name and reason. If slack is down, warn that Phase 3 will be degraded. Continue regardless — skip unavailable MCPs gracefully throughout the workflow.

---

## Phase 1: Pick a Ticket

Fetch all active Linear issues assigned to you using two calls — one per active state type — to exclude done and cancelled tickets at the query level rather than filtering after the fact:

```
list_issues(assignee: "me", state: "started", limit: 50)
list_issues(assignee: "me", state: "unstarted", limit: 50)
```

Merge the two result sets in memory. **Do not write the results to disk or parse them with bash** — work with the MCP response directly in context.

While fetching, also silently clean up stale memory: scan `{TICKET_MEMORY_ROOT}/` for any ticket directories whose `context.md` shows a `Done` status with a completion date older than 14 days, and delete those directories. Only mention this to the user if something goes wrong.

Compute an urgency score for each ticket:

- **Priority**: Urgent=40, High=25, Medium=10, Normal=5, No priority=0
- **Age**: +1 per day since creation (cap at 30)
- **Due date**: +50 if overdue, +30 if due within 3 days, +15 if due within 7 days

Sort descending. Display as a numbered list with color coding:
- 🔴 **Score ≥ 60** — critically urgent. Call this out explicitly and say why.
- 🟡 **Score 30–59** — elevated priority
- 🟢 **Score < 30** — routine

Wait for the user to select one by number.

**Resuming work**: If the user already has a Hightouch branch checked out matching `vera/<ticket-id>-*`, infer the ticket and skip this phase.

---

## Phase 2: Branch Setup

Given the selected ticket (e.g. `PLAT-1234`, title "Fix webhook retry logic"):

1. Slugify: `vera/plat-1234-fix-webhook-retry-logic` (lowercase, spaces→hyphens, strip special chars)
2. Check for an existing branch:
   - Local: `git branch --list "vera/<ticket-id-lowercase>*"`
   - Remote: github plugin, repo `hightouchio/hightouch`, branches matching `vera/<ticket-id-lowercase>*`
3. If found: check it out and pull. Tell the user.
4. If not found: create from `master` and check it out.
5. Confirm the active branch to the user before continuing.

---

## Phase 3: Load Ticket Memory

Memory lives at `{TICKET_MEMORY_ROOT}/<ticket-id>/`. See `references/ticket-memory.md` for the full file structure.

**Done tickets**: if the Linear ticket's status is `Done`, do not load Slack, Datadog, or any additional context. Load `context.md` (if it exists) for reference only and skip to Phase 8 or stop — there is nothing left to investigate. If the ticket has been `Done` for more than 14 days, delete its memory directory and inform the user.

**If memory exists**: load all files. Proceed to new-info checks (Slack refresh below).

**If no memory**: create the directory, initialize `context.md`:

```markdown
# <TICKET-ID>: <Ticket Title>
Branch: <branch-name>
Linear URL: <url>
Opened: <YYYY-MM-DD>
Type: (pending)
datadog_queried: false
```

### Load Linear Details

Fetch the full ticket: description, comments, labels, assignees, priority, due date. Append to `context.md`.

### Load Slack Thread

Look for a Slack thread URL in the Linear ticket description and comments. This thread should almost always exist — if you can't find one, **warn the user prominently** (this is abnormal for this team) and continue without Slack context.

If found:
- Read the full thread via the slack MCP using `conversations_replies` with params `channel_id` and `thread_ts` (not `channel` — the parameter name is `channel_id`)
- Recursively load any Slack URLs referenced within that thread
- Save all content to `slack.md`

If `slack.md` already exists: find the timestamp of the last saved message and fetch only newer messages. Append them.

---

## Phase 4: Datadog Investigation

**Skip entirely if**:
- `context.md` shows `datadog_queried: true`, OR
- The ticket is inferred to be a **feature request**, OR
- The bug description indicates **silent corruption** — syncs complete successfully but written values are wrong, records are missing, or output is subtly incorrect. These bugs produce no errors in Datadog; querying is wasted effort. Signs: "wrong value", "incorrect field", "not what we expected", "data looks off", "records not showing up" without any mention of failures or exceptions.

**Infer feature vs. bug** from the ticket title, description, Slack thread, and labels:
- Bug signals: error messages, stack traces, customer complaints, "broken", "failing", "regression", "not working"
- Feature signals: "add", "implement", "support for", "new", "introduce", "allow", "expose"
- When ambiguous, ask the user before proceeding.

**If this is a bug and hasn't been queried**:

1. Extract error keywords from `slack.md` and the Linear description. Pick the most specific, least common phrases.
2. Identify a destination slug if one is mentioned (ticket title, description, Slack, or logs).
3. Query Datadog APM logs:
   - Time range: last 3 days
   - Limit: 100 results max
   - If a destination slug is known: filter by it
   - Use exact error strings, not broad terms. Be conservative.
4. Deduplicate results. Extract: unique error messages, originating call sites (file + function), notable stack frames, any correlated request IDs.
5. Save findings to `datadog.md`. Set `datadog_queried: true` in `context.md`.

---

## Phase 5: Classify the Change

Based on all gathered context, determine:

- **API change**: fix requires changing how Hightouch talks to an external service — new/modified endpoint, changed parameters, auth flow, response parsing, field mapping. Signs: HTTP errors, API docs referenced, endpoint URLs in logs, destination API behavior described.
- **Logic change**: purely internal — no change to external API calls. Signs: data transformation, orchestration, retry logic, internal state machine, UI behavior.

Save to `context.md`:
```
Change type: API | Logic
Reasoning: <one sentence>
```

---

## Phase 6: API Investigation (API changes only)

Skip if change type is Logic.

Read `references/lap-trust.md` for full instructions. Summary:

1. Identify the destination slug.
2. Load `{DESTINATIONS_CONTEXT}/destinations/<destination>/context.lap` — this is the primary authority.
3. Use context7 to pull live docs for the destination's API. Cross-reference against the LAP file.
4. Identify the specific gap: what is the current implementation doing vs. what should it do? Be precise (e.g. "POST /contacts missing `sync_mode` param", "v2 endpoint deprecated, v3 required").
5. Save the gap analysis to `codebase.md`.

---

## Phase 7: Locate Code

Target: `{HIGHTOUCH_REPO}/packages/core/backend/destinations/<destination>/`

For non-destination tickets, navigate to the relevant package based on ticket context (callsite logs are often the fastest guide).

**Search order**:
1. If you have specific error call sites (Datadog) or API route names: grep/glob for those first.
2. If that's insufficient: read files one by one from the destination folder.
3. **Hard stop at 15 files** — pause and ask the user to confirm before reading more.

Once you have a sufficient picture, determine which file(s) and function(s) need to change. Save to `codebase.md`:

```markdown
## Code Location
File: <relative path>
Function/section: <name>
Change needed: <1-2 sentence description>
```

---

## Phase 8: Implementation

With full context loaded, attempt the fix or feature.

**If confident** (clear gap + clear location + straightforward change): write the code. Be surgical — touch only what needs changing.

**If not confident**: write a failing test first that encodes the expected behavior. A focused failing test is a better deliverable than a wrong fix.

Either way, write a test that would catch a regression. Save the test file path(s) to `testing.md`.

**Test fixture guidance**:
- Before constructing fixtures for complex SDK types (e.g. `DestinationRecord`), grep the same package for existing test files to find established examples.
- When a type has required fields irrelevant to the test, stub them with minimal values and cast with `as T[]` directly — not `as unknown as T[]`. The latter signals a type mismatch that should be fixed at the fixture level instead.

**Re-entry**: this phase is always re-enterable. If the user says "try again", "take another shot", or "what would you do differently" — re-read all memory files and produce a revised attempt. Use everything you've learned from prior attempts.

After any significant back-and-forth or corrections from the user, update `codebase.md` with what changed and why.

---

## Phase 9: PR & CI

When the user signals readiness to ship ("this looks good", "open a PR", "ship it"):

1. **Publish branch**: push to remote if not already up to date.
2. **Prettier**: run `pnpm prettier --write` on all files changed since `master`. Confirm clean exit.
3. **Tests**: run all tests associated with this ticket (from `testing.md`). All must pass before continuing. For destination tests, run from `packages/backend/destinations/` — not the monorepo root. The root Jest config does not wire up the TypeScript transformer the same way, so `import type` and other TS syntax will fail with a Babel parse error.
4. **Open PR**: create a PR on `hightouchio/hightouch` targeting `master` using `mcp__plugin_claude-code-home-manager_github__create_pull_request` — do not use `gh pr create` or any `gh` CLI commands, as `gh` auth is not reliable in this environment. Use the Linear ticket title as the PR title. Include the Linear URL in the PR description body. If push succeeds but PR creation fails, do not re-push — the branch is already on remote, go straight to retrying PR creation via the MCP.
5. **Monitor CI**:
   - Poll CircleCI every 15 seconds for job status on this PR
   - Do **not** read job logs unless a job fails
   - On failure: read the failure logs, diagnose the cause, propose a specific fix, and ask the user if they want to apply it
6. **Autopilot exception**: if you have extreme confidence in the solution (it's tested, clean, and unambiguous), you may commit, push, and open the PR yourself without additional prompts.
