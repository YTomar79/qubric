//
//  ActiveTaskRow.swift
//  Qubric
//
//  Row view for an in-progress task item.
//

import SwiftUI

struct ActiveTaskRow: View {
    let text: String
    let last: String?
    let isComplete: Bool
    let isFailed: Bool
    let isSaving: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if let statusImage {
                Image(systemName: statusImage)
                    .font(.system(size: QubricTheme.iPadFontSize(16), weight: .semibold))
                    .foregroundStyle(statusColor)
                    .frame(width: 22, height: 22)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(text)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(primaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)

                if let last {
                    Text(last)
                        .font(.footnote)
                        .foregroundStyle(last == "Bars didn't move." ? Color.qubricPhase : Color.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.vertical, 1)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var statusImage: String? {
        if isSaving { return "arrow.triangle.2.circlepath" }
        if isFailed { return "exclamationmark.triangle" }
        if isComplete { return "checkmark" }
        return nil
    }

    private var primaryTextColor: Color {
        if isComplete { return .qubricSuccess }
        return .primary
    }

    private var statusColor: Color {
        if isFailed { return .qubricError }
        return primaryTextColor
    }
}
