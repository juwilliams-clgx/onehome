# AI Search POC backend

A small Express server — the only backend in this repo. Every other feature in both
[`../vision-board-prototype/`](../vision-board-prototype) and [`../vision-board-ios/`](../vision-board-ios)
is client-side mock data with no server at all; this one exists solely to keep an LLM API
key off the client for the conversational "AI Search" feature (opened from the sparkle chip
in both apps' search headers).

## Why a backend was needed for this one feature

Calling OpenAI directly from the browser or the app would mean shipping the API key to
every client — anyone could read it from network traffic or a decompiled binary. This
server holds the key server-side and is the only thing that ever talks to OpenAI.

## Running it

```sh
npm install
cp .env.example .env   # then add your own OPENAI_API_KEY
npm start               # http://localhost:4300
```

Without an `OPENAI_API_KEY` set, `/api/ai-search` still responds successfully — it just
returns a reply explaining AI search isn't configured yet, so both clients degrade
gracefully instead of failing.

## How a request is handled

`POST /api/ai-search` takes the full conversation so far (`{ messages: [{ role, content }] }`)
and:

1. Sends it to OpenAI's Chat Completions API along with two tools: `apply_filters`
   (price/beds/baths/city/state/status) and `clear_filters`. The model decides whether to
   call one based on what the user said, rather than the server trying to parse natural
   language itself.
2. If a tool was called, the server applies the extracted filter **deterministically in
   code** (`applyFilters()` in `index.js`) against its own copy of the mock listings
   (`listings.js`) - the model's job is only to understand intent, not to be trusted to
   accurately enumerate which specific listings match.
3. Calls OpenAI a second time with the tool result appended, to get a natural-language
   reply that references what was actually found (e.g. "Found 3 homes...").
4. Returns `{ reply, filters, matchingIds }` - a conversational string, short chip labels
   for the UI (e.g. `"3+ bd"`, `"< $900K"`), and the matching listing ids. Both clients
   already have the full listing data locally, so only ids need to cross the wire.

`listings.js` is a server-side copy of the same 8 mock listings already duplicated between
`mock-listings.ts` (web) and `MockListings.swift` (iOS) - this project already accepts one
dataset duplicated per target rather than a shared package, so this is a third copy
following existing precedent rather than a new pattern.

## Known POC limitations

- No real device support on iOS - `http://localhost:4300` only resolves from the Simulator
  (which shares the host Mac's network). A real device needs the Mac's LAN IP.
- No conversation persistence - history lives only in the client's in-memory store for the
  session.
- `cors()` is wide open (`*`) for simplicity; a shipped version would restrict this to the
  app's actual origins.
