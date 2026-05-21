// InMemoryJobApplicationStore.swift
// JobTracker

import Foundation

/// In-memory store used in unit tests and previews.
final class InMemoryJobApplicationStore: JobApplicationStoreProtocol {

    private var storage: [UUID: JobApplication] = [:]

    func add(_ application: JobApplication) throws {
        guard storage[application.id] == nil else {
            throw JobApplicationStoreError.duplicateEntry
        }
        storage[application.id] = application
    }

    func fetchAll() throws -> [JobApplication] {
        storage.values.sorted { $0.dateApplied > $1.dateApplied }
    }

    func fetch(id: UUID) throws -> JobApplication {
        guard let app = storage[id] else {
            throw JobApplicationStoreError.notFound
        }
        return app
    }

    func fetchAll(withStatus status: ApplicationStatus) throws -> [JobApplication] {
        storage.values.filter { $0.status == status }.sorted { $0.dateApplied > $1.dateApplied }
    }

    func update(_ application: JobApplication) throws {
        guard storage[application.id] != nil else {
            throw JobApplicationStoreError.notFound
        }
        storage[application.id] = application
    }

    func updateStatus(id: UUID, to status: ApplicationStatus) throws {
        guard var app = storage[id] else {
            throw JobApplicationStoreError.notFound
        }
        app.status = status
        app.lastUpdated = Date()
        storage[id] = app
    }

    func delete(id: UUID) throws {
        guard storage[id] != nil else {
            throw JobApplicationStoreError.notFound
        }
        storage.removeValue(forKey: id)
    }

    func deleteAll() throws {
        storage.removeAll()
    }

    func count() throws -> Int {
        storage.count
    }
}
