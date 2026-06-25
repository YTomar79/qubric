//
//  GatePaletteView.swift
//  Qubric
//
//  Palette of draggable puzzle elements.
//

import SwiftUI

struct GatePicker: View {
    let puzzle: QuantumPuzzle
    @Binding var selectedQubit: Int
    let disabled: Bool
    let emphasizePrimaryGate: Bool
    var fillsWidth = true
    let onApply: (String) -> Void

    private var model: GatePaletteModel {
        GatePaletteModel(
            gates: puzzle.availableGates,
            qubits: qubitCount,
            targetQubits: puzzle.targetQubits,
            targetPairs: puzzle.targetPairs
        )
    }

    private var qubitCount: Int {
        let count = (try? QubricQuantumEngine.resolveState(puzzle.initialState).count) ?? 2
        return Int(log2(Double(count)).rounded())
    }

    private var gateCount: Int {
        model.single.count + model.direct.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            if puzzle.explicitTargetButtons && qubitCount > 1 && !model.single.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(model.single, id: \.self) { gate in
                            ForEach(model.targets, id: \.self) { target in
                                let targetLabel = puzzle.qubitLabel(for: target)
                                GateButton(gate: gate, isSuggested: emphasizePrimaryGate, subtitle: "\(targetLabel.short) · \(targetLabel.detail)", showsSubtitle: true) {
                                    onApply("\(gate)\(target)")
                                }
                                .disabled(disabled || !model.isAvailable(gate: gate, target: target, qubits: qubitCount))
                            }
                        }
                    }
                }
            } else if qubitCount > 1 && !model.single.isEmpty {
                TargetQubitSelector(
                    targets: model.targets,
                    selectedQubit: $selectedQubit,
                    labelFor: puzzle.qubitLabel(for:)
                )
            }

            if !(puzzle.explicitTargetButtons && qubitCount > 1 && !model.single.isEmpty) {
                if fillsWidth, gateCount == 1 {
                    if let gate = model.single.first {
                        singleGateButton(gate, fillsWidth: false)
                    } else if let gate = model.direct.first {
                        directGateButton(gate, fillsWidth: false)
                    }
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(model.single, id: \.self) { gate in
                                singleGateButton(gate, fillsWidth: false)
                            }

                            ForEach(model.direct, id: \.self) { gate in
                                directGateButton(gate, fillsWidth: false)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: fillsWidth ? .infinity : nil, alignment: .leading)
        .onAppear {
            if !model.targets.contains(selectedQubit) {
                selectedQubit = model.targets.first ?? 0
            }
        }
    }

    private func singleGateButton(_ gate: String, fillsWidth: Bool) -> some View {
        let actual = qubitCount > 1 ? "\(gate)\(selectedQubit)" : gate

        return GateButton(
            gate: gate,
            isSuggested: emphasizePrimaryGate && gateCount == 1,
            subtitle: gateHelp(gate),
            showsSubtitle: puzzle.showGateLabels,
            fillsWidth: fillsWidth
        ) {
            onApply(actual)
        }
        .disabled(disabled || !model.isAvailable(gate: gate, target: selectedQubit, qubits: qubitCount))
    }

    private func directGateButton(_ gate: String, fillsWidth: Bool) -> some View {
        GateButton(
            gate: gate,
            isSuggested: emphasizePrimaryGate && gateCount == 1,
            subtitle: gateHelp(gate),
            showsSubtitle: puzzle.showGateLabels,
            fillsWidth: fillsWidth
        ) {
            onApply(gate)
        }
        .disabled(disabled)
    }
}

func gateHelp(_ gate: String) -> String {
    let base = gate.replacingOccurrences(of: #"\d+$"#, with: "", options: .regularExpression)
    let targets = gate.dropFirst(base.count).compactMap { Int(String($0)) }

    switch base {
    case "H": return "split"
    case "X": return "flip 0 and 1"
    case "Y": return "flip with phase"
    case "Z": return "sign"
    case "S": return "turn phase"
    case "CNOT":
        guard targets.count == 2 else { return "control flip" }
        return "q\(targets[0]) controls q\(targets[1])"
    case "SWAP": return "trade qubits"
    case "CZ", "CP":
        guard targets.count == 2 else { return "linked phase" }
        return "q\(targets[0]) links q\(targets[1])"
    default: return "apply gate"
    }
}

private struct TargetQubitSelector: View {
    let targets: [Int]
    @Binding var selectedQubit: Int
    let labelFor: (Int) -> QubitLabel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 5) {
                ForEach(targets, id: \.self) { target in
                    let label = labelFor(target)
                    Button {
                        selectedQubit = target
                    } label: {
                        HStack(spacing: 5) {
                            Text(label.short)
                                .font(.custom("JetBrainsMono-SemiBold", size: QubricTheme.iPadFontSize(13), relativeTo: .caption))
                            Text(label.detail)
                                .font(.caption2.weight(.semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.74)
                        }
                        .foregroundStyle(selectedQubit == target ? Color.white : Color.secondary)
                        .padding(.horizontal, QubricTheme.iPadMetric(9))
                        .frame(height: QubricTheme.iPadMetric(30))
                        .frame(minWidth: QubricTheme.iPadMetric(88))
                        .background(selectionBackground(for: target), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(selectionBorder(for: target), lineWidth: QubricTheme.hairlineWidth)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Target \(label.short), \(label.detail)")
                }
            }
        }
    }

    private func selectionBackground(for target: Int) -> Color {
        selectedQubit == target ? Color.qubricPrimary : Color.qubricSecondaryGrouped
    }

    private func selectionBorder(for target: Int) -> Color {
        selectedQubit == target ? Color.qubricPrimary : Color.qubricLine.opacity(0.62)
    }
}

struct GatePaletteModel {
    let single: [String]
    let direct: [String]
    let targets: [Int]
    let targetQubits: [String: [Int]]
    let targetPairs: [String: [[Int]]]

    init(gates: [String], qubits: Int, targetQubits: [String: [Int]] = [:], targetPairs: [String: [[Int]]] = [:]) {
        self.targetQubits = targetQubits
        self.targetPairs = targetPairs
        if qubits < 2 {
            single = gates.filter { ["H", "X", "Y", "Z", "S"].contains($0) }
            direct = gates.filter { !["H", "X", "Y", "Z", "S"].contains($0) }
            targets = [0]
            return
        }

        var singleSet = Set<String>()
        var targetSet = Set<Int>()
        var directItems: [String] = []

        for gate in gates {
            if let first = gate.first,
               ["H", "X", "Y", "Z", "S"].contains(String(first)),
               let target = Int(String(gate.dropFirst())) {
                singleSet.insert(String(first))
                targetSet.insert(target)
            } else if ["H", "X", "Y", "Z", "S"].contains(gate) {
                singleSet.insert(gate)
                for target in targetQubits[gate] ?? [0] {
                    targetSet.insert(target)
                }
            } else if ["CNOT", "CZ", "CP", "SWAP"].contains(gate), let pairs = targetPairs[gate], !pairs.isEmpty {
                for pair in pairs where pair.count == 2 {
                    directItems.append("\(gate == "CP" ? "CZ" : gate)\(pair[0])\(pair[1])")
                }
            } else {
                directItems.append(gate)
            }
        }

        single = ["H", "X", "Y", "Z", "S"].filter { singleSet.contains($0) }
        direct = directItems
        targets = targetSet.sorted()
    }

    func isAvailable(gate: String, target: Int, qubits: Int) -> Bool {
        if qubits < 2 { return true }
        if let targets = targetQubits[gate] {
            return targets.contains(target)
        }
        return true
    }
}
