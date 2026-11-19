# OneHome — Future Concept

A design/engineering prototype exploring where OneHome (a CoreLogic/Cotality real-estate
buyer product) could go next, built in parallel on two platforms:

- **[vision-board-prototype/](vision-board-prototype)** — an Angular web prototype. Covers
  the full buyer browsing experience (listings, map, filter/sort), the Vision Board
  photo-pinning feature, Favorites/Dislikes management, Compare, and an agent-facing photo
  upload/crop tool. Also hosts a pixel-accurate recreation of today's live UAT site
  (`/uat/properties`, `/my-properties/favorites|dislikes`) used as a faithful baseline for
  before/after comparisons.
- **[vision-board-ios/](vision-board-ios)** — a native SwiftUI iOS app mirroring the same
  feature set. A fully separate Xcode project on purpose (SwiftUI builds with Xcode's own
  toolchain and can't share a build system with the Angular app).

Both apps are built from the same product truth, recorded once in **[PRODUCT.md](PRODUCT.md)**
rather than duplicated per platform. Each app's own README documents platform-specific
decisions (see [vision-board-prototype/README.md](vision-board-prototype/README.md) and
[vision-board-ios/README.md](vision-board-ios/README.md) — the native one in particular
tracks a running web → native translation table, updated every round).

## Repo layout

```
.
├── PRODUCT.md                   Shared product context (read this first)
├── docs/                        Background evidence: usability findings, customer feedback
├── vision-board-prototype/      Web (Angular) — npm install && npm start
└── vision-board-ios/            Native (SwiftUI) — open VisionBoardIOS.xcodeproj in Xcode
```

## Why one repo

This is one product concept expressed on two platforms, not two independent products —
both read from the same `PRODUCT.md` and the same background evidence in `docs/`, and
changes are made in lockstep (a mobile feature request is built for both web and native by
default). If this moves from prototype to production with dedicated web and mobile teams
and independent release trains, splitting `vision-board-ios/` out into its own repo is a
clean, low-cost operation — nothing about this layout blocks that later.

## Getting started

**Web:**
```sh
cd vision-board-prototype
npm install
npm start   # http://localhost:4200
```

**iOS:** open `vision-board-ios/VisionBoardIOS.xcodeproj` in Xcode (15.4+, iOS 17
deployment target) and run on the iPhone Simulator.
