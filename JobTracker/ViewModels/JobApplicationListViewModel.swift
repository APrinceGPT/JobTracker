// JobApplicationListViewModel.swift
// JobTracker

import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// Observable state owner for JobApplicationListView.
@MainActor
final class JobApplicationListViewModel: ObservableObject {

    // MARK: - Dependencies (injected)

    private let store: any JobApplicationStoreProtocol

    // MARK: - Published state

    /// All job applications to display, sorted newest-first.
    @Published var applications: [JobApplication] = []

    /// The application currently selected in the list (nil = nothing selected).
    @Published var selectedApplicationID: UUID? = nil

    /// Controls whether the add/edit form sheet is shown.
    @Published var isFormPresented: Bool = false

    /// The application being edited; nil when adding a new one.
    @Published var applicationToEdit: JobApplication? = nil

    /// Controls whether the delete-confirmation dialog is shown.
    @Published var isDeleteConfirmationPresented: Bool = false

    /// Text query for filtering the list by company name or job title.
    @Published var searchText: String = ""

    /// When non-nil, only applications matching this status are shown.
    @Published var statusFilter: ApplicationStatus? = nil

    /// Non-nil while a user-visible error needs to be displayed.
    @Published var errorMessage: String? = nil

    // MARK: - Init

    init(store: any JobApplicationStoreProtocol) {
        self.store = store
    }

    // MARK: - Intent methods

    /// Loads all applications from the store into `applications`, sorted newest-first.
    func loadApplications() {
        do {
            applications = try store.fetchAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Opens the form sheet for adding a new application.
    func presentAddForm() {
        applicationToEdit = nil
        isFormPresented = true
    }

    /// Opens the form sheet pre-populated with `application` for editing.
    func presentEditForm(for application: JobApplication) {
        applicationToEdit = application
        isFormPresented = true
    }

    /// Saves `application` to the store (add if new, update if existing).
    func save(_ application: JobApplication) {
        do {
            try application.validate()
            if applicationToEdit != nil {
                try store.update(application)
            } else {
                try store.add(application)
            }
            isFormPresented = false
            loadApplications()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Persists an inline edit to an existing application.
    func updateInline(_ application: JobApplication) {
        do {
            try application.validate()
            try store.update(application)
            loadApplications()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Clears the job description for the given application and persists the change.
    func clearDescription(for application: JobApplication) {
        var updated = application
        updated.jobDescription = ""
        updateInline(updated)
    }

    /// Updates the job description for the given application and persists the change.
    func saveDescription(for application: JobApplication, description: String) {
        var updated = application
        updated.jobDescription = description
        updateInline(updated)
    }

    /// Requests deletion of the currently selected application.
    func requestDeleteSelected() {
        guard selectedApplicationID != nil else { return }
        isDeleteConfirmationPresented = true
    }

    /// Confirms and performs deletion of the currently selected application.
    /// Calls `loadApplications()` internally so the list reflects the deletion immediately.
    /// Callers do not need to call `loadApplications()` again after this method.
    func confirmDeleteSelected() {
        guard let id = selectedApplicationID else { return }
        do {
            try store.delete(id: id)
            selectedApplicationID = nil
            isDeleteConfirmationPresented = false
            loadApplications()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Dismisses the form without saving.
    func cancelForm() {
        isFormPresented = false
    }

    /// Clears the current error message (called when the user dismisses the error alert).
    func dismissErrorMessage() {
        errorMessage = nil
    }

    // MARK: - Filtered list

    /// Applications filtered by `searchText` and `statusFilter`.
    var filteredApplications: [JobApplication] {
        applications.filter { app in
            let matchesStatus = statusFilter == nil || app.status == statusFilter
            let matchesText: Bool
            if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                matchesText = true
            } else {
                let query = searchText.lowercased()
                matchesText = app.companyName.lowercased().contains(query)
                           || app.jobTitle.lowercased().contains(query)
            }
            return matchesStatus && matchesText
        }
    }

    /// True when search or filter are active (used for empty-state messaging).
    var hasActiveFilters: Bool {
        statusFilter != nil || !searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Derived helpers

    /// The full JobApplication record for the current selection, or nil.
    var selectedApplication: JobApplication? {
        guard let id = selectedApplicationID else { return nil }
        return applications.first { $0.id == id }
    }

    /// True when a row is selected and deletion is meaningful.
    var canDelete: Bool {
        selectedApplicationID != nil
    }

    // MARK: - CSV Export

    /// Presents a save panel and exports all applications to CSV.
    func exportCSV() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType.commaSeparatedText]
        panel.nameFieldStringValue = "JobApplications.csv"
        panel.title = "Export Applications"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        let csv = buildCSV(from: applications)
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Builds CSV string from an array of applications. Internal for testability.
    func buildCSV(from apps: [JobApplication]) -> String {
        let header = "Company,Job Title,Status,Date Applied,Follow-Up Date,Salary,URL,Contact Name,Contact Email,Description"
        let rows = apps.map { app in
            let fields: [String] = [
                csvEscape(app.companyName),
                csvEscape(app.jobTitle),
                csvEscape(app.status.displayLabel),
                csvEscape(string(from: app.dateApplied)),
                csvEscape(app.followUpDate.map { string(from: $0) } ?? ""),
                csvEscape(app.salary),
                csvEscape(app.jobURL),
                csvEscape(app.contactName),
                csvEscape(app.contactEmail),
                csvEscape(app.jobDescription)
            ]
            return fields.joined(separator: ",")
        }
        return ([header] + rows).joined(separator: "\n")
    }

    private func csvEscape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return value
    }
}
