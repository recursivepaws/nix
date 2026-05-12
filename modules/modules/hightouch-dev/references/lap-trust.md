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

## Cross-referencing with Context7 and Web Search

After loading the LAP file, use context7 to pull live documentation for the destination's API. Use this to:
- Fill gaps where the LAP file has no annotation
- Confirm or challenge crawl observations
- Find recently changed endpoints or parameters not yet reflected in LAP

When context7 and LAP conflict: prefer `#[human]` or `#[crawl]` annotations over context7. Use context7 as supplemental, not authoritative.

If both the LAP file and context7 fail to produce a concrete example for a given endpoint or field, fall back to web search (see Phase 6 of the main skill for the full waterfall). Emit a warning to the user before doing so — web-sourced findings carry lower confidence than LAP or context7.

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
2. Use context7 docs as the primary reference.
3. If context7 also has no coverage, fall back to web search for official API documentation.
4. Flag to the user that findings are lower-confidence without a LAP file — and lower still if web search was the only source.
