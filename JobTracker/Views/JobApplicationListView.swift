// JobApplicationListView.swift
// JobTracker

import SwiftUI

// MARK: - Date formatting helpers (MM/DD/YYYY text input)
// Internal so JobApplicationFormView can share the same formatter.

let dateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "MM/dd/yyyy"
    f.isLenient  = true
    return f
}()

func string(from date: Date) -> String { dateFormatter.string(from: date) }
func date(from string: String) -> Date? { dateFormatter.date(from: string) }

/// The main window content: a toolbar above an inline-editable list of applications.
struct JobApplicationListView: View {

    @ObservedObject var viewModel: JobApplicationListViewModel

    var body: some View {
        Group {
            if viewModel.applications.isEmpty {
                emptyStateView
            } else {
                listView
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

    // MARK: - Column header

    private var columnHeader: some View {
        HStack(spacing: 8) {
            Text("Company")
                .frame(minWidth: 120, maxWidth: 180, alignment: .leading)
            Text("Job Title")
                .frame(minWidth: 120, maxWidth: 180, alignment: .leading)
            Text("Status")
                .frame(width: 110, alignment: .leading)
            Text("Description")
                .frame(minWidth: 100, maxWidth: .infinity, alignment: .leading)
            Text("Date Applied")
                .frame(width: 110, alignment: .leading)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }

    // MARK: - List

    private var listView: some View {
        VStack(spacing: 0) {
            columnHeader
            Divider()
            List(selection: $viewModel.selectedApplicationID) {
                ForEach(viewModel.applications) { app in
                    InlineEditRow(app: app) { updated in
                        viewModel.updateInline(updated)
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

    // MARK: - Form sheet (add only)

    private var formSheet: some View {
        JobApplicationFormView(
            viewModel: JobApplicationFormViewModel(),
            onDismiss: { viewModel.cancelForm() },
            onSave: { app in viewModel.save(app) }
        )
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
    var onDelete: () -> Void

    init(app: JobApplication, onCommit: @escaping (JobApplication) -> Void, onDelete: @escaping () -> Void) {
        _app      = State(initialValue: app)
        _dateText = State(initialValue: string(from: app.dateApplied))
        self.onCommit = onCommit
        self.onDelete = onDelete
    }

    var body: some View {
        HStack(spacing: 0) {
            // Company name
            TextField("Company", text: $app.companyName)
                .frame(minWidth: 120, maxWidth: 180)
                .textFieldStyle(.plain)
                .accessibilityIdentifier("companyName_\(app.id)")
                .onSubmit { onCommit(app) }

            columnDivider

            // Job title
            TextField("Job Title", text: $app.jobTitle)
                .frame(minWidth: 120, maxWidth: 180)
                .textFieldStyle(.plain)
                .accessibilityIdentifier("jobTitle_\(app.id)")
                .onSubmit { onCommit(app) }

            columnDivider

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
                .onChange(of: app.status) { _ in onCommit(app) }

                StatusBadgeView(status: app.status)
                    .allowsHitTesting(false) // let the Picker underneath handle taps
            }
            .frame(width: 118)
            .accessibilityIdentifier("statusPicker_\(app.id)")

            columnDivider

            // Description
            TextField("Description", text: $app.jobDescription)
                .frame(minWidth: 100, maxWidth: .infinity)
                .textFieldStyle(.plain)
                .foregroundStyle(.secondary)
                .font(.system(size: 12))
                .accessibilityIdentifier("description_\(app.id)")
                .onSubmit { onCommit(app) }

            columnDivider

            // Date — plain text MM/DD/YYYY, no stepper arrows
            TextField("MM/DD/YYYY", text: $dateText)
                .frame(width: 90)
                .textFieldStyle(.plain)
                .font(.system(size: 12).monospacedDigit())
                .foregroundStyle(dateInvalid ? .red : .primary)
                .accessibilityIdentifier("dateApplied_\(app.id)")
                .onSubmit { commitDate() }
                .onChange(of: dateText) { _ in
                    // Clear error as the user types
                    if dateInvalid { dateInvalid = false }
                }
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 8)
        .contextMenu {
            Button("Delete", role: .destructive) { onDelete() }
        }
    }

    // MARK: - Helpers

    private var columnDivider: some View {
        Divider()
            .frame(height: 16)
            .padding(.horizontal, 6)
    }

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
