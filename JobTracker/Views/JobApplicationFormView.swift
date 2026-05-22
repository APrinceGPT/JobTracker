// JobApplicationFormView.swift
// JobTracker

import SwiftUI

/// Sheet-based form for adding a new job application.
struct JobApplicationFormView: View {

    @ObservedObject var viewModel: JobApplicationFormViewModel

    var onDismiss: () -> Void
    var onSave: (JobApplication) -> Void

    /// Editable text for the date field (MM/DD/YYYY).
    @State private var dateText: String
    @State private var dateInvalid: Bool = false
    @State private var isSalaryVisible: Bool = false

    init(viewModel: JobApplicationFormViewModel, onDismiss: @escaping () -> Void = {}, onSave: @escaping (JobApplication) -> Void = { _ in }) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
        self.onSave = onSave
        _dateText = State(initialValue: string(from: viewModel.dateApplied))
    }

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
            .padding(.bottom, 12)

            Divider()

            // Form fields
            VStack(alignment: .leading, spacing: 16) {

                // Company Name
                fieldLabel("Company Name", required: true)
                TextField("e.g. Acme Corp", text: $viewModel.companyName)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("companyNameField")
                if viewModel.showsCompanyNameError {
                    errorText("Company name is required")
                        .accessibilityIdentifier("companyNameError")
                }

                // Job Title
                fieldLabel("Job Title", required: true)
                TextField("e.g. Senior iOS Engineer", text: $viewModel.jobTitle)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("jobTitleField")
                if viewModel.showsJobTitleError {
                    errorText("Job title is required")
                        .accessibilityIdentifier("jobTitleError")
                }

                // Description
                fieldLabel("Description", required: false)
                TextEditor(text: $viewModel.jobDescription)
                    .font(.body)
                    .frame(height: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                    )
                    .accessibilityIdentifier("jobDescriptionField")

                // Status + Date on one row
                HStack(alignment: .top, spacing: 16) {

                    // Status
                    VStack(alignment: .leading, spacing: 6) {
                        fieldLabel("Status", required: false)
                        ZStack(alignment: .leading) {
                            Picker("", selection: $viewModel.status) {
                                ForEach(ApplicationStatus.allCases, id: \.self) { s in
                                    Text(s.displayLabel).tag(s)
                                }
                            }
                            .labelsHidden()
                            .opacity(0.015)
                            .frame(width: 130, height: 32)

                            StatusBadgeView(status: viewModel.status)
                                .allowsHitTesting(false)
                        }
                        .fixedSize()
                        .accessibilityIdentifier("statusPicker")
                    }

                    // Date Applied
                    VStack(alignment: .leading, spacing: 6) {
                        fieldLabel("Date Applied", required: false)
                        HStack(spacing: 6) {
                            TextField("MM/DD/YYYY", text: $dateText)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 120)
                                .font(.system(size: 13).monospacedDigit())
                                .foregroundStyle(dateInvalid ? .red : .primary)
                                .accessibilityIdentifier("dateAppliedPicker")
                                .onSubmit { commitDate() }
                                .onChange(of: dateText) {
                                    if dateInvalid { dateInvalid = false }
                                }
                            if dateInvalid {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundStyle(.red)
                                    .font(.caption)
                            }
                        }
                        if dateInvalid {
                            errorText("Use MM/DD/YYYY format")
                        }
                    }
                }

                // Follow-up Date
                followUpDateSection

                // Salary
                fieldLabel("Salary", required: false)
                HStack(spacing: 6) {
                    if isSalaryVisible {
                        TextField("e.g. $120,000", text: $viewModel.salary)
                            .textFieldStyle(.roundedBorder)
                            .accessibilityIdentifier("salaryField")
                    } else {
                        SecureField("Hidden", text: $viewModel.salary)
                            .textFieldStyle(.roundedBorder)
                            .accessibilityIdentifier("salaryField")
                    }
                    Button {
                        isSalaryVisible.toggle()
                    } label: {
                        Image(systemName: isSalaryVisible ? "eye" : "eye.slash")
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("salaryVisibilityToggle")
                }

                // Job URL
                fieldLabel("Job URL", required: false)
                TextField("e.g. https://company.com/jobs/123", text: $viewModel.jobURL)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("jobURLField")

                // Contact Name
                fieldLabel("Contact Name", required: false)
                TextField("e.g. Jane Smith", text: $viewModel.contactName)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("contactNameField")

                // Contact Email
                fieldLabel("Contact Email", required: false)
                TextField("e.g. jane@company.com", text: $viewModel.contactEmail)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("contactEmailField")
            }
            .padding(.horizontal)
            .padding(.vertical, 16)

            Spacer(minLength: 0)

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
        .frame(width: 460, height: 760)
    }

    // MARK: - Follow-up Date Section

    private var followUpDateSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                fieldLabel("Follow-up Date", required: false)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { viewModel.followUpDate != nil },
                    set: { enabled in
                        viewModel.followUpDate = enabled ? Date() : nil
                    }
                ))
                .toggleStyle(.checkbox)
                .labelsHidden()
            }
            if let binding = Binding($viewModel.followUpDate) {
                DatePicker("", selection: binding, displayedComponents: .date)
                    .labelsHidden()
                    .accessibilityIdentifier("followUpDatePicker")
            }
        }
    }

    // MARK: - Helpers

    private func fieldLabel(_ title: String, required: Bool) -> some View {
        HStack(spacing: 2) {
            Text(title)
                .font(.callout)
                .fontWeight(.medium)
            if required {
                Text("*")
                    .font(.callout)
                    .foregroundStyle(.red)
            } else {
                Text("(optional)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func errorText(_ message: String) -> some View {
        Text(message)
            .font(.caption)
            .foregroundStyle(.red)
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
    JobApplicationFormView(viewModel: JobApplicationFormViewModel(), onDismiss: {}, onSave: { _ in })
}
