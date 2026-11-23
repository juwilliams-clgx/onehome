# OneHome Web — Future Concept (Angular)

The web half of the OneHome Future Concept prototype — see [`../PRODUCT.md`](../PRODUCT.md)
for shared product context and [`../vision-board-ios/`](../vision-board-ios) for the native
iOS counterpart.

This app is two things living side by side:

1. **The Future Concept experience** — a forward-looking redesign of the buyer browsing
   experience (listings grid/list/split/map, filter & sort, mobile hamburger nav, the search
   header with Compare), plus the Vision Board photo-pinning feature, capacity-limit
   handling, and an agent-facing photo upload/crop tool.
2. **A pixel-accurate recreation of today's live UAT site** (`/uat/properties`,
   `/my-properties/favorites`, `/my-properties/dislikes`) — its own look, font (Montserrat),
   and CSS namespace (`mp__`), kept deliberately separate from the Future Concept shell so the
   two never bleed into each other. Used as a faithful baseline for before/after comparisons
   and as the proving ground for bug fixes (e.g. the Filters icon, mobile overflow, the
   Status filter) before those ideas inform the Future Concept side.

## Getting started

```sh
npm install
npm start          # http://localhost:4200
```

## Routes

| Route | What it is |
|---|---|
| `/` | Future Concept listings browse (grid/list/split/map, filter & sort, search header, Compare) |
| `/property/:id` | Property detail |
| `/vision-board` | Vision Board photo viewer (pin/unpin, Gallery/Photos/Reimagine/Floor Plan/Vision Board tabs) |
| `/compare` | Compare tray destination |
| `/mockup/capacity-limit(/favorites\|dislikes)` | The "board/list is full" lead-in flow |
| `/uat/properties` | Pixel-accurate recreation of the live UAT search-results page |
| `/my-properties/favorites`, `/my-properties/dislikes` | Pixel-accurate recreation of the live Favorites/Dislikes management page — bulk select, Status filter |
| `/agent/listings` | Agent Tools: pick a listing to manage photos for |
| `/agent/listings/:id/photos` | Agent photo upload/crop workflow (auto-crop to 4:3, pinch-to-fill cropper) |

## Key interaction rules

- A listing's photos can be pinned/unpinned to the Vision Board; the board holds at most 3.
  Reaching that limit surfaces a manage flow rather than failing silently.
- A listing can be Favorited or Disliked, never both at once.
- "Love This Look?" offers a choice between pinning the photo and searching for similar
  listings.
- Every photo an agent uploads is auto-cropped to a standardized 4:3 ratio by default, with a
  full-screen pinch-to-fill cropper for manual fine-tuning.

## AI Search (conversational search POC)

A ChatGPT-style conversational search mode, opened from the existing sparkle "AI Search"
chip in the expanded search field (previously a stub that just showed a toast). Renders as a
side panel on desktop / bottom sheet on mobile, sitting alongside the grid rather than
replacing it — the grid keeps updating live as the conversation narrows things down, and the
understood criteria stay visible as removable chips, so the filtering stays transparent
instead of being a black box inside the chat.

This is the one place in the whole prototype that talks to a real backend — everything else
here is client-side mock data. `AiSearchService` (`src/app/services/ai-search.service.ts`)
POSTs the conversation to `server/`'s `/api/ai-search` endpoint, which calls OpenAI with
function-calling tools (`apply_filters` / `clear_filters`) to turn natural language into a
structured filter object, applies that filter deterministically against its own copy of the
mock listings, and returns both a conversational reply and the matching listing ids. The
backend holds the API key so it's never exposed to the browser. See
[`../server/README.md`](../server/README.md) for the backend itself, and run it with
`cd ../server && npm install && npm start` to try this feature live (without an
`OPENAI_API_KEY` configured, the panel still works end-to-end — it just explains that AI
search isn't wired up yet, rather than failing).

`property-grid.ts`'s `listings` became a `computed()` signal narrowed to
`AiSearchService.visibleListingIds()` (previously a plain `MOCK_LISTINGS` reference) so the
grid, map, and results count all update together whenever a conversational filter is applied
or cleared.

### Voice mode (the real thing, not speech-to-text)

The mic button in the panel opens a genuine voice-to-voice conversation using OpenAI's
Realtime API (the same technology behind ChatGPT's voice mode), not speech-to-text bolted
onto the text path above. `AiSearchService.startVoice()`:

1. Fetches a short-lived ("ephemeral") token from the backend's `/api/realtime-session` -
   the real `OPENAI_API_KEY` never reaches the browser.
2. Opens a WebRTC `RTCPeerConnection` directly to OpenAI (`https://api.openai.com/v1/realtime/calls`),
   adds the mic as a local audio track, and plays the model's returned audio track through
   a hidden `<audio>` element - OpenAI's own recommended browser transport.
3. Listens on the connection's data channel for transcript events (so the same chat
   transcript UI shows what was said on both sides) and `function_call` events. When the
   model calls `apply_filters`/`clear_filters` mid-conversation, the client POSTs it to the
   backend's `/api/apply-filters` (the same tool executor the text path uses) and sends the
   result back over the data channel so the model can continue speaking with the real
   answer (e.g. "Found 3 homes...").

Function-call results update the exact same `activeFilters`/`visibleListingIds` signals the
text path uses, so the grid filters identically regardless of whether the user typed or
spoke.

## Development

Standard Angular CLI commands apply: `ng generate component <name>`, `ng build`, `ng test`.
This project uses Vitest for unit tests (`ng test`) and has no e2e framework configured.
