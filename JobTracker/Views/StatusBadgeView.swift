// StatusBadgeView.swift
// JobTracker

import SwiftUI

/// A pill-shaped badge — solid filled background with white label for maximum contrast.
struct StatusBadgeView: View {

    let status: ApplicationStatus

    // MARK: - Computed properties under test

    var badgeColor: Color {
        switch status {
        case .pending:   return Color(red: 0.95, green: 0.60, blue: 0.10) // orange-amber
        case .applied:   return Color(red: 0.20, green: 0.50, blue: 0.90) // blue
        case .inProcess: return Color(red: 0.55, green: 0.25, blue: 0.90) // purple
        case .waiting:   return Color(red: 0.10, green: 0.65, blue: 0.75) // cyan-teal
        case .hired:     return Color(red: 0.13, green: 0.68, blue: 0.30) // green
        case .ghosted:   return Color(red: 0.85, green: 0.20, blue: 0.20) // red
        }
    }

    var badgeLabel: String { status.displayLabel }

    var isTerminal: Bool { status.isTerminal }

    // MARK: - View body

    var body: some View {
        Text(badgeLabel)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(badgeColor)
            .clipShape(Capsule())
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 8) {
        ForEach(ApplicationStatus.allCases, id: \.self) { status in
            StatusBadgeView(status: status)
        }
    }
    .padding()
    .frame(width: 200)
}
