//
//  JourneyView.swift
//  Qubric
//
//  Chapter map and level progression view.
//

import SwiftUI

struct JourneyView: View {
    @ObservedObject var store: QubricStore
    let onOpenPuzzle: (QuantumPuzzle) -> Void
    @State private var expandedChapterId: String?

    private var profile: PlayerProfile {
        store.profile ?? PlayerProfile(name: "Qubric Player")
    }

    private var solved: Int {
        profile.completed.values.filter { $0 }.count
    }

    private var visibleChapters: [QubricChapter] {
        guard solved < QubricData.allPuzzles.count, let activeId = activeChapterId(profile: profile) else {
            return QubricData.chapters
        }
        return QubricData.chapters.filter { chapter in
            chapter.id == activeId || chapter.puzzles.contains { profile.completed[$0.id] == true }
        }
    }

    private var hiddenLockedChapterCount: Int {
        guard solved < QubricData.allPuzzles.count, let activeId = activeChapterId(profile: profile) else {
            return 0
        }
        return QubricData.chapters.filter { chapter in
            chapter.id != activeId && !chapter.puzzles.contains { profile.completed[$0.id] == true }
        }.count
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                QubricPageHeader(title: "Journey")

                List {
                    Section {
                        JourneyHeader(profile: profile, nextPuzzle: firstPlayablePuzzle(profile: profile)) { puzzle in
                            onOpenPuzzle(puzzle)
                        }
                        .listRowInsets(EdgeInsets(top: 14, leading: 16, bottom: 18, trailing: 16))
                        .listRowSeparator(.hidden)
                    }
                    .listRowBackground(Color.qubricGrouped)

                    chapterRows
                }
                .listStyle(.plain)
                .listRowSeparatorTint(Color.qubricLine)
                .listSectionSpacing(.compact)
                .contentMargins(.top, 12, for: .scrollContent)
                .contentMargins(.bottom, 96, for: .scrollContent)
                .scrollContentBackground(.hidden)
            }
            .background(Color.qubricGrouped.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    @ViewBuilder
    private var chapterRows: some View {
        ForEach(visibleChapters) { chapter in
            if allPuzzlesLocked(chapter: chapter, profile: profile) {
                LockedChapterSection(chapter: chapter)
            } else {
                ChapterPathSection(
                    chapter: chapter,
                    profile: profile,
                    active: chapter.id == activeChapterId(profile: profile),
                    firstRun: solved == 0 && chapter.id == activeChapterId(profile: profile),
                    currentPuzzleId: firstPlayablePuzzle(profile: profile)?.id,
                    isExpanded: expandedBinding(for: chapter),
                    onOpenPuzzle: onOpenPuzzle
                )
            }
        }
        if hiddenLockedChapterCount > 0 {
            LockedChapterRollup(count: hiddenLockedChapterCount)
        }
    }

    private func expandedBinding(for chapter: QubricChapter) -> Binding<Bool> {
        Binding(
            get: {
                (expandedChapterId ?? activeChapterId(profile: profile)) == chapter.id
            },
            set: { expanded in
                expandedChapterId = expanded ? chapter.id : ""
            }
        )
    }
}

private struct JourneyHeader: View {
    let profile: PlayerProfile
    let nextPuzzle: QuantumPuzzle?
    let onOpen: (QuantumPuzzle) -> Void

    private var solved: Int {
        profile.completed.values.filter { $0 }.count
    }

    private var total: Int {
        QubricData.allPuzzles.count
    }

    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(solved) / Double(total)
    }

    var body: some View {
        if let nextPuzzle {
            Button {
                onOpen(nextPuzzle)
            } label: {
                content(showsChevron: true)
                    .journeyCard()
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(accessibilityLabel))
            .accessibilityHint("Open the next puzzle")
        } else {
            content(showsChevron: false)
                .journeyCard()
                .accessibilityElement(children: .combine)
                .accessibilityLabel(Text(accessibilityLabel))
                .accessibilityHint("All puzzles are complete")
        }
    }

    private func content(showsChevron: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                statusIcon

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 10)

                if showsChevron {
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }

            ProgressView(value: progress)
                .tint(.qubricPrimary)

            HStack(spacing: 8) {
                Text("\(solved) of \(total) solved")
                Spacer()
                if profile.streak.current > 0 && solved > 0 {
                    Label("\(profile.streak.current) day streak", systemImage: "flame")
                } else {
                    Text(nextPuzzleIndexText)
                }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }

    private var statusIcon: some View {
        RoundedRectangle(cornerRadius: QubricTheme.smallCornerRadius, style: .continuous)
            .fill(nextPuzzle == nil ? Color.qubricSuccess.opacity(0.14) : Color.qubricPrimary.opacity(0.12))
            .frame(width: 38, height: 38)
            .overlay {
                Image(systemName: nextPuzzle == nil ? "checkmark.circle.fill" : "play.fill")
                    .font(.system(size: QubricTheme.iPadFontSize(16), weight: .semibold))
                    .foregroundStyle(nextPuzzle == nil ? Color.qubricSuccess : Color.qubricPrimary)
            }
    }

    private var title: String {
        nextPuzzle?.title ?? "Path complete"
    }

    private var subtitle: String {
        guard let nextPuzzle else {
            return "Every puzzle is solved."
        }
        return nextPuzzle.objective
    }

    private var nextPuzzleIndexText: String {
        guard let nextPuzzle else {
            return "Puzzle \(total) of \(total)"
        }
        let index = QubricData.allPuzzles.firstIndex { $0.id == nextPuzzle.id }.map { $0 + 1 } ?? 1
        return "Puzzle \(index) of \(total)"
    }

    private var accessibilityLabel: String {
        guard let nextPuzzle else {
            return "Puzzle path complete. \(solved) of \(total) solved."
        }
        return "Continue with \(nextPuzzle.title). \(nextPuzzle.objective). \(nextPuzzleIndexText)."
    }
}

private struct LockedChapterSection: View {
    let chapter: QubricChapter

    var body: some View {
        Section {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "lock.fill")
                    .font(.system(size: QubricTheme.iPadFontSize(15), weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)
                    .background(Color.qubricTrack.opacity(0.45), in: RoundedRectangle(cornerRadius: QubricTheme.smallCornerRadius, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text("Chapter \(chapter.number): \(chapter.title)")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(chapter.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    Text("\(chapter.puzzles.count) puzzles · \(chapter.theme)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 3)
            .journeyCard()
            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            .listRowSeparator(.hidden)
        }
        .listRowBackground(Color.qubricGrouped)
    }
}

private struct LockedChapterRollup: View {
    let count: Int

    var body: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .font(.system(size: QubricTheme.iPadFontSize(15), weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)
                    .background(Color.qubricTrack.opacity(0.45), in: RoundedRectangle(cornerRadius: QubricTheme.smallCornerRadius, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text("\(count) \(count == 1 ? "chapter" : "chapters") locked")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("Finish the current chapter to reveal the next set.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .padding(.vertical, 3)
            .journeyCard()
            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            .listRowSeparator(.hidden)
        }
        .listRowBackground(Color.qubricGrouped)
    }
}

private struct ChapterPathSection: View {
    let chapter: QubricChapter
    let profile: PlayerProfile
    let active: Bool
    let firstRun: Bool
    let currentPuzzleId: String?
    let isExpanded: Binding<Bool>
    let onOpenPuzzle: (QuantumPuzzle) -> Void

    private var finished: Int {
        chapter.puzzles.filter { profile.completed[$0.id] == true }.count
    }

    private var visibleRows: [(index: Int, puzzle: QuantumPuzzle)] {
        guard active || finished > 0 else { return [] }
        return chapter.puzzles.enumerated().map { index, puzzle in (index, puzzle) }
    }

    var body: some View {
        Section {
            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    isExpanded.wrappedValue.toggle()
                }
            } label: {
                chapterHeader
            }
            .buttonStyle(.plain)
            .journeyCard()
            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.qubricGrouped)

            if isExpanded.wrappedValue {
                ForEach(visibleRows, id: \.puzzle.id) { row in
                    PuzzlePathRow(
                        puzzle: row.puzzle,
                        step: row.index + 1,
                        unlocked: profile.unlocked[row.puzzle.id] == true,
                        completed: profile.completed[row.puzzle.id] == true,
                        best: profile.solveStats[row.puzzle.id],
                        firstRunHighlight: firstRun && row.index == 0,
                        current: row.puzzle.id == currentPuzzleId,
                        onOpen: { onOpenPuzzle(row.puzzle) }
                    )
                    .journeyCard()
                    .listRowInsets(EdgeInsets(top: 7, leading: 16, bottom: 7, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.qubricGrouped)
                }
                if visibleRows.isEmpty {
                    Text(chapterSummary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 4)
                        .journeyCard()
                        .listRowInsets(EdgeInsets(top: 7, leading: 16, bottom: 7, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.qubricGrouped)
                }
            }
        }
    }

    private var chapterHeader: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Chapter \(chapter.number): \(chapter.title)")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(chapter.theme)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(finished)/\(chapter.puzzles.count)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(active ? Color.qubricPrimary : .secondary)
                .monospacedDigit()

            Image(systemName: isExpanded.wrappedValue ? "chevron.down" : "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
                .frame(width: 12)
        }
        .padding(.vertical, 3)
        .contentShape(Rectangle())
    }

    private var chapterSummary: String {
        if finished == chapter.puzzles.count { return "Chapter complete" }
        if chapter.puzzles.contains(where: { profile.unlocked[$0.id] == true }) { return "Continue from the current path." }
        return "Locked until the previous chapter is solved."
    }
}

private struct PuzzlePathRow: View {
    let puzzle: QuantumPuzzle
    let step: Int
    let unlocked: Bool
    let completed: Bool
    let best: SolveStats?
    let firstRunHighlight: Bool
    let current: Bool
    let onOpen: () -> Void

    var body: some View {
        Button(action: {
            guard unlocked else { return }
            onOpen()
        }) {
            HStack(spacing: 12) {
                statusMarker

                VStack(alignment: .leading, spacing: 3) {
                    Text(puzzle.title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(rowDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    Text(rowMeta)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 10)

                if unlocked {
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(unlocked || completed ? 1 : 0.58)
        .accessibilityValue(unlocked ? "Unlocked" : "Locked")
        .accessibilityHint(unlocked ? "Open puzzle" : "Complete the previous puzzle to unlock.")
    }

    private var rowMeta: String {
        if best?.perfect == true {
            return bestMoveText(prefix: "Perfect")
        }
        if completed {
            return bestMoveText(prefix: "Solved")
        }
        if !unlocked {
            return "Locked"
        }
        return "\(puzzle.difficulty) · \(puzzle.xp) XP"
    }

    private func bestMoveText(prefix: String) -> String {
        guard let moves = best?.bestGateCount else { return prefix }
        return "\(prefix) · \(moves) \(moves == 1 ? "move" : "moves") best"
    }

    private var rowDescription: String {
        if !unlocked {
            return "Unlocks after \(previousPuzzleTitle(for: puzzle.id))."
        }
        if current || firstRunHighlight {
            return puzzle.objective
        }
        if completed {
            return puzzle.recap
        }
        return moveTargetLabel(for: puzzle)
    }

    private var statusMarker: some View {
        Circle()
            .fill(markerFill)
            .frame(width: 32, height: 32)
            .overlay {
                markerContent
            }
        .frame(width: 36, height: 36)
    }

    @ViewBuilder
    private var markerContent: some View {
        if completed {
            Image(systemName: best?.perfect == true ? "checkmark.seal.fill" : "checkmark")
                .font(.system(size: QubricTheme.iPadFontSize(14), weight: .semibold))
                .foregroundStyle(best?.perfect == true ? Color.white : Color.qubricSuccess)
        } else if unlocked {
            Text("\(step)")
                .font(.system(size: QubricTheme.iPadFontSize(14), weight: .semibold))
                .foregroundStyle(isHighlighted ? Color.white : Color.qubricPrimary)
        } else {
            Image(systemName: "lock.fill")
                .font(.system(size: QubricTheme.iPadFontSize(12), weight: .semibold))
                .foregroundStyle(.secondary)
        }
    }

    private var markerFill: Color {
        if best?.perfect == true || isHighlighted { return Color.qubricPrimary }
        if completed { return Color.qubricSuccess.opacity(0.14) }
        if unlocked { return Color.qubricPrimary.opacity(0.12) }
        return Color.qubricTrack.opacity(0.45)
    }

    private var isHighlighted: Bool {
        firstRunHighlight || current
    }
}

private func moveTargetLabel(for puzzle: QuantumPuzzle) -> String {
    guard puzzle.showMoveTarget else { return puzzle.practiceLabel ?? "Practice" }
    return "\(puzzle.optimalGates) \(puzzle.optimalGates == 1 ? "move" : "moves") target"
}

private func previousPuzzleTitle(for id: String) -> String {
    guard let index = QubricData.allPuzzles.firstIndex(where: { $0.id == id }), index > 0 else {
        return "the previous puzzle"
    }
    return QubricData.allPuzzles[index - 1].title
}

private func firstPlayablePuzzle(profile: PlayerProfile) -> QuantumPuzzle? {
    if let next = QubricData.allPuzzles.first(where: { profile.unlocked[$0.id] == true && profile.completed[$0.id] != true }) {
        return next
    }
    return profile.completed.values.contains(true) ? nil : QubricData.allPuzzles.first
}

private func activeChapterId(profile: PlayerProfile) -> String? {
    guard let chapterNumber = firstPlayablePuzzle(profile: profile)?.chapterNumber else { return nil }
    return QubricData.chapters.first(where: { $0.number == chapterNumber })?.id
}

private func allPuzzlesLocked(chapter: QubricChapter, profile: PlayerProfile) -> Bool {
    chapter.puzzles.allSatisfy { puzzle in
        profile.unlocked[puzzle.id] != true && profile.completed[puzzle.id] != true
    }
}

private extension View {
    func journeyCard() -> some View {
        self
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Color.qubricSurface, in: RoundedRectangle(cornerRadius: QubricTheme.cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: QubricTheme.cornerRadius, style: .continuous)
                    .stroke(Color.qubricTileLine, lineWidth: QubricTheme.tileStrokeWidth)
            }
            .iPadReadableWidth()
    }
}
