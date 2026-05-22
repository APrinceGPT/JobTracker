# JobTracker

A focused macOS application for tracking job applications through their full lifecycle — from initial research to final outcome.

---

## What is JobTracker?

JobTracker is a native macOS app that helps you keep a clear record of every job you apply to. It replaces scattered spreadsheets and sticky notes with a single, always-available window that shows every application's current status at a glance.

The app is intentionally minimal. It does one thing well: it helps you answer "where do things stand?" without any friction.

---

## Features

- **Application list** — all entries displayed in a compact inline-editable table sorted newest-first, with columns for Company, Job Title, Status, and Date Applied.
- **Detail panel** — selecting a row shows full details including description, salary, job URL, and contact information.
- **Search and filter** — live search by company name or job title (Cmd+F to focus), with a status filter dropdown.
- **Add applications** — a sheet form (Cmd+N) with company name, job title, description, status picker, date, follow-up date, salary, URL, and contact fields.
- **Inline editing** — click any field in the list row to edit directly; changes save on Return.
- **Edit via context menu** — right-click a row and choose Edit to modify all fields including those not visible in the list row.
- **Delete applications** — select a row and press Delete, or use the toolbar trash icon. A confirmation dialog prevents accidental deletions.
- **Follow-up date with overdue indicator** — optional follow-up date per application; a red dot appears when overdue.
- **Salary field (hidden by default)** — hidden with an eye-toggle for privacy in both the form and detail panel.
- **Job URL** — stored per application, displayed as a clickable link in the detail panel.
- **Contact fields** — optional name and email for recruiter/hiring manager tracking.
- **CSV export** — export all applications to a CSV file via the toolbar export button.
- **Status badges** — colour-coded pill badges make status visible at a glance without reading labels.
- **Keyboard shortcuts** — Cmd+N (add), Delete (delete), Cmd+F (search).
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

### Run on your Mac

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

Press **Cmd+U** (or Product > Test) to run all 186 tests.

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
| `JobApplicationModelTests.swift` | Model initialisation, validation rules, computed properties, isOverdue |
| `InMemoryJobApplicationStoreTests.swift` | CRUD operations, error cases, sort order, status filtering |
| `PersistenceTests.swift` | SwiftData store behaviour in an in-memory configuration |
| `UIComponentTests.swift` | ViewModel state transitions, form validation, StatusBadge properties, search/filter, follow-up dates, CSV export, full add/edit/delete integration flows |

---

## Architecture

JobTracker follows a layered MVVM architecture and was built test-first (TDD).

```
JobTracker/
  Models/
    ApplicationStatus.swift       — enum with 6 cases, transition rules, display labels
    JobApplication.swift          — value type (struct), validation, isOverdue, Codable
  Store/
    JobApplicationStoreProtocol.swift   — read/write protocol (CRUD + query)
    InMemoryJobApplicationStore.swift   — in-memory implementation (tests & previews)
    SwiftDataJobApplicationStore.swift  — SwiftData implementation (production)
  ViewModels/
    JobApplicationListViewModel.swift   — list state, selection, search/filter, CSV export, form presentation, delete flow
    JobApplicationFormViewModel.swift   — form fields, validation, buildApplication()
  Views/
    ContentView.swift             — root NavigationSplitView host
    JobApplicationListView.swift  — List, toolbar, search bar, context menu, keyboard shortcuts
    JobApplicationFormView.swift  — add/edit sheet form with all fields
    DescriptionDetailView.swift   — detail panel with description, salary, URL, contacts
    StatusBadgeView.swift         — colour-coded pill badge component
  DateFormatting.swift            — shared date formatting helpers (MM/DD/YYYY)
  JobTrackerApp.swift             — app entry point, ModelContainer setup
```

### Key design decisions

**Protocol-driven storage.** `JobApplicationStoreProtocol` decouples ViewModels from any specific persistence backend. Tests use `InMemoryJobApplicationStore`; production uses `SwiftDataJobApplicationStore`. Swapping backends requires no ViewModel changes.

**Value-type model.** `JobApplication` is a `struct`. It is immutable once created, which makes equality checks, copying, and testing straightforward. The SwiftData layer uses a separate `@Model` class (`PersistedJobApplication`) and maps to/from the struct at the boundary.

**TDD approach.** Every public behaviour was specified as a failing test before any implementation was written. The 186 tests cover the full observable surface of every class, struct, and enum in the app.

**Thin views.** Views contain no business logic. They bind to ViewModel `@Published` properties and call ViewModel intent methods. This makes the entire behavioural surface testable without any UI automation framework.

**Backward-compatible Codable.** New fields added in v2.0 use `decodeIfPresent` with defaults, allowing existing serialized data to decode without errors. SwiftData fields use default values for automatic schema migration.

---

## Build Configuration Notes

### Versioning

| Setting | Value |
|---|---|
| `MARKETING_VERSION` (CFBundleShortVersionString) | 2.0.1 |
| `CURRENT_PROJECT_VERSION` (CFBundleVersion) | 2 |

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

The project references an `AppIcon` asset catalog entry (`ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon`). To add an icon:

1. Create `JobTracker/Assets.xcassets/AppIcon.appiconset/` and add a `Contents.json`.
2. Add the asset catalog to the Xcode project (drag it into the JobTracker group).
3. Add it to the Resources build phase of the JobTracker target.

A 1024x1024 master PNG is a practical starting point; tools such as `iconutil` or Xcode's asset catalog editor can generate the smaller sizes.

---

## Distribution

### Direct distribution (outside the Mac App Store)

1. In Xcode, select **Product > Archive**.
2. When the archive is ready, click **Distribute App** in the Organizer window.
3. Choose **Direct Distribution**.
4. Xcode notarizes the app with Apple's notarization service and exports a signed `.dmg` or `.pkg`.

### Mac App Store distribution

1. Select **Product > Archive**, then **Distribute App > App Store Connect**.
2. Xcode uploads the build to App Store Connect.
3. Complete the App Store listing in App Store Connect.
4. Submit for review.

---

## Future Enhancements

- **Sort by column** — click any column header to re-sort the table.
- **Reminder notifications** — local notifications when a follow-up date arrives.
- **Notes field separation** — separate structured notes from the job description.
- **State machine enforcement** — restrict status picker options based on valid transitions.
- **iCloud sync** — SwiftData supports CloudKit with a one-line configuration change.
