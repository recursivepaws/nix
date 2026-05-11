---
name: destination
description: Load a Hightouch destination's LAP context and advise on destination-specific API behavior, error handling, field mapping, and integration code. Use this when the user names a destination (e.g. "adestra", "stripe", "hubspot") or asks about destination code, endpoint behavior, or integration bugs.
---

The user is asking about a Hightouch destination integration. Load its LAP context file and use it to ground every claim you make.

## Step 1 — Identify the destination

The user invoked this skill with: $ARGUMENTS

Extract the destination name from `$ARGUMENTS` (the first word, lowercased, matching a directory name). If no destination is named, ask before proceeding.

Available destinations: adestra, amazon-eventbridge, amazon-kinesis, amazon-sqs, asana, aws-lambda, azure-blob, bigcommerce, box, braze, discord, dynamodb, elasticsearch, gcs, google-analytics, google-drive, google-sheets, hubspot, intercom, jira, mailchimp, mixpanel, mongodb, notion, planetscale, qualtrics, s3, send-grid, servicenow, sfmc, shopify, slack, spotify, stripe, twilio, twitter, webflow, whatsapp, xero, zapier, zendesk

## Step 2 — Read the context

Read the file at this path (substituting the destination name):
`~/Software/destinations-context/destinations/<destination>/context.lap`

Read it completely before answering. This is the single authoritative source for that destination's API surface and behavioral flags.

## Step 3 — Apply LAP annotation trust order

When interpreting the file, trust annotations in this order:

| Tag | Source | Trust |
|-----|--------|-------|
| `#[human]` | Engineer-verified | Highest — overrides everything |
| `#[crawl]` | Live API crawl fixture | High — fixture ref in parens |
| `#[dest]` | Destination-level flag | Applies to all endpoints |
| `@endpoint` / `@required` / `@returns` / `@errors` | LAP spec | API surface (what docs say) |

If a `#[crawl]` or `#[human]` flag contradicts the spec, **trust the flag**. If a flag says `MISCLASSIFIED`, the current code is wrong at that point.

## Step 4 — Answer

Answer the user's question from `$ARGUMENTS`. For every behavioral claim, cite the specific flag or spec line that supports it (e.g. `#[crawl] DEDUPE: duplicate email returns existing ID`). If the behavior you're advising on has no flag, say so explicitly — that is an evidence gap that should be flagged.
