// JobApplicationFormViewModel.swift
// JobTracker

import SwiftUI

/// Observable state owner for JobApplicationFormView.
@MainActor
final class JobApplicationFormViewModel: ObservableObject {

    // MARK: - Form fields (bound directly to the view)

    @Published var companyName: String = ""
    @Published var jobTitle: String = ""
    @Published var jobDescription: String = ""
    @Published var status: ApplicationStatus = .pending
    @Published var dateApplied: Date = Date()

    // MARK: - Validation state

    /// True when all fields satisfy validation rules.
    var isValid: Bool {
        !companyName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !jobTitle.trimmingCharacters(in: .whitespaces).isEmpty &&
        jobDescription.count <= 500
    }

    /// Human-readable descriptions of current validation failures.
    var validationErrors: [String] {
        var errors: [String] = []
        if companyName.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append("Company name is required")
        }
        if jobTitle.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append("Job title is required")
        }
        if jobDescription.count > 500 {
            errors.append("Description must be 500 characters or fewer")
        }
        return errors
    }

    /// True when companyName is empty or whitespace-only.
    var showsCompanyNameError: Bool {
        companyName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// True when jobTitle is empty or whitespace-only.
    var showsJobTitleError: Bool {
        jobTitle.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Mode

    /// The application being edited, or nil when creating a new one.
    let existingApplication: JobApplication?

    // MARK: - Init

    /// Creates a form for adding a brand-new application.
    init() {
        self.existingApplication = nil
    }

    /// Creates a form pre-populated for editing an existing application.
    init(editing application: JobApplication) {
        self.existingApplication = application
        self.companyName = application.companyName
        self.jobTitle = application.jobTitle
        self.jobDescription = application.jobDescription
        self.status = application.status
        self.dateApplied = application.dateApplied
    }

    // MARK: - Intent

    /// Builds and returns a JobApplication from the current field values.
    /// Returns nil when the form is invalid.
    func buildApplication() -> JobApplication? {
        guard isValid else { return nil }
        let id = existingApplication?.id ?? UUID()
        let now = Date()
        return JobApplication(
            id: id,
            companyName: companyName,
            jobTitle: jobTitle,
            jobDescription: jobDescription,
            status: status,
            dateApplied: dateApplied,
            lastUpdated: now
        )
    }

    /// Whether the form is in edit mode (vs. add mode).
    var isEditing: Bool {
        existingApplication != nil
    }
}
