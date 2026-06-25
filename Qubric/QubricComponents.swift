//
//  QubricComponents.swift
//  Qubric
//
//  Shared, reusable UI components.
//

import SwiftUI

struct QubricLogo: View {
    var subtitle: String?
    var titleSize: CGFloat = 22

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Qubric")
                .font(.system(size: QubricTheme.iPadFontSize(titleSize), weight: .semibold))
                .foregroundStyle(.primary)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct ProgressHeader: View {
    let profile: PlayerProfile

    private var level: Int {
        QubricData.level(for: profile.xp)
    }

    private var levelProgress: Double {
        let levelBase = (level - 1) * 300
        return max(0, min(1, Double(profile.xp - levelBase) / 300.0))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(profile.name)
                        .font(.title2.weight(.bold))
                    Text("Cloud account")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("Level \(level)")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.qubricPrimary)
            }
            ProgressView(value: levelProgress)
                .tint(.qubricPrimary)
            HStack {
                Text("\(profile.xp) XP")
                Spacer()
                Text("\(profile.completed.values.filter { $0 }.count) solved")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct QubricSectionTitleRow: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.headline.weight(.semibold))
            .foregroundStyle(.primary)
            .padding(.vertical, 4)
    }
}

struct QubricPageHeader: View {
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: QubricTheme.iPadFontSize(42), weight: .bold))
                .foregroundStyle(.primary)
                .accessibilityAddTraits(.isHeader)
                .padding(.horizontal, 16)
                .padding(.top, QubricTheme.isPad ? 58 : 94)
                .padding(.bottom, QubricTheme.isPad ? 28 : 24)

            Rectangle()
                .fill(Color.qubricLine.opacity(0.55))
                .frame(height: QubricTheme.hairlineWidth)
        }
        .background(Color.qubricGrouped)
    }
}

struct PuzzleRow: View {
    let puzzle: QuantumPuzzle
    let unlocked: Bool
    let completed: Bool
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: 12) {
                statusIcon
                VStack(alignment: .leading, spacing: 3) {
                    Text(puzzle.title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(unlocked ? "\(puzzle.difficulty) · \(puzzle.xp) XP · Puzzle \(puzzle.id)" : "Locked · Complete the previous puzzle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(unlocked ? puzzle.objective : "Finish the earlier circuit to continue.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 4)
        }
        .disabled(!unlocked)
        .buttonStyle(.plain)
        .opacity(unlocked ? 1 : 0.55)
    }

    private var statusIcon: some View {
        RoundedRectangle(cornerRadius: QubricTheme.smallCornerRadius, style: .continuous)
            .fill(Color(.systemGray6))
            .frame(width: 42, height: 42)
            .overlay(
                Image(systemName: completed ? "checkmark.circle.fill" : unlocked ? "play.circle" : "lock.fill")
                    .font(.system(size: QubricTheme.iPadFontSize(18), weight: .semibold))
                    .foregroundStyle(completed ? Color.qubricSuccess : unlocked ? Color.qubricPrimary : Color.secondary)
            )
    }
}

struct GateButton: View {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorScheme) private var colorScheme

    let gate: String
    let isSuggested: Bool
    var subtitle: String? = nil
    var showsSubtitle = false
    var fillsWidth = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            label
        }
        .buttonStyle(.plain)
        .frame(width: fillsWidth ? nil : buttonWidth, height: buttonHeight)
        .frame(maxWidth: fillsWidth ? .infinity : nil)
        .contentShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        .background(backgroundColor, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
        .foregroundStyle(foregroundColor)
        .overlay {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .stroke(borderColor, lineWidth: QubricTheme.hairlineWidth)
        }
        .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: 1)
        .opacity(isEnabled ? 1 : 0.58)
        .accessibilityLabel("Gate \(gate)")
        .accessibilityHint(subtitle ?? gateHelp(gate))
    }

    private var label: some View {
        VStack(spacing: showsSubtitle ? 3 : 0) {
            PaletteGateGlyph(gate: gate, isSuggested: isSuggested && isEnabled)

            if showsSubtitle, let subtitle {
                Text(subtitle)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(subtitleColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
        }
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private var buttonWidth: CGFloat {
        if showsSubtitle {
            return QubricTheme.iPadMetric(gate.count > 5 ? 88 : gate.count > 2 ? 78 : 68)
        }
        return QubricTheme.iPadMetric(max(48, glyphWidth + 10))
    }

    private var buttonHeight: CGFloat {
        QubricTheme.iPadMetric(showsSubtitle ? 52 : 42)
    }

    private var backgroundColor: Color {
        if !isEnabled { return Color.qubricSecondaryGrouped }
        if isSuggested { return Color.qubricPrimary }
        return Color.qubricSecondaryGrouped
    }

    private var foregroundColor: Color {
        if !isEnabled { return Color.secondary }
        if isSuggested { return Color.white }
        return Color.primary
    }

    private var borderColor: Color {
        if !isEnabled { return Color.qubricLine }
        return isSuggested ? Color.qubricPrimary : Color.qubricLine.opacity(0.72)
    }

    private var subtitleColor: Color {
        if !isEnabled { return Color.secondary }
        return isSuggested ? Color.white.opacity(0.78) : Color.secondary
    }

    private var shadowColor: Color {
        guard colorScheme == .light else { return .clear }
        return Color.black.opacity(isEnabled ? 0.04 : 0)
    }

    private var shadowRadius: CGFloat {
        colorScheme == .light ? 2 : 0
    }

    private var glyphWidth: CGFloat {
        gate.count > 5 ? 62 : gate.count > 2 ? 48 : 34
    }
}

private struct PaletteGateGlyph: View {
    let gate: String
    let isSuggested: Bool

    var body: some View {
        Text(gate)
            .font(.custom("JetBrainsMono-SemiBold", size: QubricTheme.iPadFontSize(glyphTextSize), relativeTo: .body))
            .foregroundStyle(squareText)
            .minimumScaleFactor(0.72)
            .lineLimit(1)
            .padding(.horizontal, 4)
            .frame(width: QubricTheme.iPadMetric(glyphWidth), height: QubricTheme.iPadMetric(25))
    }

    private var glyphWidth: CGFloat {
        gate.count > 5 ? 62 : gate.count > 2 ? 48 : 34
    }

    private var glyphTextSize: CGFloat {
        gate.count > 5 ? 13 : gate.count > 2 ? 15 : 20
    }

    private var squareText: Color {
        isSuggested ? Color.white : Color.primary
    }
}

struct QuantumStateVisual: View {
    let title: String
    let state: [Complex]
    var showNotation = true
    var showProbabilities = true
    var showPhase = true
    var focusedQubit: Int? = nil
    var gateEffectName: String? = nil
    var gateEffectID = 0
    var stateRole = ""
    var spotDifference: PuzzleSpotDifference? = nil
    var spotComplete = true
    var onSpotChoice: ((Bool) -> Void)? = nil

    private var probabilities: [ProbabilityEntry] {
        QubricQuantumEngine.probabilities(for: state)
    }

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 10), count: state.count == 2 ? 2 : 2)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            if state.count == 4 {
                QubitAxisView()
            }

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Array(probabilities.enumerated()), id: \.element.id) { index, item in
                    let phase = phaseLabel(for: state[index])
                    let active = item.value > 0.05
                    let spotTarget = spotDifference?.state == stateRole
                        && spotDifference?.basis == item.label
                        && spotDifference?.phase == phase
                    let phaseInteractive = showPhase && active && spotDifference != nil && !spotComplete
                    OutcomeTile(
                        label: showNotation ? "|\(item.label)>" : item.label,
                        percent: item.value,
                        phase: phase,
                        showPhase: showPhase,
                        showProbabilities: showProbabilities,
                        focusedQubit: focusedQubit,
                        gateEffectName: gateEffectName,
                        gateEffectID: gateEffectID,
                        spotTarget: spotTarget,
                        spotInteractive: phaseInteractive,
                        onSpotChoice: onSpotChoice
                    )
                }
            }

            if let linkedPathLabel {
                Label(linkedPathLabel, systemImage: "link")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.qubricPrimary)
            }

            if showNotation {
                Text(QubricQuantumEngine.format(state))
                    .font(.custom("JetBrainsMono-Regular", size: QubricTheme.iPadFontSize(13), relativeTo: .footnote))
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .minimumScaleFactor(0.6)
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: 0.18), value: probabilities)
    }

    private func phaseLabel(for amp: Complex) -> String {
        guard amp.magnitudeSquared > QubricQuantumEngine.epsilon else { return "" }
        return amp.re < -QubricQuantumEngine.epsilon || amp.im < -QubricQuantumEngine.epsilon ? "-" : "+"
    }

    private var linkedPathLabel: String? {
        guard state.count == 4 else { return nil }
        let active = Set(probabilities.filter { $0.value > 0.05 }.map(\.label))
        if active == Set(["00", "11"]) { return "Linked paths: |00> and |11>" }
        if active == Set(["01", "10"]) { return "Linked paths: |01> and |10>" }
        return nil
    }
}

private struct QubitAxisView: View {
    var body: some View {
        HStack(spacing: 8) {
            axisLabel("q0")
            axisLabel("q1")
            Spacer()
        }
    }

    private func axisLabel(_ text: String) -> some View {
        Text(text)
            .font(.custom("JetBrainsMono-Regular", size: QubricTheme.iPadFontSize(11), relativeTo: .caption2))
            .foregroundStyle(.secondary)
            .frame(width: 42, alignment: .leading)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color(.separator))
                    .frame(height: 1)
            }
    }
}

private struct OutcomeTile: View {
    let label: String
    let percent: Double
    let phase: String
    let showPhase: Bool
    let showProbabilities: Bool
    let focusedQubit: Int?
    let gateEffectName: String?
    let gateEffectID: Int
    let spotTarget: Bool
    let spotInteractive: Bool
    let onSpotChoice: ((Bool) -> Void)?

    @State private var pulsing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                BasisLabelView(label: label, focusedQubit: focusedQubit)
                if showPhase, !phase.isEmpty {
                    phaseMark
                }
                Spacer()
            }
            if showProbabilities {
                GeometryReader { proxy in
                    ZStack(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.qubricTrack)
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.qubricPrimary)
                            .frame(height: max(2, proxy.size.height * percent / 100))
                    }
                }
                .frame(height: 44)
            }
            if showProbabilities {
                Text(percent.percentLabel)
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(8)
        .frame(minHeight: showProbabilities ? 88 : 52)
        .background(tileBackground)
        .clipShape(RoundedRectangle(cornerRadius: QubricTheme.smallCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: QubricTheme.smallCornerRadius, style: .continuous)
                .stroke(tileStroke, lineWidth: spotTarget ? 1.5 : QubricTheme.hairlineWidth)
        }
        .scaleEffect(pulsing && ["H", "X"].contains(gateEffectName ?? "") && percent > 0.05 ? 1.015 : 1)
        .overlay(alignment: .bottom) {
            if pulsing && gateEffectName == "CNOT" && percent > 0.05 {
                Capsule()
                    .fill(Color.qubricPrimary)
                    .frame(height: 3)
                    .padding(.horizontal, 10)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .onChange(of: gateEffectID) { _, _ in
            triggerPulse()
        }
    }

    @ViewBuilder
    private var phaseMark: some View {
        let mark = Text(phase)
            .font(.custom("JetBrainsMono-SemiBold", size: QubricTheme.iPadFontSize(16), relativeTo: .body))
            .foregroundStyle(phase == "-" ? Color.qubricPhase : Color.secondary)
            .frame(width: 28, height: 28)
            .background(spotTarget ? Color.qubricPhase.opacity(0.16) : Color.clear)
            .clipShape(Circle())
            .scaleEffect(pulsing && gateEffectName == "Z" ? 1.12 : 1)

        if spotInteractive {
            Button {
                onSpotChoice?(spotTarget)
            } label: {
                mark
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(label) sign \(phase)")
        } else {
            mark
        }
    }

    private func triggerPulse() {
        guard gateEffectName != nil else { return }
        pulsing = true
        withAnimation(.easeOut(duration: 0.34)) {
            pulsing = false
        }
    }

    private var tileBackground: some ShapeStyle {
        if percent <= 0.05 {
            return AnyShapeStyle(Color(.systemBackground))
        }
        if spotTarget {
            return AnyShapeStyle(Color.qubricPhase.opacity(0.18))
        }
        if showPhase, phase == "-" {
            return AnyShapeStyle(Color.qubricPhase.opacity(0.16))
        }
        return AnyShapeStyle(Color.qubricSecondaryGrouped)
    }

    private var tileStroke: Color {
        if spotTarget { return Color.qubricPhase.opacity(0.72) }
        if showPhase, phase == "-" { return Color.qubricPhase.opacity(0.45) }
        return percent > 0.05 ? Color.qubricLineStrong : Color.qubricLine
    }
}

private struct BasisLabelView: View {
    let label: String
    let focusedQubit: Int?

    private var bits: [String]? {
        guard label.hasPrefix("|"), label.hasSuffix(">") else { return nil }
        let raw = label.dropFirst().dropLast()
        guard raw.allSatisfy({ $0 == "0" || $0 == "1" }) else { return nil }
        return raw.map(String.init)
    }

    var body: some View {
        if let bits {
            HStack(spacing: 0) {
                Text("|")
                ForEach(Array(bits.enumerated()), id: \.offset) { index, bit in
                    Text(bit)
                        .padding(.horizontal, 2)
                        .background(index == focusedQubit ? Color.qubricPrimary.opacity(0.22) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                }
                Text(">")
            }
            .font(.custom("JetBrainsMono-SemiBold", size: QubricTheme.iPadFontSize(17), relativeTo: .body))
        } else {
            Text(label)
                .font(.custom("JetBrainsMono-SemiBold", size: QubricTheme.iPadFontSize(17), relativeTo: .body))
        }
    }
}

struct DistributionReadout: View {
    let distribution: [ProbabilityEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Outcome chances")
                .font(.headline.weight(.semibold))

            ForEach(distribution) { item in
                HStack(spacing: 10) {
                    Text(item.label)
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 44, alignment: .leading)
                    ProgressView(value: Double(item.value), total: 100)
                    Text(item.value.percentLabel)
                        .font(.footnote.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 42, alignment: .trailing)
                }
            }
        }
        .groupedCard()
    }
}

struct StateReadout: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.custom("JetBrainsMono-SemiBold", size: QubricTheme.iPadFontSize(34), relativeTo: .title))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, minHeight: 150)
        .groupedCard()
        .accessibilityElement(children: .combine)
    }
}

struct CircuitSlots: View {
    let maxGates: Int
    let optimalGates: Int
    let strictBudget: Bool
    let showMoveTarget: Bool
    var practiceLabel: String? = nil
    var stageLabels: [String] = []
    var compact = false
    let applied: [String]

    var body: some View {
        if compact {
            compactSlots
        } else {
            fullSlots
        }
    }

    private var fullSlots: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 64), spacing: 8)], spacing: 8) {
            if !showMoveTarget && applied.isEmpty {
                Text(practiceLabel ?? "Choose a gate.")
                    .font(Font.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
            } else if !showMoveTarget {
                ForEach(Array(applied.enumerated()), id: \.offset) { _, gate in
                    slot(gate, filled: true)
                }
            } else {
                ForEach(0..<optimalGates, id: \.self) { index in
                    slot(
                        applied.indices.contains(index) ? applied[index] : "\(index + 1)",
                        filled: applied.indices.contains(index),
                        stageLabel: stageLabels.indices.contains(index) ? stageLabels[index] : nil
                    )
                }
                ForEach(extraRange, id: \.self) { index in
                    slot(
                        applied.indices.contains(index) ? applied[index] : "+",
                        filled: applied.indices.contains(index),
                        stageLabel: stageLabels.indices.contains(index) ? stageLabels[index] : nil
                    )
                        .opacity(applied.indices.contains(index) ? 1 : 0.45)
                }
            }
        }
    }

    @ViewBuilder
    private var compactSlots: some View {
        if !showMoveTarget && applied.isEmpty {
            EmptyView()
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 5) {
                    if !showMoveTarget {
                        ForEach(Array(applied.enumerated()), id: \.offset) { _, gate in
                            compactSlot(gate, filled: true)
                        }
                    } else {
                        ForEach(0..<optimalGates, id: \.self) { index in
                            compactSlot(
                                applied.indices.contains(index) ? applied[index] : "\(index + 1)",
                                filled: applied.indices.contains(index),
                                stageLabel: stageLabels.indices.contains(index) ? stageLabels[index] : nil
                            )
                        }
                        ForEach(extraRange, id: \.self) { index in
                            compactSlot(
                                applied.indices.contains(index) ? applied[index] : "+",
                                filled: applied.indices.contains(index),
                                stageLabel: stageLabels.indices.contains(index) ? stageLabels[index] : nil
                            )
                            .opacity(applied.indices.contains(index) ? 1 : 0.45)
                        }
                    }
                }
                .padding(.vertical, 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func slot(_ text: String, filled: Bool, stageLabel: String? = nil) -> some View {
        VStack(spacing: 2) {
            Text(text)
                .font(Font.headline.weight(.semibold))
            if let stageLabel {
                Text(stageLabel)
                    .font(.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
        .frame(maxWidth: .infinity, minHeight: compact ? 30 : (stageLabel == nil ? 42 : 50))
        .background(filled ? Color.qubricPrimary.opacity(0.14) : Color(.systemBackground))
        .foregroundStyle(filled ? Color.primary : Color.secondary)
        .clipShape(RoundedRectangle(cornerRadius: QubricTheme.smallCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: QubricTheme.smallCornerRadius, style: .continuous)
                .stroke(filled ? Color.qubricPrimary.opacity(0.45) : Color.qubricLine, lineWidth: QubricTheme.hairlineWidth)
        }
    }

    private func compactSlot(_ text: String, filled: Bool, stageLabel: String? = nil) -> some View {
        VStack(spacing: 4) {
            Text(text)
                .font(.custom("JetBrainsMono-SemiBold", size: QubricTheme.iPadFontSize(12), relativeTo: .caption))
                .foregroundStyle(filled ? Color.primary : Color.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.78)

            Capsule()
                .fill(filled ? Color.qubricPrimary : Color.qubricLine.opacity(0.58))
                .frame(width: min(compactSlotWidth(for: text) - 10, 28), height: 2)
        }
        .frame(width: compactSlotWidth(for: text), height: 24)
        .accessibilityLabel(stageLabel ?? "Move \(text)")
    }

    private func compactSlotWidth(for text: String) -> CGFloat {
        text.count > 4 ? 64 : text.count > 2 ? 50 : 34
    }

    private var extraRange: Range<Int> {
        let extra = strictBudget ? max(0, maxGates - optimalGates) : max(0, applied.count - optimalGates)
        return optimalGates..<(optimalGates + extra)
    }
}

private extension Double {
    var percentLabel: String {
        truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(self))%"
            : String(format: "%.1f%%", self)
    }
}

struct FlowTags: View {
    let items: [String]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 86), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: QubricTheme.smallCornerRadius, style: .continuous))
            }
        }
    }
}
