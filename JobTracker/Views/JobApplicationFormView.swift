// JobApplicationFormView.swift
// JobTracker

import SwiftUI

/// Sheet-based form for adding a new job application.
struct JobApplicationFormView: View {

    @ObservedObject var viewModel: JobApplicationFormViewModel

    var onDismiss: () -> Void = {}
    var onSave: (JobApplication) -> Void = { _ in }

    /// Editable text for the date field (MM/DD/YYYY).
    @State private var dateText: String = string(from: Date())
    @State private var dateInvalid: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Text("Add Application")
                    .font(.headline)
                    .accessibilityIdentifier("formTitle")
                Spacer()
            }
            .padding([.horizontal, .top])
            .padding(.bottom, 8)

            Divider()

            Form {
                Section("Company") {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Company Name", text: $viewModel.companyName)
                            .accessibilityIdentifier("companyNameField")
                        if viewModel.showsCompanyNameError {
                            Text("Company name is required")
                                .font(.caption)
                                .foregroundColor(.red)
                                .accessibilityIdentifier("companyNameError")
                        }
                    }
                }

                Section("Role") {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Job Title", text: $viewModel.jobTitle)
                            .accessibilityIdentifier("jobTitleField")
                        if viewModel.showsJobTitleError {
                            Text("Job title is required")
                                .font(.caption)
                                .foregroundColor(.red)
                                .accessibilityIdentifier("jobTitleError")
                        }
                    }

                    TextField("Description (optional)", text: $viewModel.jobDescription, axis: .vertical)
                        .lineLimit(3...6)
                        .accessibilityIdentifier("jobDescriptionField")
                }

                Section("Status & Date") {
                    // Status — colored menu showing the badge
                    HStack {
                        Text("Status")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Menu {
                            ForEach(ApplicationStatus.allCases, id: \.self) { s in
                                Button {
                                    viewModel.status = s
                                } label: {
                                    HStack {
                                        StatusBadgeView(status: s)
                                        if s == viewModel.status {
                                            Spacer()
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            StatusBadgeView(status: viewModel.status)
                        }
                        .menuStyle(.borderlessButton)
                        .fixedSize()
                        .accessibilityIdentifier("statusPicker")
                    }

                    // Date — plain text input, no stepper
                    HStack {
                        Text("Date Applied")
                            .foregroundStyle(.secondary)
                        Spacer()
                        TextField("MM/DD/YYYY", text: $dateText)
                            .frame(width: 100)
                            .multilineTextAlignment(.trailing)
                            .font(.system(size: 13).monospacedDigit())
                            .foregroundStyle(dateInvalid ? .red : .primary)
                            .accessibilityIdentifier("dateAppliedPicker")
                            .onSubmit { commitDate() }
                            .onChange(of: dateText) { _ in
                                if dateInvalid { dateInvalid = false }
                            }
                        if dateInvalid {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundStyle(.red)
                                .font(.caption)
                        }
                    }
                }
            }
            .formStyle(.grouped)

            Divider()

            // Button row
            HStack {
                Button("Cancel") { onDismiss() }
                    .accessibilityIdentifier("cancelButton")
                    .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Save") {
                    commitDate()
                    if !dateInvalid, let app = viewModel.buildApplication() {
                        onSave(app)
                    }
                }
                .disabled(!viewModel.isValid || dateInvalid)
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("saveButton")
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(minWidth: 400, minHeight: 380)
    }

    private func commitDate() {
        if let parsed = date(from: dateText) {
            viewModel.dateApplied = parsed
            dateText = string(from: parsed)
            dateInvalid = false
        } else {
            dateInvalid = true
        }
    }
}

#Preview {
    JobApplicationFormView(viewModel: JobApplicationFormViewModel())
}
