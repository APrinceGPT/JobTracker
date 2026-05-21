# JobTracker

A focused macOS application for tracking job applications through their full lifecycle — from initial research to final outcome.

---

## What is JobTracker?

JobTracker is a native macOS app that helps you keep a clear record of every job you apply to. It replaces scattered spreadsheets and sticky notes with a single, always-available window that shows every application's current status at a glance.

The app is intentionally minimal. It does one thing well: it helps you answer "where do things stand?" without any friction.

---

## Features

- **Application list** — all entries displayed in a compact table sorted newest-first, with columns for Company, Job Title, Status, Description, and Date Applied.
- **Add applications** — a sheet form with company name, job title, optional description, status picker, and date picker.
- **Edit applications** — double-click any row (or right-click and choose Edit) to update any field.
- **Delete applications** — select a row and click the toolbar trash icon, or right-click and choose Delete. A confirmation dialog prevents accidental deletions.
- **Status badges** — colour-coded pill badges make status visible at a glance without reading labels.
- **Persistent storage** — data is saved via SwiftData and survives app restarts.
- **Empty state** — clear prompt shown when no applications exist yet.

---

## Requirements

| Requirement | Value |
|---|---|
| macOS | 14.0 Sonoma or later |
| Xcode | 15.4 or later |
| Swift | 5.9 or later |

---

## Building and Running

### Open the project

```
open "JobTracker/JobTracker.xcodeproj"
```

Or launch Xcode and use **File > Open** to navigate to `JobTracker.xcodeproj`.

### Run in the simulator / on your Mac

1. Select the **JobTracker** scheme in the scheme picker at the top of Xcode.
2. Choose **My Mac** as the run destination.
3. Press **Cmd+R** (or Product > Run).

The app window opens immediately. No account, login, or network connection is needed.

### Build for Release from the command line

```bash
xcodebuild \
  -project JobTracker/JobTracker.xcodeproj \
  -scheme JobTracker \
  -configuration Release \
  -destination 'platform=macOS' \
  build
```

---

## Running Tests

### From Xcode

Press **Cmd+U** (or Product > Test) to run all 161 tests.

Results appear in the Test Navigator (Cmd+6). All tests should pass with green checkmarks.

### From the command line

```bash
xcodebuild \
  -project JobTracker/JobTracker.xcodeproj \
  -scheme JobTracker \
  -destination 'platform=macOS' \
  test
```

### Test suite summary

| Test file | What it covers |
|---|---|
| `ApplicationStatusTests.swift` | Status enum cases, raw values, Codable round-trips, transition rules, display labels |
| `JobApplicationModelTests.swift` | Model initialisation, validation rules, computed properties |
| `InMemoryJobApplicationStoreTests.swift` | CRUD operations, error cases, sort order |
| `PersistenceTests.swift` | SwiftData store behaviour in an in-memory configuration |
| `UIComponentTests.swift` | ViewModel state transitions, form validation, StatusBadge properties, full add/edit/delete integration flows |

---

## Architecture

JobTracker follows a layered MVVM architecture and was built test-first (TDD).

```
JobTracker/
  Models/
    ApplicationStatus.swift       — enum with 6 cases, transition rules, display labels
    JobApplication.swift          — value type (struct), validation logic
  Store/
    JobApplicationStoreProtocol.swift   — read/write protocol (CRUD + query)
    InMemoryJobApplicationStore.swift   — in-memory implementation (tests & previews)
    SwiftDataJobApplicationStore.swift  — SwiftData implementation (production)
  ViewModels/
    JobApplicationListViewModel.swift   — list state, selection, form presentation, delete flow
    JobApplicationFormViewModel.swift   — form fields, validation, buildApplication()
  Views/
    ContentView.swift             — root NavigationStack host
    JobApplicationListView.swift  — Table, toolbar, context menu, confirmation dialog
    JobApplicationFormView.swift  — add/edit sheet form
    StatusBadgeView.swift         — colour-coded pill badge component
  JobTrackerApp.swift             — app entry point, ModelContainer setup
```

### Key design decisions

**Protocol-driven storage.** `JobApplicationStoreProtocol` decouples ViewModels from any specific persistence backend. Tests use `InMemoryJobApplicationStore`; production uses `SwiftDataJobApplicationStore`. Swapping backends requires no ViewModel changes.

**Value-type model.** `JobApplication` is a `struct`. It is immutable once created, which makes equality checks, copying, and testing straightforward. The SwiftData layer uses a separate `@Model` class (`PersistedJobApplication`) and maps to/from the struct at the boundary.

**TDD approach.** Every public behaviour was specified as a failing test before any implementation was written. The 161 tests cover the full observable surface of every class, struct, and enum in the app.

**Thin views.** Views contain no business logic. They bind to ViewModel `@Published` properties and call ViewModel intent methods. This makes the entire behavioural surface testable without any UI automation framework.

---

## Build Configuration Notes

### Versioning

| Setting | Value |
|---|---|
| `MARKETING_VERSION` (CFBundleShortVersionString) | 1.0.0 |
| `CURRENT_PROJECT_VERSION` (CFBundleVersion) | 1 |

Increment `MARKETING_VERSION` for user-visible releases. Increment `CURRENT_PROJECT_VERSION` for every build submitted to distribution.

### Code signing

`CODE_SIGN_STYLE = Automatic` — Xcode manages signing automatically. You need a valid Apple Developer account (free or paid) to sign the app. Set your Team in the Signing & Capabilities tab in Xcode.

### Entitlements

The app runs in the macOS sandbox (`com.apple.security.app-sandbox = true`). No additional file-access entitlements are required; the app reads and writes only through SwiftData's internal container.

### Deployment target

macOS 14.0. SwiftData requires macOS 14 at minimum.

### Release build optimisations

The Release configuration enables:
- `SWIFT_COMPILATION_MODE = wholemodule` — whole-module optimisation for smaller, faster binaries.
- `DEBUG_INFORMATION_FORMAT = dwarf-with-dsym` — dSYM file generated for crash symbolication.
- `ENABLE_NS_ASSERTIONS = NO` — assertion overhead removed.
- `GCC_OPTIMIZATION_LEVEL` defaults to the standard Release level.

---

## App Icon Requirements

The project references an `AppIcon` asset catalog entry (`ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon`). The asset catalog itself is not yet present in the project. To add an icon:

1. Create `JobTracker/Assets.xcassets/AppIcon.appiconset/` and add a `Contents.json`.
2. Add the asset catalog to the Xcode project (drag it into the JobTracker group).
3. Add it to the Resources build phase of the JobTracker target.

Required icon sizes for macOS (all PNG, 72 dpi, sRGB):

| Use | Points | Scale | Pixels |
|---|---|---|---|
| Mac 16pt | 16pt | 1x | 16x16 |
| Mac 16pt | 16pt | 2x | 32x32 |
| Mac 32pt | 32pt | 1x | 32x32 |
| Mac 32pt | 32pt | 2x | 64x64 |
| Mac 128pt | 128pt | 1x | 128x128 |
| Mac 128pt | 128pt | 2x | 256x256 |
| Mac 256pt | 256pt | 1x | 256x256 |
| Mac 256pt | 256pt | 2x | 512x512 |
| Mac 512pt | 512pt | 1x | 512x512 |
| Mac 512pt | 512pt | 2x | 1024x1024 |

A 1024x1024 master PNG is a practical starting point; tools such as `iconutil` or Xcode's asset catalog editor can generate the smaller sizes.

---

## Distribution

### Direct distribution (outside the Mac App Store)

1. In Xcode, select **Product > Archive**.
2. When the archive is ready, click **Distribute App** in the Organizer window.
3. Choose **Direct Distribution**.
4. Xcode notarizes the app with Apple's notarization service and exports a signed `.dmg` or `.pkg`.

Requirements:
- Apple Developer Program membership (paid, $99/year).
- A valid Developer ID Application certificate.
- Active internet connection during notarization (typically takes under 5 minutes).

Deliver the exported `.dmg` to users. macOS Gatekeeper will accept a notarized Developer ID-signed app without displaying a warning.

### Mac App Store distribution

1. Select **Product > Archive**, then **Distribute App > App Store Connect**.
2. Xcode uploads the build to App Store Connect.
3. Complete the App Store listing in App Store Connect (screenshots, description, privacy policy, etc.).
4. Submit for review.

Additional requirements:
- Apple Developer Program membership.
- A valid Mac App Store distribution certificate.
- An App Store Connect listing with a unique bundle ID (`com.jobtracker.JobTracker` must be registered to your team).
- Privacy manifest (`PrivacyInfo.xcprivacy`) if any required-reason APIs are used.
- The app must pass App Review guidelines. JobTracker's current feature set is straightforward and unlikely to raise review issues.

---

## Future Enhancements

These are practical additions that fit the app's focused scope:

- **Search and filter** — filter the table by status or search by company/title.
- **Notes field per application** — a freeform notes area for interview feedback, contacts, or next steps.
- **Reminder notifications** — a local notification when an application has been in a non-terminal state for a user-configurable number of days.
- **Export to CSV** — one-click export of all applications for use in a spreadsheet.
- **Sort by column** — click any column header to re-sort the table.
- **Multiple windows** — macOS supports multiple windows; a second window showing a detail view of the selected application could be useful.
- **iCloud sync** — SwiftData supports CloudKit with a one-line configuration change; syncing across Macs would require adding the iCloud entitlement and switching to a CloudKit-backed `ModelConfiguration`.
