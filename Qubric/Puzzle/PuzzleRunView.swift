//
//  PuzzleRunView.swift
//  Qubric
//
//  Main interactive puzzle session view.
//

import AVFoundation
import SwiftUI
import UIKit

struct PuzzleRunView: View {
    let puzzle: QuantumPuzzle
    @ObservedObject var store: QubricStore
    let onBack: () -> Void
    let onNext: (String) -> Void

    @State private var gates: [String] = []
    @State private var hintsUsed = 0
    @State private var message = ""
    @State private var isComplete = false
    @State private var isFailed = false
    @State private var isSavingSolve = false
    @State private var selectedQubit = 0
    @State private var predictionChoice: String?
    @State private var spotChoice: String?
    @State private var lastGate: String?
    @State private var lastGateWasNoOp = false
    @State private var noOpCaptionVisible = false
    @State private var gateEffectID = 0
    @State private var lastEarnedXp = 0
    @State private var lastScoreBreakdown: ScoreBreakdown?
    @State private var failedAttemptCount = 0
    @State private var failureResetLocked = false
    @State private var completionNote: String?
    @StateObject private var audio = QubricAudioPlayer()

    private var currentState: [Complex] {
        if let state = try? QubricQuantumEngine.runCircuit(puzzle, gates: gates) {
            return state
        }
        return (try? QubricQuantumEngine.resolveState(puzzle.initialState)) ?? []
    }

    private var goalState: [Complex] {
        (try? QubricQuantumEngine.resolveState(puzzle.goalState)) ?? []
    }

    private var previousState: [Complex]? {
        guard !gates.isEmpty else { return nil }
        return try? QubricQuantumEngine.runCircuit(puzzle, gates: Array(gates.dropLast()))
    }

    private var locked: Bool {
        isComplete || isFailed || isSavingSolve
    }

    private var predictionComplete: Bool {
        puzzle.prediction == nil || predictionChoice != nil
    }

    private var predictionRevealed: Bool {
        !gates.isEmpty || isComplete || isFailed
    }

    private var awaitingPrediction: Bool {
        puzzle.prediction != nil && predictionChoice == nil && !isComplete && !isFailed
    }

    private var spotComplete: Bool {
        puzzle.spotDifference == nil || spotChoice == "correct"
    }

    private var isSpotDifferenceOnly: Bool {
        puzzle.puzzleType == "spot-difference"
    }

    private var showsControlDock: Bool {
        !isSpotDifferenceOnly
    }

    private var qubitCount: Int {
        let count = (try? QubricQuantumEngine.resolveState(puzzle.initialState).count) ?? 2
        return Int(log2(Double(count)).rounded())
    }

    private var focusedQubit: Int? {
        qubitCount > 1 ? selectedQubit : nil
    }

    private var showsPuzzleUtilities: Bool {
        isFailed || !gates.isEmpty || hintsUsed > 0
    }

    private var expandsPuzzleBoard: Bool {
        false
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                PuzzleTopBar(
                    puzzle: puzzle,
                    onBack: onBack
                )

                GeometryReader { geometry in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            if !awaitingPrediction {
                                puzzleWorkspace(
                                    minHeight: workspaceMinHeight(in: geometry.size.height),
                                    rowMinHeight: outcomeRowMinHeight(in: geometry.size.height)
                                )
                            } else {
                                comparisonBoard(embedded: false, roomyRows: false)
                            }

                            if let prediction = puzzle.prediction, awaitingPrediction {
                                PredictionCard(
                                    prediction: prediction,
                                    choice: predictionChoice,
                                    reveal: false,
                                    onChoose: { choice in
                                        predictionChoice = choice
                                        message = "Prediction locked. Run the gate."
                                    }
                                )
                            }

                            let learningItems = LearningTrayItem.items(
                                puzzle: puzzle,
                                message: message,
                                isFailed: isFailed,
                                isSaving: isSavingSolve,
                                previousState: previousState,
                                currentState: currentState,
                                hintsUsed: hintsUsed,
                                predictionChoice: predictionChoice,
                                predictionRevealed: predictionRevealed
                            )
                            if !awaitingPrediction && !isComplete && !isFailed && !learningItems.isEmpty {
                                LearningTrayView(items: learningItems, startsOpen: isFailed || hintsUsed > 0)
                            }

                            if isFailed {
                                FailureHintCard(
                                    message: message,
                                    moveSummary: failedMoveSummary,
                                    latestHint: latestHintText,
                                    canHint: store.profile?.settings.hintsEnabled != false && hintsUsed < puzzle.hints.count,
                                    hintsUsed: hintsUsed,
                                    totalHints: puzzle.hints.count,
                                    resetDisabled: failureResetLocked,
                                    onReset: reset,
                                    onHint: revealHint
                                )
                            }

                            if isComplete {
                                SolvedInlineView(
                                    puzzle: puzzle,
                                    gates: gates,
                                    hintsUsed: hintsUsed,
                                    best: store.profile?.solveStats[puzzle.id],
                                    profile: store.profile,
                                    earnedXp: lastEarnedXp,
                                    scoreBreakdown: lastScoreBreakdown,
                                    prediction: puzzle.prediction,
                                    predictionChoice: predictionChoice,
                                    note: completionNote,
                                    nextId: QubricData.nextPuzzleId(after: puzzle.id),
                                    skipReflection: store.profile?.settings.skipReflections == true,
                                    onReflectionAnswer: { correct in
                                        Task {
                                            await store.recordReflection(puzzle: puzzle, correct: correct)
                                        }
                                    },
                                    onNext: {
                                        if let next = QubricData.nextPuzzleId(after: puzzle.id) {
                                            onNext(next)
                                        } else {
                                            onBack()
                                        }
                                    },
                                    onMap: onBack
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, expandsPuzzleBoard ? 18 : (isComplete || awaitingPrediction || isFailed ? 18 : 118))
                        .iPadReadableWidth(maxWidth: QubricTheme.iPadPuzzleWidth)
                    }
                    .background(Color.qubricGrouped)
                }
                .background(Color.qubricGrouped)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if !isComplete && !awaitingPrediction && !isFailed && showsControlDock {
                        controlDock(inline: false)
                            .iPadReadableWidth(maxWidth: QubricTheme.iPadPuzzleWidth)
                    }
                }
            }
            .navigationBarHidden(true)
            .background(Color.qubricGrouped)
        }
        .onAppear(perform: preparePuzzle)
        .onChange(of: puzzle.id) { _, _ in
            preparePuzzle()
        }
    }

    private func workspaceMinHeight(in availableHeight: CGFloat) -> CGFloat? {
        if expandsPuzzleBoard {
            let bottomDockReserve: CGFloat = 96
            return max(0, availableHeight - bottomDockReserve)
        }
        return nil
    }

    private func outcomeRowMinHeight(in availableHeight: CGFloat) -> CGFloat? {
        guard expandsPuzzleBoard else { return nil }
        let bottomDockReserve: CGFloat = 96
        let taskReserve: CGFloat = 74
        let boardPadding: CGFloat = 8
        let outcomeCount = max(currentState.count, 1)
        let target = (availableHeight - bottomDockReserve - taskReserve - boardPadding) / CGFloat(outcomeCount)
        return min(max(target, 118), 220)
    }

    private func puzzleWorkspace(minHeight: CGFloat? = nil, rowMinHeight: CGFloat? = nil) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ActiveTaskRow(
                text: activeTaskText,
                last: lastEventText,
                isComplete: isComplete,
                isFailed: isFailed,
                isSaving: isSavingSolve
            )
            .padding(.horizontal, 14)
            .padding(.top, 11)
            .padding(.bottom, 11)

            Rectangle()
                .fill(Color.qubricLine)
                .frame(height: QubricTheme.hairlineWidth)

            comparisonBoard(
                embedded: true,
                roomyRows: expandsPuzzleBoard,
                rowMinHeight: rowMinHeight
            )
        }
                        .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .top)
        .background(Color.qubricSurface)
        .clipShape(RoundedRectangle(cornerRadius: QubricTheme.cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: QubricTheme.cornerRadius, style: .continuous)
                .stroke(Color.qubricTileLine, lineWidth: QubricTheme.tileStrokeWidth)
        }
    }

    private func comparisonBoard(embedded: Bool, roomyRows: Bool, rowMinHeight: CGFloat? = nil) -> some View {
        PuzzleComparisonBoard(
            puzzle: puzzle,
            currentState: currentState,
            previousState: previousState,
            goalState: goalState,
            focusedQubit: focusedQubit,
            gateEffect: lastGate.map { GateEffect(gate: $0, id: gateEffectID, noOp: lastGateWasNoOp) },
            spotDifference: puzzle.spotDifference,
            spotComplete: spotComplete,
            showNotationPreference: store.profile?.settings.showNotation == true,
            embedded: embedded,
            roomyRows: roomyRows,
            rowMinHeight: rowMinHeight,
            onSpotChoice: handleSpotChoice
        )
    }

    private func apply(_ gate: String) {
        guard !locked, predictionComplete, spotComplete else { return }
        let nextGates = gates + [gate]
        let startingState = currentState

        do {
            let nextState = try QubricQuantumEngine.runCircuit(puzzle, gates: nextGates)
            gates = nextGates
            lastGate = gate
            lastGateWasNoOp = QubricQuantumEngine.statesEquivalent(startingState, nextState)
            gateEffectID += 1
            showNoOpCaptionIfNeeded(lastGateWasNoOp)
            audio.play(.gate, gate: gate, enabled: store.profile?.sound == true)
            haptic(.success)

            if violatesRequiredSolutionPrefix(nextGates) {
                fail(with: feedbackMessage(for: nextGates) ?? "Wrong order. Reset and follow the prompts.")
                return
            }

            if try QubricQuantumEngine.stateMatchesGoal(puzzle, state: nextState) {
                if QubricQuantumEngine.matchesRequiredSolutionOrder(puzzle, gates: nextGates) {
                    completePuzzle(gates: nextGates)
                    return
                }

                message = stageFeedbackMessage(moveCount: nextGates.count)
                    ?? "Target matched early. Finish the route."
                return
            }

            if puzzle.strictBudget && nextGates.count >= puzzle.maxGates {
                fail(with: feedbackMessage(for: nextGates) ?? "Move limit reached. Reset and try another route.")
                return
            }

            message = stageFeedbackMessage(moveCount: nextGates.count)
                ?? wrongGateMessage(for: nextState, gates: nextGates)
                ?? (!puzzle.strictBudget && nextGates.count > puzzle.optimalGates
                    ? "Extra moves are fine here. Reset for a cleaner solve."
                    : "Move applied. Compare with the goal.")
        } catch {
            message = error.localizedDescription
            audio.play(.error, enabled: store.profile?.sound == true)
            haptic(.error)
        }
    }

    private func completePuzzle(gates solvedGates: [String]) {
        isSavingSolve = true
        completionNote = solveNote(for: solvedGates)
        message = "Solved. Saving progress..."
        Task {
            let syncResult = await store.complete(puzzle, gates: solvedGates, hintsUsed: hintsUsed)
            await MainActor.run {
                isSavingSolve = false
                isComplete = true
                lastEarnedXp = syncResult.earnedXp
                lastScoreBreakdown = syncResult.scoreBreakdown
                if syncResult.savedRemotely {
                    message = puzzle.solvedMessage ?? "Saved. State matches the goal."
                } else {
                    message = "Solved on this device. \(syncResult.message ?? "Cloud sync pending.")"
                }
                audio.play(.success, enabled: store.profile?.sound == true)
                haptic(.success)
            }
        }
    }

    private func solveNote(for solvedGates: [String]) -> String? {
        let key = QubricQuantumEngine.gateSequenceKey(solvedGates)
        if let alternate = puzzle.alternateSolutionMessages[key] {
            return alternate
        }
        guard puzzle.strictBudget, failedAttemptCount == 0 else { return nil }
        return puzzle.postSolvePrompt
    }

    private func fail(with failureMessage: String) {
        failedAttemptCount += 1
        isFailed = true
        failureResetLocked = true
        message = failureMessage
        audio.play(.error, enabled: store.profile?.sound == true)
        haptic(.error)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            if isFailed {
                failureResetLocked = false
            }
        }
    }

    private func showNoOpCaptionIfNeeded(_ noOp: Bool) {
        guard noOp else {
            noOpCaptionVisible = false
            return
        }
        noOpCaptionVisible = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            noOpCaptionVisible = false
        }
    }

    private func violatesRequiredSolutionPrefix(_ candidate: [String]) -> Bool {
        guard puzzle.enforceSolutionOrder else { return false }
        return !QubricQuantumEngine.startsAllowedSolutionRoute(puzzle, gates: candidate)
    }

    private func feedbackMessage(for gates: [String]) -> String? {
        if let sequence = puzzle.wrongGateFeedback[QubricQuantumEngine.gateSequenceKey(gates)] {
            return sequence
        }
        guard let gate = gates.last else { return nil }
        if let exact = puzzle.wrongGateFeedback[gate] {
            return exact
        }
        let base = gate.replacingOccurrences(of: #"\d+$"#, with: "", options: .regularExpression)
        return puzzle.wrongGateFeedback[base]
    }

    private var failedMoveSummary: String {
        guard let lastGate = gates.last else { return "Route paused" }
        let move = max(1, gates.count)
        if puzzle.enforceSolutionOrder,
           puzzle.solutionGates.indices.contains(move - 1) {
            return "Move \(move)/\(max(puzzle.maxGates, move)): tried \(lastGate), expected \(puzzle.solutionGates[move - 1])"
        }
        return "Move \(move)/\(max(puzzle.maxGates, move)): tried \(lastGate)"
    }

    private var latestHintText: String? {
        guard hintsUsed > 0, puzzle.hints.indices.contains(hintsUsed - 1) else { return nil }
        return puzzle.hints[hintsUsed - 1]
    }

    private func controlDock(inline: Bool) -> some View {
        PuzzleControlDock(
            puzzle: puzzle,
            selectedQubit: $selectedQubit,
            gates: gates,
            gateDisabled: locked || !predictionComplete || !spotComplete,
            showHintButton: store.profile?.settings.hintsEnabled != false && showsPuzzleUtilities,
            showUndoButton: !gates.isEmpty,
            showResetButton: showsPuzzleUtilities,
            hintDisabled: store.profile?.settings.hintsEnabled == false || hintsUsed >= puzzle.hints.count || isComplete,
            hintsUsed: hintsUsed,
            undoDisabled: gates.isEmpty || isComplete,
            resetDisabled: failureResetLocked,
            emphasizePrimaryGate: !puzzle.showMoveTarget && gates.isEmpty && puzzle.prediction == nil,
            inline: inline,
            onHint: revealHint,
            onUndo: undo,
            onReset: reset,
            onApply: apply
        )
    }

    private func revealHint() {
        guard hintsUsed < puzzle.hints.count, !isComplete else { return }
        let nextHint = puzzle.hints[hintsUsed]
        hintsUsed += 1
        message = "Hint: \(nextHint)"
        audio.play(.hint, enabled: store.profile?.sound == true)
    }

    private func reset() {
        guard !failureResetLocked else { return }
        gates = []
        hintsUsed = 0
        lastGate = nil
        lastGateWasNoOp = false
        noOpCaptionVisible = false
        gateEffectID += 1
        isSavingSolve = false
        lastEarnedXp = 0
        lastScoreBreakdown = nil
        completionNote = nil
        if puzzle.prediction == nil {
            message = initialPuzzleMessage
        } else if predictionChoice == nil {
            message = initialPuzzleMessage
        } else {
            message = "Circuit reset. Prediction stays locked."
        }
        isComplete = false
        isFailed = false
        failureResetLocked = false
    }

    private func undo() {
        guard !gates.isEmpty, !isComplete else { return }
        gates.removeLast()
        isFailed = false
        lastGate = nil
        lastGateWasNoOp = false
        noOpCaptionVisible = false
        gateEffectID += 1
        message = gates.isEmpty
            ? "Move undone. Try another gate."
            : "Move undone. Keep comparing with the goal."
    }

    private func preparePuzzle() {
        gates = []
        hintsUsed = 0
        lastGate = nil
        lastGateWasNoOp = false
        noOpCaptionVisible = false
        gateEffectID += 1
        message = initialPuzzleMessage
        isComplete = false
        isFailed = false
        failureResetLocked = false
        failedAttemptCount = 0
        isSavingSolve = false
        lastEarnedXp = 0
        lastScoreBreakdown = nil
        completionNote = nil
        predictionChoice = nil
        spotChoice = nil
        selectedQubit = 0
    }

    private func haptic(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard store.profile?.sound == true else { return }
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }

    private var initialPuzzleMessage: String {
        if let spotDifference = puzzle.spotDifference {
            return spotDifference.prompt
        }
        if puzzle.prediction != nil {
            return "Predict first, then run the gate."
        }
        return puzzle.activePrompt ?? puzzle.firstMovePrompt ?? "Choose a gate. Match the target."
    }

    private var activeTaskText: String {
        if isSavingSolve {
            return "Saving this solve to your account."
        }
        if isComplete {
            return message.isEmpty ? (puzzle.solvedMessage ?? puzzle.recap) : message
        }
        if isFailed {
            return "Try again"
        }
        if let spotDifference = puzzle.spotDifference, !spotComplete {
            return spotDifference.prompt
        }
        if let prediction = puzzle.prediction, predictionChoice == nil {
            return prediction.prompt
        }
        if puzzle.prediction != nil, predictionChoice != nil, gates.isEmpty {
            return "Prediction locked. Run the gate."
        }
        if puzzle.stageLabels.indices.contains(gates.count) {
            return stageInstruction(index: gates.count)
        }
        if gates.isEmpty {
            if !puzzle.concept.isEmpty {
                return puzzle.concept
            }
            return puzzle.activePrompt ?? puzzle.beforeMovePrompt ?? puzzle.firstMovePrompt ?? "Choose a gate. Match the target."
        }
        return stageFeedbackMessage(moveCount: gates.count + 1) ?? "Compare Now with Goal, then choose the next move."
    }

    private func stageInstruction(index: Int) -> String {
        let stage = puzzle.stageLabels[index]
        return stage
    }

    private var lastEventText: String? {
        if noOpCaptionVisible {
            return "Bars didn't move."
        }
        if isFailed {
            return nil
        }
        guard !message.isEmpty, message != activeTaskText else { return nil }
        if isSavingSolve || isComplete || isFailed || !gates.isEmpty || hintsUsed > 0 || message.hasPrefix("Hint:") {
            return message
        }
        return nil
    }

    private func handleSpotChoice(_ isCorrect: Bool) {
        guard let spotDifference = puzzle.spotDifference, !spotComplete else { return }
        if isCorrect {
            spotChoice = "correct"
            message = spotDifference.success
            haptic(.success)
            if isSpotDifferenceOnly {
                completePuzzle(gates: [])
            }
        } else {
            spotChoice = "miss"
            message = "\(spotDifference.miss) Try again; tap the other phase mark."
            haptic(.error)
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 800_000_000)
                if spotChoice == "miss" {
                    spotChoice = nil
                }
            }
        }
    }

    private func stageFeedbackMessage(moveCount: Int) -> String? {
        guard puzzle.stageFeedback.indices.contains(moveCount - 1) else { return nil }
        return puzzle.stageFeedback[moveCount - 1]
    }

    private func wrongGateMessage(for state: [Complex], gates: [String]) -> String? {
        if !gates.isEmpty && gates.enumerated().allSatisfy({ index, gate in
            puzzle.solutionGates.indices.contains(index) && puzzle.solutionGates[index] == gate
        }) {
            return nil
        }
        if let feedback = feedbackMessage(for: gates) {
            return feedback
        }
        guard !QubricQuantumEngine.probabilityShapeMatches(state, goalState) else {
            return QubricQuantumEngine.signShapeMatches(state, goalState)
                ? "Closer. Compare with the target."
                : "Bars match; only a sign differs."
        }
        return "Bars didn't move toward the target. Try a gate that splits or flips."
    }
}

private struct FailureHintCard: View {
    let message: String
    let moveSummary: String
    let latestHint: String?
    let canHint: Bool
    let hintsUsed: Int
    let totalHints: Int
    let resetDisabled: Bool
    let onReset: () -> Void
    let onHint: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: QubricTheme.iPadFontSize(17), weight: .semibold))
                    .foregroundStyle(Color.qubricError)
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Route stopped")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(moveSummary)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)
                }
            }

            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let latestHint {
                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Label("Hint \(hintsUsed)", systemImage: "lightbulb")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.qubricPrimaryStrong)
                    Text(latestHint)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Divider()

            HStack(spacing: 10) {
                Label(resetDisabled ? "Pause briefly" : "Reset is free", systemImage: resetDisabled ? "timer" : "checkmark.circle")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Spacer(minLength: 8)

                if canHint && !resetDisabled {
                    Button(action: onHint) {
                        Label("\(hintsUsed + 1)/\(totalHints)", systemImage: "lightbulb")
                            .labelStyle(.titleAndIcon)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.roundedRectangle(radius: QubricTheme.smallCornerRadius))
                    .tint(Color.qubricPrimary)
                }

                if !resetDisabled {
                    Button(action: onReset) {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                            .labelStyle(.titleAndIcon)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.roundedRectangle(radius: QubricTheme.smallCornerRadius))
                    .tint(Color.qubricPrimary)
                }
            }
        }
        .padding(14)
        .background(Color.qubricSurface)
        .clipShape(RoundedRectangle(cornerRadius: QubricTheme.cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: QubricTheme.cornerRadius, style: .continuous)
                .stroke(Color.qubricTileLine, lineWidth: QubricTheme.tileStrokeWidth)
        }
    }
}

final class QubricAudioPlayer: ObservableObject {
    enum Sound {
        case gate
        case success
        case error
        case hint
    }

    private var players: [String: AVAudioPlayer] = [:]

    init() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
    }

    func play(_ sound: Sound, gate: String? = nil, enabled: Bool) {
        guard enabled, let name = fileName(for: sound, gate: gate) else { return }
        do {
            let player = try player(for: name)
            player.currentTime = 0
            player.play()
        } catch {
            return
        }
    }

    private func player(for name: String) throws -> AVAudioPlayer {
        if let cached = players[name] {
            return cached
        }
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else {
            throw CocoaError(.fileNoSuchFile)
        }
        let player = try AVAudioPlayer(contentsOf: url)
        player.prepareToPlay()
        players[name] = player
        return player
    }

    private func fileName(for sound: Sound, gate: String?) -> String? {
        switch sound {
        case .gate:
            switch baseGate(gate) {
            case "H": return "gate-h"
            case "X", "Y": return "gate-x"
            case "Z", "S": return "gate-z"
            case "CNOT", "CZ", "CP", "SWAP": return "gate-cnot"
            default: return "gate-h"
            }
        case .success:
            return "success"
        case .error:
            return "error"
        case .hint:
            return "hint"
        }
    }

    private func baseGate(_ gate: String?) -> String {
        guard let gate else { return "H" }
        return gate.replacingOccurrences(of: #"\d+$"#, with: "", options: .regularExpression)
    }
}
