// DescriptionDetailView.swift
// JobTracker

import SwiftUI
import AppKit

struct DescriptionDetailView: View {

    let application: JobApplication
    var onClear: (JobApplication) -> Void
    var onSaveDescription: (JobApplication, String) -> Void

    @State private var isEditingDescription: Bool = false
    @State private var editedDescription: String = ""

    private var hasDescription: Bool {
        !application.jobDescription.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Header
            VStack(alignment: .leading, spacing: 2) {
                Text(application.companyName)
                    .font(.headline)
                Text(application.jobTitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                // Follow-up date
                if let followUp = application.followUpDate {
                    HStack(spacing: 4) {
                        Image(systemName: "bell")
                            .font(.caption)
                        Text("Follow up: \(followUp, style: .date)")
                            .font(.caption)
                    }
                    .foregroundStyle(application.isOverdue ? .red : .secondary)
                    .padding(.top, 2)
                }
            }
            .padding(.horizontal)
            .padding(.top)
            .padding(.bottom, 8)

            Divider()

            // Description & details area
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // Extra fields
                    if !application.salary.isEmpty {
                        SalaryRevealRow(salary: application.salary)
                    }
                    if !application.jobURL.isEmpty {
                        DetailRow(label: "URL") {
                            if let url = URL(string: application.jobURL) {
                                Link(application.jobURL, destination: url)
                                    .font(.body)
                            } else {
                                Text(application.jobURL)
                            }
                        }
                    }
                    if !application.contactName.isEmpty {
                        DetailRow(label: "Contact") {
                            Text(application.contactName)
                        }
                    }
                    if !application.contactEmail.isEmpty {
                        DetailRow(label: "Email") {
                            Text(application.contactEmail)
                                .textSelection(.enabled)
                        }
                    }

                    Divider()

                    // Description — inline editable
                    if isEditingDescription {
                        TextEditor(text: $editedDescription)
                            .font(.body)
                            .frame(minHeight: 120, maxHeight: .infinity)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.accentColor, lineWidth: 1)
                            )
                    } else if hasDescription {
                        Text(application.jobDescription)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .onTapGesture(count: 2) {
                                editedDescription = application.jobDescription
                                isEditingDescription = true
                            }
                    } else {
                        Text("Double-click to add a description…")
                            .foregroundStyle(.tertiary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .onTapGesture(count: 2) {
                                editedDescription = ""
                                isEditingDescription = true
                            }
                    }
                }
                .padding()
            }
            .frame(maxHeight: .infinity)

            Divider()

            // Action bar
            HStack {
                Button("Clear") {
                    onClear(application)
                    isEditingDescription = false
                }
                .foregroundStyle(.red)
                .disabled(!hasDescription && !isEditingDescription)

                Spacer()

                if isEditingDescription {
                    Button("Cancel") {
                        isEditingDescription = false
                    }

                    Button("Save") {
                        onSaveDescription(application, editedDescription)
                        isEditingDescription = false
                    }
                    .buttonStyle(.borderedProminent)
                }

                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(application.jobDescription, forType: .string)
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .disabled(!hasDescription)
            }
            .padding()
        }
    }
}

// MARK: - Helper Views

private struct SalaryRevealRow: View {
    let salary: String
    @State private var revealed = false

    var body: some View {
        HStack(spacing: 6) {
            Text("Salary:")
                .font(.callout)
                .fontWeight(.medium)
            Text(revealed ? salary : String(repeating: "\u{2022}", count: 5))
                .font(.body)
                .textSelection(.enabled)
            Button {
                revealed.toggle()
            } label: {
                Image(systemName: revealed ? "eye" : "eye.slash")
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
    }
}

private struct DetailRow<Content: View>: View {
    let label: String
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: 6) {
            Text("\(label):")
                .font(.callout)
                .fontWeight(.medium)
            content
        }
    }
}

#Preview {
    DescriptionDetailView(
        application: JobApplication(
            companyName: "Google",
            jobTitle: "Senior iOS Engineer",
            jobDescription: "We are looking for a skilled iOS engineer to join our team.",
            status: .applied
        ),
        onClear: { _ in },
        onSaveDescription: { _, _ in }
    )
}
