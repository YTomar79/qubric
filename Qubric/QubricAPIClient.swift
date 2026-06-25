//
//  QubricAPIClient.swift
//  Qubric
//
//  Networking layer for authentication, progress, and content sync.
//

import Foundation
import Security

struct QubricAuthSession: Codable {
    var accessToken: String
    var refreshToken: String
    var expiresAt: Int?
}

struct QubricAPIUser: Codable {
    var id: String
    var username: String?
}

struct QubricAPIProfile: Codable {
    var id: String
    var email: String?
    var username: String
}

struct QubricAPIProgress: Codable {
    var userId: String?
    var xp: Int
    var completed: [String: Bool]
    var unlocked: [String: Bool]
    var dailyXp: [String: Int]
    var mistakes: Int
    var sound: Bool
    var settings: PlayerSettings?
    var streak: ProgressStreak?
    var solveStats: [String: SolveStats]
}

struct ScoreBreakdown: Codable, Equatable {
    var baseXp: Int
    var optimalBonus: Int
    var noHintBonus: Int
    var overOptimalPenalty: Int
    var hintPenalty: Int
    var cleanSolverMultiplier: Double
    var cleanSolverBonus: Int
    var bestScore: Int
    var replayReward: Bool
    var improvedReplay: Bool
    var earned: Int
    var dailyBonus: Int?
}

struct QubricAccountResponse: Codable {
    var user: QubricAPIUser?
    var profile: QubricAPIProfile?
    var progress: QubricAPIProgress?
    var accessToken: String?
    var refreshToken: String?
    var expiresAt: Int?
    var warning: String?
}

struct QubricProgressResponse: Codable {
    var progress: QubricAPIProgress
    var earned: Int?
    var quality: SolveStats?
    var scoreBreakdown: ScoreBreakdown?
}

struct QubricDailyUnlockRequirement: Codable, Equatable {
    var type: String
    var puzzleId: String
    var label: String
    var description: String
}

struct QubricDailyChallenge: Codable, Equatable {
    var date: String
    var seed: UInt32
    var puzzleId: String
    var title: String
    var optimalGates: Int
    var xp: Int
    var streakBonusXp: Int
    var refreshesAt: String?
    var unlockRequirement: QubricDailyUnlockRequirement?

    private static let millisecondsPerDay = 86_400_000.0
    private static let dailyCycleAnchorDate = "2026-05-22"
    private static let dailyCycleAnchorPuzzleId = "1.2"

    static func local(date: Date = Date()) -> QubricDailyChallenge {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        let dateKey = formatter.string(from: date)
        let pool = QubricData.allPuzzles.filter {
            $0.chapterNumber == 1
                && $0.difficulty != "Intro"
                && $0.difficulty != "Tutorial"
                && $0.puzzleType != "spot-difference"
        }
        let source = pool.isEmpty ? QubricData.allPuzzles : pool
        let seed = dateKey.unicodeScalars.reduce(UInt32(17)) { total, scalar in
            total &* 31 &+ scalar.value
        }
        let puzzle = dailyPuzzle(for: dateKey, in: source)

        return QubricDailyChallenge(
            date: dateKey,
            seed: seed,
            puzzleId: puzzle.id,
            title: puzzle.title,
            optimalGates: puzzle.optimalGates,
            xp: puzzle.xp,
            streakBonusXp: 25,
            refreshesAt: nil,
            unlockRequirement: QubricDailyUnlockRequirement(
                type: "completedPuzzle",
                puzzleId: QubricData.dailyUnlockPuzzleId,
                label: "Complete Foundations",
                description: "Finish Chapter 1 to unlock the daily challenge."
            )
        )
    }

    private static func dailyPuzzle(for dateKey: String, in source: [QuantumPuzzle]) -> QuantumPuzzle {
        guard source.count > 1 else { return source[0] }

        let index = positiveModulo(utcDayNumber(for: dateKey) + dailyCycleOffset(in: source), source.count)
        return source[index]
    }

    private static func dailyCycleOffset(in source: [QuantumPuzzle]) -> Int {
        guard let anchorIndex = source.firstIndex(where: { $0.id == dailyCycleAnchorPuzzleId }) else {
            return 0
        }

        return positiveModulo(
            anchorIndex - positiveModulo(utcDayNumber(for: dailyCycleAnchorDate), source.count),
            source.count
        )
    }

    private static func utcDayNumber(for dateKey: String) -> Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        guard let date = formatter.date(from: dateKey) else {
            let seed = dateKey.unicodeScalars.reduce(UInt32(17)) { total, scalar in
                total &* 31 &+ scalar.value
            }
            return Int(seed)
        }

        return Int(floor((date.timeIntervalSince1970 * 1000) / millisecondsPerDay))
    }

    private static func positiveModulo(_ value: Int, _ size: Int) -> Int {
        ((value % size) + size) % size
    }
}

struct QubricDailyHistoryEntry: Codable, Identifiable, Equatable {
    var id: String { date }
    var date: String
    var puzzleId: String?
    var solved: Bool
    var solverName: String?
    var score: Int
    var gateCount: Int?
    var hintsUsed: Int?
    var createdAt: String?
}

struct QubricDailyCompletionResponse: Codable {
    var alreadyClaimed: Bool?
    var bonusXp: Int?
    var completion: QubricDailyHistoryEntry?
    var progress: QubricAPIProgress?
}

private struct QubricDailyResponse: Codable {
    var daily: QubricDailyChallenge
}

private struct QubricDailyHistoryResponse: Codable {
    var history: [QubricDailyHistoryEntry]
}

struct QubricStatusResponse: Codable {
    var status: String
    var message: String?
}

enum QubricAPIError: LocalizedError {
    case invalidURL
    case missingSession
    case unauthorized
    case server(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The Qubric API URL is invalid."
        case .missingSession:
            return "Please log in again."
        case .unauthorized:
            return "Your session expired. Please log in again."
        case .server(let message):
            return message
        }
    }
}

final class QubricAPIClient {
    private static let fallbackBaseURL = "http://127.0.0.1:3000"

    private let baseURL: URL
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init() {
        let configured = Self.configuredBaseURL()
        guard let url = URL(string: configured) else {
            baseURL = URL(string: Self.fallbackBaseURL)!
            return
        }
        baseURL = url
    }

    private static func configuredBaseURL() -> String {
        if let override = trimmed(ProcessInfo.processInfo.environment["QUBRIC_API_URL"]) {
            return override
        }

        if let bundled = trimmed(Bundle.main.object(forInfoDictionaryKey: "QubricAPIURL") as? String) {
            return bundled
        }

        return fallbackBaseURL
    }

    static var privacyPolicyURL: URL {
        let configured = URL(string: configuredBaseURL()) ?? URL(string: fallbackBaseURL)!
        return URL(string: "/privacy", relativeTo: configured)!.absoluteURL
    }

    private static func trimmed(_ value: String?) -> String? {
        let next = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return next.isEmpty ? nil : next
    }

    func signup(username: String, email: String, password: String) async throws -> QubricAccountResponse {
        struct Body: Codable {
            var username: String
            var email: String
            var password: String
        }

        return try await send(
            path: "/auth/signup",
            method: "POST",
            body: Body(username: username, email: email, password: password)
        )
    }

    func login(username: String, password: String) async throws -> QubricAccountResponse {
        struct Body: Codable {
            var username: String
            var password: String
        }

        return try await send(
            path: "/auth/login",
            method: "POST",
            body: Body(username: username, password: password)
        )
    }

    func refresh(refreshToken: String) async throws -> QubricAccountResponse {
        struct Body: Codable {
            var refreshToken: String
        }

        return try await send(path: "/auth/refresh", method: "POST", body: Body(refreshToken: refreshToken))
    }

    func me(accessToken: String) async throws -> QubricAccountResponse {
        try await send(path: "/auth/me", accessToken: accessToken)
    }

    func logout(accessToken: String) async throws -> QubricStatusResponse {
        try await send(path: "/auth/logout", method: "POST", accessToken: accessToken)
    }

    func deleteAccount(accessToken: String) async throws -> QubricStatusResponse {
        try await send(path: "/auth/account", method: "DELETE", accessToken: accessToken)
    }

    func complete(puzzleId: String, gates: [String], hintsUsed: Int, accessToken: String, replayReward: Bool? = nil, cleanSolver: Bool? = nil) async throws -> QubricProgressResponse {
        struct Body: Codable {
            var puzzleId: String
            var gates: [String]
            var hintsUsed: Int
            var replayReward: Bool?
            var cleanSolver: Bool?
        }

        return try await send(path: "/progress/complete", method: "POST", accessToken: accessToken, body: Body(puzzleId: puzzleId, gates: gates, hintsUsed: hintsUsed, replayReward: replayReward, cleanSolver: cleanSolver))
    }

    func loadDailyChallenge() async throws -> QubricDailyChallenge {
        let response: QubricDailyResponse = try await send(path: "/daily")
        return response.daily
    }

    func loadDailyHistory(accessToken: String, days: Int = 56) async throws -> [QubricDailyHistoryEntry] {
        let safeDays = min(60, max(1, days))
        let response: QubricDailyHistoryResponse = try await send(path: "/daily/history?days=\(safeDays)", accessToken: accessToken)
        return response.history
    }

    func recordDailyCompletion(puzzleId: String, gates: [String], hintsUsed: Int, accessToken: String) async throws -> QubricDailyCompletionResponse {
        struct Body: Codable {
            var puzzleId: String
            var gates: [String]
            var hintsUsed: Int
        }

        return try await send(path: "/daily/complete", method: "POST", accessToken: accessToken, body: Body(puzzleId: puzzleId, gates: gates, hintsUsed: hintsUsed))
    }

    func updatePreferences(sound: Bool? = nil, settings: PlayerSettings? = nil, accessToken: String) async throws -> QubricProgressResponse {
        struct Body: Codable {
            var sound: Bool?
            var settings: PlayerSettings?
        }

        return try await send(path: "/progress/preferences", method: "PATCH", accessToken: accessToken, body: Body(sound: sound, settings: settings))
    }

    func resetProgress(accessToken: String) async throws -> QubricProgressResponse {
        try await send(path: "/progress/reset", method: "POST", accessToken: accessToken)
    }

    func recordReflection(puzzleId: String, correct: Bool, accessToken: String) async throws -> QubricProgressResponse {
        struct Body: Codable {
            var puzzleId: String
            var correct: Bool
        }

        return try await send(path: "/progress/reflection", method: "POST", accessToken: accessToken, body: Body(puzzleId: puzzleId, correct: correct))
    }

    private func send<Response: Decodable, Body: Encodable>(
        path: String,
        method: String = "GET",
        accessToken: String? = nil,
        body: Body
    ) async throws -> Response {
        let data = try encoder.encode(body)
        return try await send(path: path, method: method, accessToken: accessToken, bodyData: data)
    }

    private func send<Response: Decodable>(
        path: String,
        method: String = "GET",
        accessToken: String? = nil
    ) async throws -> Response {
        try await send(path: path, method: method, accessToken: accessToken, bodyData: nil)
    }

    private func send<Response: Decodable>(
        path: String,
        method: String,
        accessToken: String?,
        bodyData: Data?
    ) async throws -> Response {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw QubricAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }

        if let bodyData {
            request.httpBody = bodyData
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw QubricAPIError.server("Qubric API did not return a valid response.")
        }

        if !(200..<300).contains(http.statusCode) {
            let message = (try? decoder.decode(QubricErrorResponse.self, from: data).error) ?? "Request failed. Try again."
            if http.statusCode == 401, path != "/auth/login" {
                throw QubricAPIError.unauthorized
            }
            throw QubricAPIError.server(message)
        }

        return try decoder.decode(Response.self, from: data)
    }
}

private struct QubricErrorResponse: Codable {
    var error: String
}

enum QubricKeychain {
    private static let service = "com.qubric.app.session"
    private static let account = "cloud"

    static func save(_ session: QubricAuthSession) throws {
        let data = try JSONEncoder().encode(session)
        clear()

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecValueData as String: data
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw QubricAPIError.server("Could not save session securely.")
        }
    }

    static func load() -> QubricAuthSession? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return try? JSONDecoder().decode(QubricAuthSession.self, from: data)
    }

    static func clear() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

extension PlayerProfile {
    init?(account response: QubricAccountResponse, fallback: PlayerProfile? = nil) {
        guard let progress = response.progress ?? fallback?.apiProgress else { return nil }

        let userId = response.user?.id ?? progress.userId ?? fallback?.id.uuidString
        let profileId = UUID(uuidString: userId ?? "") ?? fallback?.id ?? UUID()
        let displayName = response.profile?.username ?? response.user?.username ?? fallback?.name ?? "Qubric Player"

        self.init(
            id: profileId,
            name: displayName,
            avatarPresetId: fallback?.avatarPresetId,
            xp: progress.xp,
            completed: progress.completed,
            unlocked: QubricData.reconciledUnlocked(completed: progress.completed, unlocked: progress.unlocked),
            dailyXp: progress.dailyXp,
            mistakes: progress.mistakes,
            sound: progress.sound,
            settings: progress.settings ?? fallback?.settings ?? PlayerSettings(),
            streak: progress.streak ?? fallback?.streak ?? ProgressStreak(),
            solveStats: progress.solveStats,
            createdAt: fallback?.createdAt ?? Date(),
            lastSeenAt: Date()
        )
    }

    fileprivate var apiProgress: QubricAPIProgress {
        QubricAPIProgress(
            userId: id.uuidString,
            xp: xp,
            completed: completed,
            unlocked: QubricData.reconciledUnlocked(completed: completed, unlocked: unlocked),
            dailyXp: dailyXp,
            mistakes: mistakes,
            sound: sound,
            settings: settings,
            streak: streak,
            solveStats: solveStats
        )
    }

    func applying(progress: QubricAPIProgress) -> PlayerProfile {
        PlayerProfile(
            id: id,
            name: name,
            avatarPresetId: avatarPresetId,
            xp: progress.xp,
            completed: progress.completed,
            unlocked: QubricData.reconciledUnlocked(completed: progress.completed, unlocked: progress.unlocked),
            dailyXp: progress.dailyXp,
            mistakes: progress.mistakes,
            sound: progress.sound,
            settings: progress.settings ?? settings,
            streak: progress.streak ?? streak,
            solveStats: progress.solveStats,
            createdAt: createdAt,
            lastSeenAt: Date()
        )
    }
}
