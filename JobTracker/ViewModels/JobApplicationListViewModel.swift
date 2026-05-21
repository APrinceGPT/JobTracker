// JobApplicationListViewModel.swift
// JobTracker

import SwiftUI

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
}
