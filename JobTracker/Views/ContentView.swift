// ContentView.swift
// JobTracker

import SwiftUI

struct ContentView: View {

    @StateObject var viewModel: JobApplicationListViewModel

    var body: some View {
        NavigationStack {
            JobApplicationListView(viewModel: viewModel)
        }
    }
}

#Preview {
    ContentView(
        viewModel: JobApplicationListViewModel(store: InMemoryJobApplicationStore())
    )
}
