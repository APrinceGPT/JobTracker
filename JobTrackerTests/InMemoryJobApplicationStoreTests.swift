// InMemoryJobApplicationStoreTests.swift
// JobTrackerTests

import XCTest
@testable import JobTracker

final class InMemoryJobApplicationStoreTests: XCTestCase {

    // MARK: - System under test

    private var sut: InMemoryJobApplicationStore!

    override func setUp() {
        super.setUp()
        sut = InMemoryJobApplicationStore()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial state

    func test_newStore_hasZeroCount() throws {
        XCTAssertEqual(try sut.count(), 0,
                       "A new store must contain zero applications")
    }

    func test_newStore_fetchAllReturnsEmptyArray() throws {
        XCTAssertTrue(try sut.fetchAll().isEmpty,
                      "A new store must return an empty array from fetchAll")
    }

    // MARK: - Add (Create)

    func test_add_increasesCountByOne() throws {
        let app = makeApplication()
        try sut.add(app)
        XCTAssertEqual(try sut.count(), 1,
                       "count must be 1 after adding one application")
    }

    func test_add_multipleApplications_countReflectsTotal() throws {
        try sut.add(makeApplication(companyName: "Alpha"))
        try sut.add(makeApplication(companyName: "Beta"))
        try sut.add(makeApplication(companyName: "Gamma"))
        XCTAssertEqual(try sut.count(), 3,
                       "count must equal the number of applications added")
    }

    func test_add_duplicateID_throwsDuplicateEntryError() throws {
        let app = makeApplication()
        try sut.add(app)
        XCTAssertThrowsError(try sut.add(app)) { error in
            guard case JobApplicationStoreError.duplicateEntry = error else {
                return XCTFail("Expected duplicateEntry, got \(error)")
            }
        }
    }

    // MARK: - Fetch by ID (Read)

    func test_fetchByID_returnsCorrectApplication() throws {
        let app = makeApplication(companyName: "Tesla")
        try sut.add(app)
        let fetched = try sut.fetch(id: app.id)
        XCTAssertEqual(fetched, app,
                       "fetch(id:) must return the exact application that was added")
    }

    func test_fetchByID_throwsNotFoundForUnknownID() {
        XCTAssertThrowsError(try sut.fetch(id: UUID())) { error in
            guard case JobApplicationStoreError.notFound = error else {
                return XCTFail("Expected notFound, got \(error)")
            }
        }
    }

    func test_fetchByID_throwsNotFoundAfterDeletion() throws {
        let app = makeApplication()
        try sut.add(app)
        try sut.delete(id: app.id)

        XCTAssertThrowsError(try sut.fetch(id: app.id)) { error in
            guard case JobApplicationStoreError.notFound = error else {
                return XCTFail("Expected notFound after deletion, got \(error)")
            }
        }
    }

    // MARK: - Fetch all (Read)

    func test_fetchAll_returnsAllAddedApplications() throws {
        let app1 = makeApplication(companyName: "A")
        let app2 = makeApplication(companyName: "B")
        try sut.add(app1)
        try sut.add(app2)

        let all = try sut.fetchAll()
        XCTAssertEqual(all.count, 2,
                       "fetchAll must return 2 items after 2 adds")
        XCTAssertTrue(all.contains(app1), "fetchAll must contain app1")
        XCTAssertTrue(all.contains(app2), "fetchAll must contain app2")
    }

    func test_fetchAll_ordersByDateAppliedDescending() throws {
        let earlier = Date(timeIntervalSince1970: 1_000_000)
        let later   = Date(timeIntervalSince1970: 2_000_000)

        let old = JobApplication(
            companyName: "Old Co", jobTitle: "Dev",
            jobDescription: "", dateApplied: earlier, lastUpdated: earlier
        )
        let recent = JobApplication(
            companyName: "New Co", jobTitle: "Dev",
            jobDescription: "", dateApplied: later, lastUpdated: later
        )
        try sut.add(old)
        try sut.add(recent)

        let all = try sut.fetchAll()
        XCTAssertEqual(all.first?.id, recent.id,
                       "fetchAll must return most-recent application first")
        XCTAssertEqual(all.last?.id,  old.id,
                       "fetchAll must return oldest application last")
    }

    // MARK: - Fetch all with status filter (Read)

    func test_fetchAllWithStatus_returnsOnlyMatchingApplications() throws {
        let applied  = makeApplication(companyName: "AppliedCo",  status: .applied)
        let pending  = makeApplication(companyName: "PendingCo",  status: .pending)
        let waiting  = makeApplication(companyName: "WaitingCo",  status: .waiting)

        try sut.add(applied)
        try sut.add(pending)
        try sut.add(waiting)

        let result = try sut.fetchAll(withStatus: .applied)
        XCTAssertEqual(result.count, 1,
                       "Only the applied application must be returned")
        XCTAssertEqual(result.first?.id, applied.id)
    }

    func test_fetchAllWithStatus_returnsEmptyWhenNoneMatch() throws {
        let app = makeApplication(status: .pending)
        try sut.add(app)

        let result = try sut.fetchAll(withStatus: .hired)
        XCTAssertTrue(result.isEmpty,
                      "No hired applications exist, so result must be empty")
    }

    func test_fetchAllWithStatus_returnsMultipleMatchingApplications() throws {
        try sut.add(makeApplication(companyName: "A", status: .ghosted))
        try sut.add(makeApplication(companyName: "B", status: .ghosted))
        try sut.add(makeApplication(companyName: "C", status: .applied))

        let ghosted = try sut.fetchAll(withStatus: .ghosted)
        XCTAssertEqual(ghosted.count, 2,
                       "Both ghosted applications must be returned")
    }

    func test_fetchAllWithStatus_ordersByDateAppliedDescending() throws {
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

    func test_update_changesStoredFields() throws {
        var app = makeApplication(companyName: "Original Co")
        try sut.add(app)

        app.companyName = "Updated Co"
        app.status      = .applied
        try sut.update(app)

        let fetched = try sut.fetch(id: app.id)
        XCTAssertEqual(fetched.companyName, "Updated Co",
                       "companyName must reflect the update")
        XCTAssertEqual(fetched.status, .applied,
                       "status must reflect the update")
    }

    func test_update_throwsNotFoundForUnknownID() {
        let app = makeApplication()
        XCTAssertThrowsError(try sut.update(app)) { error in
            guard case JobApplicationStoreError.notFound = error else {
                return XCTFail("Expected notFound when updating non-existent app, got \(error)")
            }
        }
    }

    func test_update_doesNotAffectOtherApplications() throws {
        let app1 = makeApplication(companyName: "Co One")
        var app2 = makeApplication(companyName: "Co Two")
        try sut.add(app1)
        try sut.add(app2)

        app2.companyName = "Co Two Updated"
        try sut.update(app2)

        let fetched1 = try sut.fetch(id: app1.id)
        XCTAssertEqual(fetched1.companyName, "Co One",
                       "Updating app2 must not change app1")
    }

    // MARK: - updateStatus convenience method

    func test_updateStatus_changesOnlyStatus() throws {
        let app = makeApplication(status: .pending)
        try sut.add(app)
        try sut.updateStatus(id: app.id, to: .applied)

        let fetched = try sut.fetch(id: app.id)
        XCTAssertEqual(fetched.status, .applied,
                       "updateStatus must change status to .applied")
        XCTAssertEqual(fetched.companyName, app.companyName,
                       "updateStatus must not change companyName")
        XCTAssertEqual(fetched.jobTitle, app.jobTitle,
                       "updateStatus must not change jobTitle")
    }

    func test_updateStatus_throwsNotFoundForUnknownID() {
        XCTAssertThrowsError(try sut.updateStatus(id: UUID(), to: .applied)) { error in
            guard case JobApplicationStoreError.notFound = error else {
                return XCTFail("Expected notFound, got \(error)")
            }
        }
    }

    func test_updateStatus_updatesLastUpdatedTimestamp() throws {
        let originalDate = Date(timeIntervalSince1970: 1_000_000)
        let app = JobApplication(
            companyName: "X", jobTitle: "Y", jobDescription: "",
            status: .pending, dateApplied: originalDate, lastUpdated: originalDate
        )
        try sut.add(app)

        let beforeUpdate = Date()
        try sut.updateStatus(id: app.id, to: .applied)
        let afterUpdate = Date()

        let fetched = try sut.fetch(id: app.id)
        XCTAssertGreaterThanOrEqual(fetched.lastUpdated, beforeUpdate,
                                    "lastUpdated must be refreshed when status changes")
        XCTAssertLessThanOrEqual(fetched.lastUpdated, afterUpdate,
                                 "lastUpdated must not be in the future")
    }

    // MARK: - Delete

    func test_delete_removesApplicationFromStore() throws {
        let app = makeApplication()
        try sut.add(app)
        try sut.delete(id: app.id)

        XCTAssertEqual(try sut.count(), 0,
                       "count must be 0 after deleting the only application")
    }

    func test_delete_throwsNotFoundForUnknownID() {
        XCTAssertThrowsError(try sut.delete(id: UUID())) { error in
            guard case JobApplicationStoreError.notFound = error else {
                return XCTFail("Expected notFound, got \(error)")
            }
        }
    }

    func test_delete_doesNotAffectOtherApplications() throws {
        let keep   = makeApplication(companyName: "Keep Me")
        let remove = makeApplication(companyName: "Remove Me")
        try sut.add(keep)
        try sut.add(remove)

        try sut.delete(id: remove.id)

        XCTAssertEqual(try sut.count(), 1)
        XCTAssertNoThrow(try sut.fetch(id: keep.id),
                         "The retained application must still be fetchable")
    }

    func test_delete_throwsNotFoundWhenCalledTwice() throws {
        let app = makeApplication()
        try sut.add(app)
        try sut.delete(id: app.id)

        XCTAssertThrowsError(try sut.delete(id: app.id)) { error in
            guard case JobApplicationStoreError.notFound = error else {
                return XCTFail("Second delete must throw notFound, got \(error)")
            }
        }
    }

    // MARK: - Delete all

    func test_deleteAll_removesEveryApplication() throws {
        try sut.add(makeApplication(companyName: "A"))
        try sut.add(makeApplication(companyName: "B"))
        try sut.add(makeApplication(companyName: "C"))

        try sut.deleteAll()

        XCTAssertEqual(try sut.count(), 0,
                       "count must be 0 after deleteAll")
        XCTAssertTrue(try sut.fetchAll().isEmpty,
                      "fetchAll must return empty array after deleteAll")
    }

    func test_deleteAll_onEmptyStore_doesNotThrow() {
        XCTAssertNoThrow(try sut.deleteAll(),
                         "deleteAll on an already-empty store must not throw")
    }

    func test_deleteAll_allowsNewInsertsAfterwards() throws {
        try sut.add(makeApplication(companyName: "Old"))
        try sut.deleteAll()

        let fresh = makeApplication(companyName: "New")
        try sut.add(fresh)

        XCTAssertEqual(try sut.count(), 1,
                       "Store must accept new inserts after deleteAll")
        XCTAssertEqual(try sut.fetch(id: fresh.id), fresh)
    }

    // MARK: - Count

    func test_count_incrementsWithEachAdd() throws {
        for i in 1...5 {
            try sut.add(makeApplication(companyName: "Co\(i)"))
            XCTAssertEqual(try sut.count(), i,
                           "count must equal \(i) after \(i) adds")
        }
    }

    func test_count_decrementsWithEachDelete() throws {
        let apps = (1...3).map { makeApplication(companyName: "Co\($0)") }
        for app in apps { try sut.add(app) }

        for (index, app) in apps.enumerated() {
            try sut.delete(id: app.id)
            let expected = apps.count - (index + 1)
            XCTAssertEqual(try sut.count(), expected,
                           "count must be \(expected) after deleting item \(index + 1)")
        }
    }

    // MARK: - Protocol conformance (type-checked at compile time)

    func test_storeConformsToProtocol() {
        // This verifies the concrete type satisfies the protocol contract.
        let _: any JobApplicationStoreProtocol = InMemoryJobApplicationStore()
    }
}
