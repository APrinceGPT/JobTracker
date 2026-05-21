// StatusBadgeView.swift
// JobTracker

import SwiftUI

/// A pill-shaped badge with a solid color dot and label for immediate visual identification.
struct StatusBadgeView: View {

    let status: ApplicationStatus

    // MARK: - Computed properties under test

    var badgeColor: Color {
        switch status {
        case .pending:   return Color(hue: 0.08,  saturation: 0.85, brightness: 0.95) // amber
        case .applied:   return Color(hue: 0.60,  saturation: 0.75, brightness: 0.90) // steel blue
        case .inProcess: return Color(hue: 0.75,  saturation: 0.65, brightness: 0.85) // violet
        case .waiting:   return Color(hue: 0.55,  saturation: 0.70, brightness: 0.80) // teal
        case .hired:     return Color(hue: 0.38,  saturation: 0.80, brightness: 0.72) // forest green
        case .ghosted:   return Color(hue: 0.00,  saturation: 0.60, brightness: 0.75) // muted red
        }
    }

    var badgeLabel: String { status.displayLabel }

    var isTerminal: Bool { status.isTerminal }

    // MARK: - View body

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(badgeColor)
                .frame(width: 7, height: 7)
            Text(badgeLabel)
                .font(.system(size: 11, weight: isTerminal ? .semibold : .medium))
                .foregroundStyle(isTerminal ? badgeColor : .primary)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(badgeColor.opacity(isTerminal ? 0.15 : 0.10))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .strokeBorder(badgeColor.opacity(0.25), lineWidth: 0.5)
        )
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
