// TestFixtures.swift
// JobTrackerTests
//
// Shared test helpers used across multiple test files in this target.

import Foundation
@testable import JobTracker

// MARK: - Factory

/// Creates a `JobApplication` with sensible defaults for use in tests.
/// Override only the parameters relevant to the test at hand.
func makeApplication(
    companyName: String        = "Acme Corp",
    jobTitle: String           = "iOS Engineer",
    jobDescription: String     = "Build great apps",
    status: ApplicationStatus  = .pending
) -> JobApplication {
    JobApplication(
        companyName: companyName,
        jobTitle: jobTitle,
        jobDescription: jobDescription,
        status: status
    )
}
