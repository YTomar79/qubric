//
//  PuzzleComparisonBoard.swift
//  Qubric
//
//  Side-by-side comparison board.
//

import SwiftUI

struct PuzzleComparisonBoard: View {
    let puzzle: QuantumPuzzle
    let currentState: [Complex]
    let previousState: [Complex]?
    let goalState: [Complex]
    let focusedQubit: Int?
    let gateEffect: GateEffect?
    let spotDifference: PuzzleSpotDifference?
    let spotComplete: Bool
    let showNotationPreference: Bool
    var embedded = false
    var roomyRows = false
    var rowMinHeight: CGFloat? = nil
    let onSpotChoice: (Bool) -> Void

    private var showNotation: Bool {
        puzzle.showNotation || showNotationPreference
    }

    private var currentProbabilities: [ProbabilityEntry] {
        QubricQuantumEngine.probabilities(for: currentState)
    }

    private var goalProbabilities: [ProbabilityEntry] {
        QubricQuantumEngine.probabilities(for: goalState)
    }

    private var usesPlainDeltaLanguage: Bool {
        puzzle.id.hasPrefix("1.") && previousState == nil
    }

    private var compactRows: Bool {
        currentProbabilities.count > 4
    }

    private var basisColumnWidth: CGFloat {
        let bitCount = currentProbabilities.map(\.label.count).max() ?? 1
        guard showNotation else {
            guard bitCount > 1 else { return compactRows ? 42 : 32 }
            let minimum: CGFloat = compactRows ? 110 : 86
            return max(minimum, CGFloat(bitCount) * 28 + 32)
        }
        guard bitCount > 1 else { return 32 }
        let minimum: CGFloat = compactRows ? 138 : 110
        return max(minimum, CGFloat(bitCount) * 28 + 60)
    }

    private var rowSeparatorLeadingInset: CGFloat {
        12 + basisColumnWidth
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(currentProbabilities.enumerated()), id: \.element.id) { index, current in
                let goal = goalProbabilities.indices.contains(index) ? goalProbabilities[index] : ProbabilityEntry(label: current.label, value: 0)
                DistributionOutcomeRow(
                    label: current.label,
                    changed: rowChanged(index: index, current: current),
                    delta: rowDelta(
                        current: current,
                        goal: goal,
                        currentPhase: currentState.indices.contains(index) ? phaseLabel(for: currentState[index]) : "",
                        goalPhase: goalState.indices.contains(index) ? phaseLabel(for: goalState[index]) : "",
                        plainLanguage: usesPlainDeltaLanguage
                    ),
                    current: PuzzleComparisonCellModel(
                        percent: current.value,
                        phase: currentState.indices.contains(index) ? phaseLabel(for: currentState[index]) : ""
                    ),
                    goal: PuzzleComparisonCellModel(
                        percent: goal.value,
                        phase: goalState.indices.contains(index) ? phaseLabel(for: goalState[index]) : ""
                    ),
                    showNotation: showNotation,
                    showProbabilities: puzzle.showProbabilities,
                    showPhase: puzzle.showPhase,
                    focusedQubit: focusedQubit,
                    noOpEffect: gateEffect?.noOp == true,
                    gateEffectID: gateEffect?.id ?? 0,
                    spotDifference: spotDifference,
                    spotComplete: spotComplete,
                    compact: compactRows,
                    basisColumnWidth: basisColumnWidth,
                    minHeight: rowMinHeight ?? (roomyRows ? 132 : nil),
                    onSpotChoice: onSpotChoice
                )

                if index < currentProbabilities.count - 1 {
                    Rectangle()
                        .fill(Color.qubricLine)
                        .frame(height: QubricTheme.hairlineWidth)
                        .padding(.leading, rowSeparatorLeadingInset)
                }
            }

            if showNotation {
                Text("Now \(QubricQuantumEngine.format(currentState)) · Goal \(QubricQuantumEngine.format(goalState))")
                .font(.custom("JetBrainsMono-Regular", size: QubricTheme.iPadFontSize(12), relativeTo: .caption))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .minimumScaleFactor(0.65)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.top, 8)
                .padding(.bottom, 10)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color.qubricLine)
                        .frame(height: QubricTheme.hairlineWidth)
                }
            }
        }
        .padding(.vertical, 1)
        .background(embedded ? Color.clear : Color.qubricSurface)
        .clipShape(RoundedRectangle(cornerRadius: QubricTheme.cornerRadius, style: .continuous))
        .overlay {
            if !embedded {
                RoundedRectangle(cornerRadius: QubricTheme.cornerRadius, style: .continuous)
                    .stroke(Color.qubricTileLine, lineWidth: QubricTheme.tileStrokeWidth)
            }
        }
    }

    private func phaseLabel(for amp: Complex) -> String {
        guard amp.magnitudeSquared > QubricQuantumEngine.epsilon else { return "" }
        return amp.re < -QubricQuantumEngine.epsilon || amp.im < -QubricQuantumEngine.epsilon ? "-" : "+"
    }

    private func rowChanged(index: Int, current: ProbabilityEntry) -> Bool {
        guard
            let previousState,
            previousState.indices.contains(index),
            currentState.indices.contains(index)
        else { return false }

        let previous = QubricQuantumEngine.probabilities(for: previousState)
        guard previous.indices.contains(index) else { return false }
        let previousPhase = phaseLabel(for: previousState[index])
        let currentPhase = phaseLabel(for: currentState[index])
        return abs(previous[index].value - current.value) >= 0.5
            || (!previousPhase.isEmpty && !currentPhase.isEmpty && previousPhase != currentPhase)
    }

    private func rowDelta(current: ProbabilityEntry, goal: ProbabilityEntry, currentPhase: String, goalPhase: String, plainLanguage: Bool) -> String {
        if plainLanguage { return "" }

        let diff = goal.value - current.value
        let phaseDiff = current.value > 0.05 && goal.value > 0.05 && !currentPhase.isEmpty && !goalPhase.isEmpty && currentPhase != goalPhase

        if abs(diff) >= 0.5 {
            return diff > 0 ? "+\(comparisonPercentLabel(abs(diff)))" : "-\(comparisonPercentLabel(abs(diff)))"
        }
        if phaseDiff { return "sign" }
        return ""
    }
}

struct PuzzleComparisonCellModel: Equatable {
    let percent: Double
    let phase: String

    var active: Bool {
        percent > 0.05
    }
}

private struct DistributionOutcomeRow: View {
    let label: String
    let changed: Bool
    let delta: String
    let current: PuzzleComparisonCellModel
    let goal: PuzzleComparisonCellModel
    let showNotation: Bool
    let showProbabilities: Bool
    let showPhase: Bool
    let focusedQubit: Int?
    let noOpEffect: Bool
    let gateEffectID: Int
    let spotDifference: PuzzleSpotDifference?
    let spotComplete: Bool
    let compact: Bool
    let basisColumnWidth: CGFloat
    let minHeight: CGFloat?
    let onSpotChoice: (Bool) -> Void

    var body: some View {
        HStack(alignment: .center, spacing: compact ? 8 : 10) {
            PuzzleBasisLabel(bits: label, showNotation: showNotation, focusedQubit: focusedQubit)
                .frame(minWidth: basisColumnWidth, idealWidth: basisColumnWidth, maxWidth: basisColumnWidth, alignment: .leading)
                .layoutPriority(1)

            VStack(alignment: .leading, spacing: compact ? 4 : 6) {
                if showProbabilities {
                    HStack(alignment: .firstTextBaseline, spacing: 7) {
                        ValueLabel(title: "Now", value: comparisonPercentLabel(current.percent), compact: true)
                        phaseMark(for: current, stateRole: "current")
                        Spacer(minLength: 6)
                        if !delta.isEmpty {
                            Text(delta)
                                .font(.caption.monospacedDigit().weight(.semibold))
                                .foregroundStyle(Color.qubricPrimaryStrong)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                        ValueLabel(title: "Goal", value: comparisonPercentLabel(goal.percent), compact: true)
                        phaseMark(for: goal, stateRole: "goal")
                    }

                    DistributionTrack(
                        currentPercent: current.percent,
                        goalPercent: goal.percent,
                        changed: changed,
                        noOpEffect: noOpEffect,
                        gateEffectID: gateEffectID,
                        phase: showPhase ? current.phase : ""
                    )
                    .frame(height: compact ? 10 : 14)
                }

                if !showProbabilities {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        ValueLabel(title: "Now", value: comparisonPercentLabel(current.percent), compact: false)
                        phaseMark(for: current, stateRole: "current")
                        Spacer(minLength: 8)
                        if !delta.isEmpty {
                            Text(delta)
                                .font(.caption.monospacedDigit().weight(.semibold))
                                .foregroundStyle(Color.qubricPrimaryStrong)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                        ValueLabel(title: "Goal", value: comparisonPercentLabel(goal.percent), compact: false)
                        phaseMark(for: goal, stateRole: "goal")
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, compact ? 6 : 10)
        .frame(minHeight: minHeight)
        .background(Color.qubricSurface)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Outcome \(label). Now \(comparisonPercentLabel(current.percent)). Goal \(comparisonPercentLabel(goal.percent)).")
    }

    @ViewBuilder
    private func phaseMark(for model: PuzzleComparisonCellModel, stateRole: String) -> some View {
        if showPhase, model.active, !model.phase.isEmpty {
            let spotTarget = spotDifference?.state == stateRole
                && spotDifference?.basis == label
                && spotDifference?.phase == model.phase
            let interactive = spotDifference != nil && !spotComplete
            let mark = Text(model.phase)
                .font(.custom("JetBrainsMono-SemiBold", size: QubricTheme.iPadFontSize(13), relativeTo: .caption))
                .foregroundStyle(spotTarget ? Color.qubricPhase : model.phase == "-" ? Color.qubricPhase : Color.secondary)
                .frame(width: 22, height: 20)
                .background(spotTarget ? Color.qubricPhase.opacity(0.18) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay {
                    if spotTarget {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(Color.qubricPhase, lineWidth: 1.5)
                    }
                }

            if interactive {
                Button {
                    onSpotChoice(spotTarget)
                } label: {
                    mark
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(stateRole) \(label) sign \(model.phase)")
            } else {
                mark
            }
        }
    }
}

private struct DistributionTrack: View {
    let currentPercent: Double
    let goalPercent: Double
    let changed: Bool
    let noOpEffect: Bool
    let gateEffectID: Int
    let phase: String
    @State private var shaking = false

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let currentWidth = barWidth(for: currentPercent, in: width)
            let targetX = targetOffset(for: goalPercent, in: width)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.qubricTrack)
                    .frame(height: 5)

                Capsule()
                    .fill(fillColor)
                    .frame(width: currentWidth, height: 5)

                Capsule()
                    .fill(Color.primary.opacity(0.78))
                    .frame(width: 2, height: 15)
                    .offset(x: targetX)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .offset(x: shaking ? 2 : 0)
            .animation(.easeInOut(duration: 0.18), value: currentPercent)
            .animation(.easeInOut(duration: 0.18), value: goalPercent)
        }
        .onChange(of: gateEffectID) { _, _ in
            guard noOpEffect else { return }
            withAnimation(.linear(duration: 0.045).repeatCount(4, autoreverses: true)) {
                shaking = true
            }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 180_000_000)
                shaking = false
            }
        }
    }

    private var fillColor: Color {
        if phase == "-" { return .qubricPhase }
        return changed ? .qubricPrimaryStrong : .qubricPrimary
    }

    private func barWidth(for percent: Double, in width: CGFloat) -> CGFloat {
        guard percent > 0.05 else { return 0 }
        return max(3, width * min(max(percent, 0), 100) / 100)
    }

    private func targetOffset(for percent: Double, in width: CGFloat) -> CGFloat {
        let raw = width * min(max(percent, 0), 100) / 100
        return min(max(raw - 1, 0), max(width - 2, 0))
    }
}

private struct ValueLabel: View {
    let title: String
    let value: String
    let compact: Bool

    var body: some View {
        Text(compact ? value : "\(title) \(value)")
            .font(.caption2.monospacedDigit().weight(.semibold))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }
}

struct PuzzleBasisLabel: View {
    let bits: String
    let showNotation: Bool
    let focusedQubit: Int?

    var body: some View {
        if showNotation, bits.count > 1, focusedQubit != nil {
            HStack(spacing: 0) {
                Text("|")
                ForEach(Array(bits.enumerated()), id: \.offset) { index, bit in
                    Text(String(bit))
                        .padding(.horizontal, 2)
                        .background(index == focusedQubit ? Color.qubricPrimary.opacity(0.18) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                }
                Text(">")
            }
            .font(.custom("JetBrainsMono-SemiBold", size: QubricTheme.iPadFontSize(17), relativeTo: .body))
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .fixedSize(horizontal: true, vertical: false)
        } else {
            Text(showNotation ? "|\(bits)>" : bits)
                .font(.custom("JetBrainsMono-SemiBold", size: QubricTheme.iPadFontSize(17), relativeTo: .body))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .fixedSize(horizontal: true, vertical: false)
        }
    }
}

func comparisonPercentLabel(_ value: Double) -> String {
    value.truncatingRemainder(dividingBy: 1) == 0
        ? "\(Int(value))%"
        : String(format: "%.1f%%", value)
}
