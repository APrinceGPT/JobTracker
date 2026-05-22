// DescriptionDetailView.swift
// JobTracker

import SwiftUI
import AppKit

struct DescriptionDetailView: View {

    let application: JobApplication
    var onClear: (JobApplication) -> Void

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

                    // Description
                    if hasDescription {
                        Text(application.jobDescription)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text("No description added yet. Use the + button to add one when creating an application, or edit this application to include a description.")
                            .foregroundStyle(.tertiary)
                            .frame(maxWidth: .infinity, alignment: .leading)
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
                }
                .foregroundStyle(.red)
                .disabled(!hasDescription)

                Spacer()

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
        onClear: { _ in }
    )
}
