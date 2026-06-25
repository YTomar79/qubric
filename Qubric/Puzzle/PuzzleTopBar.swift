//
//  PuzzleTopBar.swift
//  Qubric
//
//  Top bar for the puzzle screen.
//

import SwiftUI

struct PuzzleTopBar: View {
    let puzzle: QuantumPuzzle
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            navigationRow
            objectiveLine
        }
        .padding(.horizontal, 16)
        .padding(.top, 9)
        .padding(.bottom, 11)
        .background(Color.qubricGrouped)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.qubricLine)
                .frame(height: QubricTheme.hairlineWidth)
        }
    }

    private var navigationRow: some View {
        ZStack {
            Text(puzzle.title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .padding(.horizontal, 84)
                .frame(maxWidth: .infinity)

            HStack(alignment: .center, spacing: 12) {
                backButton
                Spacer(minLength: 12)
            }
        }
        .frame(minHeight: 34)
    }

    private var backButton: some View {
        Button(action: onBack) {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.medium))
                Text("Map")
                    .font(.callout.weight(.medium))
            }
            .frame(minHeight: 34, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.qubricPrimary)
        .accessibilityLabel("Back to map")
    }

    private var objectiveLine: some View {
        Text(puzzle.objective)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .frame(maxWidth: .infinity)
    }
}
