# SPM Migration Design

**Date:** 2026-05-10  
**Scope:** Migrate CRRefresh from CocoaPods to Swift Package Manager. Remove podspec. Keep xcodeproj untouched.

---

## Context

CRRefresh is an iOS pull-to-refresh library. Currently distributed via CocoaPods (`CRRefresh.podspec`, Swift 4.2, iOS 8.0 minimum). Goal: add SPM support, delete podspec, make no code changes beyond what SPM requires.

---

## Decisions

| Decision | Choice | Reason |
|----------|--------|--------|
| iOS minimum | 13.0 | Modern baseline; CocoaPods consumers already require 13+ |
| Swift tools version | 5.9 | Enables `Bundle.module`; matches iOS 13 floor |
| Podspec | Delete entirely | Clean break; consumers switch to SPM |
| xcodeproj | Keep as-is | Demo app still uses it; no changes needed |
| `.swift-version` | Delete | Redundant once `Package.swift` owns the toolchain version |

---

## Approach: Single target, `.copy()` resources

One `library` target in `Package.swift`. Sources stay at their current path. The two `.bundle` directories in `NormalAnimator/` are included via `.copy()` to preserve their internal structure.

---

## Files Changed

### Add: `Package.swift` (repo root)

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CRRefresh",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "CRRefresh",
            targets: ["CRRefresh"]
        ),
    ],
    targets: [
        .target(
            name: "CRRefresh",
            path: "CRRefresh/CRRefresh",
            resources: [
                .copy("Animators/NormalAnimator/NormalHeader.bundle"),
                .copy("Animators/NormalAnimator/NormalFooter.bundle")
            ]
        ),
    ]
)
```

`.copy()` preserves the `.bundle` directory structure verbatim. SPM places them at the root of `Bundle.module`, so existing `path(forResource:ofType:)` lookups resolve correctly.

### Modify: `CRRefresh/CRRefresh/CRRefreshBundle.swift:37`

```swift
// Before
let bundle = Bundle(for: aClass)

// After
let bundle = Bundle.module
```

`Bundle(for: aClass)` finds a framework's bundle by class identity — not applicable in SPM where there is no framework bundle. `Bundle.module` is the SPM-generated accessor for the target's resource bundle. The `aClass` parameter stays in the method signature for API compatibility; Swift does not warn on unused function parameters.

### Delete: `CRRefresh.podspec`

Removed entirely. Consumers must switch to SPM.

### Delete: `.swift-version`

Redundant. `Package.swift` with `swift-tools-version: 5.9` owns the Swift version contract for SPM consumers. The file has no effect on Xcode or SPM once `Package.swift` is present.

---

## What Does Not Change

- `CRRefresh.xcodeproj` — untouched
- `Demo/` — untouched
- All Swift source files except the one-line change in `CRRefreshBundle.swift`
- All `.bundle` resource contents

---

## Architecture

```
CRRefresh/                          ← repo root
├── Package.swift                   ← NEW
├── CRRefresh.xcodeproj             ← unchanged
├── CRRefresh/
│   └── CRRefresh/                  ← SPM target sources
│       ├── *.swift                 ← core files
│       └── Animators/
│           ├── FastAnimator/
│           ├── NormalAnimator/
│           │   ├── NormalHeader.bundle   ← copied into Bundle.module
│           │   ├── NormalFooter.bundle   ← copied into Bundle.module
│           │   ├── NormalHeaderAnimator.swift
│           │   └── NormalFooterAnimator.swift
│           ├── RamotionAnimator/
│           └── SlackLoadingAnimator/
└── Demo/                           ← unchanged, used via xcodeproj
```

---

## Resource Loading

`CRRefreshBundle.bundle(name:for:)` resolves bundle resources. After migration:

1. `Bundle.module` gives access to the SPM-generated resource bundle
2. `.path(forResource: name, ofType: "bundle")` finds `NormalHeader.bundle` / `NormalFooter.bundle` within it
3. Subsequent image and localisation lookups inside those bundles are unchanged

---

## Error Handling

No new error paths introduced. SPM will fail at build time (not runtime) if resources are missing from `Package.swift` — earlier and clearer than the CocoaPods equivalent.

---

## Testing

No test target exists. Manual verification: add the local package to a test project via Xcode's "Add Local Package" and confirm the library resolves, builds, and `NormalHeaderAnimator` / `NormalFooterAnimator` display their bundled images and localised strings correctly.
