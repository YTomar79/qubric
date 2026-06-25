//
//  DailyView.swift
//  Qubric
//
//  Daily challenge screen and its session flow.
//

import SwiftUI

struct DailyView: View {
    @ObservedObject var store: QubricStore
    let onOpenPuzzle: (QuantumPuzzle) -> Void

    @State private var daily = QubricDailyChallenge.local()
    @State private var history: [QubricDailyHistoryEntry] = []
    @State private var now = Date()
    @State private var lastRefreshAttempt = Date.distantPast

    private let resetTicker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var dailyPuzzle: QuantumPuzzle {
        QubricData.puzzle(id: daily.puzzleId) ?? QubricData.allPuzzles[0]
    }

    private var solvedToday: Bool {
        history.first(where: { $0.date == daily.date })?.solved == true
    }

    private var dailyEligible: Bool {
        QubricData.isDailyEligible(completed: store.profile?.completed ?? [:])
    }

    private var profile: PlayerProfile {
        store.profile ?? PlayerProfile(name: "Qubric Player")
    }

    private var nextFoundationPuzzle: QuantumPuzzle {
        return QubricData.allPuzzles.first { profile.unlocked[$0.id] == true && profile.completed[$0.id] != true }
            ?? QubricData.puzzle(id: QubricData.firstPuzzleId)
            ?? QubricData.allPuzzles[0]
    }

    private var unlockPuzzle: QuantumPuzzle? {
        QubricData.puzzle(id: QubricData.dailyUnlockPuzzleId)
    }

    private var currentStreak: Int {
        profile.streak.current
    }

    private var foundationPuzzles: [QuantumPuzzle] {
        guard let unlockIndex = QubricData.allPuzzles.firstIndex(where: { $0.id == QubricData.dailyUnlockPuzzleId }) else {
            return []
        }
        return Array(QubricData.allPuzzles.prefix(unlockIndex + 1))
    }

    private var completedFoundationCount: Int {
        foundationPuzzles.filter { profile.completed[$0.id] == true }.count
    }

    private var foundationProgress: Double {
        guard !foundationPuzzles.isEmpty else { return 0 }
        return Double(completedFoundationCount) / Double(foundationPuzzles.count)
    }

    private var foundationStatus: String {
        "\(completedFoundationCount)/\(foundationPuzzles.isEmpty ? 0 : foundationPuzzles.count)"
    }

    private var resetDate: Date {
        dailyResetDate(for: daily)
    }

    private var resetCountdown: String {
        formattedResetCountdown(from: now, to: resetDate)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                QubricPageHeader(title: "Daily")

                List {
                    if dailyEligible {
                        dailyPlayContent
                        dailyDetailsContent

                        Section {
                            DailyHistoryStrip(history: history, daily: daily, solvedToday: solvedToday)
                                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 18, trailing: 16))
                                .listRowSeparator(.hidden)
                        } header: {
                            Text("History")
                                .textCase(nil)
                                .padding(.top, 14)
                                .padding(.bottom, 4)
                        }
                        .listRowBackground(Color.qubricGrouped)
                    } else {
                        lockedContent
                        unlockPathContent
                        lockedDetailsContent
                    }
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
            .task {
                await loadDailyContent()
            }
            .task(id: store.dailyHistoryRefreshID) {
                await refreshDailyHistory()
            }
            .onReceive(resetTicker) { date in
                now = date
                refreshDailyAfterResetIfNeeded(date)
            }
        }
    }

    @ViewBuilder
    private var dailyPlayContent: some View {
        Section {
            DailyPlayFeatureRow(
                puzzle: dailyPuzzle,
                solvedToday: solvedToday,
                currentStreak: currentStreak
            ) {
                onOpenPuzzle(dailyPuzzle)
            }
            .listRowInsets(EdgeInsets(top: 14, leading: 16, bottom: 16, trailing: 16))
            .listRowSeparator(.hidden)
        }
        .listRowBackground(Color.qubricGrouped)
    }

    @ViewBuilder
    private var dailyDetailsContent: some View {
        Section {
            DailyDetailsSummary(
                dateText: formattedDailyDate(daily.date),
                resetText: resetCountdown,
                targetText: "\(dailyPuzzle.optimalGates) \(dailyPuzzle.optimalGates == 1 ? "move" : "moves")",
                rewardText: "\(dailyPuzzle.xp) XP + \(daily.streakBonusXp) bonus XP",
                streakText: "\(currentStreak) \(currentStreak == 1 ? "day" : "days")"
            )
            .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 22, trailing: 16))
            .listRowSeparator(.hidden)
        }
        .listRowBackground(Color.qubricGrouped)
    }

    @ViewBuilder
    private var lockedDetailsContent: some View {
        Section {
            DailyDetailsSummary(
                dateText: "Daily unlocks after Chapter 1",
                resetText: resetCountdown,
                targetText: unlockPuzzle?.title ?? "Chapter 1",
                rewardText: "\(daily.streakBonusXp) bonus XP",
                streakText: foundationStatus
            )
            .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 14, trailing: 16))
            .listRowSeparator(.hidden)
        }
        .listRowBackground(Color.qubricGrouped)
    }

    @ViewBuilder
    private var lockedContent: some View {
        Section {
            DailyLockedFeatureRow(
                progress: foundationProgress,
                progressText: foundationStatus,
                completedCount: completedFoundationCount,
                totalCount: foundationPuzzles.count,
                nextTitle: nextFoundationPuzzle.title
            ) {
                onOpenPuzzle(nextFoundationPuzzle)
            }
            .listRowInsets(EdgeInsets(top: 14, leading: 16, bottom: 16, trailing: 16))
            .listRowSeparator(.hidden)
        }
        .listRowBackground(Color.qubricGrouped)
    }

    @ViewBuilder
    private var unlockPathContent: some View {
        Section {
            if QubricTheme.isPad {
                VStack(spacing: 0) {
                    ForEach(foundationPuzzles) { puzzle in
                        DailyUnlockPathRow(
                            puzzle: puzzle,
                            step: foundationStep(for: puzzle),
                            unlocked: profile.unlocked[puzzle.id] == true,
                            completed: profile.completed[puzzle.id] == true,
                            current: puzzle.id == nextFoundationPuzzle.id
                        ) {
                            onOpenPuzzle(puzzle)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)

                        if foundationPuzzles.last?.id != puzzle.id {
                            Divider()
                                .overlay(Color.qubricLine)
                                .padding(.leading, 58)
                        }
                    }
                }
                .background(Color.qubricSurface, in: RoundedRectangle(cornerRadius: QubricTheme.cornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: QubricTheme.cornerRadius, style: .continuous)
                        .stroke(Color.qubricTileLine, lineWidth: QubricTheme.tileStrokeWidth)
                }
                .iPadReadableWidth()
                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 18, trailing: 16))
                .listRowSeparator(.hidden)
            } else {
                ForEach(foundationPuzzles) { puzzle in
                    DailyUnlockPathRow(
                        puzzle: puzzle,
                        step: foundationStep(for: puzzle),
                        unlocked: profile.unlocked[puzzle.id] == true,
                        completed: profile.completed[puzzle.id] == true,
                        current: puzzle.id == nextFoundationPuzzle.id
                    ) {
                        onOpenPuzzle(puzzle)
                    }
                    .listRowInsets(EdgeInsets(top: 11, leading: 16, bottom: 11, trailing: 16))
                }
            }
        } header: {
            Text("Chapter 1 progress").textCase(nil)
        }
        .listRowBackground(Color.qubricGrouped)
    }

    private func foundationStep(for puzzle: QuantumPuzzle) -> Int {
        foundationPuzzles.firstIndex { $0.id == puzzle.id }.map { $0 + 1 } ?? 1
    }

    @MainActor
    private func loadDailyContent() async {
        daily = await store.loadDailyChallenge()
        await refreshDailyHistory()
    }

    @MainActor
    private func refreshDailyHistory() async {
        history = dailyEligible ? await store.loadDailyHistory() : []
    }

    private func refreshDailyAfterResetIfNeeded(_ date: Date) {
        guard date >= resetDate else { return }
        guard date.timeIntervalSince(lastRefreshAttempt) > 30 else { return }

        lastRefreshAttempt = date
        Task {
            await loadDailyContent()
        }
    }
}

private func formattedDailyDate(_ value: String) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    let date = formatter.date(from: value) ?? Date()

    let output = DateFormatter()
    output.dateStyle = .medium
    output.timeZone = TimeZone(secondsFromGMT: 0)
    return "\(output.string(from: date)) UTC"
}

private func dailyResetDate(for daily: QubricDailyChallenge) -> Date {
    if let refreshesAt = daily.refreshesAt, let date = parsedRefreshDate(refreshesAt) {
        return date
    }

    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? TimeZone.current

    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.timeZone = calendar.timeZone

    guard let date = formatter.date(from: daily.date) else {
        return calendar.nextDate(after: Date(), matching: DateComponents(hour: 0, minute: 0, second: 0), matchingPolicy: .nextTime) ?? Date().addingTimeInterval(86_400)
    }
    return calendar.date(byAdding: .day, value: 1, to: date) ?? date.addingTimeInterval(86_400)
}

private func parsedRefreshDate(_ value: String) -> Date? {
    let fractional = ISO8601DateFormatter()
    fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = fractional.date(from: value) {
        return date
    }

    return ISO8601DateFormatter().date(from: value)
}

private func formattedResetCountdown(from now: Date, to resetDate: Date) -> String {
    let secondsRemaining = max(0, Int(resetDate.timeIntervalSince(now).rounded(.down)))
    guard secondsRemaining > 0 else { return "Refreshing soon" }

    let hours = secondsRemaining / 3_600
    let minutes = (secondsRemaining % 3_600) / 60
    let seconds = secondsRemaining % 60

    if hours > 0 {
        return "\(hours)h \(minutes)m \(seconds)s"
    }
    return "\(minutes)m \(seconds)s"
}

private func dailyMoveTargetLabel(for puzzle: QuantumPuzzle) -> String {
    guard puzzle.showMoveTarget else { return puzzle.practiceLabel ?? "Practice" }
    return "\(puzzle.optimalGates) \(puzzle.optimalGates == 1 ? "move" : "moves") target"
}

private struct DailyPlayFeatureRow: View {
    let puzzle: QuantumPuzzle
    let solvedToday: Bool
    let currentStreak: Int
    let action: () -> Void

    private var statusText: String {
        solvedToday ? "Solved" : "Ready"
    }

    private var statusColor: Color {
        solvedToday ? .qubricSuccess : .qubricPrimaryStrong
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                DailyStatusIcon(systemImage: solvedToday ? "checkmark.circle.fill" : "calendar")

                VStack(alignment: .leading, spacing: 7) {
                    Text(solvedToday ? "Daily complete" : "Daily challenge")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(puzzle.title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(puzzle.objective)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                Text(statusText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(statusColor)
                    .lineLimit(1)
            }

            if solvedToday {
                Label("Solved today", systemImage: "checkmark.circle.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(statusColor)
            } else if currentStreak > 0 {
                Label("\(currentStreak) day streak", systemImage: "flame")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.qubricPrimary)
            }

            DailyActionButton(
                title: solvedToday ? "Replay Daily" : "Play Daily",
                systemImage: solvedToday ? "arrow.clockwise" : "play.fill",
                action: action
            )
            .padding(.top, 2)
        }
        .padding(14)
        .background(Color.qubricSurface, in: RoundedRectangle(cornerRadius: QubricTheme.cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: QubricTheme.cornerRadius, style: .continuous)
                .stroke(Color.qubricTileLine, lineWidth: QubricTheme.tileStrokeWidth)
        }
        .iPadReadableWidth()
        .accessibilityElement(children: .contain)
    }
}

private struct DailyLockedFeatureRow: View {
    let progress: Double
    let progressText: String
    let completedCount: Int
    let totalCount: Int
    let nextTitle: String
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                DailyStatusIcon(systemImage: "lock.fill")

                VStack(alignment: .leading, spacing: 7) {
                    Text("Daily locked")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)

                Text("Finish Chapter 1 to unlock the daily challenge.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                Text(progressText)
                    .font(.subheadline.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(completedCount) of \(totalCount) complete")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Spacer(minLength: 12)
                }

                ProgressView(value: progress)
                    .tint(.qubricPrimary)

                Text("Next: \(nextTitle)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            DailyActionButton(
                title: "Continue Chapter 1",
                systemImage: "play.fill",
                minHeight: 44,
                textFont: .subheadline.weight(.semibold),
                iconSize: 14,
                action: action
            )
            .padding(.top, 4)
        }
        .padding(14)
        .background(Color.qubricSurface, in: RoundedRectangle(cornerRadius: QubricTheme.cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: QubricTheme.cornerRadius, style: .continuous)
                .stroke(Color.qubricTileLine, lineWidth: QubricTheme.tileStrokeWidth)
        }
        .iPadReadableWidth()
        .accessibilityElement(children: .combine)
    }
}

private struct DailyStatusIcon: View {
    let systemImage: String

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: QubricTheme.iPadFontSize(18), weight: .semibold))
            .foregroundStyle(Color.qubricPrimaryStrong)
            .frame(width: 40, height: 40)
            .background(Color.qubricPrimary.opacity(0.12), in: RoundedRectangle(cornerRadius: QubricTheme.smallCornerRadius, style: .continuous))
    }
}

private struct DailyUnlockPathRow: View {
    let puzzle: QuantumPuzzle
    let step: Int
    let unlocked: Bool
    let completed: Bool
    let current: Bool
    let action: () -> Void

    var body: some View {
        Button {
            guard unlocked else { return }
            action()
        } label: {
            HStack(spacing: 11) {
                marker

                VStack(alignment: .leading, spacing: 2) {
                    Text(puzzle.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(rowDescription)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 12)

                Text(rowState)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(current ? Color.qubricPrimary : .secondary)
                    .lineLimit(1)

                if unlocked {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(unlocked || completed ? 1 : 0.58)
        .accessibilityElement(children: .combine)
        .accessibilityValue(rowState)
        .accessibilityHint(unlocked ? "Open puzzle" : "Complete the previous puzzle to unlock.")
    }

    private var marker: some View {
        Circle()
            .fill(markerBackground)
            .frame(width: 30, height: 30)
            .overlay {
                Group {
                    if completed {
                        Image(systemName: "checkmark")
                    } else if unlocked {
                        Text("\(step)")
                    } else {
                        Image(systemName: "lock.fill")
                    }
                }
                .font(.system(size: QubricTheme.iPadFontSize(13), weight: .semibold))
                .foregroundStyle(markerForeground)
            }
    }

    private var markerBackground: Color {
        if completed || current { return Color.qubricPrimary }
        return Color.qubricSecondaryGrouped
    }

    private var markerForeground: Color {
        if completed || current { return .white }
        return unlocked ? Color.qubricPrimary : .secondary
    }

    private var rowState: String {
        if completed { return "Solved" }
        if current { return "Next" }
        return unlocked ? "Ready" : "Locked"
    }

    private var rowDescription: String {
        if completed { return "Solved" }
        if current { return dailyMoveTargetLabel(for: puzzle) }
        if unlocked { return "Ready" }
        return "Finish the previous puzzle"
    }
}

private struct DailyDetailsSummary: View {
    let dateText: String
    let resetText: String
    let targetText: String
    let rewardText: String
    let streakText: String

    var body: some View {
        VStack(spacing: 0) {
            DailyInfoRow(title: "Resets", value: resetText)
            DailyDivider()
            DailyInfoRow(title: "Target", value: targetText)
            DailyDivider()
            DailyInfoRow(title: "Reward", value: rewardText)
            DailyDivider()
            DailyInfoRow(title: "Streak", value: streakText)
            DailyDivider()
            DailyInfoRow(title: "Date", value: dateText, valueStyle: .secondary)
        }
        .background(Color.qubricSurface, in: RoundedRectangle(cornerRadius: QubricTheme.cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: QubricTheme.cornerRadius, style: .continuous)
                .stroke(Color.qubricTileLine, lineWidth: QubricTheme.tileStrokeWidth)
        }
        .iPadReadableWidth()
        .accessibilityElement(children: .combine)
    }
}

private struct DailyInfoRow: View {
    let title: String
    let value: String
    var valueStyle: Color = .primary

    private var titleWidth: CGFloat {
        QubricTheme.isPad ? QubricTheme.iPadMetric(86) : 64
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(width: titleWidth, alignment: .leading)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(valueStyle)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .accessibilityElement(children: .combine)
    }
}

private struct DailyDivider: View {
    var body: some View {
        Divider()
            .overlay(Color.qubricLine)
            .padding(.leading, 14)
    }
}

private struct DailyActionButton: View {
    let title: String
    let systemImage: String
    var minHeight: CGFloat = 48
    var textFont: Font = .body.weight(.semibold)
    var iconSize: CGFloat = 15
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Spacer(minLength: 0)
                Image(systemName: systemImage)
                    .font(.system(size: QubricTheme.iPadFontSize(iconSize), weight: .semibold))
                Text(title)
                    .font(textFont)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: minHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.roundedRectangle(radius: QubricTheme.smallCornerRadius))
        .accessibilityLabel(title)
    }
}

private struct DailyHistoryStrip: View {
    let history: [QubricDailyHistoryEntry]
    let daily: QubricDailyChallenge
    let solvedToday: Bool

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    private var days: [DailyHistoryDay] {
        let today = daily.date
        let byDate = Dictionary(uniqueKeysWithValues: history.map { ($0.date, $0) })
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        let weekdayFormatter = DateFormatter()
        weekdayFormatter.dateFormat = "EEEEE"
        weekdayFormatter.timeZone = formatter.timeZone
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "d"
        dayFormatter.timeZone = formatter.timeZone
        let todayDate = formatter.date(from: today) ?? Date()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = formatter.timeZone

        return (0..<56).map { index in
            let offset = index - 55
            let date = calendar.date(byAdding: .day, value: offset, to: todayDate) ?? todayDate
            let key = formatter.string(from: date)
            let solved = byDate[key]?.solved == true || (key == daily.date && solvedToday)
            return DailyHistoryDay(
                date: key,
                weekday: weekdayFormatter.string(from: date),
                dayNumber: dayFormatter.string(from: date),
                solved: solved,
                current: key == today
            )
        }
    }

    private var recentDays: [DailyHistoryDay] {
        Array(days.suffix(14))
    }

    private var solvedRecentCount: Int {
        recentDays.filter(\.solved).count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("Last 14 days")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Spacer(minLength: 10)

                Text("\(solvedRecentCount) of 14")
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            if history.isEmpty && !solvedToday {
                Text("No daily solves yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
            } else {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(recentDays) { day in
                        DailyHistoryDayCell(day: day)
                    }
                }

                HStack(spacing: 14) {
                    DailyHistoryLegendItem(color: .qubricPrimary, title: "Solved")
                    DailyHistoryLegendItem(color: .qubricPhase, title: "Today", outlined: true)
                    Spacer(minLength: 0)
                }
                .padding(.top, 1)
            }
        }
        .padding(14)
        .background(Color.qubricSurface, in: RoundedRectangle(cornerRadius: QubricTheme.cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: QubricTheme.cornerRadius, style: .continuous)
                .stroke(Color.qubricTileLine, lineWidth: QubricTheme.tileStrokeWidth)
        }
        .iPadReadableWidth()
        .accessibilityElement(children: .contain)
    }
}

private struct DailyHistoryDayCell: View {
    let day: DailyHistoryDay

    var body: some View {
        VStack(spacing: 4) {
            Text(day.weekday)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Text(day.dayNumber)
                .font(.caption2.monospacedDigit().weight(day.solved || day.current ? .semibold : .regular))
                .foregroundStyle(day.solved ? Color.white : Color.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 26)
                .background(cellFill, in: RoundedRectangle(cornerRadius: 5, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .stroke(day.current ? Color.qubricPhase : Color.qubricLine, lineWidth: day.current ? 2 : QubricTheme.hairlineWidth)
                }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(day.date), \(day.solved ? "solved" : "not solved")\(day.current ? ", today" : "")")
    }

    private var cellFill: Color {
        day.solved ? Color.qubricPrimary : Color.qubricSecondaryGrouped
    }
}

private struct DailyHistoryLegendItem: View {
    let color: Color
    let title: String
    var outlined = false

    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(outlined ? Color.clear : color)
                .frame(width: 10, height: 10)
                .overlay {
                    if outlined {
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .stroke(color, lineWidth: 1.5)
                    }
                }

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct DailyHistoryDay: Identifiable {
    let date: String
    let weekday: String
    let dayNumber: String
    let solved: Bool
    let current: Bool

    var id: String { date }
}
