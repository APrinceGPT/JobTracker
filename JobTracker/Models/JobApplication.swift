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
    var followUpDate: Date?
    var salary: String
    var jobURL: String
    var contactName: String
    var contactEmail: String

    init(
        id: UUID = UUID(),
        companyName: String,
        jobTitle: String,
        jobDescription: String,
        status: ApplicationStatus = .pending,
        dateApplied: Date = Date(),
        lastUpdated: Date = Date(),
        followUpDate: Date? = nil,
        salary: String = "",
        jobURL: String = "",
        contactName: String = "",
        contactEmail: String = ""
    ) {
        self.id = id
        self.companyName = companyName
        self.jobTitle = jobTitle
        self.jobDescription = jobDescription
        self.status = status
        self.dateApplied = dateApplied
        self.lastUpdated = lastUpdated
        self.followUpDate = followUpDate
        self.salary = salary
        self.jobURL = jobURL
        self.contactName = contactName
        self.contactEmail = contactEmail
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
        guard jobDescription.count <= 50_000 else {
            throw JobApplicationValidationError.descriptionTooLong
        }
    }

    /// True when the follow-up date is in the past and the application is still active.
    var isOverdue: Bool {
        guard let date = followUpDate, !isTerminal else { return false }
        return date < Calendar.current.startOfDay(for: Date())
    }

    /// True when the application has reached a terminal state (hired or ghosted).
    var isTerminal: Bool {
        status.isTerminal
    }

    /// Compact display string combining company name and job title.
    var summary: String {
        "\(companyName) \u{2013} \(jobTitle)"
    }

    // MARK: - Codable (backward-compatible)

    enum CodingKeys: String, CodingKey {
        case id, companyName, jobTitle, jobDescription, status, dateApplied, lastUpdated
        case followUpDate, salary, jobURL, contactName, contactEmail
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id              = try c.decode(UUID.self, forKey: .id)
        companyName     = try c.decode(String.self, forKey: .companyName)
        jobTitle        = try c.decode(String.self, forKey: .jobTitle)
        jobDescription  = try c.decode(String.self, forKey: .jobDescription)
        status          = try c.decode(ApplicationStatus.self, forKey: .status)
        dateApplied     = try c.decode(Date.self, forKey: .dateApplied)
        lastUpdated     = try c.decode(Date.self, forKey: .lastUpdated)
        followUpDate    = try c.decodeIfPresent(Date.self, forKey: .followUpDate)
        salary          = try c.decodeIfPresent(String.self, forKey: .salary) ?? ""
        jobURL          = try c.decodeIfPresent(String.self, forKey: .jobURL) ?? ""
        contactName     = try c.decodeIfPresent(String.self, forKey: .contactName) ?? ""
        contactEmail    = try c.decodeIfPresent(String.self, forKey: .contactEmail) ?? ""
    }
}
