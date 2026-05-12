# Ticket Memory Structure

Each ticket gets its own directory: `~/.claude/tickets/<ticket-id>/`

Files are created as needed — don't create them all upfront.

## Files

### `context.md` — always created first
Core ticket state. Contains:
- Ticket ID, title, branch name, Linear URL
- Date opened
- `Type: (pending | bug | feature)`
- `datadog_queried: (true | false)`
- `Change type: (API | Logic)`
- Reasoning for change type
- Full Linear description and comments (appended on first load)
- Running notes from the session

### `slack.md` — created when Slack thread is found
Full transcript of the primary Slack thread and any threads it references.

Format:
```
## Thread: <channel-name> / <thread-timestamp>
URL: <slack-url>
Last fetched: <YYYY-MM-DD HH:MM>

<speaker> [HH:MM]: <message text>
<speaker> [HH:MM]: <message text>
...

## Referenced Thread: <channel-name> / <thread-timestamp>
...
```

When refreshing: append new messages after the last entry. Add a separator:
```
--- Updated <YYYY-MM-DD HH:MM> ---
```

### `datadog.md` — created after Datadog query (bugs only)
Non-redundant findings from the APM log query.

Format:
```markdown
## Error: <error message verbatim>
Call site: <file>:<function> (line if available)
Frequency: <N occurrences>
Sample trace ID: <id if available>
Notes: <anything notable>

## Error: ...
```

If no errors found: note that explicitly so we don't re-query.

### `codebase.md` — created during Phase 6/7
API gap analysis and code location assessment.

Format:
```markdown
## API Gap Analysis
Destination: <slug>
Expected behavior: <what the API/spec says>
Current behavior: <what the code does>
Specific difference: <precise description>
LAP sources cited: <flag names used>

## Code Location
File: <relative path from repo root>
Function/section: <name>
Change needed: <description>

## Proposed Changes
<summary of what was written or attempted, updated as work progresses>
```

### `testing.md` — created when tests are written
Test tracking.

Format:
```markdown
## Tests
- `<relative path to test file>` — <what it tests>

## Results
Last run: <YYYY-MM-DD>
Status: passing | failing | not run
Notes: <any relevant output>
```

## Tips

- Update files incrementally — don't rewrite from scratch on each session.
- Keep `context.md` as the source of truth for ticket state (type, queried flags, change type).
- `datadog.md` and `codebase.md` are write-once-then-append — never discard prior findings.
- If a file grows very large (>500 lines), consider splitting into versioned files (e.g. `codebase-v2.md`).
