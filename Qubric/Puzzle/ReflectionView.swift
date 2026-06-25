//
//  ReflectionView.swift
//  Qubric
//
//  Post-solve reflection prompt.
//

import SwiftUI

struct ReflectionInlineView: View {
    let reflection: PuzzlePrediction
    var onAnswer: (Bool) -> Void = { _ in }
    @State private var choice: String?

    private var isAnswered: Bool {
        choice != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Check understanding")
                .font(.subheadline.weight(.semibold))
            Text(reflection.prompt)
                .font(.subheadline)

            ForEach(reflection.options) { option in
                Button {
                    answer(option.id)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: iconName(for: option))
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(iconColor(for: option))
                            .frame(width: 18)
                        Text(option.label)
                            .font(.subheadline.weight(.semibold))
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .background(optionBackground(for: option))
                .clipShape(RoundedRectangle(cornerRadius: QubricTheme.smallCornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: QubricTheme.smallCornerRadius, style: .continuous)
                        .stroke(optionStroke(for: option), lineWidth: QubricTheme.hairlineWidth)
                }
                .disabled(isAnswered)
            }

            if isAnswered {
                Text(reflection.explanation)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(Color.qubricSecondaryGrouped)
        .clipShape(RoundedRectangle(cornerRadius: QubricTheme.cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: QubricTheme.cornerRadius, style: .continuous)
                .stroke(Color.qubricTileLine, lineWidth: QubricTheme.tileStrokeWidth)
        }
    }

    private func answer(_ id: String) {
        guard !isAnswered else { return }
        choice = id
        onAnswer(id == reflection.correctOptionId)
    }

    private func iconName(for option: PredictionOption) -> String {
        guard isAnswered else { return "circle" }
        if option.id == reflection.correctOptionId { return "checkmark.circle.fill" }
        if option.id == choice { return "xmark.circle.fill" }
        return "circle"
    }

    private func iconColor(for option: PredictionOption) -> Color {
        guard isAnswered else { return .secondary }
        if option.id == reflection.correctOptionId { return .qubricSuccess }
        if option.id == choice { return .qubricError }
        return .secondary
    }

    private func optionBackground(for option: PredictionOption) -> some ShapeStyle {
        guard isAnswered else { return AnyShapeStyle(Color(.systemBackground)) }
        if option.id == reflection.correctOptionId {
            return AnyShapeStyle(Color.qubricSuccess.opacity(0.14))
        }
        if option.id == choice {
            return AnyShapeStyle(Color.qubricError.opacity(0.12))
        }
        return AnyShapeStyle(Color(.systemBackground).opacity(0.65))
    }

    private func optionStroke(for option: PredictionOption) -> Color {
        guard isAnswered else { return Color.qubricLine }
        if option.id == reflection.correctOptionId { return Color.qubricSuccess.opacity(0.72) }
        if option.id == choice { return Color.qubricError.opacity(0.62) }
        return Color.qubricLine
    }
}
