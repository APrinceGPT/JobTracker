// JobApplication.swift
// JobTracker

import Foundation

/// Validation errors thrown by `JobApplication.validate()`.
enum JobApplicationValidationError: Error, Equatable {
    case emptyCompanyName
    case companyNameTooLong
    case emptyJobTitle
    case jobTitleTooLong
    case descriptionTooLong
}

/// Represents a single job application record.
struct JobApplication: Identifiable, Equatable, Codable {

    let id: UUID
    var companyName: String
    var jobTitle: String
    var jobDescription: String
    var status: ApplicationStatus
    var dateApplied: Date
    var lastUpdated: Date

    init(
        id: UUID = UUID(),
        companyName: String,
        jobTitle: String,
        jobDescription: String,
        status: ApplicationStatus = .pending,
        dateApplied: Date = Date(),
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.companyName = companyName
        self.jobTitle = jobTitle
        self.jobDescription = jobDescription
        self.status = status
        self.dateApplied = dateApplied
        self.lastUpdated = lastUpdated
    }

    /// Validates field constraints. Throws `JobApplicationValidationError` on failure.
    func validate() throws {
        guard !companyName.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw JobApplicationValidationError.emptyCompanyName
        }
        guard companyName.count <= 100 else {
            throw JobApplicationValidationError.companyNameTooLong
        }
        guard !jobTitle.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw JobApplicationValidationError.emptyJobTitle
        }
        guard jobTitle.count <= 100 else {
            throw JobApplicationValidationError.jobTitleTooLong
        }
        guard jobDescription.count <= 500 else {
            throw JobApplicationValidationError.descriptionTooLong
        }
    }

    /// True when the application has reached a terminal state (hired or ghosted).
    var isTerminal: Bool {
        status.isTerminal
    }

    /// Compact display string combining company name and job title.
    var summary: String {
        "\(companyName) \u{2013} \(jobTitle)"
    }
}
