//
//  SolvedInlineView.swift
//  Qubric
//
//  Inline solved / success state view.
//

import SwiftUI

struct ConceptNote: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: QubricTheme.smallCornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: QubricTheme.smallCornerRadius, style: .continuous)
                    .stroke(Color.qubricTileLine, lineWidth: QubricTheme.tileStrokeWidth)
            }
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(Color.qubricLineStrong)
                    .frame(width: QubricTheme.hairlineWidth)
            }
    }
}

struct SolvedInlineView: View {
    let puzzle: QuantumPuzzle
    let gates: [String]
    let hintsUsed: Int
    let best: SolveStats?
    let profile: PlayerProfile?
    let earnedXp: Int
    let scoreBreakdown: ScoreBreakdown?
    let prediction: PuzzlePrediction?
    let predictionChoice: String?
    let note: String?
    let nextId: String?
    let skipReflection: Bool
    let onReflectionAnswer: (Bool) -> Void
    let onNext: () -> Void
    let onMap: () -> Void

    private var perfect: Bool {
        gates.count <= puzzle.optimalGates && hintsUsed == 0
    }

    private var currentStreak: Int {
        profile?.streak.current ?? 0
    }

    private var statsLine: String {
        "\(gates.count) \(gates.count == 1 ? "gate" : "gates") · \(hintsUsed) \(hintsUsed == 1 ? "hint" : "hints") · best \(best?.bestGateCount ?? gates.count)"
    }

    private var rewardLine: String {
        let reward = earnedXp > 0 ? "+\(earnedXp) XP" : "Practice complete"
        let streak = "\(currentStreak) \(currentStreak == 1 ? "day" : "days") streak"
        return "\(reward) · \(streak)"
    }

    private var dailyProtected: Bool {
        let solvedToday = (profile?.dailyXp[QubricData.todayKey(), default: 0] ?? 0) > 0
        return solvedToday && puzzle.id == Self.dailyPuzzleId
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(perfect ? "Clean solve" : "Solved")
                .font(.title.weight(.semibold))
                .foregroundStyle(.primary)

            Text(rewardLine)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.qubricPrimary)

            if let note, !note.isEmpty {
                Text(note)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button(action: nextId == nil ? onMap : onNext) {
                HStack {
                    Text(nextId == nil ? "Return to map" : "Next puzzle")
                    Spacer()
                }
                .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            DisclosureGroup {
                VStack(alignment: .leading, spacing: 12) {
                    Text(statsLine)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if let scoreBreakdown {
                        ScoreBreakdownList(breakdown: scoreBreakdown)
                    }

                    if dailyProtected {
                        Label("Today's streak protected", systemImage: "flame.fill")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color.qubricAccent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color.qubricAccentSoft)
                            .clipShape(RoundedRectangle(cornerRadius: QubricTheme.smallCornerRadius, style: .continuous))
                    }

                    if let prediction, let predictionChoice {
                        Label {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(predictionChoice == prediction.correctOptionId ? "Prediction matched" : "Prediction differed")
                                    .font(.subheadline.weight(.semibold))
                                Text(prediction.explanation)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: predictionChoice == prediction.correctOptionId ? "checkmark.circle.fill" : "arrow.triangle.2.circlepath")
                        }
                        .foregroundStyle(.primary)
                    }

                    if !puzzle.recap.isEmpty {
                        Label {
                            Text(puzzle.recap)
                                .font(.subheadline)
                        } icon: {
                            Image(systemName: "key.fill")
                        }
                        .foregroundStyle(.primary)
                    }

                    HStack {
                        ShareLink(item: shareText) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(.bordered)

                        if nextId != nil {
                            Button("Map", action: onMap)
                                .buttonStyle(.bordered)
                        }
                    }

                    if !puzzle.concept.isEmpty {
                        Text(puzzle.concept)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    if let reflection = puzzle.reflection, !skipReflection {
                        ReflectionInlineView(reflection: reflection, onAnswer: onReflectionAnswer)
                    }

                    SolveReplayView(
                        puzzle: puzzle,
                        gates: gates,
                        showNotationPreference: profile?.settings.showNotation == true
                    )
                }
                .padding(.top, 8)
            } label: {
                Text("Review")
                    .font(.subheadline.weight(.semibold))
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: QubricTheme.cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: QubricTheme.cornerRadius, style: .continuous)
                .stroke(Color.qubricTileLine, lineWidth: QubricTheme.tileStrokeWidth)
        }
    }

    private static var dailyPuzzleId: String {
        let pool = QubricData.allPuzzles.filter {
            $0.chapterNumber == 1
                && $0.difficulty != "Intro"
                && $0.difficulty != "Tutorial"
                && $0.puzzleType != "spot-difference"
        }
        let date = QubricData.todayKey()
        let seed = date.unicodeScalars.reduce(UInt32(17)) { total, scalar in
            total &* 31 &+ scalar.value
        }
        let source = pool.isEmpty ? QubricData.allPuzzles : pool
        return source[Int(seed) % source.count].id
    }

    private var shareText: String {
        let blocks = gates.map { gate -> String in
            let base = gate.replacingOccurrences(of: #"\d+$"#, with: "", options: .regularExpression)
            if base == "H" { return "🟩" }
            if base == "X" { return "🟦" }
            if base == "Y" { return "🟫" }
            if base == "Z" || base == "S" { return "🟪" }
            if base == "CNOT" { return "🔗" }
            if base == "SWAP" { return "🔄" }
            if base == "CZ" || base == "CP" { return "✨" }
            return "🟨"
        }.joined()
        return "Qubric \(puzzle.id) \(perfect ? "clean" : "solved")\n\(blocks.isEmpty ? "□" : blocks)\n\(gates.count)/\(puzzle.optimalGates) · \(perfect ? "clean solve" : "standard solve")\nqubric.app"
    }
}

private struct ScoreBreakdownList: View {
    let breakdown: ScoreBreakdown

    private var rows: [(String, Int)] {
        [
            ("Base", breakdown.baseXp),
            ("Clean route", breakdown.optimalBonus),
            ("No hint", breakdown.noHintBonus),
            ("Extra moves", -breakdown.overOptimalPenalty),
            ("Hints", -breakdown.hintPenalty),
            ("Hints off", breakdown.cleanSolverBonus),
            ("Daily", breakdown.dailyBonus ?? 0),
        ].filter { $0.1 != 0 }
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.element.0) { index, row in
                HStack(alignment: .firstTextBaseline) {
                    Text(row.0)
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Spacer(minLength: 12)

                    Text(row.1 > 0 ? "+\(row.1)" : "\(row.1)")
                        .font(.footnote.monospacedDigit().weight(.semibold))
                        .foregroundStyle(row.1 >= 0 ? .primary : .secondary)
                        .lineLimit(1)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)

                if index < rows.count - 1 {
                    Divider()
                        .overlay(Color.qubricLine)
                        .padding(.leading, 10)
                }
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: QubricTheme.smallCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: QubricTheme.smallCornerRadius, style: .continuous)
                .stroke(Color.qubricTileLine, lineWidth: QubricTheme.tileStrokeWidth)
        }
    }
}
