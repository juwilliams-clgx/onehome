# Product

<!-- impeccable:product-schema 1 -->

## Platform

ios

## Stack

SwiftUI

## Users

Home buyers browsing and saving real-estate listings shared with them by their real estate agent (primary user for this effort). The product also serves real estate agents as a distinct user type (they share listings, grant buyer access, and receive buyer activity), but agent-facing experience is out of scope for the current native iOS effort.

## Product Purpose

OneHome lets a home buyer browse MLS-sourced listings their agent has shared with them, organize the ones they're interested in (Favorites / Dislikes), and build a visual sense of the style they want by pinning favorite listing photos to a personal "Vision Board." Success is a buyer who can clearly express and refine their taste and shortlist, and an agent who can see that signal.

## Positioning

OneHome's listings come from the buyer's own agent and MLS data (not an open consumer search), so the product's job is to support an existing agent-buyer relationship rather than compete as an open-market search tool. Photo-based taste signaling (pin a look, get offered similar listings) is a differentiator the team is actively prototyping, not yet shipped to the native apps.

## Operating Context

- Buyers currently reach listings via native iOS/Android apps and a web app; an agent-buyer relationship (shared listings, access grants) underlies all of it.
- The existing shipped native app (iOS + Android) has known, documented usability problems (see Evidence on Hand): scroll/search-state loss, authentication/session sync errors, an iPad launch crash, missing swipe gestures in photo galleries, and slow/incomplete search results on mobile.
- A newer web-only Angular prototype ([vision-board-prototype/](vision-board-prototype)) has built out a set of interactions not yet in the shipped native app: pinning up to 3 photos to a "Vision Board," a capacity-limit flow when the board or a list is full, a "Love This Look?" choice (pin this look vs. search for similar listings), and Favorites/Dislikes lists (mutually exclusive per listing).

## Capabilities and Constraints

- **Native iOS effort now covers the Vision Board / photo-pinning feature set plus the listings browse experience** (listings grid/list, map, filter/sort, split view, hamburger nav) once the web prototype's mobile redesign landed there too — both built in SwiftUI. It is still not a broader redesign of the existing shipped native app's auth/account UX or a full property-detail screen, even though that existing UX has documented problems.
- Confirmed interaction rules from the web prototype to preserve: a photo can be pinned/unpinned; the board holds a maximum of 3 pinned photos; reaching that limit surfaces a manage flow instead of silently failing; unpinning always asks for confirmation; a listing can be Favorited or Disliked but not both at once; "Love This Look?" offers a choice between pinning the photo and searching for similar looks.
- No native (SwiftUI/UIKit/Android) source exists yet in this workspace; this is new native UI built from product/interaction truth, not ported from existing native code.
- Native constraints from the web pattern that must be reconformed, not reflowed: the web prototype opens property detail as its own route/page; native iOS has no tab/window equivalent, so this needs a navigation-stack (push) or sheet treatment instead, chosen deliberately per flow.

## Evidence on Hand

- [vision-board-prototype/](vision-board-prototype): Angular web prototype implementing the Vision Board, capacity-limit, Love-This-Look, and Favorites/Dislikes interactions. Source of interaction truth for the native port.
- [docs/OneHome-Usability-Test.docx](docs/OneHome-Usability-Test.docx): a personal usability-test plan built from App Store (~1.9★) and Google Play (~2.7★) review patterns for the existing shipped native app. Documents real, known pain points (out of scope for this effort, but useful context on what not to repeat).
- [docs/Mobile_App_Feedback_Quick_Wins.docx](docs/Mobile_App_Feedback_Quick_Wins.docx) and [docs/OneHome_Mobile_App_Bug_Feedback.xlsx](docs/OneHome_Mobile_App_Bug_Feedback.xlsx): prioritized customer feedback / bug findings for the existing shipped app (mixed web/native, mostly unconfirmed against this sandbox). Same relevance as above: background, not current scope.

## Product Principles

- Preserve the agent-buyer relationship model; the app organizes shared listings, it doesn't replace the agent.
- Taste signaling through photos (pin, "Love This Look?") is a first-class interaction, not a secondary gallery feature.
- Limits (3 pinned photos, Favorite/Dislike exclusivity) are deliberate product rules, not technical constraints — the native UI must surface them clearly rather than hide or silently enforce them.
- Native iOS screens follow iOS conventions (navigation stack, sheets, HIG components) rather than reproducing the web prototype's routes and modals literally.
