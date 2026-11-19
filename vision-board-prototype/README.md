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

## Development

Standard Angular CLI commands apply: `ng generate component <name>`, `ng build`, `ng test`.
This project uses Vitest for unit tests (`ng test`) and has no e2e framework configured.
