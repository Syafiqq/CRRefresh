# SPM Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate CRRefresh distribution from CocoaPods to Swift Package Manager by adding `Package.swift`, updating resource bundle loading, and removing CocoaPods artefacts.

**Architecture:** Single SPM library target pointing at the existing source tree. `.bundle` resources included via `.copy()`. One required code change in `CRRefreshBundle.swift` to use `Bundle.module` instead of `Bundle(for:)`.

**Tech Stack:** Swift 5.9, SwiftPM 5.9, iOS 13+

---

### Task 1: Add Package.swift

**Files:**
- Create: `Package.swift`

- [ ] **Step 1: Create Package.swift at repo root**

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

- [ ] **Step 2: Verify SPM resolves the package**

```bash
swift package dump-package
```

Expected: JSON dump with `name: "CRRefresh"`, one target, two resources. No errors.

- [ ] **Step 3: Commit**

```bash
git add Package.swift
git commit -m "feat: add Package.swift for SPM support"
```

---

### Task 2: Update CRRefreshBundle to use Bundle.module

**Files:**
- Modify: `CRRefresh/CRRefresh/CRRefreshBundle.swift:40`

- [ ] **Step 1: Replace Bundle(for:) with Bundle.module**

In `CRRefresh/CRRefresh/CRRefreshBundle.swift`, change line 40:

```swift
// Before
let bundle = Bundle(for: aClass)

// After
let bundle = Bundle.module
```

Full method after change:

```swift
@discardableResult
static func bundle(name: String, for aClass: Swift.AnyClass) -> CRRefreshBundle? {
    let bundle = Bundle.module
    if let path = bundle.path(forResource: name, ofType: "bundle") {
        if let bundle = Bundle(path: path) {
            return CRRefreshBundle(bundle: bundle)
        }
    }
    return nil
}
```

- [ ] **Step 2: Verify package builds**

```bash
swift build
```

Expected: `Build complete!` No errors.

- [ ] **Step 3: Commit**

```bash
git add CRRefresh/CRRefresh/CRRefreshBundle.swift
git commit -m "fix: use Bundle.module for SPM resource loading"
```

---

### Task 3: Remove CocoaPods artefacts

**Files:**
- Delete: `CRRefresh.podspec`
- Delete: `.swift-version`

- [ ] **Step 1: Delete podspec and swift-version**

```bash
git rm CRRefresh.podspec .swift-version
```

- [ ] **Step 2: Commit**

```bash
git commit -m "chore: remove CocoaPods podspec and .swift-version"
```

---

### Task 4: Verify final state

- [ ] **Step 1: Confirm package resolves and builds clean**

```bash
swift package dump-package && swift build
```

Expected: JSON dump with no errors, then `Build complete!`

- [ ] **Step 2: Confirm deleted files are gone**

```bash
ls CRRefresh.podspec .swift-version 2>&1
```

Expected: `No such file or directory` for both.

- [ ] **Step 3: Confirm xcodeproj untouched**

```bash
ls CRRefresh.xcodeproj
```

Expected: directory listed normally.
