// JobApplicationListView.swift
// JobTracker

import SwiftUI

/// The main window content: a toolbar above an inline-editable list of applications.
struct JobApplicationListView: View {

    @ObservedObject var viewModel: JobApplicationListViewModel

    @FocusState private var searchFieldFocused: Bool
    @State private var formVM: JobApplicationFormViewModel?

    var body: some View {
        Group {
            if viewModel.applications.isEmpty && !viewModel.hasActiveFilters {
                emptyStateView
            } else {
                VStack(spacing: 0) {
                    searchFilterBar
                    if viewModel.filteredApplications.isEmpty {
                        filteredEmptyStateView
                    } else {
                        listView
                    }
                }
            }
        }
        .navigationTitle("Job Applications")
        .toolbar { toolbarItems }
        .onChange(of: viewModel.isFormPresented) {
            if viewModel.isFormPresented {
                if let existing = viewModel.applicationToEdit {
                    formVM = JobApplicationFormViewModel(editing: existing)
                } else {
                    formVM = JobApplicationFormViewModel()
                }
            }
        }
        .sheet(isPresented: $viewModel.isFormPresented) {
            if let vm = formVM {
                JobApplicationFormView(
                    viewModel: vm,
                    onDismiss: { viewModel.cancelForm() },
                    onSave: { app in viewModel.save(app) }
                )
            }
        }
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
        .background {
            Button("") { searchFieldFocused = true }
                .keyboardShortcut("f", modifiers: .command)
                .frame(width: 0, height: 0)
                .opacity(0)
        }
    }

    // MARK: - Search & Filter bar

    private var searchFilterBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 4) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search company or title…", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                    .focused($searchFieldFocused)
                    .accessibilityIdentifier("searchField")
                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(6)
            .background(RoundedRectangle(cornerRadius: 6).fill(.quaternary))

            Picker("Status", selection: $viewModel.statusFilter) {
                Text("All Statuses").tag(ApplicationStatus?.none)
                Divider()
                ForEach(ApplicationStatus.allCases, id: \.self) { s in
                    Text(s.displayLabel).tag(ApplicationStatus?.some(s))
                }
            }
            .frame(width: 140)
            .accessibilityIdentifier("statusFilterPicker")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
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

    private var filteredEmptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("No applications match your search.")
                .foregroundColor(.secondary)
                .accessibilityIdentifier("filteredEmptyStateMessage")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Column header

    private var columnHeader: some View {
        HStack(spacing: 0) {
            Text("Company")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Job Title")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Status")
                .frame(width: 130, alignment: .leading)
            Text("Date Applied")
                .frame(width: 100, alignment: .leading)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 20)
        .padding(.vertical, 4)
    }

    // MARK: - List

    private var listView: some View {
        VStack(spacing: 0) {
            columnHeader
            Divider()
            List(selection: $viewModel.selectedApplicationID) {
                ForEach(viewModel.filteredApplications) { app in
                    InlineEditRow(app: app) { updated in
                        viewModel.updateInline(updated)
                    } onEdit: {
                        viewModel.presentEditForm(for: app)
                    } onDelete: {
                        viewModel.selectedApplicationID = app.id
                        viewModel.requestDeleteSelected()
                    }
                    .tag(app.id)
                }
            }
            .listStyle(.inset)
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

        ToolbarItem(placement: .automatic) {
            Button {
                viewModel.exportCSV()
            } label: {
                Label("Export CSV", systemImage: "square.and.arrow.up")
            }
            .disabled(viewModel.applications.isEmpty)
            .accessibilityIdentifier("exportButton")
        }

        ToolbarItem(placement: .destructiveAction) {
            Button(role: .destructive) {
                viewModel.requestDeleteSelected()
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .keyboardShortcut(.delete, modifiers: [])
            .disabled(!viewModel.canDelete)
            .accessibilityIdentifier("deleteButton")
        }
    }

}

// MARK: - Inline edit row

/// A single list row with inline-editable fields for all columns.
private struct InlineEditRow: View {

    @State private var app: JobApplication
    /// Editable text for the date field (MM/DD/YYYY).
    @State private var dateText: String
    /// True when the date text cannot be parsed.
    @State private var dateInvalid: Bool = false

    var onCommit: (JobApplication) -> Void
    var onEdit: () -> Void
    var onDelete: () -> Void

    init(app: JobApplication, onCommit: @escaping (JobApplication) -> Void, onEdit: @escaping () -> Void, onDelete: @escaping () -> Void) {
        _app      = State(initialValue: app)
        _dateText = State(initialValue: string(from: app.dateApplied))
        self.onCommit = onCommit
        self.onEdit = onEdit
        self.onDelete = onDelete
    }

    var body: some View {
        HStack(spacing: 0) {
            // Overdue indicator
            if app.isOverdue {
                Circle()
                    .fill(.red)
                    .frame(width: 6, height: 6)
                    .padding(.trailing, 4)
                    .accessibilityIdentifier("overdueIndicator_\(app.id)")
            }

            // Company name
            TextField("Company", text: $app.companyName)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textFieldStyle(.plain)
                .accessibilityIdentifier("companyName_\(app.id)")
                .onSubmit { onCommit(app) }

            // Job title
            TextField("Job Title", text: $app.jobTitle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textFieldStyle(.plain)
                .accessibilityIdentifier("jobTitle_\(app.id)")
                .onSubmit { onCommit(app) }

            // Status — badge overlays a transparent Picker so the badge
            // renders in a plain view environment, unaffected by button styling.
            ZStack(alignment: .leading) {
                Picker("", selection: $app.status) {
                    ForEach(ApplicationStatus.allCases, id: \.self) { s in
                        Text(s.displayLabel).tag(s)
                    }
                }
                .labelsHidden()
                .opacity(0.015) // nearly invisible; just captures the interaction
                .onChange(of: app.status) { onCommit(app) }

                StatusBadgeView(status: app.status)
                    .allowsHitTesting(false) // let the Picker underneath handle taps
            }
            .frame(width: 130, alignment: .leading)
            .accessibilityIdentifier("statusPicker_\(app.id)")

            // Date — plain text MM/DD/YYYY, no stepper arrows
            TextField("MM/DD/YYYY", text: $dateText)
                .frame(width: 100, alignment: .leading)
                .textFieldStyle(.plain)
                .font(.system(size: 12).monospacedDigit())
                .foregroundStyle(dateInvalid ? .red : .primary)
                .accessibilityIdentifier("dateApplied_\(app.id)")
                .onSubmit { commitDate() }
                .onChange(of: dateText) {
                    // Clear error as the user types
                    if dateInvalid { dateInvalid = false }
                }
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 8)
        .contextMenu {
            Button("Edit") { onEdit() }
            Divider()
            Button("Delete", role: .destructive) { onDelete() }
        }
    }

    // MARK: - Helpers

    private func commitDate() {
        if let parsed = date(from: dateText) {
            app.dateApplied = parsed
            dateText = string(from: parsed) // normalise format
            dateInvalid = false
            onCommit(app)
        } else {
            dateInvalid = true
        }
    }
}

#Preview {
    NavigationStack {
        JobApplicationListView(
            viewModel: JobApplicationListViewModel(store: InMemoryJobApplicationStore())
        )
    }
}
