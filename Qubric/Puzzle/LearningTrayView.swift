//
//  LearningTrayView.swift
//  Qubric
//
//  Inline learning and hint tray.
//

import SwiftUI

struct LearningTrayItem: Identifiable {
    let id = UUID()
    let title: String
    let body: String
    var monospaced = false

    static func items(
        puzzle: QuantumPuzzle,
        message: String,
        isFailed: Bool,
        isSaving: Bool,
        previousState: [Complex]?,
        currentState: [Complex],
        hintsUsed: Int,
        predictionChoice: String?,
        predictionRevealed: Bool
    ) -> [LearningTrayItem] {
        var items: [LearningTrayItem] = []

        if isSaving {
            items.append(LearningTrayItem(title: "Saving", body: message))
        }

        if hintsUsed > 0, puzzle.hints.indices.contains(hintsUsed - 1) {
            items.append(LearningTrayItem(title: "Hint \(hintsUsed)", body: puzzle.hints[hintsUsed - 1]))
        }

        if let prediction = puzzle.prediction, let predictionChoice, predictionRevealed {
            items.append(
                LearningTrayItem(
                    title: predictionChoice == prediction.correctOptionId ? "Prediction matched" : "Prediction differed",
                    body: prediction.explanation
                )
            )
        }

        if let previousState {
            if !isFailed, !isSaving, hintsUsed == 0 {
                items.append(LearningTrayItem(title: "Last move", body: message))
            }
            items.append(
                LearningTrayItem(
                    title: "Visible change",
                    body: lastMoveChanges(previousState: previousState, currentState: currentState, showPhase: puzzle.showPhase).joined(separator: " · "),
                    monospaced: true
                )
            )
        }

        if puzzle.showPhase && puzzle.spotDifference == nil {
            items.append(LearningTrayItem(title: "Signs", body: "+ paths add; - paths cancel matching paths."))
        }

        if hintsUsed > 1 {
            for (index, hint) in puzzle.hints.prefix(hintsUsed - 1).enumerated() {
                items.append(LearningTrayItem(title: "Hint \(index + 1)", body: hint))
            }
        }

        if !puzzle.concept.isEmpty && hintsUsed > 0 {
            items.append(LearningTrayItem(title: "Why", body: puzzle.concept))
        }

        return items.filter { !$0.body.isEmpty }
    }

    private static func lastMoveChanges(previousState: [Complex], currentState: [Complex], showPhase: Bool) -> [String] {
        guard !previousState.isEmpty, previousState.count == currentState.count else { return [] }

        let before = QubricQuantumEngine.probabilities(for: previousState)
        let after = QubricQuantumEngine.probabilities(for: currentState)
        guard !before.isEmpty, before.count == after.count else { return [] }

        let items = before.enumerated().compactMap { index, entry -> String? in
            guard after.indices.contains(index) else { return nil }
            let next = after[index]
            if abs(entry.value - next.value) >= 0.5 {
                return "\(entry.label): \(comparisonPercentLabel(entry.value)) -> \(comparisonPercentLabel(next.value))"
            }

            let beforePhase = phaseLabel(for: previousState[index])
            let afterPhase = phaseLabel(for: currentState[index])
            if showPhase, next.value > 0.05, !beforePhase.isEmpty, !afterPhase.isEmpty, beforePhase != afterPhase {
                return "\(entry.label): sign \(beforePhase) -> \(afterPhase)"
            }
            return nil
        }

        return items.isEmpty ? ["No visible bar change. It may matter later."] : Array(items.prefix(4))
    }

    private static func phaseLabel(for amp: Complex) -> String {
        guard amp.magnitudeSquared > QubricQuantumEngine.epsilon else { return "" }
        return amp.re < -QubricQuantumEngine.epsilon || amp.im < -QubricQuantumEngine.epsilon ? "-" : "+"
    }
}

struct LearningTrayView: View {
    let items: [LearningTrayItem]
    let startsOpen: Bool
    @State private var isExpanded: Bool

    init(items: [LearningTrayItem], startsOpen: Bool) {
        self.items = items
        self.startsOpen = startsOpen
        _isExpanded = State(initialValue: startsOpen)
    }

    private var visibleItems: [LearningTrayItem] {
        isExpanded ? items : Array(items.prefix(1))
    }

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(visibleItems) { item in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.title)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text(item.body)
                            .font(item.monospaced ? .caption.monospaced() : .footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 9)

                    if item.id != visibleItems.last?.id {
                        Divider()
                    }
                }
            }
            .padding(.top, 8)
        } label: {
            Label(startsOpen ? (visibleItems.first?.title ?? "Review") : "Review", systemImage: "text.bubble")
                .font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.qubricSurface)
        .clipShape(RoundedRectangle(cornerRadius: QubricTheme.smallCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: QubricTheme.smallCornerRadius, style: .continuous)
                .stroke(Color.qubricTileLine, lineWidth: QubricTheme.tileStrokeWidth)
        }
        .tint(Color.qubricPrimary)
    }
}
