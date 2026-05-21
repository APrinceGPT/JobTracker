# JobTracker - Development Summary

## Project Overview

**JobTracker** is a native macOS application built with SwiftUI and SwiftData that helps users track job applications. The app provides a clean, compact interface to manage company names, job titles, descriptions, and application statuses in a single view.

## Development Process

This project was developed using strict TDD methodology following the **red-green-refactor** cycle across 7 phases.

---

### Phase 1 — RED: Data Model & Persistence Tests

**Goal:** Define the domain model and persistence contract through failing tests before writing any implementation.

- Scaffolded the Xcode project with stub types that compile but do nothing
- Wrote 91 failing tests across 4 test files:
  - `ApplicationStatusTests` (28 tests): enum cases, Codable, transition rules, display labels
  - `JobApplicationModelTests` (23 tests): validation, computed properties, error types
  - `InMemoryJobApplicationStoreTests` (29 tests): CRUD, sort order, error cases
  - `PersistenceTests` (11 tests): SwiftData-backed store behaviour
- All 91 tests failed as expected — no production logic existed yet

**Test count: 91 failing**

---

### Phase 2 — GREEN: Data Layer Implementation

**Goal:** Implement the minimum code to pass all 91 tests.

- `ApplicationStatus`: added `canTransition(to:)` state machine and `displayLabel`
- `JobApplication`: added `validate()`, `isTerminal`, `summary`; moved `JobApplicationValidationError` to main target
- `InMemoryJobApplicationStore`: full dictionary-backed CRUD with sort and error handling
- `SwiftDataJobApplicationStore`: full SwiftData implementation with `FetchDescriptor`, `#Predicate`, and a `findPersisted(id:)` helper
- Fixed a broken `XCSwiftPackageProductDependency` reference for SwiftData in `project.pbxproj`

**Test count: 91 passing, 0 failing**

---

### Phase 3 — RED: UI Component Tests

**Goal:** Define the expected UI behaviour through failing tests before writing any Views or ViewModels.

- Created stub Views and ViewModels that compile but return wrong/empty values
- Wrote 63 new failing tests in `UIComponentTests.swift`:
  - List ViewModel state (load, sort, select)
  - Toolbar actions (add, edit, delete, confirm, cancel)
  - Form ViewModel (validation, `isValid`, `buildApplication()`)
  - `StatusBadgeView` (colours, labels, terminal styling)
  - Integration workflows (add → edit → delete cycle, persistence across ViewModel recreation)

**Test count: 154 total (91 passing + 63 new failing)**

---

### Phase 4 — GREEN: UI Implementation

**Goal:** Implement Views and ViewModels to pass all 63 UI tests.

- `JobApplicationListViewModel`: `loadApplications()`, toolbar intent methods, selection state, `save()`, form lifecycle
- `JobApplicationFormViewModel`: `isValid`, `showsCompanyNameError`, `showsJobTitleError`, `buildApplication()`
- `StatusBadgeView`: per-status colours, `displayLabel` delegation, bold weight for terminal statuses
- `JobApplicationListView`: native macOS `Table`, empty state, context menu, double-click to edit, toolbar
- `JobApplicationFormView`: grouped form sheet, inline validation errors, keyboard shortcuts
- `ContentView`: wired to `JobApplicationListView` inside `NavigationStack`
- `JobTrackerApp`: wired to `SwiftDataJobApplicationStore` backed by a real `ModelContainer`

**Test count: 154 passing, 0 failing**

---

### Phase 5 — REFACTOR: Code Quality

**Goal:** Improve clarity and remove duplication while keeping all tests green.

- Extracted `isTerminal` as a computed property on `ApplicationStatus`; `JobApplication.isTerminal` and `StatusBadgeView.isTerminal` now delegate to it, eliminating three copies of the same predicate
- Removed unused `import Combine` from both ViewModels
- Replaced an immediately-invoked closure in `JobApplicationListView` with idiomatic `Optional.map`
- Removed stale RED-phase scaffolding comments from all test files and the store protocol
- Verified all 154 tests remained green after each individual change

**Test count: 154 passing, 0 failing**

---

### Phase 6 — Code Review & Fixes

**Goal:** Address all critical and important issues surfaced by a comprehensive code review.

The review identified 1 critical issue, 5 important issues, and 4 suggestions.

**Issues fixed:**

| Severity | Issue | Fix |
|---|---|---|
| Critical | `try!` on `ModelContainer` init crashes on schema migration or corrupt store | Replaced with `do/catch` — disk store attempted first, falls back to in-memory with user alert |
| Important | `validate()` never called in save path — 100-char limit silently unenforced | Added `try application.validate()` at the top of `save()` |
| Important | `try? store.fetch()` silently swallows non-`notFound` errors to detect add vs. update | Replaced with `applicationToEdit != nil` check — no store read needed |
| Important | `fetchAll(withStatus:)` returned unsorted results unlike `fetchAll()` | Added `.sorted { $0.dateApplied > $1.dateApplied }` (in-memory) and `SortDescriptor` (SwiftData) |
| Important | `errorMessage` set but never displayed — errors silently lost | Added `dismissErrorMessage()` to ViewModel; wired `.alert` modifier in `JobApplicationListView` |
| Important | Double-load pattern between `confirmDeleteSelected()` and callers | Added doc comment clarifying internal reload; callers do not need to reload |

7 new tests added to cover each fix.

**Test count: 161 passing, 0 failing**

---

### Phase 7 — Final Polish

**Goal:** Remove leftover cruft and consolidate test infrastructure.

- Removed the unused `com.apple.security.files.user-selected.read-write` entitlement — the app only requires the sandbox entitlement
- Created `TestFixtures.swift` with a single shared `makeApplication()` factory function; removed four duplicated copies from individual test files
- Updated `README.md` to reflect the removed entitlement
- Created `CHANGELOG.md` with a full record of what was built and why

**Test count: 161 passing, 0 failing (final)**

## Final Architecture

### Data Layer
- **Models**: `JobApplication` (value type), `ApplicationStatus` (enum)
- **Validation**: Business rules enforced at model level
- **Persistence**: Protocol-based (`JobApplicationStoreProtocol`)
  - `InMemoryJobApplicationStore` (for testing)
  - `SwiftDataJobApplicationStore` (production)

### Presentation Layer (MVVM)
- **ViewModels**:
  - `JobApplicationListViewModel` (main list, CRUD operations)
  - `JobApplicationFormViewModel` (add/edit form logic)
- **Views**:
  - `JobApplicationListView` (main table interface)
  - `JobApplicationFormView` (add/edit sheet)
  - `StatusBadgeView` (color-coded status badges)

### Key Design Decisions

1. **Protocol-based storage**: Enables fast, deterministic unit tests with in-memory store
2. **Separate persistence layer**: `PersistedJobApplication` keeps domain model clean
3. **Value types for models**: Immutable, thread-safe, easy to test
4. **Validation at model level**: Single source of truth for business rules
5. **Status state machine**: `canTransition(to:)` enforces valid status transitions

## Test Coverage

**161 total tests** covering:

- **Model Layer** (51 tests):
  - Application status transitions and validation
  - Job application model validation
  - Business rule enforcement

- **Persistence Layer** (40 tests):
  - In-memory store CRUD operations
  - SwiftData persistence and querying
  - Error handling and edge cases

- **ViewModel Layer** (46 tests):
  - Form validation and state management
  - List operations (add, edit, delete)
  - Selection and toolbar actions

- **UI Components** (18 tests):
  - Status badge rendering and colors
  - Component behavior and styling

- **Integration** (6 tests):
  - End-to-end workflows
  - Data persistence across app launches

## Features Implemented

✅ **Add job applications** with company, title, description, status
✅ **Edit existing applications** via double-click or context menu
✅ **Update application status** through six predefined states
✅ **Delete applications** with confirmation dialog
✅ **Compact table view** showing all information at once
✅ **Color-coded status badges** for visual clarity
✅ **Persistent storage** using SwiftData
✅ **Data validation** with user-friendly error messages
✅ **Status state machine** preventing invalid transitions
✅ **Empty state** with helpful messaging
✅ **Native macOS UI** following Human Interface Guidelines

## Quality Assurance

- ✅ Zero compiler warnings
- ✅ All 161 tests passing
- ✅ No `try!` crash risks
- ✅ Proper error handling throughout
- ✅ Validation enforced in save path
- ✅ Error messages displayed to users
- ✅ Graceful ModelContainer failure handling
- ✅ Minimal entitlements (sandbox only)
- ✅ Consistent code style
- ✅ Clean separation of concerns

## Build & Run

### Requirements
- macOS 14.0+ (Sonoma)
- Xcode 15.0+
- Swift 5.9+

### Quick Start
```bash
cd "/Users/adrianprince/Downloads/AI Project/Job Tracker/JobTracker"
open JobTracker.xcodeproj
# Press Cmd+R to build and run
# Press Cmd+U to run all 161 tests
```

### Command Line
```bash
# Build
xcodebuild -scheme JobTracker -destination 'platform=macOS'

# Run tests
xcodebuild test -scheme JobTracker -destination 'platform=macOS'
```

## Documentation

- **README.md**: Full build instructions, architecture overview, distribution guide
- **USER_GUIDE.md**: End-user documentation with screenshots and workflows
- **DEVELOPMENT_SUMMARY.md**: This file - development process and technical details

## Distribution Ready

The app is production-ready with:
- Version 1.0.0 set in project settings
- Proper code signing configuration
- Minimal entitlements for App Store submission
- Comprehensive test suite for regression prevention
- Error handling for edge cases
- User-friendly validation messages

## Future Enhancement Suggestions

See README.md for a curated list of potential features:
- Search and filtering
- Export functionality
- Application deadline tracking
- Notes and interview scheduling
- Application statistics dashboard
- Tags and categories
- Email integration

---

**Development completed using TDD methodology**
**Total development time**: Single session
**Final test count**: 161 passing, 0 failing
**Code quality**: Production-ready
