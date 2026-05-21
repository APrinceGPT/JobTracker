// ApplicationStatus.swift
// JobTracker

import Foundation

/// Represents every lifecycle state a job application can occupy.
enum ApplicationStatus: String, CaseIterable, Codable, Equatable {
    case pending
    case applied
    case inProcess
    case waiting
    case hired
    case ghosted

    /// Returns true when transitioning from this status to `other` is a valid business move.
    func canTransition(to other: ApplicationStatus) -> Bool {
        guard other != self else { return false }
        switch self {
        case .pending:   return other == .applied
        case .applied:   return [.inProcess, .waiting, .ghosted].contains(other)
        case .inProcess: return [.hired, .ghosted].contains(other)
        case .waiting:   return [.inProcess, .ghosted].contains(other)
        case .hired:     return false
        case .ghosted:   return false
        }
    }

    /// True when the status represents a terminal lifecycle state (no further transitions allowed).
    var isTerminal: Bool {
        self == .hired || self == .ghosted
    }

    /// Human-readable label for UI display.
    var displayLabel: String {
        switch self {
        case .pending:   return "Pending"
        case .applied:   return "Applied"
        case .inProcess: return "In Process"
        case .waiting:   return "Waiting"
        case .hired:     return "Hired"
        case .ghosted:   return "Ghosted"
        }
    }
}
