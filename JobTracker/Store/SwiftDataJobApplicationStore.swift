// SwiftDataJobApplicationStore.swift
// JobTracker

import Foundation
import SwiftData

// MARK: - SwiftData model class (persisted entity)

/// Maps a JobApplication value type to a SwiftData @Model object.
@Model
final class PersistedJobApplication {
    @Attribute(.unique) var id: UUID
    var companyName: String
    var jobTitle: String
    var jobDescription: String
    var statusRawValue: String
    var dateApplied: Date
    var lastUpdated: Date

    init(
        id: UUID,
        companyName: String,
        jobTitle: String,
        jobDescription: String,
        statusRawValue: String,
        dateApplied: Date,
        lastUpdated: Date
    ) {
        self.id               = id
        self.companyName      = companyName
        self.jobTitle         = jobTitle
        self.jobDescription   = jobDescription
        self.statusRawValue   = statusRawValue
        self.dateApplied      = dateApplied
        self.lastUpdated      = lastUpdated
    }
}

// MARK: - Conversion helpers

private extension PersistedJobApplication {
    convenience init(from app: JobApplication) {
        self.init(
            id: app.id,
            companyName: app.companyName,
            jobTitle: app.jobTitle,
            jobDescription: app.jobDescription,
            statusRawValue: app.status.rawValue,
            dateApplied: app.dateApplied,
            lastUpdated: app.lastUpdated
        )
    }

    func toJobApplication() throws -> JobApplication {
        guard let status = ApplicationStatus(rawValue: statusRawValue) else {
            throw JobApplicationStoreError.invalidData(reason: "Unknown status: \(statusRawValue)")
        }
        return JobApplication(
            id: id,
            companyName: companyName,
            jobTitle: jobTitle,
            jobDescription: jobDescription,
            status: status,
            dateApplied: dateApplied,
            lastUpdated: lastUpdated
        )
    }
}

// MARK: - SwiftData-backed store

/// Concrete store that uses SwiftData for persistence.
final class SwiftDataJobApplicationStore: JobApplicationStoreProtocol {

    private let context: ModelContext

    init(modelContext: ModelContext) {
        self.context = modelContext
    }

    func add(_ application: JobApplication) throws {
        let existing = try findPersisted(id: application.id)
        guard existing == nil else {
            throw JobApplicationStoreError.duplicateEntry
        }
        let persisted = PersistedJobApplication(from: application)
        context.insert(persisted)
        try context.save()
    }

    func fetchAll() throws -> [JobApplication] {
        let descriptor = FetchDescriptor<PersistedJobApplication>(
            sortBy: [SortDescriptor(\.dateApplied, order: .reverse)]
        )
        let results = try context.fetch(descriptor)
        return try results.map { try $0.toJobApplication() }
    }

    func fetch(id: UUID) throws -> JobApplication {
        guard let persisted = try findPersisted(id: id) else {
            throw JobApplicationStoreError.notFound
        }
        return try persisted.toJobApplication()
    }

    func fetchAll(withStatus status: ApplicationStatus) throws -> [JobApplication] {
        let rawValue = status.rawValue
        let predicate = #Predicate<PersistedJobApplication> { $0.statusRawValue == rawValue }
        let descriptor = FetchDescriptor<PersistedJobApplication>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.dateApplied, order: .reverse)]
        )
        let results = try context.fetch(descriptor)
        return try results.map { try $0.toJobApplication() }
    }

    func update(_ application: JobApplication) throws {
        guard let persisted = try findPersisted(id: application.id) else {
            throw JobApplicationStoreError.notFound
        }
        persisted.companyName    = application.companyName
        persisted.jobTitle       = application.jobTitle
        persisted.jobDescription = application.jobDescription
        persisted.statusRawValue = application.status.rawValue
        persisted.dateApplied    = application.dateApplied
        persisted.lastUpdated    = application.lastUpdated
        try context.save()
    }

    func updateStatus(id: UUID, to status: ApplicationStatus) throws {
        guard let persisted = try findPersisted(id: id) else {
            throw JobApplicationStoreError.notFound
        }
        persisted.statusRawValue = status.rawValue
        persisted.lastUpdated    = Date()
        try context.save()
    }

    func delete(id: UUID) throws {
        guard let persisted = try findPersisted(id: id) else {
            throw JobApplicationStoreError.notFound
        }
        context.delete(persisted)
        try context.save()
    }

    func deleteAll() throws {
        let descriptor = FetchDescriptor<PersistedJobApplication>()
        let all = try context.fetch(descriptor)
        for item in all {
            context.delete(item)
        }
        try context.save()
    }

    func count() throws -> Int {
        let descriptor = FetchDescriptor<PersistedJobApplication>()
        return try context.fetchCount(descriptor)
    }

    // MARK: - Private helpers

    private func findPersisted(id: UUID) throws -> PersistedJobApplication? {
        let predicate = #Predicate<PersistedJobApplication> { $0.id == id }
        var descriptor = FetchDescriptor<PersistedJobApplication>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}
