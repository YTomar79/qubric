//
//  PredictionCard.swift
//  Qubric
//
//  Card for capturing the player's prediction.
//

import SwiftUI

struct PredictionCard: View {
    let prediction: PuzzlePrediction
    let choice: String?
    let reveal: Bool
    let onChoose: (String) -> Void

    private var isAnswered: Bool {
        choice != nil
    }

    private var pickedCorrect: Bool {
        choice == prediction.correctOptionId
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(prediction.prompt)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(prediction.options) { option in
                Button {
                    onChoose(option.id)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: iconName(for: option))
                            .font(.footnote)
                            .foregroundStyle(iconColor(for: option))
                            .frame(width: 16)
                        Text(option.label)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
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
                Text(reveal ? prediction.explanation : "Prediction locked. Run the gate.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: QubricTheme.cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: QubricTheme.cornerRadius, style: .continuous)
                .stroke(Color.qubricTileLine, lineWidth: QubricTheme.tileStrokeWidth)
        }
    }

    private func iconName(for option: PredictionOption) -> String {
        guard isAnswered else { return "circle" }
        if !reveal { return option.id == choice ? "record.circle" : "circle" }
        if option.id == prediction.correctOptionId { return "checkmark.circle.fill" }
        if option.id == choice { return "xmark.circle.fill" }
        return "circle"
    }

    private func iconColor(for option: PredictionOption) -> Color {
        guard isAnswered else { return .secondary }
        if !reveal { return option.id == choice ? .qubricPrimary : .secondary }
        if option.id == prediction.correctOptionId { return .qubricSuccess }
        if option.id == choice { return .qubricError }
        return .secondary
    }

    private func optionBackground(for option: PredictionOption) -> some ShapeStyle {
        guard isAnswered else { return AnyShapeStyle(Color(.systemBackground)) }
        if !reveal {
            return option.id == choice
                ? AnyShapeStyle(Color.qubricPrimary.opacity(0.12))
                : AnyShapeStyle(Color(.systemBackground))
        }
        if option.id == prediction.correctOptionId {
            return AnyShapeStyle(Color.qubricSuccess.opacity(0.14))
        }
        if option.id == choice {
            return AnyShapeStyle(Color.qubricError.opacity(0.12))
        }
        return AnyShapeStyle(Color(.systemBackground).opacity(0.65))
    }

    private func optionStroke(for option: PredictionOption) -> Color {
        guard isAnswered else { return Color.qubricLine }
        if !reveal {
            return option.id == choice ? Color.qubricPrimary.opacity(0.72) : Color.qubricLine
        }
        if option.id == prediction.correctOptionId { return Color.qubricSuccess.opacity(0.72) }
        if option.id == choice { return Color.qubricError.opacity(0.62) }
        return Color.qubricLine
    }
}
