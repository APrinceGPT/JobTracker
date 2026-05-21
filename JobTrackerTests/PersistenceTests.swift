// PersistenceTests.swift
// JobTrackerTests

import XCTest
import SwiftData
@testable import JobTracker

@MainActor
final class PersistenceTests: XCTestCase {

    // MARK: - System under test

    private var container: ModelContainer!
    private var sut: SwiftDataJobApplicationStore!

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        // Use an in-memory ModelContainer so tests never touch disk.
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container  = try ModelContainer(for: PersistedJobApplication.self,
                                            configurations: config)
            sut        = SwiftDataJobApplicationStore(modelContext: container.mainContext)
        } catch {
            XCTFail("Failed to create ModelContainer: \(error)")
        }
    }

    override func tearDown() {
        sut       = nil
        container = nil
        super.tearDown()
    }

    // MARK: - Create

    func test_persist_add_savesApplicationToSwiftData() throws {
        let app = makeApplication()
        try sut.add(app)
        XCTAssertEqual(try sut.count(), 1,
                       "count must be 1 after adding one application")
    }

    func test_persist_add_duplicateID_throwsDuplicateEntry() throws {
        let app = makeApplication()
        try sut.add(app)
        XCTAssertThrowsError(try sut.add(app)) { error in
            guard case JobApplicationStoreError.duplicateEntry = error else {
                return XCTFail("Expected duplicateEntry, got \(error)")
            }
        }
    }

    // MARK: - Read

    func test_persist_fetchByID_returnsCorrectApplication() throws {
        let app = makeApplication(companyName: "SwiftData Inc")
        try sut.add(app)
        let fetched = try sut.fetch(id: app.id)
        XCTAssertEqual(fetched.companyName, app.companyName)
        XCTAssertEqual(fetched.status,      app.status)
    }

    func test_persist_fetchAll_returnsAllPersistedApplications() throws {
        try sut.add(makeApplication(companyName: "Alpha"))
        try sut.add(makeApplication(companyName: "Beta"))
        let all = try sut.fetchAll()
        XCTAssertEqual(all.count, 2)
    }

    func test_persist_fetchAllWithStatus_filtersCorrectly() throws {
        try sut.add(makeApplication(companyName: "A", status: .applied))
        try sut.add(makeApplication(companyName: "B", status: .pending))
        let applied = try sut.fetchAll(withStatus: .applied)
        XCTAssertEqual(applied.count, 1)
        XCTAssertEqual(applied.first?.companyName, "A")
    }

    func test_persist_fetchAllWithStatus_ordersByDateAppliedDescending() throws {
        let earlier = Date(timeIntervalSince1970: 1_000_000)
        let later   = Date(timeIntervalSince1970: 2_000_000)

        let old = JobApplication(
            id: UUID(), companyName: "Old Co", jobTitle: "Dev",
            jobDescription: "", status: .applied,
            dateApplied: earlier, lastUpdated: earlier
        )
        let recent = JobApplication(
            id: UUID(), companyName: "New Co", jobTitle: "Dev",
            jobDescription: "", status: .applied,
            dateApplied: later, lastUpdated: later
        )
        try sut.add(old)
        try sut.add(recent)

        let result = try sut.fetchAll(withStatus: .applied)
        XCTAssertEqual(result.first?.id, recent.id,
                       "fetchAll(withStatus:) must return most-recent application first")
        XCTAssertEqual(result.last?.id, old.id,
                       "fetchAll(withStatus:) must return oldest application last")
    }

    // MARK: - Update

    func test_persist_update_reflectsChangesOnSubsequentFetch() throws {
        var app = makeApplication(companyName: "Before")
        try sut.add(app)
        app.companyName = "After"
        app.status      = .inProcess
        try sut.update(app)

        let fetched = try sut.fetch(id: app.id)
        XCTAssertEqual(fetched.companyName, "After")
        XCTAssertEqual(fetched.status,      .inProcess)
    }

    func test_persist_updateStatus_updatesOnlyStatus() throws {
        let app = makeApplication(status: .applied)
        try sut.add(app)
        try sut.updateStatus(id: app.id, to: .waiting)

        let fetched = try sut.fetch(id: app.id)
        XCTAssertEqual(fetched.status,      .waiting)
        XCTAssertEqual(fetched.companyName, app.companyName)
    }

    // MARK: - Delete

    func test_persist_delete_removesApplicationFromContext() throws {
        let app = makeApplication()
        try sut.add(app)
        try sut.delete(id: app.id)
        XCTAssertThrowsError(try sut.fetch(id: app.id)) { error in
            guard case JobApplicationStoreError.notFound = error else {
                return XCTFail("Expected notFound after deletion, got \(error)")
            }
        }
    }

    func test_persist_deleteAll_clearsAllRecords() throws {
        try sut.add(makeApplication(companyName: "X"))
        try sut.add(makeApplication(companyName: "Y"))
        try sut.deleteAll()
        XCTAssertEqual(try sut.count(), 0)
    }

    // MARK: - Data survives context save/reload
    //
    // Simulate the real-world case of saving and reading back from a
    // fresh context (proves the model is actually persisted, not just held
    // in a transient cache).

    func test_persist_dataRemainsAfterContextSave() throws {
        let app = makeApplication(companyName: "Durable Co")
        try sut.add(app)

        // Use a NEW ModelContext from the same container — this forces a real
        // round-trip through the SwiftData store. If context.save() was never
        // called, the new context will not see the inserted record and the
        // fetch will throw .notFound, failing the test.
        let newContext  = ModelContext(container)
        let secondStore = SwiftDataJobApplicationStore(modelContext: newContext)
        let fetched     = try secondStore.fetch(id: app.id)

        XCTAssertEqual(fetched.companyName, "Durable Co",
                       "Data written by sut must be visible through a fresh ModelContext")
    }

    // MARK: - Protocol conformance

    func test_swiftDataStoreConformsToProtocol() {
        let _: any JobApplicationStoreProtocol = SwiftDataJobApplicationStore(
            modelContext: container.mainContext
        )
    }

    // MARK: - Safe container creation (Issue #1)

    func test_makeModelContainer_returnsValidContainerForInMemoryConfig() throws {
        // Verifies the crash-safe container factory produces a usable container.
        let result = makeModelContainer(storedInMemoryOnly: true)
        XCTAssertNotNil(result, "makeModelContainer must return a non-nil container")
        // Confirm the returned container is usable by performing a basic operation.
        let store = SwiftDataJobApplicationStore(modelContext: result!.mainContext)
        XCTAssertNoThrow(try store.fetchAll(),
                         "A freshly created container must support fetchAll without error")
    }
}
