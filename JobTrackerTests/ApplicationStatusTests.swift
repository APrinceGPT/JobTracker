// ApplicationStatusTests.swift
// JobTrackerTests

import XCTest
@testable import JobTracker

final class ApplicationStatusTests: XCTestCase {

    // MARK: - Case existence

    func test_allCasesExist() {
        // Every required status must be present in CaseIterable.
        let allCases = ApplicationStatus.allCases
        XCTAssertTrue(allCases.contains(.pending),   "pending case must exist")
        XCTAssertTrue(allCases.contains(.applied),   "applied case must exist")
        XCTAssertTrue(allCases.contains(.inProcess), "inProcess case must exist")
        XCTAssertTrue(allCases.contains(.waiting),   "waiting case must exist")
        XCTAssertTrue(allCases.contains(.hired),     "hired case must exist")
        XCTAssertTrue(allCases.contains(.ghosted),   "ghosted case must exist")
    }

    func test_exactlySixCasesExist() {
        // Guard against accidental extra cases being added.
        XCTAssertEqual(ApplicationStatus.allCases.count, 6,
                       "ApplicationStatus must have exactly 6 cases")
    }

    // MARK: - Raw values (used for persistence and display)

    func test_rawValues_matchExpectedStrings() {
        XCTAssertEqual(ApplicationStatus.pending.rawValue,   "pending")
        XCTAssertEqual(ApplicationStatus.applied.rawValue,   "applied")
        XCTAssertEqual(ApplicationStatus.inProcess.rawValue, "inProcess")
        XCTAssertEqual(ApplicationStatus.waiting.rawValue,   "waiting")
        XCTAssertEqual(ApplicationStatus.hired.rawValue,     "hired")
        XCTAssertEqual(ApplicationStatus.ghosted.rawValue,   "ghosted")
    }

    func test_initialisingFromRawValue_returnsCorrectCase() {
        XCTAssertEqual(ApplicationStatus(rawValue: "pending"),   .pending)
        XCTAssertEqual(ApplicationStatus(rawValue: "applied"),   .applied)
        XCTAssertEqual(ApplicationStatus(rawValue: "inProcess"), .inProcess)
        XCTAssertEqual(ApplicationStatus(rawValue: "waiting"),   .waiting)
        XCTAssertEqual(ApplicationStatus(rawValue: "hired"),     .hired)
        XCTAssertEqual(ApplicationStatus(rawValue: "ghosted"),   .ghosted)
    }

    func test_initialisingFromUnknownRawValue_returnsNil() {
        XCTAssertNil(ApplicationStatus(rawValue: "rejected"),
                     "Unknown raw values must not map to any case")
        XCTAssertNil(ApplicationStatus(rawValue: ""),
                     "Empty string must not map to any case")
        XCTAssertNil(ApplicationStatus(rawValue: "PENDING"),
                     "Raw value lookup must be case-sensitive")
    }

    // MARK: - Equatability

    func test_equalCases_areEqual() {
        XCTAssertEqual(ApplicationStatus.hired, ApplicationStatus.hired)
    }

    func test_differentCases_areNotEqual() {
        XCTAssertNotEqual(ApplicationStatus.hired, ApplicationStatus.ghosted)
    }

    // MARK: - Codable round-trip

    func test_encodeThenDecode_preservesStatus() throws {
        let statuses = ApplicationStatus.allCases
        for status in statuses {
            let encoded = try JSONEncoder().encode(status)
            let decoded = try JSONDecoder().decode(ApplicationStatus.self, from: encoded)
            XCTAssertEqual(decoded, status,
                           "\(status.rawValue) must survive a JSON encode/decode round-trip")
        }
    }

    func test_decodingInvalidJSON_throwsDecodingError() {
        let badJSON = "\"rejected\"".data(using: .utf8)!
        XCTAssertThrowsError(
            try JSONDecoder().decode(ApplicationStatus.self, from: badJSON),
            "Decoding an unknown status string must throw a DecodingError"
        )
    }

    // MARK: - Valid status transitions

    func test_pending_canTransitionTo_applied() {
        XCTAssertTrue(ApplicationStatus.pending.canTransition(to: .applied),
                      "A pending application can be marked as applied")
    }

    func test_applied_canTransitionTo_inProcess() {
        XCTAssertTrue(ApplicationStatus.applied.canTransition(to: .inProcess),
                      "An applied application can move to inProcess")
    }

    func test_applied_canTransitionTo_waiting() {
        XCTAssertTrue(ApplicationStatus.applied.canTransition(to: .waiting),
                      "An applied application can be marked as waiting")
    }

    func test_applied_canTransitionTo_ghosted() {
        XCTAssertTrue(ApplicationStatus.applied.canTransition(to: .ghosted),
                      "An applied application can be marked as ghosted")
    }

    func test_inProcess_canTransitionTo_hired() {
        XCTAssertTrue(ApplicationStatus.inProcess.canTransition(to: .hired),
                      "An inProcess application can result in hired")
    }

    func test_inProcess_canTransitionTo_ghosted() {
        XCTAssertTrue(ApplicationStatus.inProcess.canTransition(to: .ghosted),
                      "An inProcess application can be ghosted")
    }

    func test_waiting_canTransitionTo_inProcess() {
        XCTAssertTrue(ApplicationStatus.waiting.canTransition(to: .inProcess),
                      "A waiting application can move to inProcess")
    }

    func test_waiting_canTransitionTo_ghosted() {
        XCTAssertTrue(ApplicationStatus.waiting.canTransition(to: .ghosted),
                      "A waiting application can become ghosted")
    }

    func test_hired_cannotTransitionToAnyOtherStatus() {
        // hired is a terminal state.
        let others = ApplicationStatus.allCases.filter { $0 != .hired }
        for other in others {
            XCTAssertFalse(ApplicationStatus.hired.canTransition(to: other),
                           "hired is terminal; transition to \(other.rawValue) must be rejected")
        }
    }

    func test_ghosted_cannotTransitionToAnyOtherStatus() {
        // ghosted is a terminal state.
        let others = ApplicationStatus.allCases.filter { $0 != .ghosted }
        for other in others {
            XCTAssertFalse(ApplicationStatus.ghosted.canTransition(to: other),
                           "ghosted is terminal; transition to \(other.rawValue) must be rejected")
        }
    }

    func test_cannotTransitionToSameStatus() {
        // Transitioning to the current state is a no-op and must be rejected.
        for status in ApplicationStatus.allCases {
            XCTAssertFalse(status.canTransition(to: status),
                           "Transition from \(status.rawValue) to itself must be invalid")
        }
    }

    func test_pending_cannotTransitionDirectlyTo_hired() {
        XCTAssertFalse(ApplicationStatus.pending.canTransition(to: .hired),
                       "pending cannot skip straight to hired")
    }

    func test_pending_cannotTransitionDirectlyTo_ghosted() {
        XCTAssertFalse(ApplicationStatus.pending.canTransition(to: .ghosted),
                       "pending cannot skip straight to ghosted")
    }

    // MARK: - Display label

    func test_displayLabel_pending() {
        XCTAssertEqual(ApplicationStatus.pending.displayLabel, "Pending",
                       "pending display label must be 'Pending'")
    }

    func test_displayLabel_applied() {
        XCTAssertEqual(ApplicationStatus.applied.displayLabel, "Applied",
                       "applied display label must be 'Applied'")
    }

    func test_displayLabel_inProcess() {
        XCTAssertEqual(ApplicationStatus.inProcess.displayLabel, "In Process",
                       "inProcess display label must be 'In Process'")
    }

    func test_displayLabel_waiting() {
        XCTAssertEqual(ApplicationStatus.waiting.displayLabel, "Waiting",
                       "waiting display label must be 'Waiting'")
    }

    func test_displayLabel_hired() {
        XCTAssertEqual(ApplicationStatus.hired.displayLabel, "Hired",
                       "hired display label must be 'Hired'")
    }

    func test_displayLabel_ghosted() {
        XCTAssertEqual(ApplicationStatus.ghosted.displayLabel, "Ghosted",
                       "ghosted display label must be 'Ghosted'")
    }
}
