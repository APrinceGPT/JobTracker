// JobApplicationFormView.swift
// JobTracker

import SwiftUI

/// Sheet-based form for adding or editing a job application.
struct JobApplicationFormView: View {

    @ObservedObject var viewModel: JobApplicationFormViewModel

    /// Called by the parent to dismiss the sheet without saving.
    var onDismiss: () -> Void = {}

    /// Called with the completed application when the user taps Save.
    var onSave: (JobApplication) -> Void = { _ in }

    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Text(viewModel.isEditing ? "Edit Application" : "Add Application")
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
                    Picker("Status", selection: $viewModel.status) {
                        ForEach(ApplicationStatus.allCases, id: \.self) { status in
                            Text(status.displayLabel).tag(status)
                        }
                    }
                    .accessibilityIdentifier("statusPicker")

                    DatePicker(
                        "Date Applied",
                        selection: $viewModel.dateApplied,
                        displayedComponents: .date
                    )
                    .accessibilityIdentifier("dateAppliedPicker")
                }
            }
            .formStyle(.grouped)

            Divider()

            // Button row
            HStack {
                Button("Cancel") {
                    onDismiss()
                }
                .accessibilityIdentifier("cancelButton")
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Save") {
                    if let app = viewModel.buildApplication() {
                        onSave(app)
                    }
                }
                .disabled(!viewModel.isValid)
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("saveButton")
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(minWidth: 400, minHeight: 380)
    }
}

#Preview {
    JobApplicationFormView(viewModel: JobApplicationFormViewModel())
}
