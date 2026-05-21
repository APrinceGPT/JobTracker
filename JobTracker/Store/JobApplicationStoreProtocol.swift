// JobApplicationStoreProtocol.swift
// JobTracker

import Foundation

/// Errors the store layer may surface.
enum JobApplicationStoreError: Error, Equatable {
    case notFound
    case duplicateEntry
    case saveFailed(reason: String)
    case invalidData(reason: String)
}

/// Read/write contract for managing JobApplication records.
/// Any concrete store (in-memory, SwiftData, Core Data) must conform.
protocol JobApplicationStoreProtocol {

    // MARK: - Create
    /// Adds a new application. Throws `duplicateEntry` if an application
    /// with the same `id` already exists.
    func add(_ application: JobApplication) throws

    // MARK: - Read
    /// Returns all stored applications, ordered by `dateApplied` descending.
    func fetchAll() throws -> [JobApplication]

    /// Returns a single application matching `id`, or throws `notFound`.
    func fetch(id: UUID) throws -> JobApplication

    /// Returns all applications whose status matches `status`.
    func fetchAll(withStatus status: ApplicationStatus) throws -> [JobApplication]

    // MARK: - Update
    /// Replaces the stored record that shares the application's `id`.
    /// Throws `notFound` if no matching record exists.
    func update(_ application: JobApplication) throws

    /// Convenience: changes only the status field of the matching record.
    /// Throws `notFound` if no matching record exists.
    func updateStatus(id: UUID, to status: ApplicationStatus) throws

    // MARK: - Delete
    /// Removes the application matching `id`. Throws `notFound` if absent.
    func delete(id: UUID) throws

    /// Removes every stored application.
    func deleteAll() throws

    // MARK: - Query helpers
    /// Returns the total number of stored applications.
    func count() throws -> Int
}
