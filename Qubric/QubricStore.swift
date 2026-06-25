//
//  QubricStore.swift
//  Qubric
//
//  Central observable app state and persistence.
//

import Darwin
import Foundation

@MainActor
struct QubricSyncResult {
    let savedRemotely: Bool
    let message: String?
    let earnedXp: Int
    let scoreBreakdown: ScoreBreakdown?
}

struct LevelUpEvent: Identifiable, Equatable {
    let id = UUID()
    let from: Int
    let to: Int
}

struct BadgeEarnedEvent: Identifiable, Equatable {
    let id: UUID
    let badgeId: String
    let label: String

    init(id: UUID = UUID(), badgeId: String, label: String) {
        self.id = id
        self.badgeId = badgeId
        self.label = label
    }
}

private struct PendingPuzzleSolve: Codable, Equatable {
    let puzzleId: String
    let gates: [String]
    let hintsUsed: Int
    let cleanSolver: Bool
    let dailyDate: String?
    let queuedAt: Date

    enum CodingKeys: String, CodingKey {
        case puzzleId
        case gates
        case hintsUsed
        case cleanSolver
        case dailyDate
        case queuedAt
    }

    init(puzzleId: String, gates: [String], hintsUsed: Int, cleanSolver: Bool, dailyDate: String? = nil, queuedAt: Date) {
        self.puzzleId = puzzleId
        self.gates = gates
        self.hintsUsed = hintsUsed
        self.cleanSolver = cleanSolver
        self.dailyDate = dailyDate
        self.queuedAt = queuedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        puzzleId = try container.decode(String.self, forKey: .puzzleId)
        gates = try container.decode([String].self, forKey: .gates)
        hintsUsed = try container.decode(Int.self, forKey: .hintsUsed)
        cleanSolver = try container.decodeIfPresent(Bool.self, forKey: .cleanSolver) ?? false
        dailyDate = try container.decodeIfPresent(String.self, forKey: .dailyDate)
        queuedAt = try container.decode(Date.self, forKey: .queuedAt)
    }

    func matches(puzzleId: String, gates: [String], hintsUsed: Int, cleanSolver: Bool, dailyDate: String?) -> Bool {
        self.puzzleId == puzzleId
            && self.gates == gates
            && self.hintsUsed == hintsUsed
            && self.cleanSolver == cleanSolver
            && self.dailyDate == dailyDate
    }
}

@MainActor
final class QubricStore: ObservableObject {
    @Published var profile: PlayerProfile?
    @Published var isLoading = false
    @Published var isRestoringSession = false
    @Published var syncMessage = ""
    @Published var levelUpEvent: LevelUpEvent?
    @Published var badgeEarnedEvent: BadgeEarnedEvent?
    @Published var dailyHistoryRefreshID = UUID()

    private let cachedProfileKey = "qubric.cachedCloudProfile.v1"
    private let pendingSolvesKey = "qubric.pendingPuzzleSolves.v1"
    private let api = QubricAPIClient()
    private let notificationManager = QubricNotificationManager.shared
    private var session = QubricKeychain.load()
    private var pendingBadgeEvents: [BadgeEarnedEvent] = []
    private var appIsActive = true
    private var badgeNotificationRequestToken = UUID()

    init() {
        clearRetiredLocalAccountState()

        guard session != nil else {
            profile = nil
            clearCachedProfile()
            clearPendingSolves()
            return
        }

        profile = loadCachedProfile()
        isRestoringSession = true
        Task { await restoreSession() }
    }

    func createAccount(username: String, email: String, password: String) async -> String? {
        let trimmedName = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedName.range(of: #"^[A-Za-z0-9][A-Za-z0-9_-]{1,23}$"#, options: .regularExpression) != nil else {
            return "Use 2-24 characters: letters, numbers, underscore, or dash."
        }
        guard trimmedEmail.range(of: #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#, options: .regularExpression) != nil else {
            return "Enter a valid email address."
        }
        guard password.count >= 8 else { return "Use an 8+ character password." }

        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await api.signup(
                username: trimmedName,
                email: trimmedEmail,
                password: password
            )

            guard QubricAuthSession(response: response) != nil, response.progress != nil else {
                return response.warning ?? "Could not start your cloud account."
            }

            guard let next = try saveAccountResponse(response, fallback: profile) else {
                return response.warning ?? "Could not start your cloud account."
            }

            profile = next
            saveCachedProfile(next)
            await flushPendingSolves(emitBadgeEvents: false)
            syncMessage = "Cloud account ready."
            return nil
        } catch {
            return error.localizedDescription
        }
    }

    func login(username: String, password: String) async -> String? {
        let trimmedName = username.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else { return "Enter your username or email." }
        guard !password.isEmpty else { return "Enter your password." }

        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await api.login(username: trimmedName, password: password)
            guard QubricAuthSession(response: response) != nil, response.progress != nil else {
                return response.warning ?? "Could not load your cloud profile."
            }

            guard let next = try saveAccountResponse(response, fallback: profile) else {
                return "Could not load your cloud profile."
            }

            profile = next
            saveCachedProfile(next)
            await flushPendingSolves(emitBadgeEvents: false)
            syncMessage = "Cloud progress restored."
            return nil
        } catch {
            return error.localizedDescription
        }
    }

    func logout() {
        let accessToken = session?.accessToken
        session = nil
        QubricKeychain.clear()
        clearCachedProfile()
        clearPendingSolves()
        clearBadgeEarnedEvents()
        levelUpEvent = nil
        profile = nil
        syncMessage = ""

        if let accessToken {
            Task {
                _ = try? await api.logout(accessToken: accessToken)
            }
        }
    }

    func deleteAccount() async {
        guard session != nil else {
            clearSessionState(message: QubricAPIError.missingSession.localizedDescription)
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await withAccessToken { token in
                try await self.api.deleteAccount(accessToken: token)
            }
            session = nil
            QubricKeychain.clear()
            clearCachedProfile()
            clearPendingSolves()
            clearBadgeEarnedEvents()
            levelUpEvent = nil
            profile = nil
            syncMessage = "Account deleted."
        } catch {
            syncMessage = error.localizedDescription
        }
    }

    func complete(_ puzzle: QuantumPuzzle, gates: [String], hintsUsed: Int) async -> QubricSyncResult {
        guard let current = profile else {
            let message = QubricAPIError.missingSession.localizedDescription
            syncMessage = message
            return QubricSyncResult(savedRemotely: false, message: message, earnedXp: 0, scoreBreakdown: nil)
        }
        let cleanSolver = !current.settings.hintsEnabled
        let replayReward: Bool? = current.completed[puzzle.id] == true ? false : nil
        let dailyChallenge = QubricDailyChallenge.local()
        let dailyEligibleForSolve =
            QubricData.isDailyEligible(completed: current.completed)
            || puzzle.id == QubricData.dailyUnlockPuzzleId
        let dailyDate = dailyEligibleForSolve && puzzle.id == dailyChallenge.puzzleId
            ? dailyChallenge.date
            : nil
        var earnedXp = 0

        do {
            let local = try locallyCompletedProfile(current, puzzle: puzzle, gates: gates, hintsUsed: hintsUsed)
            earnedXp = local.earned
            profile = local.profile
            saveProfile(local.profile)
            publishLevelUpIfNeeded(from: current.xp, to: local.profile.xp)
            publishBadgeEarnedEvents(from: current, to: local.profile)
            queuePendingSolve(puzzleId: puzzle.id, gates: gates, hintsUsed: hintsUsed, cleanSolver: cleanSolver, dailyDate: dailyDate)
            syncMessage = "Saved on this device. Cloud sync pending."
        } catch {
            let message = error.localizedDescription
            syncMessage = message
            return QubricSyncResult(savedRemotely: false, message: message, earnedXp: 0, scoreBreakdown: nil)
        }

        do {
            let remote = try await withAccessToken { token in
                let response = try await self.api.complete(puzzleId: puzzle.id, gates: gates, hintsUsed: hintsUsed, accessToken: token, replayReward: replayReward, cleanSolver: cleanSolver)
                let daily = try await self.recordDailyCompletionIfNeeded(
                    puzzleId: puzzle.id,
                    gates: gates,
                    hintsUsed: hintsUsed,
                    accessToken: token,
                    dailyDate: dailyDate
                )
                return (response, daily)
            }
            let response = remote.0
            let daily = remote.1
            let progress = response.progress
            if daily?.completion != nil || daily?.alreadyClaimed == true {
                dailyHistoryRefreshID = UUID()
            }
            earnedXp = (response.earned ?? earnedXp) + (daily?.bonusXp ?? 0)
            var scoreBreakdown = response.scoreBreakdown ?? localScoreBreakdown(for: puzzle, gates: gates, hintsUsed: hintsUsed, previousStats: current.solveStats[puzzle.id], cleanSolver: cleanSolver)
            scoreBreakdown.dailyBonus = daily?.bonusXp
            scoreBreakdown.earned = earnedXp
            if let current = profile {
                let next = current.applying(progress: daily?.progress ?? progress)
                publishLevelUpIfNeeded(from: current.xp, to: next.xp)
                publishBadgeEarnedEvents(from: current, to: next)
                profile = next
                saveCachedProfile(next)
            }
            removePendingSolve(puzzleId: puzzle.id, gates: gates, hintsUsed: hintsUsed, cleanSolver: cleanSolver, dailyDate: dailyDate)
            syncMessage = "Cloud progress saved."
            return QubricSyncResult(savedRemotely: true, message: nil, earnedXp: earnedXp, scoreBreakdown: scoreBreakdown)
        } catch QubricAPIError.unauthorized {
            let message = QubricAPIError.unauthorized.localizedDescription
            clearSessionState(message: message)
            return QubricSyncResult(savedRemotely: false, message: message, earnedXp: earnedXp, scoreBreakdown: localScoreBreakdown(for: puzzle, gates: gates, hintsUsed: hintsUsed, previousStats: current.solveStats[puzzle.id], cleanSolver: cleanSolver))
        } catch QubricAPIError.missingSession {
            let message = QubricAPIError.missingSession.localizedDescription
            clearSessionState(message: message)
            return QubricSyncResult(savedRemotely: false, message: message, earnedXp: earnedXp, scoreBreakdown: localScoreBreakdown(for: puzzle, gates: gates, hintsUsed: hintsUsed, previousStats: current.solveStats[puzzle.id], cleanSolver: cleanSolver))
        } catch {
            let message = "Cloud sync will retry."
            syncMessage = "\(message) \(error.localizedDescription)"
            return QubricSyncResult(savedRemotely: false, message: message, earnedXp: earnedXp, scoreBreakdown: localScoreBreakdown(for: puzzle, gates: gates, hintsUsed: hintsUsed, previousStats: current.solveStats[puzzle.id], cleanSolver: cleanSolver))
        }
    }

    @discardableResult
    func recordReflection(puzzle: QuantumPuzzle, correct: Bool) async -> Int {
        guard let current = profile else { return 0 }
        let local = locallyReflectedProfile(current, puzzle: puzzle, correct: correct)
        profile = local.profile
        saveProfile(local.profile)
        publishBadgeEarnedEvents(from: current, to: local.profile)

        do {
            let response = try await withAccessToken { token in
                try await self.api.recordReflection(puzzleId: puzzle.id, correct: correct, accessToken: token)
            }
            if let current = profile {
                let next = current.applying(progress: response.progress)
                publishBadgeEarnedEvents(from: current, to: next)
                profile = next
                saveCachedProfile(next)
            }
            if response.earned ?? 0 > 0 {
                syncMessage = "Reflection bonus saved."
            }
            return response.earned ?? local.earned
        } catch QubricAPIError.unauthorized {
            clearSessionState(message: QubricAPIError.unauthorized.localizedDescription)
            return local.earned
        } catch QubricAPIError.missingSession {
            clearSessionState(message: QubricAPIError.missingSession.localizedDescription)
            return local.earned
        } catch {
            syncMessage = "Reflection saved on this device. Cloud sync pending."
            return local.earned
        }
    }

    func loadDailyChallenge() async -> QubricDailyChallenge {
        (try? await api.loadDailyChallenge()) ?? QubricDailyChallenge.local()
    }

    func loadDailyHistory() async -> [QubricDailyHistoryEntry] {
        guard session != nil else { return [] }

        return (try? await withAccessToken { token in
            try await self.api.loadDailyHistory(accessToken: token, days: 56)
        }) ?? []
    }

    func resetProgress() {
        clearBadgeEarnedEvents()
        levelUpEvent = nil
        dailyHistoryRefreshID = UUID()
        Task {
            _ = await syncProgress("Resetting cloud progress...") { token in
                try await self.api.resetProgress(accessToken: token).progress
            }
            dailyHistoryRefreshID = UUID()
        }
    }

    func toggleSound() {
        guard let current = profile else { return }
        setSound(!current.sound)
    }

    func setSound(_ enabled: Bool) {
        guard var current = profile else { return }
        current.sound = enabled
        profile = current
        saveProfile(current)

        Task {
            _ = await syncProgress("Saving preference...") { token in
                try await self.api.updatePreferences(sound: enabled, accessToken: token).progress
            }
        }
    }

    func setSettings(_ settings: PlayerSettings) {
        guard var current = profile else { return }
        current.settings = settings
        profile = current
        saveProfile(current)

        Task {
            _ = await syncProgress("Saving settings...") { token in
                try await self.api.updatePreferences(settings: settings, accessToken: token).progress
            }
        }
    }

    func setAvatarPreset(_ presetId: String?) {
        guard var current = profile else { return }
        current.avatarPresetId = presetId
        profile = current
        saveProfile(current)
    }

    func setBadgeNotificationsEnabled(_ enabled: Bool) {
        guard profile != nil else { return }

        guard enabled else {
            badgeNotificationRequestToken = UUID()
            var settings = profile?.settings ?? PlayerSettings()
            settings.badgeNotificationsEnabled = false
            setSettings(settings)
            syncMessage = "Badge alerts off."
            return
        }

        let requestToken = UUID()
        badgeNotificationRequestToken = requestToken

        Task {
            let allowed = await notificationManager.requestBadgeNotificationAuthorization()
            guard badgeNotificationRequestToken == requestToken else { return }

            if allowed {
                var settings = profile?.settings ?? PlayerSettings()
                settings.badgeNotificationsEnabled = true
                setSettings(settings)
                syncMessage = "Badge alerts on."
            } else {
                if profile?.settings.badgeNotificationsEnabled == true {
                    var settings = profile?.settings ?? PlayerSettings()
                    settings.badgeNotificationsEnabled = false
                    setSettings(settings)
                }
                syncMessage = "Badge alerts need notification permission in iOS Settings."
            }
        }
    }

    func setAppActive(_ active: Bool) {
        appIsActive = active
    }

    func dismissBadgeEarnedEvent() {
        badgeEarnedEvent = nil
        presentNextBadgeEventIfNeeded()
    }

    private func restoreSession() async {
        defer { isRestoringSession = false }
        do {
            let response = try await withAccessToken { token in
                try await api.me(accessToken: token)
            }
            if let next = try saveAccountResponse(response, fallback: profile) {
                profile = next
                saveCachedProfile(next)
                syncMessage = "Cloud progress restored."
                await flushPendingSolves(emitBadgeEvents: false)
            }
        } catch QubricAPIError.unauthorized {
            clearSessionState(message: QubricAPIError.unauthorized.localizedDescription)
        } catch QubricAPIError.missingSession {
            clearSessionState(message: QubricAPIError.missingSession.localizedDescription)
        } catch {
            syncMessage = error.localizedDescription
        }
    }

    @discardableResult
    private func syncProgress(_ message: String, operation: @escaping (String) async throws -> QubricAPIProgress) async -> String? {
        guard let current = profile else {
            let message = QubricAPIError.missingSession.localizedDescription
            syncMessage = message
            return message
        }
        syncMessage = message

        do {
            let progress = try await withAccessToken(operation)
            let next = current.applying(progress: progress)
            profile = next
            saveProfile(next)
            syncMessage = "Cloud progress saved."
            return nil
        } catch QubricAPIError.unauthorized {
            let message = QubricAPIError.unauthorized.localizedDescription
            clearSessionState(message: message)
            return message
        } catch QubricAPIError.missingSession {
            let message = QubricAPIError.missingSession.localizedDescription
            clearSessionState(message: message)
            return message
        } catch {
            let message = error.localizedDescription
            syncMessage = message
            return message
        }
    }

    private func withAccessToken<T>(_ operation: (String) async throws -> T) async throws -> T {
        guard let session else { throw QubricAPIError.missingSession }

        do {
            return try await operation(session.accessToken)
        } catch QubricAPIError.unauthorized {
            do {
                let refreshed = try await api.refresh(refreshToken: session.refreshToken)
                guard let nextSession = QubricAuthSession(response: refreshed) else {
                    throw QubricAPIError.missingSession
                }
                self.session = nextSession
                try QubricKeychain.save(nextSession)
                return try await operation(nextSession.accessToken)
            } catch {
                throw QubricAPIError.missingSession
            }
        }
    }

    private func saveAccountResponse(_ response: QubricAccountResponse, fallback: PlayerProfile? = nil) throws -> PlayerProfile? {
        if let nextSession = QubricAuthSession(response: response) {
            session = nextSession
            try QubricKeychain.save(nextSession)
        }

        return PlayerProfile(account: response, fallback: fallback)
    }

    private func publishLevelUpIfNeeded(from previousXp: Int, to nextXp: Int) {
        let previousLevel = QubricData.level(for: previousXp)
        let nextLevel = QubricData.level(for: nextXp)
        if nextLevel > previousLevel {
            levelUpEvent = LevelUpEvent(from: previousLevel, to: nextLevel)
        }
    }

    private func publishBadgeEarnedEvents(from previous: PlayerProfile, to next: PlayerProfile) {
        let previouslyEarned = Set(
            QubricData.allBadges(for: previous)
                .filter(\.earned)
                .map(\.id)
        )
        let events = QubricData.allBadges(for: next)
            .filter { $0.earned && !previouslyEarned.contains($0.id) }
            .map { BadgeEarnedEvent(badgeId: $0.id, label: $0.label) }

        guard !events.isEmpty else { return }

        if appIsActive {
            pendingBadgeEvents.append(contentsOf: events)
            presentNextBadgeEventIfNeeded()
            return
        }

        guard next.settings.badgeNotificationsEnabled else { return }
        for event in events {
            Task {
                await notificationManager.scheduleBadgeNotification(event)
            }
        }
    }

    private func presentNextBadgeEventIfNeeded() {
        guard badgeEarnedEvent == nil, !pendingBadgeEvents.isEmpty else { return }
        badgeEarnedEvent = pendingBadgeEvents.removeFirst()
    }

    private func clearBadgeEarnedEvents() {
        badgeEarnedEvent = nil
        pendingBadgeEvents.removeAll()
    }

    private func loadCachedProfile() -> PlayerProfile? {
        guard let data = UserDefaults.standard.data(forKey: cachedProfileKey) else { return nil }
        guard var cached = try? JSONDecoder().decode(PlayerProfile.self, from: data) else { return nil }
        cached.unlocked = QubricData.reconciledUnlocked(completed: cached.completed, unlocked: cached.unlocked)
        return cached
    }

    private func saveProfile(_ profile: PlayerProfile) {
        saveCachedProfile(profile)
    }

    private func saveCachedProfile(_ profile: PlayerProfile) {
        guard let data = try? JSONEncoder().encode(profile) else { return }
        UserDefaults.standard.set(data, forKey: cachedProfileKey)
    }

    private func locallyCompletedProfile(_ current: PlayerProfile, puzzle: QuantumPuzzle, gates: [String], hintsUsed: Int) throws -> (profile: PlayerProfile, earned: Int, breakdown: ScoreBreakdown) {
        _ = try QubricQuantumEngine.validate(puzzle, gates: gates, hintsUsed: hintsUsed)

        var previousStats = current.solveStats[puzzle.id] ?? SolveStats()
        if current.completed[puzzle.id] == true && previousStats.attempts == 0 {
            previousStats.attempts = 1
        }

        let scored = QubricQuantumEngine.score(
            puzzle,
            gates: gates,
            hintsUsed: hintsUsed,
            previousStats: previousStats,
            cleanSolver: !current.settings.hintsEnabled
        )
        let earned = current.completed[puzzle.id] == true ? 0 : scored.earned
        var breakdown = scored.breakdown
        breakdown.earned = earned
        let nextPuzzle = QubricData.nextPuzzleId(after: puzzle.id)
        let day = QubricData.todayKey()

        var completed = current.completed
        completed[puzzle.id] = true

        var unlocked = current.unlocked
        unlocked[puzzle.id] = true
        if let nextPuzzle {
            unlocked[nextPuzzle] = true
        }

        var dailyXp = current.dailyXp
        dailyXp[day] = (dailyXp[day] ?? 0) + earned

        var solveStats = current.solveStats
        solveStats[puzzle.id] = scored.quality

        let next = PlayerProfile(
            id: current.id,
            name: current.name,
            avatarPresetId: current.avatarPresetId,
            xp: current.xp + earned,
            completed: completed,
            unlocked: QubricData.reconciledUnlocked(completed: completed, unlocked: unlocked),
            dailyXp: dailyXp,
            mistakes: current.mistakes,
            sound: current.sound,
            settings: current.settings,
            streak: Self.streak(for: dailyXp),
            solveStats: solveStats,
            createdAt: current.createdAt,
            lastSeenAt: Date()
        )
        return (next, earned, breakdown)
    }

    private func localScoreBreakdown(for puzzle: QuantumPuzzle, gates: [String], hintsUsed: Int, previousStats: SolveStats?, cleanSolver: Bool) -> ScoreBreakdown {
        QubricQuantumEngine.score(
            puzzle,
            gates: gates,
            hintsUsed: hintsUsed,
            previousStats: previousStats,
            cleanSolver: cleanSolver
        ).breakdown
    }

    private func locallyReflectedProfile(_ current: PlayerProfile, puzzle: QuantumPuzzle, correct: Bool) -> (profile: PlayerProfile, earned: Int) {
        var previousStats = current.solveStats[puzzle.id] ?? SolveStats()
        let alreadyCorrect = previousStats.reflectionCorrect
        let earned = correct && !alreadyCorrect ? 10 : 0
        let day = QubricData.todayKey()
        let answeredAt = ISO8601DateFormatter().string(from: Date())

        previousStats.reflectionAnswered = true
        previousStats.reflectionCorrect = alreadyCorrect || correct
        previousStats.reflectionAnsweredAt = answeredAt
        previousStats.updatedAt = answeredAt

        var dailyXp = current.dailyXp
        dailyXp[day] = (dailyXp[day] ?? 0) + earned

        var solveStats = current.solveStats
        solveStats[puzzle.id] = previousStats

        let next = PlayerProfile(
            id: current.id,
            name: current.name,
            avatarPresetId: current.avatarPresetId,
            xp: current.xp + earned,
            completed: current.completed,
            unlocked: current.unlocked,
            dailyXp: dailyXp,
            mistakes: current.mistakes,
            sound: current.sound,
            settings: current.settings,
            streak: Self.streak(for: dailyXp),
            solveStats: solveStats,
            createdAt: current.createdAt,
            lastSeenAt: Date()
        )

        return (next, earned)
    }

    private func queuePendingSolve(puzzleId: String, gates: [String], hintsUsed: Int, cleanSolver: Bool, dailyDate: String?) {
        let pending = PendingPuzzleSolve(puzzleId: puzzleId, gates: gates, hintsUsed: hintsUsed, cleanSolver: cleanSolver, dailyDate: dailyDate, queuedAt: Date())
        var solves = pendingSolves()
        if !solves.contains(where: { $0.matches(puzzleId: puzzleId, gates: gates, hintsUsed: hintsUsed, cleanSolver: cleanSolver, dailyDate: dailyDate) }) {
            solves.append(pending)
            savePendingSolves(solves)
        }
    }

    private func removePendingSolve(puzzleId: String, gates: [String], hintsUsed: Int, cleanSolver: Bool, dailyDate: String?) {
        savePendingSolves(
            pendingSolves().filter { !$0.matches(puzzleId: puzzleId, gates: gates, hintsUsed: hintsUsed, cleanSolver: cleanSolver, dailyDate: dailyDate) }
        )
    }

    private func recordDailyCompletionIfNeeded(
        puzzleId: String,
        gates: [String],
        hintsUsed: Int,
        accessToken: String,
        dailyDate: String?
    ) async throws -> QubricDailyCompletionResponse? {
        guard let dailyDate else { return nil }
        let daily = QubricDailyChallenge.local()
        guard daily.date == dailyDate, daily.puzzleId == puzzleId else { return nil }

        return try await api.recordDailyCompletion(puzzleId: puzzleId, gates: gates, hintsUsed: hintsUsed, accessToken: accessToken)
    }

    private func pendingSolves() -> [PendingPuzzleSolve] {
        guard let data = UserDefaults.standard.data(forKey: pendingSolvesKey) else { return [] }
        return (try? JSONDecoder().decode([PendingPuzzleSolve].self, from: data)) ?? []
    }

    private func savePendingSolves(_ solves: [PendingPuzzleSolve]) {
        if solves.isEmpty {
            UserDefaults.standard.removeObject(forKey: pendingSolvesKey)
            return
        }
        guard let data = try? JSONEncoder().encode(solves) else { return }
        UserDefaults.standard.set(data, forKey: pendingSolvesKey)
    }

    private func clearPendingSolves() {
        UserDefaults.standard.removeObject(forKey: pendingSolvesKey)
    }

    private func flushPendingSolves(emitBadgeEvents: Bool = true) async {
        let solves = pendingSolves()
        guard !solves.isEmpty else { return }

        for solve in solves {
            do {
                let remote = try await withAccessToken { token in
                    let response = try await self.api.complete(
                        puzzleId: solve.puzzleId,
                        gates: solve.gates,
                        hintsUsed: solve.hintsUsed,
                        accessToken: token,
                        replayReward: false,
                        cleanSolver: solve.cleanSolver
                    )
                    let daily = try await self.recordDailyCompletionIfNeeded(
                        puzzleId: solve.puzzleId,
                        gates: solve.gates,
                        hintsUsed: solve.hintsUsed,
                        accessToken: token,
                        dailyDate: solve.dailyDate
                    )
                    return (response.progress, daily?.progress)
                }
                let progress = remote.1 ?? remote.0

                if let current = profile {
                    let next = current.applying(progress: progress)
                    if emitBadgeEvents {
                        publishBadgeEarnedEvents(from: current, to: next)
                    }
                    profile = next
                    saveCachedProfile(next)
                }
                removePendingSolve(puzzleId: solve.puzzleId, gates: solve.gates, hintsUsed: solve.hintsUsed, cleanSolver: solve.cleanSolver, dailyDate: solve.dailyDate)
            } catch {
                syncMessage = "Saved on this device. Cloud sync pending."
                return
            }
        }

        syncMessage = "Cloud progress saved."
    }

    private func clearCachedProfile() {
        UserDefaults.standard.removeObject(forKey: cachedProfileKey)
    }

    private func clearSessionState(message: String) {
        session = nil
        QubricKeychain.clear()
        clearCachedProfile()
        clearPendingSolves()
        clearBadgeEarnedEvents()
        levelUpEvent = nil
        profile = nil
        syncMessage = message
    }

    private func clearRetiredLocalAccountState() {
        let retiredProfileKeys = [
            "qubric.cachedGuestProfile.v1",
            "qubric.cachedGuestProfile.v2"
        ]
        for key in retiredProfileKeys {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    private static func streak(for dailyXp: [String: Int]) -> ProgressStreak {
        let activeDays = dailyXp
            .filter { $0.value > 0 }
            .map(\.key)
            .sorted()

        guard !activeDays.isEmpty else { return ProgressStreak() }

        func dayOffset(_ key: String, _ offset: Int) -> String? {
            var components = DateComponents()
            components.calendar = Calendar(identifier: .gregorian)
            components.timeZone = TimeZone(secondsFromGMT: 0)
            let parts = key.split(separator: "-").compactMap { Int($0) }
            guard parts.count == 3 else { return nil }
            components.year = parts[0]
            components.month = parts[1]
            components.day = parts[2] + offset
            guard let date = components.calendar?.date(from: components) else { return nil }
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: date)
        }

        var longest = 1
        var run = 1
        for index in activeDays.indices.dropFirst() {
            run = dayOffset(activeDays[index - 1], 1) == activeDays[index] ? run + 1 : 1
            longest = max(longest, run)
        }

        var current = 0
        var day = QubricData.todayKey()
        while dailyXp[day, default: 0] > 0 {
            current += 1
            guard let previous = dayOffset(day, -1) else { break }
            day = previous
        }

        return ProgressStreak(current: current, longest: longest, lastSolvedDay: activeDays.last)
    }

}

private extension QubricAuthSession {
    init?(response: QubricAccountResponse) {
        guard let accessToken = response.accessToken, let refreshToken = response.refreshToken else {
            return nil
        }

        self.init(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: response.expiresAt
        )
    }

}
