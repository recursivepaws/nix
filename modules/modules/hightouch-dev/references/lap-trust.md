# LAP File Usage & Trust Order

LAP (Lifecycle API Profile) files are the primary authority on destination API behavior. They are stored at:

```
{DESTINATIONS_CONTEXT}/destinations/<destination>/context.lap
```

Read the file completely before drawing any conclusions.

## Annotation Trust Order

When annotations conflict, trust in this order:

| Tag | Source | Trust level |
|-----|--------|-------------|
| `#[human]` | Engineer-verified observation | **Highest** — overrides everything including spec |
| `#[crawl]` | Live API crawl fixture | **High** — fixture ref in parens; reflects actual API behavior |
| `#[dest]` | Destination-level flag | Applies to all endpoints in this destination |
| `@endpoint` / `@required` / `@returns` / `@errors` | LAP spec | API surface as documented |

**If `#[crawl]` or `#[human]` contradicts the spec, trust the flag.**
**If a flag says `MISCLASSIFIED`, the current code is wrong at that point.**

## Cross-referencing with Context7

After loading the LAP file, use context7 to pull live documentation for the destination's API. Use this to:
- Fill gaps where the LAP file has no annotation
- Confirm or challenge crawl observations
- Find recently changed endpoints or parameters not yet reflected in LAP

When context7 and LAP conflict: prefer `#[human]` or `#[crawl]` annotations over context7. Use context7 as supplemental, not authoritative.

## Gap Analysis Output

After cross-referencing, produce a precise gap statement:

> The current implementation does X. The API (per #[crawl] annotation / context7 docs) expects Y. The specific difference is Z.

Examples of good gap statements:
- "POST /contacts is called without the `sync_mode` parameter. The LAP `#[crawl]` annotation shows this is required for deduplication."
- "The endpoint is hardcoded to `/v2/users`. Per context7 docs (and a `#[crawl]` fixture from 2024-11), the v2 endpoint returns 410 Gone — v3 is required."
- "Error response parsing assumes `{ error: string }`. The `#[human]` annotation says this destination returns `{ errors: [{ message }] }` for validation failures."

Vague gap statements like "the API call is wrong" are not acceptable. Be specific enough that a developer could fix it from your description alone.

## When No LAP File Exists

Some destinations may not have a LAP file yet. In that case:
1. Note the absence explicitly.
2. Rely solely on context7 docs and any error evidence from Datadog.
3. Flag to the user that findings are lower-confidence without a LAP file.
