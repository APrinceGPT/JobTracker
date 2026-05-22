// ContentView.swift
// JobTracker

import SwiftUI

struct ContentView: View {

    @StateObject var viewModel: JobApplicationListViewModel

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            JobApplicationListView(viewModel: viewModel)
                .navigationSplitViewColumnWidth(min: 500, ideal: 620)
        } detail: {
            if let app = viewModel.selectedApplication {
                DescriptionDetailView(
                    application: app,
                    onClear: { viewModel.clearDescription(for: $0) }
                )
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
