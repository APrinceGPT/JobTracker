// JobApplicationModelTests.swift
// JobTrackerTests

import XCTest
@testable import JobTracker

final class JobApplicationModelTests: XCTestCase {

    // MARK: - Initialisation

    func test_init_setsAllFieldsCorrectly() {
        let id    = UUID()
        let date  = Date(timeIntervalSince1970: 1_000_000)
        let app   = JobApplication(
            id: id,
            companyName: "Stripe",
            jobTitle: "Staff Engineer",
            jobDescription: "Payments infra",
            status: .applied,
            dateApplied: date,
            lastUpdated: date
        )

        XCTAssertEqual(app.id,             id)
        XCTAssertEqual(app.companyName,    "Stripe")
        XCTAssertEqual(app.jobTitle,       "Staff Engineer")
        XCTAssertEqual(app.jobDescription, "Payments infra")
        XCTAssertEqual(app.status,         .applied)
        XCTAssertEqual(app.dateApplied,    date)
        XCTAssertEqual(app.lastUpdated,    date)
    }

    func test_defaultInit_assignsUniqueID() {
        let a = makeApplication()
        let b = makeApplication()
        XCTAssertNotEqual(a.id, b.id,
                          "Each application must receive a unique UUID by default")
    }

    func test_defaultInit_setsStatusToPending() {
        let app = JobApplication(
            companyName: "Apple",
            jobTitle: "Engineer",
            jobDescription: "..."
        )
        XCTAssertEqual(app.status, .pending,
                       "Default status must be .pending")
    }

    func test_defaultInit_populatesDateApplied() {
        let before = Date()
        let app    = makeApplication()
        let after  = Date()
        XCTAssertGreaterThanOrEqual(app.dateApplied, before)
        XCTAssertLessThanOrEqual(app.dateApplied, after)
    }

    // MARK: - Validation

    func test_validate_succeedsForValidApplication() throws {
        let app = makeApplication()
        XCTAssertNoThrow(try app.validate(),
                         "A fully populated application must pass validation")
    }

    func test_validate_throwsWhenCompanyNameIsEmpty() {
        let app = makeApplication(companyName: "")
        XCTAssertThrowsError(try app.validate()) { error in
            guard case JobApplicationValidationError.emptyCompanyName = error else {
                return XCTFail("Expected emptyCompanyName, got \(error)")
            }
        }
    }

    func test_validate_throwsWhenCompanyNameIsWhitespaceOnly() {
        let app = makeApplication(companyName: "   ")
        XCTAssertThrowsError(try app.validate()) { error in
            guard case JobApplicationValidationError.emptyCompanyName = error else {
                return XCTFail("Expected emptyCompanyName, got \(error)")
            }
        }
    }

    func test_validate_throwsWhenJobTitleIsEmpty() {
        let app = makeApplication(jobTitle: "")
        XCTAssertThrowsError(try app.validate()) { error in
            guard case JobApplicationValidationError.emptyJobTitle = error else {
                return XCTFail("Expected emptyJobTitle, got \(error)")
            }
        }
    }

    func test_validate_throwsWhenJobTitleIsWhitespaceOnly() {
        let app = makeApplication(jobTitle: "\t\t")
        XCTAssertThrowsError(try app.validate()) { error in
            guard case JobApplicationValidationError.emptyJobTitle = error else {
                return XCTFail("Expected emptyJobTitle, got \(error)")
            }
        }
    }

    func test_validate_throwsWhenJobDescriptionExceedsMaxLength() {
        // Requirement: description must not exceed 500 characters.
        let longDescription = String(repeating: "x", count: 501)
        let app = makeApplication(jobDescription: longDescription)
        XCTAssertThrowsError(try app.validate()) { error in
            guard case JobApplicationValidationError.descriptionTooLong = error else {
                return XCTFail("Expected descriptionTooLong, got \(error)")
            }
        }
    }

    func test_validate_succeedsWhenJobDescriptionIsExactlyMaxLength() throws {
        let exactDescription = String(repeating: "x", count: 500)
        let app = makeApplication(jobDescription: exactDescription)
        XCTAssertNoThrow(try app.validate(),
                         "500-character description is exactly at the limit and must pass")
    }

    func test_validate_succeedsWhenJobDescriptionIsEmpty() throws {
        // Description is optional; empty string is valid.
        let app = makeApplication(jobDescription: "")
        XCTAssertNoThrow(try app.validate(),
                         "Empty job description is allowed")
    }

    func test_validate_throwsWhenCompanyNameExceedsMaxLength() {
        // Requirement: company name must not exceed 100 characters.
        let longName = String(repeating: "A", count: 101)
        let app = makeApplication(companyName: longName)
        XCTAssertThrowsError(try app.validate()) { error in
            guard case JobApplicationValidationError.companyNameTooLong = error else {
                return XCTFail("Expected companyNameTooLong, got \(error)")
            }
        }
    }

    func test_validate_throwsWhenJobTitleExceedsMaxLength() {
        // Requirement: job title must not exceed 100 characters.
        let longTitle = String(repeating: "B", count: 101)
        let app = makeApplication(jobTitle: longTitle)
        XCTAssertThrowsError(try app.validate()) { error in
            guard case JobApplicationValidationError.jobTitleTooLong = error else {
                return XCTFail("Expected jobTitleTooLong, got \(error)")
            }
        }
    }

    // MARK: - Equatability (identity is UUID-based)

    func test_twoApplicationsWithSameID_areEqual() {
        let id  = UUID()
        let a   = JobApplication(id: id, companyName: "X", jobTitle: "Y", jobDescription: "Z")
        let b   = JobApplication(id: id, companyName: "X", jobTitle: "Y", jobDescription: "Z")
        XCTAssertEqual(a, b)
    }

    func test_twoApplicationsWithDifferentIDs_areNotEqual() {
        let a = makeApplication()
        let b = makeApplication()
        XCTAssertNotEqual(a, b)
    }

    // MARK: - Codable round-trip

    func test_encodeThenDecode_preservesAllFields() throws {
        let id    = UUID()
        let date  = Date(timeIntervalSince1970: 1_700_000_000)
        let app   = JobApplication(
            id: id,
            companyName: "Google",
            jobTitle: "SWE III",
            jobDescription: "Search infra",
            status: .inProcess,
            dateApplied: date,
            lastUpdated: date
        )

        let encoded = try JSONEncoder().encode(app)
        let decoded = try JSONDecoder().decode(JobApplication.self, from: encoded)

        XCTAssertEqual(decoded.id,             app.id)
        XCTAssertEqual(decoded.companyName,    app.companyName)
        XCTAssertEqual(decoded.jobTitle,       app.jobTitle)
        XCTAssertEqual(decoded.jobDescription, app.jobDescription)
        XCTAssertEqual(decoded.status,         app.status)
        XCTAssertEqual(decoded.dateApplied,    app.dateApplied)
        XCTAssertEqual(decoded.lastUpdated,    app.lastUpdated)
    }

    // MARK: - Mutability (struct copy semantics)

    func test_mutatingStatus_doesNotAffectOriginal() {
        let original = makeApplication(status: .pending)
        var copy     = original
        copy.status  = .applied

        XCTAssertEqual(original.status, .pending,
                       "Mutating the copy must not change the original (value semantics)")
        XCTAssertEqual(copy.status, .applied)
    }

    func test_updatingLastUpdated_isIndependentOfDateApplied() {
        let date1 = Date(timeIntervalSince1970: 1_000_000)
        let date2 = Date(timeIntervalSince1970: 2_000_000)
        var app   = JobApplication(
            companyName: "Meta",
            jobTitle: "PM",
            jobDescription: "Product work",
            dateApplied: date1,
            lastUpdated: date1
        )
        app.lastUpdated = date2

        XCTAssertEqual(app.dateApplied, date1,
                       "dateApplied must remain unchanged when lastUpdated changes")
        XCTAssertEqual(app.lastUpdated, date2)
    }

    // MARK: - isTerminal computed property

    func test_isTerminal_isTrueWhenHired() {
        let app = makeApplication(status: .hired)
        XCTAssertTrue(app.isTerminal,
                      "A hired application must report isTerminal == true")
    }

    func test_isTerminal_isTrueWhenGhosted() {
        let app = makeApplication(status: .ghosted)
        XCTAssertTrue(app.isTerminal,
                      "A ghosted application must report isTerminal == true")
    }

    func test_isTerminal_isFalseForNonTerminalStatuses() {
        let nonTerminal: [ApplicationStatus] = [.pending, .applied, .inProcess, .waiting]
        for status in nonTerminal {
            let app = makeApplication(status: status)
            XCTAssertFalse(app.isTerminal,
                           "\(status.rawValue) must not be terminal")
        }
    }

    // MARK: - Summary computed property

    func test_summary_combinesCompanyNameAndJobTitle() {
        let app = makeApplication(companyName: "Notion", jobTitle: "Designer")
        XCTAssertEqual(app.summary, "Notion – Designer",
                       "summary must return '<companyName> – <jobTitle>'")
    }
}

// JobApplicationValidationError is defined in the main target (JobApplication.swift).
