// ContentView.swift
// JobTracker

import SwiftUI

struct ContentView: View {

    @ObservedObject var viewModel: JobApplicationListViewModel

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            JobApplicationListView(viewModel: viewModel)
                .navigationSplitViewColumnWidth(min: 500, ideal: 620)
        } detail: {
            if let app = viewModel.selectedApplication {
                DescriptionDetailView(
                    application: app,
                    onClear: { viewModel.clearDescription(for: $0) },
                    onSaveDescription: { application, newDescription in
                        viewModel.saveDescription(for: application, description: newDescription)
                    }
                )
                .id("\(app.id)\(app.companyName)\(app.jobTitle)\(app.status)\(app.dateApplied)\(app.jobDescription)")
            } else {
                Text("Select an application to view its description.")
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
}

#Preview {
    ContentView(
        viewModel: JobApplicationListViewModel(store: InMemoryJobApplicationStore())
    )
}
