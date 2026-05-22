// UIComponentTests.swift
// JobTrackerTests
//
// Tests for all SwiftUI UI components.
//
// Testing approach:
//   - ViewModels are tested directly (plain XCTestCase, no UI automation).
//   - StatusBadgeView computed properties are tested as plain Swift values.
//   - Integration tests drive the full ViewModel lifecycle end-to-end.
//
// Why this approach:
//   macOS SwiftUI has no XCUIApplication-level access to SwiftUI view trees in
//   unit-test bundles. Instead we test behaviour through the ViewModel layer,
//   which owns all state transitions. Views are thin wrappers that react to
//   ViewModel state – if the ViewModel is correct the view will be correct.

import XCTest
@testable import JobTracker

// ---------------------------------------------------------------------------
// MARK: - Helpers shared across test classes
// ---------------------------------------------------------------------------

private func makeApp(
    companyName: String        = "Acme",
    jobTitle: String           = "Engineer",
    jobDescription: String     = "Build things",
    status: ApplicationStatus  = .pending,
    daysAgo: Int               = 0
) -> JobApplication {
    let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
    return JobApplication(
        companyName: companyName,
        jobTitle: jobTitle,
        jobDescription: jobDescription,
        status: status,
        dateApplied: date,
        lastUpdated: date
    )
}

// ---------------------------------------------------------------------------
// MARK: - 1. Main List View (ViewModel) Tests
// ---------------------------------------------------------------------------

@MainActor
final class JobApplicationListViewModelTests: XCTestCase {

    private var store: InMemoryJobApplicationStore!
    private var sut: JobApplicationListViewModel!

    override func setUp() {
        super.setUp()
        store = InMemoryJobApplicationStore()
        sut   = JobApplicationListViewModel(store: store)
    }

    override func tearDown() {
        sut   = nil
        store = nil
        super.tearDown()
    }

    // MARK: 1a – All applications displayed

    func test_loadApplications_populatesApplicationsFromStore() throws {
        let app1 = makeApp(companyName: "Alpha")
        let app2 = makeApp(companyName: "Beta")
        try store.add(app1)
        try store.add(app2)

        sut.loadApplications()

        XCTAssertEqual(sut.applications.count, 2,
                       "loadApplications must populate applications with all store records")
        XCTAssertTrue(sut.applications.contains(where: { $0.id == app1.id }))
        XCTAssertTrue(sut.applications.contains(where: { $0.id == app2.id }))
    }

    // MARK: 1b – Compact layout (all columns present per row)

    func test_applications_eachRowExposesCompanyNameJobTitleStatusAndDate() throws {
        let app = makeApp(companyName: "Stripe", jobTitle: "SWE", status: .applied)
        try store.add(app)

        sut.loadApplications()

        let row = try XCTUnwrap(sut.applications.first,
                                "There must be at least one application after loading")
        XCTAssertFalse(row.companyName.isEmpty, "companyName must be non-empty")
        XCTAssertFalse(row.jobTitle.isEmpty,    "jobTitle must be non-empty")
        XCTAssertNotNil(row.dateApplied,        "dateApplied must be present")
        XCTAssertEqual(row.status, .applied)
    }

    // MARK: 1c – Sorted newest first

    func test_loadApplications_sortsByDateAppliedDescending() throws {
        let oldest  = makeApp(companyName: "Old Co",    daysAgo: 30)
        let middle  = makeApp(companyName: "Middle Co", daysAgo: 15)
        let newest  = makeApp(companyName: "New Co",    daysAgo: 0)
        try store.add(oldest)
        try store.add(newest)
        try store.add(middle)

        sut.loadApplications()

        XCTAssertEqual(sut.applications.count, 3)
        XCTAssertEqual(sut.applications[0].companyName, "New Co",
                       "Newest application must appear first")
        XCTAssertEqual(sut.applications[2].companyName, "Old Co",
                       "Oldest application must appear last")
    }

    // MARK: 1d – Empty state

    func test_applications_isEmpty_whenStoreContainsNoRecords() {
        sut.loadApplications()

        XCTAssertTrue(sut.applications.isEmpty,
                      "applications must be empty when the store has no records")
    }

    func test_applications_isEmpty_afterAllRecordsDeleted() throws {
        let app = makeApp()
        try store.add(app)
        sut.loadApplications()
        try store.delete(id: app.id)
        sut.loadApplications()

        XCTAssertTrue(sut.applications.isEmpty,
                      "applications must be empty after all records have been deleted")
    }

    // MARK: 1e – Row selection

    func test_selectedApplicationID_isNilByDefault() {
        XCTAssertNil(sut.selectedApplicationID,
                     "No row must be selected on initial load")
    }

    func test_selectedApplication_returnsMatchingRow_whenIDIsSet() throws {
        let app = makeApp(companyName: "Tesla")
        try store.add(app)
        sut.loadApplications()

        sut.selectedApplicationID = app.id

        XCTAssertEqual(sut.selectedApplication?.id, app.id,
                       "selectedApplication must return the row whose id matches selectedApplicationID")
    }

    func test_selectedApplication_isNil_whenIDDoesNotMatchAnyRow() throws {
        let app = makeApp()
        try store.add(app)
        sut.loadApplications()
        sut.selectedApplicationID = UUID() // non-existent id

        XCTAssertNil(sut.selectedApplication,
                     "selectedApplication must be nil when selectedApplicationID matches no loaded row")
    }

    func test_canDelete_isFalse_whenNothingIsSelected() {
        XCTAssertFalse(sut.canDelete,
                       "canDelete must be false when no row is selected")
    }

    func test_canDelete_isTrue_whenRowIsSelected() throws {
        let app = makeApp()
        try store.add(app)
        sut.loadApplications()
        sut.selectedApplicationID = app.id

        XCTAssertTrue(sut.canDelete,
                      "canDelete must be true when a row is selected")
    }

    // MARK: 1f – isFormPresented initial state

    func test_isFormPresented_isFalseByDefault() {
        XCTAssertFalse(sut.isFormPresented,
                       "The form must not be visible on initial load")
    }

    // MARK: 1g – errorMessage alert state

    func test_errorMessage_isNilByDefault() {
        XCTAssertNil(sut.errorMessage,
                     "errorMessage must be nil on initial load")
    }

    func test_dismissErrorMessage_clearsErrorMessage() {
        // Simulate an error being set (e.g. by a failed save)
        sut.errorMessage = "Something went wrong"

        sut.dismissErrorMessage()

        XCTAssertNil(sut.errorMessage,
                     "dismissErrorMessage must clear errorMessage to nil")
    }
}

// ---------------------------------------------------------------------------
// MARK: - 2. Toolbar Actions Tests
// ---------------------------------------------------------------------------

@MainActor
final class ToolbarActionsTests: XCTestCase {

    private var store: InMemoryJobApplicationStore!
    private var sut: JobApplicationListViewModel!

    override func setUp() {
        super.setUp()
        store = InMemoryJobApplicationStore()
        sut   = JobApplicationListViewModel(store: store)
    }

    override func tearDown() {
        sut   = nil
        store = nil
        super.tearDown()
    }

    // MARK: 2a – Add button opens form

    func test_presentAddForm_setsIsFormPresentedToTrue() {
        sut.presentAddForm()

        XCTAssertTrue(sut.isFormPresented,
                      "presentAddForm must set isFormPresented to true")
    }

    func test_presentAddForm_setsApplicationToEditToNil() {
        sut.presentAddForm()

        XCTAssertNil(sut.applicationToEdit,
                     "presentAddForm must clear applicationToEdit (new record, not an edit)")
    }

    // MARK: 2b – Edit opens form pre-populated

    func test_presentEditForm_setsIsFormPresentedToTrue() throws {
        let app = makeApp()
        try store.add(app)
        sut.loadApplications()

        sut.presentEditForm(for: app)

        XCTAssertTrue(sut.isFormPresented,
                      "presentEditForm must set isFormPresented to true")
    }

    func test_presentEditForm_setsApplicationToEdit() throws {
        let app = makeApp(companyName: "Edit Me")
        try store.add(app)
        sut.loadApplications()

        sut.presentEditForm(for: app)

        XCTAssertEqual(sut.applicationToEdit?.id, app.id,
                       "presentEditForm must set applicationToEdit to the chosen application")
    }

    // MARK: 2c – Delete button shows confirmation

    func test_requestDeleteSelected_setsDeleteConfirmationPresented_whenRowSelected() throws {
        let app = makeApp()
        try store.add(app)
        sut.loadApplications()
        sut.selectedApplicationID = app.id

        sut.requestDeleteSelected()

        XCTAssertTrue(sut.isDeleteConfirmationPresented,
                      "requestDeleteSelected must show the confirmation dialog")
    }

    func test_requestDeleteSelected_doesNotShowConfirmation_whenNothingSelected() {
        sut.requestDeleteSelected()

        XCTAssertFalse(sut.isDeleteConfirmationPresented,
                       "requestDeleteSelected must not show a dialog when nothing is selected")
    }

    // MARK: 2d – Confirm delete removes item

    func test_confirmDeleteSelected_removesSelectedApplicationFromList() throws {
        let app = makeApp()
        try store.add(app)
        sut.loadApplications()
        sut.selectedApplicationID = app.id
        sut.requestDeleteSelected()

        sut.confirmDeleteSelected()

        sut.loadApplications() // reload to reflect store state
        XCTAssertFalse(sut.applications.contains(where: { $0.id == app.id }),
                       "confirmDeleteSelected must remove the application from the list")
    }

    func test_confirmDeleteSelected_clearsSelection() throws {
        let app = makeApp()
        try store.add(app)
        sut.loadApplications()
        sut.selectedApplicationID = app.id
        sut.requestDeleteSelected()

        sut.confirmDeleteSelected()

        XCTAssertNil(sut.selectedApplicationID,
                     "confirmDeleteSelected must clear the selection")
    }

    func test_confirmDeleteSelected_dismissesConfirmationDialog() throws {
        let app = makeApp()
        try store.add(app)
        sut.loadApplications()
        sut.selectedApplicationID = app.id
        sut.requestDeleteSelected()

        sut.confirmDeleteSelected()

        XCTAssertFalse(sut.isDeleteConfirmationPresented,
                       "confirmDeleteSelected must dismiss the confirmation dialog")
    }

    // MARK: 2e – Cancel form

    func test_cancelForm_setsIsFormPresentedToFalse() {
        sut.presentAddForm()
        sut.cancelForm()

        XCTAssertFalse(sut.isFormPresented,
                       "cancelForm must hide the form sheet")
    }
}

// ---------------------------------------------------------------------------
// MARK: - 3. Add / Edit Form (ViewModel) Tests
// ---------------------------------------------------------------------------

@MainActor
final class JobApplicationFormViewModelTests: XCTestCase {

    // MARK: 3a – All fields present / pre-populated

    func test_addMode_fieldsStartEmpty() {
        let sut = JobApplicationFormViewModel()

        XCTAssertTrue(sut.companyName.isEmpty,    "companyName must start empty in add mode")
        XCTAssertTrue(sut.jobTitle.isEmpty,       "jobTitle must start empty in add mode")
        XCTAssertTrue(sut.jobDescription.isEmpty, "jobDescription must start empty in add mode")
    }

    func test_addMode_defaultStatusIsPending() {
        let sut = JobApplicationFormViewModel()

        XCTAssertEqual(sut.status, .pending,
                       "Default status in add mode must be .pending")
    }

    func test_editMode_fieldsPrePopulatedFromExistingApplication() {
        let app = makeApp(companyName: "Pre-filled", jobTitle: "Designer",
                         jobDescription: "Design work", status: .applied)
        let sut = JobApplicationFormViewModel(editing: app)

        XCTAssertEqual(sut.companyName,    "Pre-filled")
        XCTAssertEqual(sut.jobTitle,       "Designer")
        XCTAssertEqual(sut.jobDescription, "Design work")
        XCTAssertEqual(sut.status,         .applied)
    }

    func test_isEditing_isFalseForNewApplication() {
        let sut = JobApplicationFormViewModel()
        XCTAssertFalse(sut.isEditing, "isEditing must be false when creating a new application")
    }

    func test_isEditing_isTrueWhenEditingExistingApplication() {
        let app = makeApp()
        let sut = JobApplicationFormViewModel(editing: app)
        XCTAssertTrue(sut.isEditing, "isEditing must be true when an existing application is supplied")
    }

    // MARK: 3b – Validation: isValid

    func test_isValid_isFalseWhenCompanyNameIsEmpty() {
        let sut = JobApplicationFormViewModel()
        sut.companyName = ""
        sut.jobTitle    = "Engineer"

        XCTAssertFalse(sut.isValid,
                       "isValid must be false when companyName is empty")
    }

    func test_isValid_isFalseWhenJobTitleIsEmpty() {
        let sut = JobApplicationFormViewModel()
        sut.companyName = "Acme"
        sut.jobTitle    = ""

        XCTAssertFalse(sut.isValid,
                       "isValid must be false when jobTitle is empty")
    }

    func test_isValid_isTrueWhenRequiredFieldsArePopulated() {
        let sut = JobApplicationFormViewModel()
        sut.companyName = "Acme"
        sut.jobTitle    = "Engineer"

        XCTAssertTrue(sut.isValid,
                      "isValid must be true when companyName and jobTitle are non-empty")
    }

    func test_isValid_isFalseWhenCompanyNameIsWhitespaceOnly() {
        let sut = JobApplicationFormViewModel()
        sut.companyName = "   "
        sut.jobTitle    = "Engineer"

        XCTAssertFalse(sut.isValid,
                       "isValid must be false when companyName contains only whitespace")
    }

    func test_isValid_isFalseWhenJobTitleIsWhitespaceOnly() {
        let sut = JobApplicationFormViewModel()
        sut.companyName = "Acme"
        sut.jobTitle    = "\t  "

        XCTAssertFalse(sut.isValid,
                       "isValid must be false when jobTitle contains only whitespace")
    }

    func test_isValid_isFalseWhenDescriptionExceeds50000Characters() {
        let sut = JobApplicationFormViewModel()
        sut.companyName    = "Acme"
        sut.jobTitle       = "Engineer"
        sut.jobDescription = String(repeating: "x", count: 50_001)

        XCTAssertFalse(sut.isValid,
                       "isValid must be false when description exceeds 50,000 characters")
    }

    func test_isValid_isTrueWhenDescriptionIsExactly50000Characters() {
        let sut = JobApplicationFormViewModel()
        sut.companyName    = "Acme"
        sut.jobTitle       = "Engineer"
        sut.jobDescription = String(repeating: "x", count: 50_000)

        XCTAssertTrue(sut.isValid,
                      "isValid must be true when description is exactly at the 50,000-character limit")
    }

    // MARK: 3c – Validation: error visibility flags

    func test_showsCompanyNameError_isTrueWhenCompanyNameIsEmpty() {
        let sut = JobApplicationFormViewModel()
        sut.companyName = ""
        sut.jobTitle    = "Engineer"

        XCTAssertTrue(sut.showsCompanyNameError,
                      "showsCompanyNameError must be true when companyName is blank")
    }

    func test_showsCompanyNameError_isFalseWhenCompanyNameIsPopulated() {
        let sut = JobApplicationFormViewModel()
        sut.companyName = "Acme"

        XCTAssertFalse(sut.showsCompanyNameError,
                       "showsCompanyNameError must be false when companyName is filled in")
    }

    func test_showsJobTitleError_isTrueWhenJobTitleIsEmpty() {
        let sut = JobApplicationFormViewModel()
        sut.companyName = "Acme"
        sut.jobTitle    = ""

        XCTAssertTrue(sut.showsJobTitleError,
                      "showsJobTitleError must be true when jobTitle is blank")
    }

    func test_showsJobTitleError_isFalseWhenJobTitleIsPopulated() {
        let sut = JobApplicationFormViewModel()
        sut.jobTitle = "Engineer"

        XCTAssertFalse(sut.showsJobTitleError,
                       "showsJobTitleError must be false when jobTitle is filled in")
    }

    // MARK: 3d – buildApplication

    func test_buildApplication_returnsNilWhenFormIsInvalid() {
        let sut = JobApplicationFormViewModel()
        // companyName and jobTitle are empty → invalid

        XCTAssertNil(sut.buildApplication(),
                     "buildApplication must return nil when the form is invalid")
    }

    func test_buildApplication_returnsApplicationWithCorrectFieldsWhenValid() {
        let sut = JobApplicationFormViewModel()
        sut.companyName    = "Notion"
        sut.jobTitle       = "Designer"
        sut.jobDescription = "Design cool things"
        sut.status         = .applied

        let result = sut.buildApplication()

        XCTAssertNotNil(result,
                        "buildApplication must return an application when the form is valid")
        XCTAssertEqual(result?.companyName,    "Notion")
        XCTAssertEqual(result?.jobTitle,       "Designer")
        XCTAssertEqual(result?.jobDescription, "Design cool things")
        XCTAssertEqual(result?.status,         .applied)
    }

    func test_buildApplication_inEditMode_preservesOriginalID() {
        let original = makeApp(companyName: "Old Name")
        let sut      = JobApplicationFormViewModel(editing: original)
        sut.companyName = "New Name"

        let result = sut.buildApplication()

        XCTAssertEqual(result?.id, original.id,
                       "buildApplication in edit mode must preserve the original application's ID")
    }

    // MARK: 3e – Save button disabled state

    func test_saveButton_isDisabled_whenFormIsInvalid() {
        let sut = JobApplicationFormViewModel()
        // Both required fields are empty.

        XCTAssertFalse(sut.isValid,
                       "Save must be disabled (isValid == false) when required fields are missing")
    }

    func test_saveButton_isEnabled_whenFormIsValid() {
        let sut = JobApplicationFormViewModel()
        sut.companyName = "Apple"
        sut.jobTitle    = "Engineer"

        XCTAssertTrue(sut.isValid,
                      "Save must be enabled (isValid == true) when required fields are filled")
    }
}

// ---------------------------------------------------------------------------
// MARK: - 4. StatusBadgeView Component Tests
// ---------------------------------------------------------------------------

final class StatusBadgeViewTests: XCTestCase {

    // MARK: 4a – Each status has the correct label

    func test_badgeLabel_pending_isCorrect() {
        let sut = StatusBadgeView(status: .pending)
        XCTAssertEqual(sut.badgeLabel, "Pending",
                       "badgeLabel for .pending must be 'Pending'")
    }

    func test_badgeLabel_applied_isCorrect() {
        let sut = StatusBadgeView(status: .applied)
        XCTAssertEqual(sut.badgeLabel, "Applied",
                       "badgeLabel for .applied must be 'Applied'")
    }

    func test_badgeLabel_inProcess_isCorrect() {
        let sut = StatusBadgeView(status: .inProcess)
        XCTAssertEqual(sut.badgeLabel, "In Process",
                       "badgeLabel for .inProcess must be 'In Process'")
    }

    func test_badgeLabel_waiting_isCorrect() {
        let sut = StatusBadgeView(status: .waiting)
        XCTAssertEqual(sut.badgeLabel, "Waiting",
                       "badgeLabel for .waiting must be 'Waiting'")
    }

    func test_badgeLabel_hired_isCorrect() {
        let sut = StatusBadgeView(status: .hired)
        XCTAssertEqual(sut.badgeLabel, "Hired",
                       "badgeLabel for .hired must be 'Hired'")
    }

    func test_badgeLabel_ghosted_isCorrect() {
        let sut = StatusBadgeView(status: .ghosted)
        XCTAssertEqual(sut.badgeLabel, "Ghosted",
                       "badgeLabel for .ghosted must be 'Ghosted'")
    }

    // MARK: 4b – Each status has a distinct, non-gray colour

    func test_badgeColor_pending_isNotGray() {
        let sut = StatusBadgeView(status: .pending)
        XCTAssertNotEqual(sut.badgeColor, .gray,
                          "pending badge must not use the default gray colour")
    }

    func test_badgeColor_applied_isNotGray() {
        let sut = StatusBadgeView(status: .applied)
        XCTAssertNotEqual(sut.badgeColor, .gray,
                          "applied badge must not use the default gray colour")
    }

    func test_badgeColor_inProcess_isNotGray() {
        let sut = StatusBadgeView(status: .inProcess)
        XCTAssertNotEqual(sut.badgeColor, .gray,
                          "inProcess badge must not use the default gray colour")
    }

    func test_badgeColor_waiting_isNotGray() {
        let sut = StatusBadgeView(status: .waiting)
        XCTAssertNotEqual(sut.badgeColor, .gray,
                          "waiting badge must not use the default gray colour")
    }

    func test_badgeColor_hired_isDistinctFromGhosted() {
        let hired   = StatusBadgeView(status: .hired)
        let ghosted = StatusBadgeView(status: .ghosted)
        XCTAssertNotEqual(hired.badgeColor, ghosted.badgeColor,
                          "hired and ghosted must have distinct badge colours")
    }

    // MARK: 4c – Terminal statuses

    func test_isTerminal_isTrueForHired() {
        let sut = StatusBadgeView(status: .hired)
        XCTAssertTrue(sut.isTerminal,
                      "isTerminal must be true for the .hired status")
    }

    func test_isTerminal_isTrueForGhosted() {
        let sut = StatusBadgeView(status: .ghosted)
        XCTAssertTrue(sut.isTerminal,
                      "isTerminal must be true for the .ghosted status")
    }

    func test_isTerminal_isFalseForNonTerminalStatuses() {
        let nonTerminal: [ApplicationStatus] = [.pending, .applied, .inProcess, .waiting]
        for status in nonTerminal {
            let sut = StatusBadgeView(status: status)
            XCTAssertFalse(sut.isTerminal,
                           "\(status.rawValue) badge must not be marked as terminal")
        }
    }

    func test_allStatusesHaveDistinctLabels() {
        let labels = ApplicationStatus.allCases.map { StatusBadgeView(status: $0).badgeLabel }
        let uniqueLabels = Set(labels)
        XCTAssertEqual(uniqueLabels.count, ApplicationStatus.allCases.count,
                       "Each status must produce a unique badge label")
    }
}

// ---------------------------------------------------------------------------
// MARK: - 5. Integration Tests (full lifecycle through ViewModel)
// ---------------------------------------------------------------------------

@MainActor
final class UIIntegrationTests: XCTestCase {

    private var store: InMemoryJobApplicationStore!
    private var listVM: JobApplicationListViewModel!

    override func setUp() {
        super.setUp()
        store  = InMemoryJobApplicationStore()
        listVM = JobApplicationListViewModel(store: store)
    }

    override func tearDown() {
        listVM = nil
        store  = nil
        super.tearDown()
    }

    // MARK: 5a – Complete add workflow

    func test_integration_addApplication_appearsInList() {
        // Step 1: open the form
        listVM.presentAddForm()

        XCTAssertTrue(listVM.isFormPresented, "Form must be presented after tapping Add")

        // Step 2: fill in the form and save
        let formVM = JobApplicationFormViewModel()
        formVM.companyName = "Integration Co"
        formVM.jobTitle    = "QA Engineer"

        let app = formVM.buildApplication()

        XCTAssertNotNil(app, "buildApplication must return an application when fields are valid")

        if let app = app {
            listVM.save(app)
        }

        // Step 3: reload and confirm the new application is visible
        listVM.loadApplications()

        XCTAssertEqual(listVM.applications.count, 1,
                       "The saved application must appear in the list")
        XCTAssertEqual(listVM.applications.first?.companyName, "Integration Co")
    }

    // MARK: 5b – Edit workflow

    func test_integration_editApplication_updatesInList() throws {
        // Seed the store
        let original = makeApp(companyName: "Before Edit")
        try store.add(original)
        listVM.loadApplications()

        // Open edit form
        listVM.presentEditForm(for: original)

        XCTAssertTrue(listVM.isFormPresented)
        XCTAssertEqual(listVM.applicationToEdit?.id, original.id)

        // Modify and save
        let formVM = JobApplicationFormViewModel(editing: original)
        formVM.companyName = "After Edit"
        let updated = formVM.buildApplication()

        XCTAssertNotNil(updated)
        if let updated = updated {
            listVM.save(updated)
        }

        listVM.loadApplications()

        XCTAssertEqual(listVM.applications.first?.companyName, "After Edit",
                       "The list must reflect the edited company name")
    }

    // MARK: 5c – Delete workflow

    func test_integration_deleteApplication_removesFromList() throws {
        let app = makeApp(companyName: "To Delete")
        try store.add(app)
        listVM.loadApplications()

        XCTAssertEqual(listVM.applications.count, 1)

        listVM.selectedApplicationID = app.id
        listVM.requestDeleteSelected()

        XCTAssertTrue(listVM.isDeleteConfirmationPresented)

        listVM.confirmDeleteSelected()
        listVM.loadApplications()

        XCTAssertTrue(listVM.applications.isEmpty,
                      "List must be empty after deleting the only application")
    }

    // MARK: 5d – Status update workflow

    func test_integration_updateStatus_reflectedInList() throws {
        let app = makeApp(status: .applied)
        try store.add(app)
        listVM.loadApplications()

        // Simulate user opening the edit form then changing the status
        listVM.presentEditForm(for: app)
        let formVM = JobApplicationFormViewModel(editing: app)
        formVM.status = .inProcess
        let updated = formVM.buildApplication()

        XCTAssertNotNil(updated)
        if let updated = updated {
            listVM.save(updated)
        }

        listVM.loadApplications()

        XCTAssertEqual(listVM.applications.first?.status, .inProcess,
                       "Status change through the form must be reflected in the list")
    }

    // MARK: 5e – Data persistence (simulated via store)

    func test_integration_dataPersistedAcrossViewModelRecreation() throws {
        // Add an application and save it
        let formVM = JobApplicationFormViewModel()
        formVM.companyName = "Persistent Co"
        formVM.jobTitle    = "Archivist"
        let app = formVM.buildApplication()

        XCTAssertNotNil(app)
        if let app = app {
            try store.add(app)
        }

        // Simulate app relaunch by creating a brand-new ViewModel with the same store
        let freshVM = JobApplicationListViewModel(store: store)
        freshVM.loadApplications()

        XCTAssertEqual(freshVM.applications.count, 1,
                       "A new ViewModel using the same store must see previously saved applications")
        XCTAssertEqual(freshVM.applications.first?.companyName, "Persistent Co")
    }

    // MARK: 5a2 – save() validates before persisting

    func test_save_withInvalidApplication_setsErrorMessage() {
        // Open the add form so isFormPresented is true before the attempted save.
        listVM.presentAddForm()

        // Construct an application that fails validation (empty company name).
        let invalid = JobApplication(
            id: UUID(),
            companyName: "",
            jobTitle: "Engineer",
            jobDescription: "",
            status: .pending,
            dateApplied: Date(),
            lastUpdated: Date()
        )

        listVM.save(invalid)

        XCTAssertNotNil(listVM.errorMessage,
                        "save() must set errorMessage when the application fails validation")
        XCTAssertTrue(listVM.applications.isEmpty,
                      "An invalid application must not be added to the store")
        XCTAssertTrue(listVM.isFormPresented,
                      "The form must remain open when save fails validation")
    }

    // MARK: 5e2 – save() uses applicationToEdit to decide add vs update

    func test_save_usesApplicationToEdit_toDistinguishAddFromUpdate() throws {
        // When applicationToEdit is nil, save must call add (not update).
        let formVM = JobApplicationFormViewModel()
        formVM.companyName = "Brand New Co"
        formVM.jobTitle    = "Engineer"
        let app = formVM.buildApplication()!

        // applicationToEdit is nil on listVM → this is an add
        listVM.applicationToEdit = nil
        listVM.save(app)

        listVM.loadApplications()
        XCTAssertEqual(listVM.applications.count, 1,
                       "Saving with applicationToEdit nil must add to the store")

        // Simulate edit path: applicationToEdit is set → save must update
        listVM.applicationToEdit = listVM.applications.first
        var edited = listVM.applications.first!
        edited.companyName = "Renamed Co"
        listVM.save(edited)

        listVM.loadApplications()
        XCTAssertEqual(listVM.applications.count, 1,
                       "Saving with applicationToEdit set must update, not duplicate")
        XCTAssertEqual(listVM.applications.first?.companyName, "Renamed Co",
                       "The updated company name must be reflected in the list")
    }

    // MARK: 5f – Cancel does not persist

    func test_integration_cancelAdd_doesNotAddApplicationToStore() throws {
        listVM.presentAddForm()
        listVM.cancelForm()

        XCTAssertFalse(listVM.isFormPresented,
                       "Cancelling must close the form")

        listVM.loadApplications()
        XCTAssertTrue(listVM.applications.isEmpty,
                      "Cancelling must not persist any application")
    }
}

// ---------------------------------------------------------------------------
// MARK: - 6. Search & Filter Tests
// ---------------------------------------------------------------------------

@MainActor
final class SearchFilterTests: XCTestCase {

    private var store: InMemoryJobApplicationStore!
    private var sut: JobApplicationListViewModel!

    override func setUp() {
        super.setUp()
        store = InMemoryJobApplicationStore()
        sut   = JobApplicationListViewModel(store: store)
    }

    override func tearDown() {
        sut   = nil
        store = nil
        super.tearDown()
    }

    func test_filteredApplications_returnsAllWhenNoFilters() throws {
        try store.add(makeApp(companyName: "Alpha"))
        try store.add(makeApp(companyName: "Beta"))
        sut.loadApplications()

        XCTAssertEqual(sut.filteredApplications.count, 2)
    }

    func test_filteredApplications_filtersBySearchText() throws {
        try store.add(makeApp(companyName: "Apple"))
        try store.add(makeApp(companyName: "Google"))
        sut.loadApplications()

        sut.searchText = "apple"
        XCTAssertEqual(sut.filteredApplications.count, 1)
        XCTAssertEqual(sut.filteredApplications.first?.companyName, "Apple")
    }

    func test_filteredApplications_filtersByJobTitle() throws {
        try store.add(makeApp(companyName: "A", jobTitle: "iOS Engineer"))
        try store.add(makeApp(companyName: "B", jobTitle: "Backend Dev"))
        sut.loadApplications()

        sut.searchText = "ios"
        XCTAssertEqual(sut.filteredApplications.count, 1)
        XCTAssertEqual(sut.filteredApplications.first?.jobTitle, "iOS Engineer")
    }

    func test_filteredApplications_filtersByStatus() throws {
        try store.add(makeApp(companyName: "A", status: .applied))
        try store.add(makeApp(companyName: "B", status: .pending))
        sut.loadApplications()

        sut.statusFilter = .applied
        XCTAssertEqual(sut.filteredApplications.count, 1)
        XCTAssertEqual(sut.filteredApplications.first?.companyName, "A")
    }

    func test_filteredApplications_combinesSearchAndStatusFilter() throws {
        try store.add(makeApp(companyName: "Apple", status: .applied))
        try store.add(makeApp(companyName: "Amazon", status: .pending))
        try store.add(makeApp(companyName: "Google", status: .applied))
        sut.loadApplications()

        sut.searchText = "a"
        sut.statusFilter = .applied
        XCTAssertEqual(sut.filteredApplications.count, 1)
        XCTAssertEqual(sut.filteredApplications.first?.companyName, "Apple")
    }

    func test_hasActiveFilters_isFalseByDefault() {
        XCTAssertFalse(sut.hasActiveFilters)
    }

    func test_hasActiveFilters_isTrueWhenSearchTextIsSet() {
        sut.searchText = "test"
        XCTAssertTrue(sut.hasActiveFilters)
    }

    func test_hasActiveFilters_isTrueWhenStatusFilterIsSet() {
        sut.statusFilter = .applied
        XCTAssertTrue(sut.hasActiveFilters)
    }
}

// ---------------------------------------------------------------------------
// MARK: - 7. Follow-Up Date & Overdue Tests
// ---------------------------------------------------------------------------

final class FollowUpDateTests: XCTestCase {

    func test_isOverdue_isFalseWhenNoFollowUpDate() {
        let app = makeApp()
        XCTAssertFalse(app.isOverdue)
    }

    func test_isOverdue_isTrueWhenFollowUpDateIsInPast() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let app = JobApplication(
            companyName: "X", jobTitle: "Y", jobDescription: "",
            status: .applied, followUpDate: yesterday
        )
        XCTAssertTrue(app.isOverdue)
    }

    func test_isOverdue_isFalseWhenFollowUpDateIsInFuture() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let app = JobApplication(
            companyName: "X", jobTitle: "Y", jobDescription: "",
            status: .applied, followUpDate: tomorrow
        )
        XCTAssertFalse(app.isOverdue)
    }

    func test_isOverdue_isFalseWhenStatusIsTerminal() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let app = JobApplication(
            companyName: "X", jobTitle: "Y", jobDescription: "",
            status: .hired, followUpDate: yesterday
        )
        XCTAssertFalse(app.isOverdue)
    }

    func test_isOverdue_isFalseWhenFollowUpDateIsToday() {
        let today = Calendar.current.startOfDay(for: Date())
        let app = JobApplication(
            companyName: "X", jobTitle: "Y", jobDescription: "",
            status: .applied, followUpDate: today
        )
        XCTAssertFalse(app.isOverdue,
                       "Follow-up date set to today must not be overdue (only past dates are overdue)")
    }

    func test_isOverdue_isFalseWhenStatusIsGhosted() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let app = JobApplication(
            companyName: "X", jobTitle: "Y", jobDescription: "",
            status: .ghosted, followUpDate: yesterday
        )
        XCTAssertFalse(app.isOverdue,
                       "Ghosted is terminal; overdue must be suppressed")
    }
}

// ---------------------------------------------------------------------------
// MARK: - 8. New Fields Tests
// ---------------------------------------------------------------------------

@MainActor
final class NewFieldsTests: XCTestCase {

    func test_formViewModel_populatesNewFieldsInEditMode() {
        let app = JobApplication(
            companyName: "Co", jobTitle: "Dev", jobDescription: "",
            salary: "$100k", jobURL: "https://example.com",
            contactName: "Jane", contactEmail: "jane@co.com"
        )
        let sut = JobApplicationFormViewModel(editing: app)

        XCTAssertEqual(sut.salary, "$100k")
        XCTAssertEqual(sut.jobURL, "https://example.com")
        XCTAssertEqual(sut.contactName, "Jane")
        XCTAssertEqual(sut.contactEmail, "jane@co.com")
    }

    func test_buildApplication_includesNewFields() {
        let sut = JobApplicationFormViewModel()
        sut.companyName = "Co"
        sut.jobTitle = "Dev"
        sut.salary = "$150k"
        sut.jobURL = "https://jobs.co"
        sut.contactName = "Bob"
        sut.contactEmail = "bob@co.com"

        let result = sut.buildApplication()
        XCTAssertEqual(result?.salary, "$150k")
        XCTAssertEqual(result?.jobURL, "https://jobs.co")
        XCTAssertEqual(result?.contactName, "Bob")
        XCTAssertEqual(result?.contactEmail, "bob@co.com")
    }

    func test_buildApplication_includesFollowUpDate() {
        let date = Date()
        let sut = JobApplicationFormViewModel()
        sut.companyName = "Co"
        sut.jobTitle = "Dev"
        sut.followUpDate = date

        let result = sut.buildApplication()
        XCTAssertEqual(result?.followUpDate, date)
    }

    func test_codable_backwardCompatibility() throws {
        // Encode a minimal JSON without new fields (simulating old data)
        let json = """
        {
            "id": "12345678-1234-1234-1234-123456789012",
            "companyName": "Old Co",
            "jobTitle": "Dev",
            "jobDescription": "desc",
            "status": "applied",
            "dateApplied": 0,
            "lastUpdated": 0
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let app = try decoder.decode(JobApplication.self, from: json)

        XCTAssertEqual(app.companyName, "Old Co")
        XCTAssertEqual(app.salary, "")
        XCTAssertEqual(app.jobURL, "")
        XCTAssertEqual(app.contactName, "")
        XCTAssertEqual(app.contactEmail, "")
        XCTAssertNil(app.followUpDate)
    }
}

// ---------------------------------------------------------------------------
// MARK: - 9. CSV Export Tests
// ---------------------------------------------------------------------------

@MainActor
final class CSVExportTests: XCTestCase {

    func test_buildCSV_producesHeaderRow() {
        let store = InMemoryJobApplicationStore()
        let sut = JobApplicationListViewModel(store: store)

        let csv = sut.buildCSV(from: [])
        XCTAssertTrue(csv.hasPrefix("Company,Job Title,Status,Date Applied"))
    }

    func test_buildCSV_includesApplicationData() throws {
        let store = InMemoryJobApplicationStore()
        let sut = JobApplicationListViewModel(store: store)
        let app = JobApplication(
            companyName: "Acme", jobTitle: "Engineer", jobDescription: "desc",
            status: .applied, dateApplied: Date(), lastUpdated: Date(),
            salary: "$100k"
        )

        let csv = sut.buildCSV(from: [app])
        let lines = csv.components(separatedBy: "\n")
        XCTAssertEqual(lines.count, 2, "CSV must have header + 1 data row")
        XCTAssertTrue(lines[1].contains("Acme"))
        XCTAssertTrue(lines[1].contains("$100k"))
    }

    func test_buildCSV_escapesCommasInFields() throws {
        let store = InMemoryJobApplicationStore()
        let sut = JobApplicationListViewModel(store: store)
        let app = JobApplication(
            companyName: "Acme, Inc.", jobTitle: "Engineer", jobDescription: "",
            status: .pending, dateApplied: Date(), lastUpdated: Date()
        )

        let csv = sut.buildCSV(from: [app])
        XCTAssertTrue(csv.contains("\"Acme, Inc.\""),
                      "Fields with commas must be quoted")
    }

    func test_buildCSV_escapesQuotesInFields() throws {
        let store = InMemoryJobApplicationStore()
        let sut = JobApplicationListViewModel(store: store)
        let app = JobApplication(
            companyName: "He said \"hello\"", jobTitle: "Dev", jobDescription: "",
            status: .pending, dateApplied: Date(), lastUpdated: Date()
        )

        let csv = sut.buildCSV(from: [app])
        XCTAssertTrue(csv.contains("\"He said \"\"hello\"\"\""),
                      "Quotes in fields must be doubled and field must be quoted")
    }

    func test_buildCSV_escapesNewlinesInFields() {
        let store = InMemoryJobApplicationStore()
        let sut = JobApplicationListViewModel(store: store)
        let app = JobApplication(
            companyName: "Acme", jobTitle: "Dev", jobDescription: "Line1\nLine2",
            status: .pending, dateApplied: Date(), lastUpdated: Date()
        )

        let csv = sut.buildCSV(from: [app])
        XCTAssertTrue(csv.contains("\"Line1\nLine2\""),
                      "Fields with newlines must be quoted")
    }

    func test_buildCSV_formValidation_isInvalidWhenCompanyNameTooLong() {
        let sut = JobApplicationFormViewModel()
        sut.companyName = String(repeating: "A", count: 101)
        sut.jobTitle = "Engineer"

        XCTAssertFalse(sut.isValid,
                       "isValid must be false when companyName exceeds 100 characters")
    }

    func test_buildCSV_formValidation_isInvalidWhenJobTitleTooLong() {
        let sut = JobApplicationFormViewModel()
        sut.companyName = "Acme"
        sut.jobTitle = String(repeating: "B", count: 101)

        XCTAssertFalse(sut.isValid,
                       "isValid must be false when jobTitle exceeds 100 characters")
    }
}
