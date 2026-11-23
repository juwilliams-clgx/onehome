# One Home — iOS (SwiftUI)

A native iOS build of the OneHome buyer experience, built up from the Vision
Board / photo-pinning feature prototyped in
[`vision-board-prototype/`](../vision-board-prototype) (Angular, web), then
expanded to the full browsing experience (listings, map, filter/sort,
hamburger nav) once that mobile redesign landed on web. This is a **separate
Xcode project** on purpose — SwiftUI apps build with Xcode's own toolchain and
can't share a build system with the Angular prototypes.

Scope (confirmed): Vision Board (pinning, capacity limit, "Love This Look?",
confirm-unpin) **plus** the listings browse screen, property cards, map
(MapKit), the Filter/Sort sheet, and the hamburger nav menu — i.e. everything
covered by this session's mobile redesign of the web prototype. It does not
redesign the existing shipped OneHome native app's broader UX (search, auth,
account), even though that app has its own documented issues (see
`../docs/OneHome-Usability-Test.docx`) — those are tracked separately. There is
also no property detail screen yet (full description, schools, year built,
etc.) - tapping a listing opens its photos, not a full detail page.

Product context lives in [`../PRODUCT.md`](../PRODUCT.md), not duplicated here.

## Opening the project

This machine only has the Xcode Command Line Tools, not full Xcode, so the
project was written but never built or run here. Open
`VisionBoardIOS.xcodeproj` in Xcode (15.4+; iOS 17 deployment target) and
build/run on the iPhone Simulator to verify. If Xcode flags the project as
needing an upgrade, let it — that's expected for a hand-written `.pbxproj`.
MapKit is a system framework; if Xcode doesn't auto-link it, add it under the
target's "Frameworks, Libraries, and Embedded Content".

## What changed going from web to native (reconform, not reflow)

| Web pattern | iOS replacement | Why |
|---|---|---|
| Hamburger slide-in nav menu (mobile) | `.overlay` + animated slide-in panel from the leading edge, same sections, violet accent bar | Same job, no web-only chrome; backdrop tap / closes it like the web version |
| "Filter" pill → bottom sheet (Sort By + Filters) | `.sheet` (`FilterSortSheet`), `.presentationDetents([.medium, .large])` | Sheets are the native "focused sub-task" idiom; same content, native presentation |
| List/Split/Map/Table layout picker, "slides out to the left" | Same reveal, icon-only buttons in a `HStack`, scale+fade transition | Matches the web's reworked mobile picker directly |
| Fixed 50/50 Split view, map pans to whichever card is in view | `GeometryReader` 50/50 `VStack` + `ScrollView.scrollPosition(id:)` driving `MapCameraPosition` | `scrollPosition(id:)` (iOS 17+) reports the topmost visible row for free - the direct native equivalent of the web's IntersectionObserver |
| Leaflet map + custom price-pin DOM elements | MapKit `Map` + `Annotation` per listing, highlighted pin scales/darkens | Same visual language (price capsule, highlight state), native map engine |
| Prev/next arrow buttons on card photos | None - `TabView(.page)` swipe | Touch devices get swipe-to-browse for free; this *is* the native fix for the web version's "arrows stuck visible after tap" problem, not a workaround for it |
| Separate "Gallery" / "Photos" / "Vision Board" page tabs | `NavigationStack` pushes from a tapped listing or photo grid tile instead of tab clicks | iOS has no browser-tab equivalent; push is the idiomatic "open this and come back" gesture |
| `vision-board-modal` (manage pins, shown when full) | `.sheet` presented over the current screen | Resolves "board full" without losing the buyer's place |
| Unpin confirm modal | Native `.alert` | A short yes/no confirmation is exactly what `.alert` is for |
| `love-this-look-modal` | `.sheet` with the same two options (reordered when full) | Not wired to a trigger in the web prototype either — see note below |
| File-drop `<input type="file">` upload tile | `PhotosPicker` (PhotosUI) | Reads from the photo library instead of a file-system drop |
| "Search Similar Look" opening a new browser tab | Toast-style confirmation only | No tab equivalent exists on iOS |

**Open item:** the web prototype's `VisionBoardService.openLoveThisLook` isn't
called from any control in the current UI — there's no existing trigger to
port faithfully. It's exposed here as an explicit "Love This Look?" button in
the full-screen photo viewer so the flow is reachable for review. Confirm or
replace with the team's intended entry point (e.g. long-press, or
auto-surfacing after a pin).

## Policy going forward

Every mobile feature request now gets built for **both** mobile web
([vision-board-prototype/](../vision-board-prototype)) and this native app by
default, per direction from the business - the two should mirror the same
experience. This round added: a labeled vertical layout picker, a real
Compare feature (it was a stub despite heavy analytics usage), and the
search header (location-defaulted saved-search picker + expanding search
field). See the table below for the web → native translation of each.

## What changed this round (web → native)

| Web pattern | iOS replacement | Why |
|---|---|---|
| Icon-only horizontal layout picker | Native `Menu` (vertical, icon + label, checkmark on selection) | A proper menu *is* the vertical labeled list this called for - no custom reveal needed |
| Compare button (previously a stub) | `CompareStore` + `CompareView`, wired to every card's Compare button | Analytics showed heavy use of a button that did nothing; this makes it real |
| Compare tray icon + badge in header | Same, `NavigationLink` to `CompareView`, badge = `compare.count` | Direct port |
| IP-based `LocationService` (geolocation default) | `LocationStore` using CoreLocation + `CLGeocoder` reverse-geocoding | A phone has a far better, user-trusted on-device location mechanism (with its own permission prompt) than IP lookup - reconform, not reflow |
| Search icon expands the saved-search pill into a full field, condensing the Compare icon | Same: `searchExpanded` collapses the Compare icon's width to 0 and swaps in the field, autofocused via `@FocusState` | Direct port of the interaction, using `@FocusState` as the native equivalent of DOM `.focus()` |
| Camera chip → Vision Board ("Search Similar Look") | `onSearchByPhoto` closure threaded from `ContentView`, switches `topSection` to My Properties | Same destination, via SwiftUI's view-hierarchy callback pattern instead of a router navigation |
| Saved-search dropdown (agent + personal searches, removable) | Same two sections, same mock data, in a `ScrollView` under the pill | Direct port |

## Manage Favorites/Dislikes + bulk select

New screen: `ManageListView`, reached from the nav menu's **My Properties**
section (sub-items: Vision Board, Favorites, Dislikes) - the web counterpart
([manage-list](../vision-board-prototype/src/app/components/manage-list))
isn't linked from its own app's main nav either (only reachable directly or
via the capacity-limit mockup), so adding a real entry point here is a
deliberate improvement, not a gap versus web.

Both platforms got the same bulk-select feature in the same pass: a
"Select" mode toggle, a checkbox per card, Select All/Deselect All, and a
confirmed "Remove Selected" action - so clearing a whole saved list doesn't
require removing items one at a time. Native uses a native `.alert` for the
confirmation instead of the web's styled dialog overlay; everything else
(entering selection mode, tapping a card to toggle it, the bulk bar) is a
direct port.

## Agent photo cropping tool

A new user type, not a mobile-web feature being mirrored: real-estate photos
need to look consistent at 4:3, but an agent's phone or photographer often
hands over photos locked to a different ratio. This adds an agent-only
upload/crop workflow, reachable from the nav menu's new **Agent Tools**
section (kept clearly separate from the buyer chrome, same as the web
counterpart's standalone `/agent/*` routes) — pick a listing, then review its
photos in a grid where each gets an instant auto-crop (center "cover-fit") by
default, with a tap-to-fine-tune full-screen cropper for anything that needs
a human look.

The crop engine (`Models/CropState.swift`) is a line-by-line port of
[crop-math.ts](../vision-board-prototype/src/app/components/photo-cropper/crop-math.ts):
state is stored **normalized** (zoom relative to that photo's own cover-fit
scale, pan as a fraction of frame size) rather than in raw points, so the
same saved crop renders identically in a small grid thumbnail and the
full-screen editor, and the two platforms' math is directly comparable
field-for-field.

| Web pattern | iOS replacement | Why |
|---|---|---|
| Fixed-frame "pinch to fill" cropper, CSS `transform: translate() scale()` on an `<img>`, Pointer Events for drag/pinch | `PhotoCropperView`: `scaleEffect`/`.offset` on an `Image`, `DragGesture` + `MagnificationGesture` combined via `SimultaneousGesture` | SwiftUI's two built-in gesture recognizers are the direct native equivalent of unifying mouse/touch pointer events — no custom touch tracking needed |
| Canvas `drawImage(source rect → dest size)` for the final cropped raster | `CGImage.cropping(to:)` + `UIGraphicsImageRenderer` (`Models/PhotoRaster.swift`) | Same "crop then resize" two-step, Core Graphics' native equivalent of a canvas |
| Rotate 90° by re-drawing into a rotated canvas, then resetting to that image's default crop | Same approach with `CGContext` rotate + translate, same reset | Identical strategy — avoids composing a live rotation transform with pan/zoom |
| Zoom anchored at the pinch midpoint (`zoomAnchored`, frame-local focal point) | Same formula, but anchored at frame center (`focalX/Y = 0`) rather than the live pinch midpoint | SwiftUI's `MagnificationGesture` reports only a scale factor, not touch locations, so pinch-midpoint anchoring isn't available without dropping to UIKit gesture recognizers — center-anchored zoom is the pragmatic native equivalent and still feels natural |
| `<input type="file" multiple>` for new uploads, existing MLS photos loaded via `<img crossorigin>` | `PhotosPicker` (PhotosUI, multi-select) for new uploads; `URLSession` download for existing listing photos | Native photo library picker instead of a file-system drop; same "both sources feed the same batch" model |
| Rule-of-thirds grid overlay, fades in during a gesture and out ~500ms after | Same (`GridOverlay`, a `Path` drawn over the frame), same fade timing via a cancellable `Task` | Direct port, `Task.sleep` replacing `setTimeout` |
| Cover-photo race condition fix: `sortIndex` assigned synchronously at ingest time, array re-sorted after each async load completes | Same `sortIndex` field and sort-after-insert, since `PhotosPickerItem`/`URLSession` loads also resolve out of order | Both platforms load photos concurrently and asynchronously; without a stable sort key, whichever photo's load finishes first visually "jumps" to the front and can wrongly claim the cover-photo slot |

**Not yet exercised on a device:** every other native feature this session
was at least syntax-parsed and pbxproj-validated; this one adds the same,
but the gesture feel (particularly the pinch-zoom anchor point and the
rotate-then-reset flow) is the piece most worth a hands-on pass in Xcode
once full Xcode is available — `swiftc -parse` confirms syntax, not that the
gesture composition feels right on a real device.

## Service Unavailable fallback (preview)

A reviewable concept, not a wired feature: neither platform has a real
splash/login flow yet, so there's nothing to attach a genuine backend-down
state to. `ServiceUnavailableView`, reached from the nav menu's new
**Service Unavailable (Preview)** item, mirrors the web mockup
([service-unavailable-mockup](../vision-board-prototype/src/app/components/service-unavailable-mockup)):
a Splash/Login segmented toggle over one shared card (neither screen can
show anything meaningful without listing data, so one design serves both),
the exact approved copy, and a two-step "Try Again" demo — first tap shows a
"still having trouble" state, second tap simulates recovery.

Both platforms' layout is modeled directly on OneHome's real sign-in screen
(a user-provided screenshot), not a generic error-page template: headline →
body copy → (illustration, standing in for the form that can't render
without a backend) → primary button → a separate footer strip for the
secondary link — the same vertical hierarchy and the exact Sign In button
color (`#4577b6`) as the real screen. No header banner or background color
shift between the card and footer, per follow-up feedback simplifying
toward a single flat white surface.

| Web pattern | iOS replacement | Why |
|---|---|---|
| User-provided `illustration-wet-floor-sign.png` ("it's not you, caution in progress") | Same PNG, downsampled with PIL into `Assets.xcassets/illustration-wet-floor-sign.imageset` as a 1x/2x/3x set (108/216/324pt wide, matching the source's native aspect ratio) | Already a raster asset, so no SVG-conversion step was needed this time; scaling down from the single high-res source avoids upscaling artifacts at any density |
| Splash/Login pill toggle | Native `Picker` with `.pickerStyle(.segmented)` | A segmented control is the native, HIG-expected equivalent of a two-option toggle |
| Faint, labeled Email/Password field outlines shown between body copy and the illustration in Login context | Same labels + `RoundedRectangle` outlines at reduced opacity, `allowsHitTesting(false)` | Direct port, positioned where the real form sits rather than floating separately |
| Amber "still down" banner | Same copy/colors via `Label` + `info.circle.fill` | Direct port |
| Two-attempt retry demo navigating to `/` on success | Same two-attempt counter, `dismiss()` on success (pops back to the real app) | Native has no root route to redirect to, so popping the preview off the stack is the equivalent "you're back in the app" signal |

## Structure

```
VisionBoardIOS/
  VisionBoardIOSApp.swift      App entry; builds the shared stores
  Models/
    Listing.swift              Mirrors listing.model.ts (trimmed to grid/card/map fields)
    Photo.swift                 Mirrors photo.model.ts
    CropState.swift             Mirrors crop-math.ts's normalized crop state + pure math
    PhotoRaster.swift            UIImage crop/export/rotate helpers (Core Graphics)
  Stores/
    BrowseStore.swift          Layout (List/Split/Map/Table), filter sheet, sort, map highlight
    CompareStore.swift         Compare tray membership - ports compare.service.ts
    LocationStore.swift        CoreLocation + reverse geocoding (native equivalent of LocationService)
    SavedPropertiesStore.swift Favorite/Dislike — ports saved-properties.service.ts
    VisionBoardStore.swift     Pin/unpin/capacity rules — ports vision-board.service.ts
    ToastCenter.swift          Ports toast.service.ts (5s auto-dismiss + undo)
  Views/
    ContentView.swift          Root: hamburger header, nav menu, Buy/Rent vs My Properties
    NavMenuView.swift          Slide-in nav menu
    SearchHeaderView.swift     Compare tray + saved-search pill + expanding search field
    ListingsBrowseView.swift   Search header + Filter/layout control bar + List/Split/Map/Table
    ListingCardView.swift      Swipeable photo card, badges, favorite/dislike/map-focus/compare actions
    PropertyMapView.swift      MapKit price-pin map, highlight + pan-to-listing
    FilterSortSheet.swift      Sort By + Filters bottom sheet
    CompareView.swift          Compare tray destination - side-by-side listing cards
    ManageListView.swift       Favorites/Dislikes management - bulk select + remove
    PhotoGridView.swift        A listing's photo grid → pushes PhotoDetailView
    PhotoDetailView.swift      Full-screen swipeable viewer + pin/unpin/love-this-look
    VisionBoardView.swift      Persistent Vision Board section
    VisionBoardGridView.swift  Pinned-photo grid, shared with the sheet below
    CapacityManageSheet.swift  "Manage pins" sheet (board full)
    LoveThisLookSheet.swift    "Love This Look?" choice sheet
    ToastBannerView.swift      Bottom confirmation banner
    AgentListingsView.swift     Agent Tools listing picker
    AgentPhotoUploadView.swift  Agent batch photo review/crop/save workflow
    PhotoCropperView.swift      Reusable full-screen "pinch to fill" cropper
    ServiceUnavailableView.swift Splash/Login outage-fallback preview (not wired to a real flow)
  Resources/
    MockListings.swift         Same 8 listings as mock-listings.ts (same coords, prices, photos)
    MockPhotos.swift           Same Unsplash stand-in photos as mock-photos.ts
```

Mock data matches the web prototype's `mock-listings.ts` (8 listings, same
coordinates/prices) and `mock-photos.ts` (`p1`–`p6`; the floor-plan photo
`p7` is still out of scope - no floor plan view exists natively either).

## Location permission

`LocationStore` requests "When In Use" location access on first launch to
default the search header's location. The usage-description string is set
via `INFOPLIST_KEY_NSLocationWhenInUseUsageDescription` in the hand-written
`project.pbxproj` (no physical `Info.plist` exists - this project uses
`GENERATE_INFOPLIST_FILE = YES`). If the user denies access, the header falls
back to its placeholder text; nothing else depends on location.
