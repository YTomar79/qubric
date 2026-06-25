//
//  QubricNotificationManager.swift
//  Qubric
//
//  Local notification scheduling and permission handling.
//

import Foundation
import UserNotifications

final class QubricNotificationManager {
    static let shared = QubricNotificationManager()

    private let center = UNUserNotificationCenter.current()

    private init() { }

    func requestBadgeNotificationAuthorization() async -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            do {
                return try await center.requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                return false
            }
        @unknown default:
            return false
        }
    }

    func notificationPermissionGranted() async -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied, .notDetermined:
            return false
        @unknown default:
            return false
        }
    }

    func scheduleBadgeNotification(_ event: BadgeEarnedEvent) async {
        guard await notificationPermissionGranted() else { return }

        let content = UNMutableNotificationContent()
        content.title = "New badge"
        content.body = event.label
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "badge-\(event.badgeId)-\(event.id.uuidString)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )

        try? await center.add(request)
    }
}
