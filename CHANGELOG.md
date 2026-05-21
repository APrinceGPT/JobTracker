# Changelog

All notable changes to JobTracker are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning follows [Semantic Versioning](https://semver.org/).

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
- `validate()` method on `JobApplication` enforcing: non-empty company name and job title, max 100 characters each, max 500 characters for description
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
- `JobApplicationListView` — native macOS `Table` with five columns: Company, Job Title, Status, Description, Date Applied
- `JobApplicationFormView` — sheet form with grouped sections, inline validation errors, keyboard shortcuts (Cmd+S / Esc)
- `StatusBadgeView` — colour-coded pill badge per status:
  - Pending: orange
  - Applied: blue
  - In Process: purple
  - Waiting: yellow
  - Hired: green (bold, terminal)
  - Ghosted: red (bold, terminal)
- `ContentView` — root `NavigationStack` host
- Toolbar with Add (+) and Delete (trash) buttons
- Context menu on table rows: Edit, Delete
- Double-click to edit
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

## Unreleased

### Planned
- Search and filter by company name, job title, or status
- Notes field per application for interview feedback and follow-up actions
- Local reminder notifications for stale applications
- CSV export
- Sort by any column header
- iCloud sync via SwiftData + CloudKit (one-line configuration change)
