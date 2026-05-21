// JobApplicationListView.swift
// JobTracker

import SwiftUI

/// The main window content: a toolbar above a compact table of applications.
struct JobApplicationListView: View {

    @ObservedObject var viewModel: JobApplicationListViewModel

    var body: some View {
        Group {
            if viewModel.applications.isEmpty {
                emptyStateView
            } else {
                tableView
            }
        }
        .navigationTitle("Job Applications")
        .toolbar { toolbarItems }
        .sheet(isPresented: $viewModel.isFormPresented) { formSheet }
        .confirmationDialog(
            "Delete Application",
            isPresented: $viewModel.isDeleteConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                viewModel.confirmDeleteSelected()
            }
            .accessibilityIdentifier("confirmDeleteButton")
            Button("Cancel", role: .cancel) {}
                .accessibilityIdentifier("cancelDeleteButton")
        } message: {
            Text("This action cannot be undone.")
        }
        .onAppear {
            viewModel.loadApplications()
        }
        .alert(
            "Error",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.dismissErrorMessage() } }
            )
        ) {
            Button("OK", role: .cancel) {
                viewModel.dismissErrorMessage()
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Empty state

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("No applications yet. Click + to add one.")
                .foregroundColor(.secondary)
                .accessibilityIdentifier("emptyStateMessage")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Table

    private var tableView: some View {
        Table(viewModel.applications, selection: $viewModel.selectedApplicationID) {
            TableColumn("Company") { app in
                Text(app.companyName)
                    .accessibilityIdentifier("companyName_\(app.id)")
            }
            .width(min: 120, ideal: 160)

            TableColumn("Job Title") { app in
                Text(app.jobTitle)
                    .accessibilityIdentifier("jobTitle_\(app.id)")
            }
            .width(min: 120, ideal: 160)

            TableColumn("Status") { app in
                StatusBadgeView(status: app.status)
                    .accessibilityIdentifier("statusBadge_\(app.id)")
            }
            .width(min: 80, ideal: 100)

            TableColumn("Description") { app in
                Text(app.jobDescription)
                    .lineLimit(1)
                    .foregroundColor(.secondary)
                    .accessibilityIdentifier("description_\(app.id)")
            }
            .width(min: 100, ideal: 200)

            TableColumn("Date Applied") { app in
                Text(app.dateApplied, style: .date)
                    .accessibilityIdentifier("dateApplied_\(app.id)")
            }
            .width(min: 90, ideal: 110)
        }
        .contextMenu(forSelectionType: UUID.self) { selection in
            if let id = selection.first,
               let app = viewModel.applications.first(where: { $0.id == id }) {
                Button("Edit") { viewModel.presentEditForm(for: app) }
                Button("Delete", role: .destructive) {
                    viewModel.selectedApplicationID = id
                    viewModel.requestDeleteSelected()
                }
            }
        } primaryAction: { selection in
            if let id = selection.first,
               let app = viewModel.applications.first(where: { $0.id == id }) {
                viewModel.presentEditForm(for: app)
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                viewModel.presentAddForm()
            } label: {
                Label("Add Application", systemImage: "plus")
            }
            .accessibilityIdentifier("addApplicationButton")
        }

        ToolbarItem(placement: .destructiveAction) {
            Button(role: .destructive) {
                viewModel.requestDeleteSelected()
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .disabled(!viewModel.canDelete)
            .accessibilityIdentifier("deleteButton")
        }
    }

    // MARK: - Form sheet

    private var formSheet: some View {
        let formVM = viewModel.applicationToEdit.map(JobApplicationFormViewModel.init(editing:))
                     ?? JobApplicationFormViewModel()
        return JobApplicationFormView(
            viewModel: formVM,
            onDismiss: { viewModel.cancelForm() },
            onSave: { app in viewModel.save(app) }
        )
    }
}

#Preview {
    NavigationStack {
        JobApplicationListView(
            viewModel: JobApplicationListViewModel(store: InMemoryJobApplicationStore())
        )
    }
}
