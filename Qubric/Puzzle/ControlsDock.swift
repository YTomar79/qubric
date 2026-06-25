//
//  ControlsDock.swift
//  Qubric
//
//  Bottom control dock for puzzle interactions.
//

import SwiftUI

struct PuzzleActions: View {
    let onHint: () -> Void
    let onUndo: () -> Void
    let onReset: () -> Void
    let showHintButton: Bool
    let showUndoButton: Bool
    let showResetButton: Bool
    let hintDisabled: Bool
    let hintsUsed: Int
    let totalHints: Int
    let undoDisabled: Bool
    let resetDisabled: Bool

    var body: some View {
        HStack(spacing: 6) {
            if showHintButton && totalHints > 0 {
                Button(action: onHint) {
                    VStack(spacing: 1) {
                        Image(systemName: "lightbulb")
                        Text("\(min(hintsUsed + 1, totalHints))/\(totalHints)")
                            .font(.caption2.monospacedDigit().weight(.semibold))
                    }
                }
                .accessibilityLabel("Hint \(min(hintsUsed + 1, totalHints)) of \(totalHints)")
                .buttonStyle(DockIconButtonStyle(width: 46, height: 42))
                .disabled(hintDisabled)
            }

            if showUndoButton {
                Button(action: onUndo) {
                    Image(systemName: "arrow.uturn.backward")
                }
                .dockIconButton()
                .accessibilityLabel("Undo last move")
                .disabled(undoDisabled)
            }

            if showResetButton {
                Button(action: onReset) {
                    Image(systemName: "arrow.counterclockwise")
                }
                .dockIconButton()
                .accessibilityLabel("Reset")
                .disabled(resetDisabled)
            }
        }
        .font(.system(size: QubricTheme.iPadFontSize(17), weight: .semibold))
        .foregroundStyle(Color.qubricPrimary)
        .controlSize(.regular)
    }
}

struct DockIconButtonStyle: ButtonStyle {
    var width: CGFloat = 42
    var height: CGFloat = 42

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: QubricTheme.iPadMetric(width), height: QubricTheme.iPadMetric(height))
            .background(Color.qubricSecondaryGrouped)
            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(Color.qubricLine.opacity(0.62), lineWidth: QubricTheme.hairlineWidth)
            }
            .opacity(configuration.isPressed ? 0.72 : 1)
    }
}

extension View {
    func dockIconButton(width: CGFloat = 42, height: CGFloat = 42) -> some View {
        buttonStyle(DockIconButtonStyle(width: width, height: height))
    }
}

struct PuzzleControlDock: View {
    let puzzle: QuantumPuzzle
    @Binding var selectedQubit: Int
    let gates: [String]
    let gateDisabled: Bool
    let showHintButton: Bool
    let showUndoButton: Bool
    let showResetButton: Bool
    let hintDisabled: Bool
    let hintsUsed: Int
    let undoDisabled: Bool
    let resetDisabled: Bool
    let emphasizePrimaryGate: Bool
    let inline: Bool
    let onHint: () -> Void
    let onUndo: () -> Void
    let onReset: () -> Void
    let onApply: (String) -> Void

    private var showsCircuitSlots: Bool {
        puzzle.showMoveTarget || !gates.isEmpty
    }

    private var showsActions: Bool {
        (showHintButton && !puzzle.hints.isEmpty) || showUndoButton || showResetButton
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if showsCircuitSlots {
                CircuitSlots(
                    maxGates: puzzle.maxGates,
                    optimalGates: puzzle.optimalGates,
                    strictBudget: puzzle.strictBudget,
                    showMoveTarget: puzzle.showMoveTarget,
                    practiceLabel: puzzle.practiceLabel ?? puzzle.firstMovePrompt,
                    stageLabels: puzzle.stageLabels,
                    compact: true,
                    applied: gates
                )
            }

            if inline || !showsActions {
                inlineControlsRow
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    GatePicker(
                        puzzle: puzzle,
                        selectedQubit: $selectedQubit,
                        disabled: gateDisabled,
                        emphasizePrimaryGate: emphasizePrimaryGate,
                        fillsWidth: true,
                        onApply: onApply
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: false)

                    PuzzleActions(
                        onHint: onHint,
                        onUndo: onUndo,
                        onReset: onReset,
                        showHintButton: showHintButton,
                        showUndoButton: showUndoButton,
                        showResetButton: showResetButton,
                        hintDisabled: hintDisabled,
                        hintsUsed: hintsUsed,
                        totalHints: puzzle.hints.count,
                        undoDisabled: undoDisabled,
                        resetDisabled: resetDisabled
                    )
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, inline ? 14 : (QubricTheme.isPad ? 18 : 16))
        .padding(.top, inline ? 14 : (QubricTheme.isPad ? 12 : 9))
        .padding(.bottom, inline ? 14 : (QubricTheme.isPad ? 12 : 9))
        .background(
            dockBackground,
            in: RoundedRectangle(cornerRadius: inline ? QubricTheme.cornerRadius : 0, style: .continuous)
        )
        .overlay {
            if inline {
                RoundedRectangle(cornerRadius: QubricTheme.cornerRadius, style: .continuous)
                    .stroke(Color.qubricTileLine, lineWidth: QubricTheme.tileStrokeWidth)
            }
        }
        .overlay(alignment: .top) {
            if !inline {
                Rectangle()
                    .fill(Color.qubricLine)
                    .frame(height: QubricTheme.hairlineWidth)
            }
        }
    }

    private var inlineControlsRow: some View {
        HStack(alignment: .bottom, spacing: 8) {
            GatePicker(
                puzzle: puzzle,
                selectedQubit: $selectedQubit,
                disabled: gateDisabled,
                emphasizePrimaryGate: emphasizePrimaryGate,
                fillsWidth: true,
                onApply: onApply
            )
            .frame(maxWidth: inline ? nil : .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: false)

            if showsActions {
                PuzzleActions(
                    onHint: onHint,
                    onUndo: onUndo,
                    onReset: onReset,
                    showHintButton: showHintButton,
                    showUndoButton: showUndoButton,
                    showResetButton: showResetButton,
                    hintDisabled: hintDisabled,
                    hintsUsed: hintsUsed,
                    totalHints: puzzle.hints.count,
                    undoDisabled: undoDisabled,
                    resetDisabled: resetDisabled
                )
            }
        }
    }

    private var dockBackground: Color {
        inline ? Color.qubricSecondaryGrouped : Color.qubricGrouped
    }
}
