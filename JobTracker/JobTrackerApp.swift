// JobTrackerApp.swift
// JobTracker

import SwiftUI
import SwiftData

/// Creates a ModelContainer for the app schema.
/// Returns nil if the on-disk store cannot be initialised (e.g. corrupted database),
/// in which case the caller should fall back to an in-memory container.
func makeModelContainer(storedInMemoryOnly: Bool = false) -> ModelContainer? {
    let schema = Schema([PersistedJobApplication.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: storedInMemoryOnly)
    return try? ModelContainer(for: schema, configurations: config)
}

@main
struct JobTrackerApp: App {

    @State private var containerError: Bool = false

    let container: ModelContainer

    init() {
        if let disk = makeModelContainer(storedInMemoryOnly: false) {
            container = disk
        } else if let memory = makeModelContainer(storedInMemoryOnly: true) {
            container = memory
            containerError = true
        } else {
            // Both attempts failed — this should never happen in practice.
            fatalError("Unable to create ModelContainer from either disk or in-memory config")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(
                viewModel: JobApplicationListViewModel(
                    store: SwiftDataJobApplicationStore(modelContext: container.mainContext)
                )
            )
            .alert("Storage Unavailable", isPresented: $containerError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your job applications could not be loaded from disk. Data will not be saved this session.")
            }
        }
        .modelContainer(container)
    }
}
