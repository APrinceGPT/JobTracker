# Changelog

All notable changes to JobTracker are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning follows [Semantic Versioning](https://semver.org/).

---

## [2.0.1] - 2026-05-22

Post-release code review fixes and test coverage improvements.

### Fixed

- **Form sheet ViewModel recreation** — the form sheet's `JobApplicationFormViewModel` was being recreated on every parent view render pass via a computed property. If the parent re-rendered while the sheet was open (e.g. search text changed), form state could be reset. Fixed by constructing the form ViewModel once via `@State` + `onChange` when presentation begins.
- **Incomplete form validation** — the form ViewModel's `isValid` was missing the 100-character limits for company name and job title that exist in `JobApplication.validate()`. The Save button could appear enabled when the model-layer validation would reject the input. Added `companyName.count <= 100` and `jobTitle.count <= 100` to `isValid` and corresponding entries to `validationErrors`.

### Changed

- **Date formatting extracted to `DateFormatting.swift`** — the module-level `dateFormatter`, `string(from:)`, and `date(from:)` functions previously lived in `JobApplicationListView.swift` but were called from the ViewModel's `buildCSV` method, creating an implicit cross-layer dependency. Moved to a dedicated file for proper discoverability.
- **`isSalaryVisible` moved from ViewModel to View** — the salary visibility toggle is a pure UI concern (which widget renders) with no effect on model data or validation. Moved from `@Published` on `JobApplicationFormViewModel` to `@State` on `JobApplicationFormView` where it semantically belongs.

### Added (Tests)

- `test_isOverdue_isFalseWhenFollowUpDateIsToday` — today-boundary off-by-one verification
- `test_isOverdue_isFalseWhenStatusIsGhosted` — ghosted terminal status suppresses overdue
- `test_buildCSV_escapesNewlinesInFields` — CSV newline escaping coverage
- `test_buildCSV_formValidation_isInvalidWhenCompanyNameTooLong` — 101-char company name rejected
- `test_buildCSV_formValidation_isInvalidWhenJobTitleTooLong` — 101-char job title rejected

### Reviewed and Intentionally Kept As-Is

The following items were flagged during the comprehensive code review, validated against the actual codebase and runtime behavior, and determined to be either false positives or carrying net-negative tradeoffs if "fixed":

- **`NSSavePanel.runModal()` on `@MainActor`** — `runModal()` runs a nested modal event loop (standard macOS pattern), not a blocking call that freezes the UI. This is the correct and idiomatic API for save panels on macOS.
- **`filteredApplications` recalculated on every access** — with two accesses per render and a realistic dataset of 50–200 applications, the cost is sub-millisecond. Caching via Combine or `didSet` would add 10–20 lines of invalidation logic for no measurable benefit at this scale.
- **`loadApplications()` full fetch after every mutation** — the always-fetch pattern guarantees UI/store consistency with zero risk of divergence. At N ≤ 500, the SwiftData fetch is in the microsecond range. In-place mutation would introduce a consistency risk for no user-visible improvement.
- **`@StateObject` in `ContentView`** — while `@ObservedObject` is semantically more precise for an externally-constructed ViewModel, the ViewModel is created inline in the `WindowGroup` body and has no stored owner. Changing to `@ObservedObject` without providing a stable owner introduces a deallocation risk. The current code is the safer choice.

---

## [2.0.0] - 2026-05-22

Major feature release with bug fixes, new fields, search/filter, and CSV export.

### Fixed

- **`save()` not refreshing the list** — after adding or editing an application via the form sheet, the list now reloads automatically. Previously users had to relaunch or trigger a manual reload to see changes.
- **Edit form not pre-populating** — opening the edit form (via context menu) now correctly passes the existing application to the form ViewModel, pre-filling all fields. The form title also dynamically shows "Edit Application" vs "Add Application".

### Added

- **Search and filter** — a search bar (Cmd+F to focus) filters the list live by company name or job title. A status filter picker shows only applications matching a specific status.
- **Follow-up date with overdue indicator** — optional per-application follow-up date. When the date passes and the application is still active (not Hired/Ghosted), a red dot appears on the list row and the detail panel shows the date in red.
- **Salary field (hidden by default)** — a privacy-first salary field that renders as a SecureField by default. An eye icon toggles visibility in both the form and the detail panel.
- **Job URL field** — optional URL stored per application. Displayed as a clickable link in the detail panel.
- **Contact Name and Contact Email fields** — optional fields for tracking recruiter/hiring manager info, shown in the detail panel.
- **CSV export** — toolbar button (square-and-arrow-up icon) exports all applications to a CSV file via NSSavePanel. All fields are included with proper escaping.
- **Keyboard shortcuts**:
  - Cmd+N: open Add Application form
  - Delete: delete selected application (with confirmation)
  - Cmd+F: focus search field
- **Backward-compatible Codable** — new fields use `decodeIfPresent` with defaults, so existing JSON data decodes without errors.
- **SwiftData lightweight migration** — new `PersistedJobApplication` fields use default values, enabling automatic schema migration.

### Changed

- Form sheet height increased from 540 to 760 to accommodate new fields.
- Detail panel now shows salary, URL, contact info, and follow-up date above the description.
- Empty state messaging distinguishes between "no applications" and "no results matching filter".
- `USER_GUIDE.md` fully rewritten to cover all new features, correct description limit (50,000 chars), and document keyboard shortcuts, search/filter, detail panel, and CSV export.

---

## [1.3.0] - 2026-05-21

### Added

- **Full description detail panel** — selecting any row in the list opens a persistent detail panel on the right side of the window (macOS `NavigationSplitView` master-detail layout). The panel shows the full job description with the company name and job title as a header.
- **Clear button** — empties the job description for the selected application immediately and persists the change to the store. Disabled when the description is already empty.
- **Copy to Clipboard button** — writes the full description text to `NSPasteboard`. Disabled when the description is empty.
- **Placeholder state** — when no row is selected, the detail column shows a subtle "Select an application to view its description." prompt.
- `clearDescription(for:)` method on `JobApplicationListViewModel`.
- `DescriptionDetailView` — new view (`Views/DescriptionDetailView.swift`) implementing the detail panel.

---

## [1.2.2] - 2026-05-21

### Fixed

- **Status badge colors still invisible** — root cause identified: `StatusBadgeView` was used as the label of a `Menu` with `.menuStyle(.borderlessButton)`. On macOS, the borderless button menu style injects its own rendering environment into the label, overriding all background and foreground color modifiers on child views — making every badge appear colorless regardless of what colors were set.

  Fix: replaced the `Menu` + label pattern with a `ZStack` in both the list row and the add form. A nearly-transparent `Picker` (opacity 0.015) sits on top to capture interaction; the `StatusBadgeView` renders underneath it in a plain view environment with `.allowsHitTesting(false)`, completely isolated from any button styling inheritance. The badge now renders its solid fill color exactly as defined.

---

## [1.2.1] - 2026-05-21

### Fixed

- **Status badge colors not visible** — the previous implementation used HSB colors with low-opacity backgrounds (10–15%), making amber, blue, violet, and teal nearly invisible against the window background in both light and dark mode. Replaced with solid opaque fills and white semibold labels, matching the convention used by tags in apps like Xcode, GitHub, and Linear. All six statuses are now equally distinct and immediately readable by color alone:
  - Pending: orange-amber
  - Applied: blue
  - In Process: purple
  - Waiting: cyan-teal
  - Hired: green
  - Ghosted: red

---

## [1.2.0] - 2026-05-21

### Changed

- **Date field — stepper removed, direct text input** — the date column and the add form now render a plain `TextField` accepting `MM/DD/YYYY` input. No calendar popover, no up/down stepper arrows. The field normalises the format on commit (e.g. `5/3/2026` → `05/03/2026`). Invalid input turns the field red and blocks saving until corrected.

- **Status — redesigned color-coded badge with dot indicator** — each status now shows a solid colored circle followed by its label inside a pill shape with a color-matched background and a subtle border. Colors are semantically distinct and accessible at a glance without reading the text:
  - Pending: amber
  - Applied: steel blue
  - In Process: violet
  - Waiting: teal
  - Hired: forest green (bold, terminal)
  - Ghosted: muted red (bold, terminal)

- **Status picker — badge renders as the menu trigger** — clicking a status in the inline row or the add form opens a dropdown menu where every option shows its colored badge. The current selection is shown with a checkmark. No plain-text dropdown remains anywhere.

---

## [1.1.0] - 2026-05-21

### Changed

- **Inline editing replaces the edit sheet** — every existing row is now fully editable in place without opening a modal form:
  - **Company name, Job Title, Description**: click any cell to edit the text directly; changes are saved on Return or when focus leaves the field.
  - **Status**: click the status cell to open a dropdown menu showing all six statuses; selecting a new value saves immediately.
  - **Date Applied**: click the date cell to open a native date picker inline; changing the date saves immediately.
- The sheet form is now used exclusively for **adding new applications** (+). The separate "Edit Application" sheet has been removed.
- The list now uses a `List` with a fixed column header row, replacing the `Table`, to support live interactive controls in each cell.
- Context menu on each row retains the **Delete** action.

---

## [1.0.1] - 2026-05-21

### Fixed

- **Data not persisting across app launches** — `SwiftDataJobApplicationStore` was inserting, updating, and deleting records in the `ModelContext` but never calling `context.save()`. SwiftData does not auto-save on every mutation; changes remained in memory only and were lost when the app quit. Added `try context.save()` after every mutating operation: `add`, `update`, `updateStatus`, `delete`, and `deleteAll`.

- **Tautological persistence test** — `test_persist_dataRemainsAfterContextSave` was asserting data visibility through a second store that shared the same `ModelContext` instance as the first. Because both stores operated on the same live object graph, the test passed even without `context.save()`. Fixed by creating a fresh `ModelContext(container)` for the second store, which forces a real round-trip through the SwiftData store and would have caught the missing `save()` call from the start.

---

## [1.0.0] - 2026-05-21

Initial release of JobTracker, built end-to-end using Test-Driven Development (TDD).

### Added

#### Core Data Model
- `JobApplication` value type (struct) with fields: company name, job title, description, status, date applied, last updated
- `ApplicationStatus` enum with six cases: `pending`, `applied`, `inProcess`, `waiting`, `hired`, `ghosted`
- Status transition validation via `canTransition(to:)` — enforces a directional state machine
- `isTerminal` computed property on `ApplicationStatus` (and delegated from `JobApplication`) for `hired` and `ghosted`
- `displayLabel` computed property on `ApplicationStatus` for human-readable UI strings
- `validate()` method on `JobApplication` enforcing: non-empty company name and job title, max 100 characters each, max 50,000 characters for description
- `summary` computed property returning `"<companyName> – <jobTitle>"` for compact display
- `JobApplicationValidationError` enum with five cases for precise validation feedback

#### Persistence Layer
- `JobApplicationStoreProtocol` defining the full CRUD + query contract
- `InMemoryJobApplicationStore` — dictionary-backed, used in all tests for speed and determinism
- `SwiftDataJobApplicationStore` — production-grade persistence using SwiftData
- `PersistedJobApplication` `@Model` class as a mapping layer, keeping the domain struct free of persistence annotations
- All fetch operations return results sorted by `dateApplied` descending, including filtered queries

#### Presentation Layer (MVVM)
- `JobApplicationListViewModel` managing list state, selection, form presentation, and delete confirmation
- `JobApplicationFormViewModel` managing form fields, real-time validation, and `buildApplication()`
- All business logic in ViewModels; Views contain no logic

#### User Interface
- `JobApplicationListView` — native macOS list with inline editing: Company, Job Title, Status, Date Applied
- `JobApplicationFormView` — sheet form with grouped sections, inline validation errors, keyboard shortcuts (Cmd+S / Esc)
- `StatusBadgeView` — colour-coded pill badge per status:
  - Pending: orange
  - Applied: blue
  - In Process: purple
  - Waiting: cyan-teal
  - Hired: green (bold, terminal)
  - Ghosted: red (bold, terminal)
- `ContentView` — root `NavigationStack` host
- Toolbar with Add (+) and Delete (trash) buttons
- Context menu on table rows: Delete
- Delete confirmation dialog
- Empty state prompt when no applications exist
- Error alert wired to `errorMessage` on the list ViewModel

#### App Infrastructure
- `JobTrackerApp` entry point with graceful `ModelContainer` initialisation:
  - Tries disk-backed store first
  - Falls back to in-memory store and presents a user alert on disk failure
  - Only calls `fatalError` if both configurations fail (not possible in practice)
- SwiftData schema and `ModelConfiguration` setup
- Sandbox entitlement only (`com.apple.security.app-sandbox`)
- Version 1.0.0 / Build 1

#### Test Suite — 161 Tests
- `ApplicationStatusTests.swift` — enum cases, raw values, Codable, transitions, display labels
- `JobApplicationModelTests.swift` — model creation, validation rules, computed properties
- `InMemoryJobApplicationStoreTests.swift` — CRUD, error cases, sort order, status filtering
- `PersistenceTests.swift` — SwiftData store behaviour, cross-instance persistence
- `UIComponentTests.swift` — ViewModel state, form validation, badge styling, toolbar actions, full integration workflows
- `TestFixtures.swift` — shared `makeApplication()` factory used across all test files

#### Documentation
- `README.md` — build instructions, architecture overview, test suite breakdown, build configuration, icon requirements, distribution guide, future enhancements
- `USER_GUIDE.md` — end-user guide covering all workflows and status colour meanings
- `DEVELOPMENT_SUMMARY.md` — full TDD development process, design decisions, quality checklist
- `CHANGELOG.md` — this file

### Technical Decisions

- Value-type model (`struct`) keeps domain logic immutable and testable without mocking
- Protocol-driven storage enables ViewModel tests to run in-memory with zero I/O
- Validation enforced at both model layer (`validate()`) and ViewModel layer (form `isValid`) — the save path calls `validate()` as a final guard
- `applicationToEdit` used to distinguish add vs. update in `save()` — avoids a redundant store read and silent error swallowing
- `fetchAll(withStatus:)` consistent sort order matches `fetchAll()`, preventing display inconsistencies
