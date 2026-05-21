// StatusBadgeView.swift
// JobTracker

import SwiftUI

/// A pill-shaped badge that displays an ApplicationStatus label with a
/// background colour that communicates urgency and finality.
struct StatusBadgeView: View {

    let status: ApplicationStatus

    // MARK: - Computed properties under test

    /// The background colour that corresponds to `status`.
    var badgeColor: Color {
        switch status {
        case .pending:   return .orange
        case .applied:   return .blue
        case .inProcess: return .purple
        case .waiting:   return .yellow
        case .hired:     return .green
        case .ghosted:   return .red
        }
    }

    /// The human-readable label rendered inside the badge.
    var badgeLabel: String {
        status.displayLabel
    }

    /// True when the status is terminal (hired or ghosted).
    var isTerminal: Bool {
        status.isTerminal
    }

    // MARK: - View body

    var body: some View {
        Text(badgeLabel)
            .font(.caption)
            .fontWeight(isTerminal ? .semibold : .medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(badgeColor.opacity(0.2))
            .foregroundColor(badgeColor)
            .clipShape(Capsule())
    }
}

#Preview {
    VStack(spacing: 8) {
        ForEach(ApplicationStatus.allCases, id: \.self) { status in
            StatusBadgeView(status: status)
        }
    }
    .padding()
}
