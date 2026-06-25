//
//  SolveReplayView.swift
//  Qubric
//
//  Replay of a completed solution.
//

import SwiftUI

struct SolveReplayView: View {
    let puzzle: QuantumPuzzle
    let gates: [String]
    let showNotationPreference: Bool
    @State private var step = 0

    private var replayState: [Complex] {
        (try? QubricQuantumEngine.runCircuit(puzzle, gates: Array(gates.prefix(step)))) ?? []
    }

    var body: some View {
        QuantumStateVisual(
            title: step == 0 ? "Start" : gates[step - 1],
            state: replayState,
            showNotation: puzzle.showNotation || showNotationPreference,
            showProbabilities: puzzle.showProbabilities,
            showPhase: puzzle.showPhase
        )
        .task(id: gates) {
            step = 0
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 650_000_000)
                step = step >= gates.count ? 0 : step + 1
            }
        }
    }
}
