# BookBrowser

A SwiftUI app that fetches and displays science fiction books from the Open Library API, with offline caching.

## Setup

1. Open `BookBrowser.xcodeproj` in Xcode 15+.
2. Select a simulator or device running iOS 17+.
3. Build and run — the app fetches books on launch automatically.

No third-party dependencies. Everything uses Apple's platform frameworks.

## Architecture

MVVM with protocol-driven dependency injection. Every layer is testable in isolation — the ViewModel never touches a concrete networking or persistence type.

```
BookBrowser/
  App/                        – Entry point, wires dependencies
  Models/                     – Codable domain types (Work, Author)
  Services/
    Networking/
      APIClient               – Generic HTTP layer (fetch + decode any Decodable)
      Endpoint                – Typed request builder (method, headers, timeout)
      BookService             – Protocol + OpenLibraryBookService implementation
    Caching/
      CacheServiceProtocol    – Generic cache abstraction
      FileSystemCacheService  – File-based Codable persistence
  ViewModels/                 – BookListViewModel (@MainActor, Foundation-only)
  Views/                      – SwiftUI views + CachedAsyncImage
  Utilities/                  – ImageCacheService (actor), NetworkMonitor, AccessibilityHelpers
  Tests/                      – Swift Testing suites + mocks
```

**Key design choices:**

- **`APIClient` + `BookService` separation** — The `APIClient` is a generic HTTP layer: give it an `Endpoint` and a `Decodable` type, it gives you back the decoded response. It knows nothing about books. `OpenLibraryBookService` uses `APIClient` internally and is the only place that knows about the Open Library API shape.

## Caching Approach

I chose `Codable` + `FileManager` over CoreData. For a flat list of around 20 items with no relationships or complex queries, CoreData's migration overhead and threading model (`NSManagedObjectContext`) don't pay for themselves. The JSON file is written atomically to the system's Caches directory — the OS can reclaim this space under storage pressure, which is the correct behaviour for data that can be re-fetched.

**Fetch strategy (stale-while-revalidate):**

The Open Library API is slow (2-4 seconds typical), even tried to load it on browser, which also took some time. We show cached data instantly and refresh in the background:

1. First launch (no cache) → shows loading spinner → fetches from network.
2. Subsequent launches → shows cached books immediately → silently refreshes from network → updates the list when fresh data arrives.
3. Pull-to-refresh → always hits the network.(Just in case user wants to fetch updated data, if it has been changed)
4. If both network and cache fail → error screen with retry button.
5. If cache is on screen and network fails → keeps showing cached data silently (no error flash).

**Image caching** is handled separately by `ImageCacheService`, an actor with two tiers: `NSCache` for in-memory (session-scoped, instant) and disk persistence in the Caches directory (survives relaunch, enables offline cover art). Disk filenames use SHA-256 hashes of the source URL — this is deterministic across app launches, unlike Swift's `hashValue` which uses a random seed per process. The actor also coalesces duplicate in-flight requests — if two cells request the same cover simultaneously, only one download fires.

## Offline Experience

The app uses `NWPathMonitor` to detect connectivity changes in real time. When the device is offline or the user is viewing cached data, a non-intrusive animated banner appears at the top of the list.

## Testing

  I used Swift Testing Apple's modern testing framework. Chosen over XCTest for clearer diagnostics, `@Suite` organisation, and parameterised test support.

- **BookListViewModel** — Stale-while-revalidate flow: first launch shows loading, cached data shows instantly on relaunch, network refresh updates silently, network failure with cache keeps showing cached data, both fail → error, concurrent fetch deduplication, `CancellationError` handled cleanly.
- **Work Model** — Author display formatting (single, multiple, none), cover URL construction, identity from API `key`
- **Endpoint** — URL correctness, configurable limit, `Accept` header, HTTP method, timeout, custom header override, cover image URL construction with default and custom sizes.
- **JSON Decoding** — Realistic API payloads, null/missing `cover_id`, multi-work response, round-trip encode/decode, and a parameterised test (`@Test(arguments:)`)
- **Error Types** — `NetworkError` and `CacheError` equality for assertion correctness.

Run with `Cmd+U` or `swift test`.

## Trade-offs and Known Limitations

- **No cache expiry.** The cache is indefinite. In production I'd add a TTL check (stale after 24 hours as an example) and a background refresh strategy.
- **No pagination.** The API call uses `limit=20`. Extending to infinite scroll would mean offset tracking and appending to the existing list.
- **iOS 17 minimum.** Gives us `ContentUnavailableView`, `@Observable`, and `NavigationStack` without back-compat wrappers. If iOS 16 support were needed, these have simple equivalents.
- **No disk cache eviction for images.** `NSCache` handles memory warnings automatically. The disk cache doesn't prune old entries, but for 20 covers at ~50-100KB each, this is under 2MB. At scale, I'd add LRU eviction.
- **No SPM package extraction.** The networking and caching layers are structured to be package-extractable (protocol + implementation separation, no UIKit dependencies in the service layer), but I chose not to create a separate package for a take-home scope. In a production codebase, I'd pull the service layer into its own module to have a parallel compilation and enforced boundary.
- **No retry on transient failures.** Network errors wait for manual pull-to-refresh. In production I'd add exponential backoff (2s, 4s, 8s) for timeouts and 5xx errors — not for 4xx or decoding failures where retrying is pointless.

## Accessibility

I have implemented accessibility as I think it must be even for a sample app.
- **`AccessibilityAnnouncementModifier`** — A generic `ViewModifier` that posts VoiceOver announcements when observed values change. Used to announce "20 books loaded", error messages, and loading state transitions. Reusable on any screen with any value type.
- **`ScaledCoverFrameModifier`** — Scales cover image dimensions proportionally with the user's Dynamic Type setting. Users who increase text size also get larger cover images and tap targets.
- **`AdaptiveHStack`** — Switches from horizontal to vertical layout at accessibility text sizes. Side-by-side becomes cramped at large sizes — stacking vertically gives both elements room. Reusable anywhere, not coupled to books.

Additionally: the loading spinner, error state, offline banner, empty state, and retry button all have proper VoiceOver labels, hints, and traits. Cover images are marked `accessibilityHidden` since they're decorative.

## What I'd Add With More Time

- Snapshot tests for all UI states (loading, loaded, empty, error, accessibility sizes).
- A book detail screen with synopsis and additional metadata.
- Search/filtering within the cached list.
- Shimmer animation during image loading.
- Reduce Motion support for the offline banner transition.
- Background refresh via `.scenePhase` when the app returns to foreground.
- Structured logging with `os.Logger` instead of `print` for cache/network diagnostics.
