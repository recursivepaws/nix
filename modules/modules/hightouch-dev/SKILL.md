---
name: hightouch-dev
description: Full development workflow for the Hightouch repo (hightouchio/hightouch). Orchestrates everything from picking a Linear ticket to opening a PR with passing CI. Use this when starting or resuming work on a Hightouch issue, creating a branch for a Linear ticket, gathering context for a bug or feature, investigating Datadog errors, looking up destination API behavior, or getting ready to ship. Trigger on phrases like "let's work on a ticket", "pick up a Linear issue", "start a Hightouch branch", "resume my ticket", "open a PR for this", or any time the user is working in the Hightouch codebase. Also trigger on "serve the people" — this is a shorthand invocation that goes directly to Phase 1 ticket selection.
allowed-tools: [
  "Bash", "Glob", "Grep", "Read", "Write", "Edit",
  "mcp__plugin_linear_linear__list_issues",
  "mcp__plugin_linear_linear__get_issue",
  "mcp__plugin_linear_linear__get_issue_status",
  "mcp__plugin_linear_linear__list_issue_statuses",
  "mcp__plugin_linear_linear__list_teams",
  "mcp__plugin_linear_linear__get_team",
  "mcp__plugin_linear_linear__list_comments",
  "mcp__plugin_linear_linear__get_user",
  "mcp__plugin_linear_linear__list_users",
  "mcp__plugin_claude-code-home-manager_github__get_me",
  "mcp__plugin_claude-code-home-manager_github__list_branches",
  "mcp__plugin_claude-code-home-manager_github__create_branch",
  "mcp__plugin_claude-code-home-manager_github__get_file_contents",
  "mcp__plugin_claude-code-home-manager_github__list_pull_requests",
  "mcp__plugin_claude-code-home-manager_github__pull_request_read",
  "mcp__plugin_claude-code-home-manager_github__list_commits",
  "mcp__plugin_claude-code-home-manager_github__get_commit",
  "mcp__plugin_claude-code-home-manager_github__search_code",
  "mcp__plugin_claude-code-home-manager_github__search_issues",
  "mcp__plugin_claude-code-home-manager_github__search_pull_requests",
  "mcp__plugin_claude-code-home-manager_git__git_status",
  "mcp__plugin_claude-code-home-manager_git__git_log",
  "mcp__plugin_claude-code-home-manager_git__git_diff",
  "mcp__plugin_claude-code-home-manager_git__git_diff_staged",
  "mcp__plugin_claude-code-home-manager_git__git_diff_unstaged",
  "mcp__plugin_claude-code-home-manager_git__git_branch",
  "mcp__plugin_claude-code-home-manager_git__git_checkout",
  "mcp__plugin_claude-code-home-manager_git__git_create_branch",
  "mcp__plugin_claude-code-home-manager_git__git_show",
  "mcp__plugin_claude-code-home-manager_datadog__get_logs",
  "mcp__plugin_claude-code-home-manager_datadog__get_active_hosts_count",
  "mcp__plugin_claude-code-home-manager_datadog__query_metrics",
  "mcp__plugin_claude-code-home-manager_datadog__list_traces",
  "mcp__plugin_claude-code-home-manager_datadog__get_monitors",
  "mcp__plugin_claude-code-home-manager_datadog__get_incident",
  "mcp__plugin_claude-code-home-manager_datadog__list_incidents",
  "mcp__plugin_claude-code-home-manager_circleci__get_latest_pipeline_status",
  "mcp__plugin_claude-code-home-manager_circleci__get_build_failure_logs",
  "mcp__plugin_claude-code-home-manager_circleci__get_job_test_results",
  "mcp__plugin_claude-code-home-manager_circleci__list_followed_projects",
  "mcp__plugin_claude-code-home-manager_circleci__rerun_workflow",
  "mcp__plugin_claude-code-home-manager_circleci__list_artifacts",
  "mcp__plugin_claude-code-home-manager_context7__resolve-library-id",
  "mcp__plugin_claude-code-home-manager_context7__query-docs",
  "mcp__plugin_claude-code-home-manager_memory__read_graph",
  "mcp__plugin_claude-code-home-manager_memory__search_nodes",
  "mcp__plugin_claude-code-home-manager_memory__open_nodes",
  "mcp__plugin_claude-code-home-manager_memory__create_entities",
  "mcp__plugin_claude-code-home-manager_memory__add_observations",
  "mcp__plugin_claude-code-home-manager_memory__create_relations",
  "mcp__plugin_claude-code-home-manager_memory__delete_entities",
  "mcp__plugin_claude-code-home-manager_memory__delete_observations",
  "mcp__plugin_claude-code-home-manager_filesystem__read_file",
  "mcp__plugin_claude-code-home-manager_filesystem__read_multiple_files",
  "mcp__plugin_claude-code-home-manager_filesystem__write_file",
  "mcp__plugin_claude-code-home-manager_filesystem__list_directory",
  "mcp__plugin_claude-code-home-manager_filesystem__create_directory",
  "mcp__plugin_claude-code-home-manager_filesystem__search_files",
  "mcp__plugin_claude-code-home-manager_filesystem__move_file",
  "mcp__plugin_claude-code-home-manager_filesystem__edit_file",
  "mcp__plugin_claude-code-home-manager_fetch__fetch"
]
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

Show a summary. Flag any failures with the MCP name and reason. Skip unavailable MCPs gracefully — **except Slack**. If the Slack MCP is unavailable, stop and ask the user:

> "The Slack MCP is not connected. Slack context is important for understanding ticket background. Can you check the environment variables / MCP config and reconnect before we continue?"

Wait for their response. Only proceed without Slack if the user explicitly says to. Do not infer consent — a non-answer or "let's keep going" is not explicit consent.

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

**If Slack MCP is unavailable** (flagged in Phase 0 health check as down and user has not explicitly okayed skipping it): stop here. Do not proceed to Phase 4. Re-prompt the user to fix the Slack MCP before continuing. Only resume if the user explicitly confirms they want to proceed without Slack.

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
- Ticket type (from Phase 5) is any of: `new-destination`, `destination-version-update`, `destination-bug-silent`, `destination-feature`, `platform-feature`

**Run Datadog if** ticket type is `destination-bug-erroring` or `platform-bug`.

**If ticket type is not yet classified** (Phase 5 hasn't run): infer from the ticket title, description, Slack thread, and labels before deciding:
- Bug signals: error messages, stack traces, customer complaints, "broken", "failing", "regression", "not working"
- Silent corruption signals: "wrong value", "incorrect field", "not what we expected", "data looks off", "records not showing up" without failures or exceptions — skip Datadog
- Feature signals: "add", "implement", "support for", "new", "introduce", "allow", "expose" — skip Datadog
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

### Step 1: Ticket Type

Classify into one of the following types based on the ticket title, description, Slack thread, and labels. When ambiguous, ask the user.

| Type | Description | Signals |
|------|-------------|---------|
| `new-destination` | Net new integration, doesn't exist in the codebase | "new destination", "add support for X", destination slug not found in `packages/` |
| `destination-version-update` | Existing destination needs an API version bump | "v2 → v3", "deprecated endpoint", "migrate to new API", "API upgrade" |
| `destination-bug-erroring` | Existing destination failing with errors or exceptions | Error messages, stack traces, "broken", "failing", "regression" |
| `destination-bug-silent` | Syncs complete but data is wrong or missing | "wrong value", "missing records", "data looks off", no exceptions mentioned |
| `destination-feature` | New capability on an existing destination | "add field", "support X operation", "expose Y", destination already exists |
| `platform-bug` | Non-destination bug (orchestration, infra, scheduler, etc.) | No destination slug, core platform errors |
| `platform-feature` | Non-destination feature work | No destination slug, "add", "implement", "new" in platform context |

### Step 2: Destination Slug & Package Scripts

If the ticket type involves a destination (all `destination-*` types):

1. Identify the destination slug (from ticket, Slack, or Datadog logs).
2. Locate its directory: `{HIGHTOUCH_REPO}/packages/core/backend/destinations/<slug>/`
3. Read its `package.json` and extract available scripts. Save to `context.md`:

```
Destination: <slug>
Destination path: packages/core/backend/destinations/<slug>/
Package scripts: <list of script names and their commands>
```

4. Keep this context active for the remainder of the session. All test runs, builds, and dev commands should be run using the scripts from this `package.json` via the `/pnpm` skill (see `{HIGHTOUCH_REPO}/.claude/skills/pnpm/`), not hardcoded commands. When in doubt about which script to use, check the destination's `package.json` first.

### Step 3: Sub-skill Routing

For ticket types that have dedicated sub-skills, hand off now rather than continuing through Phases 6–8:

- **`new-destination`** → Ask the user: "Does this destination follow CRUD/ORM patterns (create, update, upsert, delete on named objects), or does it need event/audience/segment sync support?" Then invoke the appropriate skill:
  - CRUD/ORM patterns → `/write-orm-destination <slug>`
  - Event/audience/multi-sync → `/write-destination <slug>`
  - If unclear → show both options and ask
- **`destination-version-update`** → invoke `/update-destination-version <slug> <current> <target>`

For all other types, continue to Phase 6.

### Step 4: Change Scope (bug and feature tickets only)

For `destination-bug-erroring`, `destination-bug-silent`, `destination-feature`, `platform-bug`, `platform-feature`:

- **API change**: fix requires changing how Hightouch talks to an external service — new/modified endpoint, changed parameters, auth flow, response parsing, field mapping.
- **Logic change**: purely internal — data transformation, orchestration, retry logic, internal state machine, UI behavior.

Save to `context.md`:
```
Ticket type: <type>
Change scope: API | Logic
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

**If a destination is in scope** (established in Phase 5): confirm the destination path and `package.json` scripts are loaded in context before reading any code. If the destination's `package.json` hasn't been read yet, do that now. These scripts inform how to run tests and builds throughout Phases 7–9 — do not assume commands, always check the scripts first.

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

**Running tests and scripts**: Always use the `/pnpm` skill (at `{HIGHTOUCH_REPO}/.claude/skills/pnpm/`) and the scripts from the destination's `package.json` (loaded in Phase 5/7). Do not hardcode `jest`, `tsc`, or other commands directly — the destination's scripts may wrap them with necessary flags or environment setup. When running a destination-scoped command, run it from within the destination's directory, not the monorepo root.

**Test fixture guidance**:
- Before constructing fixtures for complex SDK types (e.g. `DestinationRecord`), grep the same package for existing test files to find established examples.
- When a type has required fields irrelevant to the test, stub them with minimal values and cast with `as T[]` directly — not `as unknown as T[]`. The latter signals a type mismatch that should be fixed at the fixture level instead.

**Re-entry**: this phase is always re-enterable. If the user says "try again", "take another shot", or "what would you do differently" — re-read all memory files and produce a revised attempt. Use everything you've learned from prior attempts.

After any significant back-and-forth or corrections from the user, update `codebase.md` with what changed and why.

---

## Phase 9: PR & CI

When the user signals readiness to ship ("this looks good", "open a PR", "ship it"):

1. **Publish branch**: push to remote if not already up to date.
2. **Prettier**: run prettier on all files changed since `master` using the `/pnpm` skill. Confirm clean exit.
3. **Tests**: run all tests associated with this ticket (from `testing.md`) using the scripts defined in the destination's `package.json` via the `/pnpm` skill. All must pass before continuing. Run from the destination's directory, not the monorepo root — the root Jest config does not wire up the TypeScript transformer the same way, so `import type` and other TS syntax will fail with a Babel parse error.
4. **Open PR**: create a PR on `hightouchio/hightouch` targeting `master` using `gh pr create`. Use the Linear ticket title as the PR title. Include the Linear URL in the PR description body. If push succeeds but PR creation fails, do not re-push — the branch is already on remote, go straight to retrying PR creation.
5. **Monitor CI**:
   - Poll CircleCI every 15 seconds for job status on this PR
   - Do **not** read job logs unless a job fails
   - On failure: read the failure logs, diagnose the cause, propose a specific fix, and ask the user if they want to apply it
6. **Autopilot exception**: if you have extreme confidence in the solution (it's tested, clean, and unambiguous), you may commit, push, and open the PR yourself without additional prompts.
