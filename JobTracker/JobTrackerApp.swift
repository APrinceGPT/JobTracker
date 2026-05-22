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
    @StateObject private var viewModel: JobApplicationListViewModel

    let container: ModelContainer

    init() {
        let resolvedContainer: ModelContainer
        var hadError = false
        if let disk = makeModelContainer(storedInMemoryOnly: false) {
            resolvedContainer = disk
        } else if let memory = makeModelContainer(storedInMemoryOnly: true) {
            resolvedContainer = memory
            hadError = true
        } else {
            fatalError("Unable to create ModelContainer from either disk or in-memory config")
        }
        self.container = resolvedContainer
        _containerError = State(initialValue: hadError)
        _viewModel = StateObject(wrappedValue: JobApplicationListViewModel(
            store: SwiftDataJobApplicationStore(modelContext: resolvedContainer.mainContext)
        ))
    }

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .alert("Storage Unavailable", isPresented: $containerError) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("Your job applications could not be loaded from disk. Data will not be saved this session.")
                }
        }
        .modelContainer(container)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Application") {
                    viewModel.presentAddForm()
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
    }
}
