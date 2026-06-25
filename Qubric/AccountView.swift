//
//  AccountView.swift
//  Qubric
//
//  Account screen: profile details, preferences, and data controls.
//

import SwiftUI

struct AccountView: View {
    @ObservedObject var store: QubricStore
    @State private var showingBadges = false
    @State private var showingSettings = false
    @State private var showingAvatarPicker = false
    @State private var didOpenLaunchBadges = false
    @State private var didOpenLaunchSettings = false

    private var profile: PlayerProfile {
        store.profile ?? PlayerProfile(name: "Qubric Player")
    }

    private var badges: [QubricBadge] {
        QubricData.allBadges(for: profile)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                QubricPageHeader(title: "Account")

                ScrollView {
                    VStack(spacing: 18) {
                        AccountProfileSummary(profile: profile) {
                            showingAvatarPicker = true
                        }
                        .accountTile(padding: 18)

                        AccountStatsTile(
                            solvedCount: solvedCount,
                            totalPuzzles: QubricData.allPuzzles.count,
                            earnedBadges: badges.filter(\.earned).count,
                            totalBadges: badges.count,
                            streak: profile.streak.current,
                            onBadgesTap: {
                                showingBadges = true
                            }
                        )
                        .accountTile(padding: 0)

                        Button {
                            showingSettings = true
                        } label: {
                            AccountDisclosureRow(title: "Settings", systemImage: "gearshape")
                                .padding(16)
                                .accountTile(padding: 0)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 22)
                    .padding(.bottom, 96)
                }
            }
            .background(Color.qubricGrouped.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showingBadges) {
                AccountBadgesView(profile: profile)
            }
            .navigationDestination(isPresented: $showingSettings) {
                AccountSettingsView(store: store)
            }
            .sheet(isPresented: $showingAvatarPicker) {
                AccountAvatarPickerView(selectedPresetId: profile.avatarPresetId) { presetId in
                    store.setAvatarPreset(presetId)
                }
                .presentationDetents([.medium])
            }
            .onAppear(perform: openLaunchDestinationsIfNeeded)
        }
    }

    private func openLaunchDestinationsIfNeeded() {
        openLaunchBadgesIfNeeded()
        openLaunchSettingsIfNeeded()
    }

    private func openLaunchBadgesIfNeeded() {
        guard !didOpenLaunchBadges else { return }
        guard ProcessInfo.processInfo.arguments.contains("--qubric-open-account-badges") else { return }
        didOpenLaunchBadges = true
        showingBadges = true
    }

    private func openLaunchSettingsIfNeeded() {
        guard !didOpenLaunchSettings else { return }
        guard !showingBadges else { return }
        guard ProcessInfo.processInfo.arguments.contains("--qubric-open-account-settings") else { return }
        didOpenLaunchSettings = true
        showingSettings = true
    }

    private var solvedCount: Int {
        profile.completed.values.filter { $0 }.count
    }
}

private struct AccountBadgesView: View {
    let profile: PlayerProfile
    @State private var selectedFilter: BadgeFilter = .all

    private var badges: [QubricBadge] {
        QubricData.allBadges(for: profile)
    }

    private var nextBadge: QubricBadge? {
        badges.first { !$0.earned }
    }

    private var earnedCount: Int {
        badges.filter(\.earned).count
    }

    private var completion: Double {
        guard !badges.isEmpty else { return 0 }
        return Double(earnedCount) / Double(badges.count)
    }

    private var visibleBadges: [QubricBadge] {
        switch selectedFilter {
        case .all:
            return badges
        case .open:
            return badges.filter { !$0.earned }
        case .earned:
            return badges.filter(\.earned)
        }
    }

    var body: some View {
        List {
            Section {
                BadgeOverviewRow(
                    earnedCount: earnedCount,
                    totalCount: badges.count,
                    completion: completion,
                    nextBadge: nextBadge
                )
                .badgeTile()
                .listRowInsets(EdgeInsets(top: 14, leading: 16, bottom: 12, trailing: 16))
                .listRowSeparator(.hidden)
            }
            .listRowBackground(Color.qubricGrouped)

            Section {
                Picker("Badge filter", selection: $selectedFilter) {
                    ForEach(BadgeFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 14, trailing: 16))
                .listRowSeparator(.hidden)
                .accessibilityLabel("Badge filter")
            }
            .listRowBackground(Color.qubricGrouped)

            Section {
                if visibleBadges.isEmpty {
                    BadgeEmptyRow(filter: selectedFilter)
                        .listRowInsets(EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16))
                        .listRowSeparator(.hidden)
                } else {
                    VStack(spacing: 12) {
                        ForEach(visibleBadges) { badge in
                            BadgeRow(
                                badge: badge,
                                progress: badgeProgress(for: badge, profile: profile),
                                isNext: badge.id == nextBadge?.id
                            )
                            .badgeTile()
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 18, trailing: 16))
                    .listRowSeparator(.hidden)
                }
            }
            .listRowBackground(Color.qubricGrouped)
        }
        .listStyle(.plain)
        .listRowSeparatorTint(Color.qubricLine)
        .listSectionSpacing(.custom(12))
        .contentMargins(.top, 8, for: .scrollContent)
        .contentMargins(.bottom, 96, for: .scrollContent)
        .scrollContentBackground(.hidden)
        .background(Color.qubricGrouped.ignoresSafeArea())
        .navigationTitle("Badges")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.qubricGrouped, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

private enum AccountSettingsAlert {
    case resetFirst
    case resetFinal
    case logout
    case deleteFirst
    case deleteFinal
}

private struct AccountSettingsView: View {
    @Environment(\.openURL) private var openURL
    @ObservedObject var store: QubricStore
    @State private var settingsAlert: AccountSettingsAlert?
    @State private var showingPrivacy = false

    private var profile: PlayerProfile {
        store.profile ?? PlayerProfile(name: "Qubric Player")
    }

    private var notationUnlocked: Bool {
        profile.unlocked["3.1"] == true || profile.completed.keys.contains { $0.hasPrefix("3.") }
    }

    private var reflectionQuizzesAvailable: Bool {
        QubricData.allPuzzles.contains { $0.reflection != nil }
    }

    private var settingsFooterText: String {
        var messages = [
            "Hints off adds a +50% clean-solve bonus.",
            "Badge alerts use iOS notifications."
        ]

        if reflectionQuizzesAvailable {
            messages.append("Quiz controls apply after reflection puzzles.")
        }

        return messages.joined(separator: "\n")
    }

    var body: some View {
        List {
            if !store.syncMessage.isEmpty {
                Section {
                    SyncStatusRow(message: store.syncMessage)
                }
                .listRowBackground(Color.qubricElevatedSurface)
            }

            Section {
                Toggle(isOn: soundBinding) {
                    Label("Sound", systemImage: profile.sound ? "speaker.wave.2.fill" : "speaker.slash.fill")
                }
                Toggle(isOn: badgeNotificationsBinding) {
                    Label("Badge notifications", systemImage: "rosette")
                }
                Toggle(isOn: hintsBinding) {
                    Label("Hints", systemImage: "lightbulb")
                }
                if reflectionQuizzesAvailable {
                    Toggle(isOn: reflectionsBinding) {
                        Label("End-of-puzzle quiz", systemImage: "text.bubble")
                    }
                }
                if notationUnlocked {
                    Toggle(isOn: notationBinding) {
                        Label("Notation", systemImage: "curlybraces")
                    }
                }
            } footer: {
                Text(settingsFooterText)
            }
            .listRowBackground(Color.qubricElevatedSurface)

            Section {
                Button {
                    showingPrivacy = true
                } label: {
                    AccountDisclosureRow(title: "Privacy & Data", systemImage: "hand.raised")
                }
                .buttonStyle(.plain)

                Button(action: openPrivacyPolicy) {
                    Label("Privacy Policy", systemImage: "safari")
                }
            } footer: {
                Text("Review what Qubric stores, the optional permission it asks for, and how account deletion works.")
            }
            .listRowBackground(Color.qubricElevatedSurface)

            Section {
                Button(role: .destructive) {
                    settingsAlert = .resetFirst
                } label: {
                    Label("Reset progress", systemImage: "arrow.counterclockwise")
                }
                Button {
                    settingsAlert = .logout
                } label: {
                    Label("Log out", systemImage: "rectangle.portrait.and.arrow.right")
                }
                Button(role: .destructive) {
                    settingsAlert = .deleteFirst
                } label: {
                    Label("Delete account", systemImage: "trash")
                }
            }
            .listRowBackground(Color.qubricElevatedSurface)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.qubricGrouped.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.qubricGrouped, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .listRowSeparatorTint(Color.qubricLine)
        .navigationDestination(isPresented: $showingPrivacy) {
            AccountPrivacyDataView(onOpenPrivacyPolicy: openPrivacyPolicy)
        }
        .alert(settingsAlertTitle, isPresented: settingsAlertPresented) {
            settingsAlertActions
        } message: {
            Text(settingsAlertMessage)
        }
    }

    private func openPrivacyPolicy() {
        openURL(QubricAPIClient.privacyPolicyURL)
    }

    private var settingsAlertPresented: Binding<Bool> {
        Binding(
            get: { settingsAlert != nil },
            set: { presented in
                guard !presented else { return }
                settingsAlert = nil
            }
        )
    }

    private func presentFollowUpAlert(_ alert: AccountSettingsAlert) {
        settingsAlert = nil
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 250_000_000)
            settingsAlert = alert
        }
    }

    private var settingsAlertTitle: String {
        switch settingsAlert {
        case .resetFirst:
            return "Reset progress?"
        case .resetFinal:
            return "Are you sure?"
        case .logout:
            return "Log out?"
        case .deleteFirst:
            return "Delete account?"
        case .deleteFinal:
            return "Delete account permanently?"
        case nil:
            return ""
        }
    }

    private var settingsAlertMessage: String {
        switch settingsAlert {
        case .resetFirst:
            return "This removes XP, streaks, solved puzzles, and badges from this account."
        case .resetFinal:
            return "This cannot be undone. Your puzzle progress and earned badges will be reset."
        case .logout:
            return "You will need to log in again to continue."
        case .deleteFirst:
            return "This deletes your Qubric account and all saved app data."
        case .deleteFinal:
            return "This cannot be undone. Your cloud account, profile, progress, badges, streaks, settings, and daily history will be deleted."
        case nil:
            return ""
        }
    }

    @ViewBuilder
    private var settingsAlertActions: some View {
        switch settingsAlert {
        case .resetFirst:
            Button("Continue", role: .destructive) {
                presentFollowUpAlert(.resetFinal)
            }
            Button("Cancel", role: .cancel) { }
        case .resetFinal:
            Button("Reset progress", role: .destructive) {
                store.resetProgress()
            }
            Button("Cancel", role: .cancel) { }
        case .logout:
            Button("Log out", role: .destructive) {
                store.logout()
            }
            Button("Cancel", role: .cancel) { }
        case .deleteFirst:
            Button("Continue", role: .destructive) {
                presentFollowUpAlert(.deleteFinal)
            }
            Button("Cancel", role: .cancel) { }
        case .deleteFinal:
            Button("Delete account", role: .destructive) {
                Task { await store.deleteAccount() }
            }
            Button("Cancel", role: .cancel) { }
        case nil:
            EmptyView()
        }
    }

    private var soundBinding: Binding<Bool> {
        Binding(
            get: { profile.sound },
            set: { store.setSound($0) }
        )
    }

    private var hintsBinding: Binding<Bool> {
        Binding(
            get: { profile.settings.hintsEnabled },
            set: { hintsEnabled in
                var settings = profile.settings
                settings.hintsEnabled = hintsEnabled
                store.setSettings(settings)
            }
        )
    }

    private var badgeNotificationsBinding: Binding<Bool> {
        Binding(
            get: { profile.settings.badgeNotificationsEnabled },
            set: { store.setBadgeNotificationsEnabled($0) }
        )
    }

    private var reflectionsBinding: Binding<Bool> {
        Binding(
            get: { !profile.settings.skipReflections },
            set: { enabled in
                var settings = profile.settings
                settings.skipReflections = !enabled
                store.setSettings(settings)
            }
        )
    }

    private var notationBinding: Binding<Bool> {
        Binding(
            get: { profile.settings.showNotation },
            set: { enabled in
                var settings = profile.settings
                settings.showNotation = enabled
                store.setSettings(settings)
            }
        )
    }

}

private struct AccountPrivacyDataView: View {
    let onOpenPrivacyPolicy: () -> Void

    var body: some View {
        List {
            Section {
                PrivacyDisclosureRow(
                    systemImage: "person.crop.circle",
                    title: "Account data",
                    detail: "Email address, username, cloud session, and account deletion state."
                )
                PrivacyDisclosureRow(
                    systemImage: "chart.bar",
                    title: "Progress data",
                    detail: "XP, solved puzzles, badges, streaks, daily challenge history, settings, and solve stats."
                )
                PrivacyDisclosureRow(
                    systemImage: "bell.badge",
                    title: "Notifications",
                    detail: "Badge notifications are optional and requested only after you turn them on."
                )
            } header: {
                Text("Collected")
            }
            .listRowBackground(Color.qubricElevatedSurface)

            Section {
                PrivacyDisclosureRow(
                    systemImage: "location.slash",
                    title: "No sensitive device data",
                    detail: "Qubric does not ask for Location, Camera, Photos, Contacts, Microphone, Bluetooth, or tracking permission."
                )
                PrivacyDisclosureRow(
                    systemImage: "eye.slash",
                    title: "No tracking",
                    detail: "Qubric does not track you across apps or websites owned by other companies."
                )
                PrivacyDisclosureRow(
                    systemImage: "person.2.slash",
                    title: "No public posting",
                    detail: "Qubric has no public chat, image sharing, or public user-generated content surface."
                )
            } header: {
                Text("Not Collected")
            } footer: {
                Text("Because there is no public posting or user-to-user messaging, report and block controls are not part of the current app.")
            }
            .listRowBackground(Color.qubricElevatedSurface)

            Section {
                PrivacyDisclosureRow(
                    systemImage: "server.rack",
                    title: "Storage",
                    detail: "Cloud account and progress data are stored with Supabase and accessed through the Qubric backend."
                )
                PrivacyDisclosureRow(
                    systemImage: "trash",
                    title: "Deletion",
                    detail: "Delete account in Settings removes the cloud account, profile, progress, badges, streaks, settings, and daily history."
                )
            } header: {
                Text("Controls")
            }
            .listRowBackground(Color.qubricElevatedSurface)

            Section {
                Button(action: onOpenPrivacyPolicy) {
                    Label("Open Privacy Policy", systemImage: "safari")
                }
            }
            .listRowBackground(Color.qubricElevatedSurface)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.qubricGrouped.ignoresSafeArea())
        .navigationTitle("Privacy & Data")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.qubricGrouped, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .listRowSeparatorTint(Color.qubricLine)
    }
}

private struct PrivacyDisclosureRow: View {
    let systemImage: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 3)
        .accessibilityElement(children: .combine)
    }
}

private struct AccountDisclosureRow: View {
    let title: String
    var value: String?
    let systemImage: String
    var showsChevron = true

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.body)
                .foregroundStyle(Color.qubricPrimary)
                .frame(width: 24)

            Text(title)
                .font(.subheadline)
                .foregroundStyle(.primary)

            Spacer(minLength: 12)

            if let value {
                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

private struct AccountStatsTile: View {
    let solvedCount: Int
    let totalPuzzles: Int
    let earnedBadges: Int
    let totalBadges: Int
    let streak: Int
    let onBadgesTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            AccountStatRow(
                title: "Solved puzzles",
                value: "\(solvedCount)/\(totalPuzzles)",
                systemImage: "checkmark.circle"
            )

            AccountTileDivider()

            Button(action: onBadgesTap) {
                AccountStatRow(
                    title: "Badges",
                    value: "\(earnedBadges)/\(totalBadges)",
                    systemImage: "rosette",
                    tint: .qubricPrimary,
                    showsChevron: true
                )
            }
            .buttonStyle(.plain)

            AccountTileDivider()

            AccountStatRow(title: "Current streak", value: dayCount(streak), systemImage: "flame")
        }
        .accessibilityElement(children: .contain)
    }
}

private struct AccountStatRow: View {
    let title: String
    let value: String
    let systemImage: String
    var tint: Color = .secondary
    var showsChevron = false

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.body)
                .foregroundStyle(tint)
                .frame(width: 24, height: 24)

            Text(title)
                .font(.subheadline)
                .foregroundStyle(.primary)

            Spacer(minLength: 12)

            Text(value)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

private struct AccountTileDivider: View {
    var body: some View {
        Divider()
            .overlay(Color.qubricLine)
            .padding(.leading, 54)
    }
}

private struct AccountProfileSummary: View {
    let profile: PlayerProfile
    let onEditAvatar: () -> Void

    private var level: Int {
        QubricData.level(for: profile.xp)
    }

    private var levelBase: Int {
        (level - 1) * 300
    }

    private var nextLevelXp: Int {
        level * 300
    }

    private var levelProgress: Double {
        max(0, min(1, Double(profile.xp - levelBase) / 300.0))
    }

    private var remainingXp: Int {
        max(0, nextLevelXp - profile.xp)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 14) {
                Button(action: onEditAvatar) {
                    AccountAvatar(presetId: profile.avatarPresetId, showsEditBadge: true, size: 52)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Edit profile picture")
                .accessibilityValue(AccountAvatarPreset.name(for: profile.avatarPresetId))
                .accessibilityHint("Opens profile picture options")

                VStack(alignment: .leading, spacing: 4) {
                    Text(profile.name)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                    Text(QubricData.rank(for: profile.xp))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Label("Cloud account", systemImage: "icloud")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Text("Level \(level)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.qubricPrimaryStrong)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.qubricPrimary.opacity(0.12), in: Capsule())
                    .overlay {
                        Capsule()
                            .stroke(Color.qubricPrimary.opacity(0.45), lineWidth: QubricTheme.hairlineWidth)
                    }
                    .lineLimit(1)
            }

            Divider()
                .overlay(Color.qubricLine)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(accountNumber(profile.xp)) XP")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Spacer()

                    Text("\(accountNumber(remainingXp)) XP to level \(level + 1)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                AccountProgressBar(value: levelProgress)
            }
        }
        .accessibilityElement(children: .contain)
    }
}

private struct AccountProgressBar: View {
    let value: Double

    private var clampedValue: Double {
        max(0, min(1, value))
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.qubricTrack)

                Capsule()
                    .fill(Color.qubricPrimary)
                    .frame(width: proxy.size.width * clampedValue)
            }
        }
        .frame(height: 6)
        .accessibilityHidden(true)
    }
}

private struct AccountAvatarPreset: Identifiable {
    let id: String
    let name: String
    let systemImage: String
    let color: Color

    static let all: [AccountAvatarPreset] = [
        AccountAvatarPreset(id: "spark", name: "Spark", systemImage: "sparkles", color: .qubricAccent),
        AccountAvatarPreset(id: "bolt", name: "Bolt", systemImage: "bolt.fill", color: .qubricPrimaryStrong),
        AccountAvatarPreset(id: "proof", name: "Proof", systemImage: "seal.fill", color: .qubricPhase),
        AccountAvatarPreset(id: "cube", name: "Cube", systemImage: "cube.fill", color: .qubricPrimary),
        AccountAvatarPreset(id: "streak", name: "Streak", systemImage: "flame.fill", color: .qubricWarning),
        AccountAvatarPreset(id: "orbit", name: "Orbit", systemImage: "moon.stars.fill", color: .qubricSuccess)
    ]

    static func preset(for id: String?) -> AccountAvatarPreset? {
        guard let id else { return nil }
        return all.first { $0.id == id }
    }

    static func name(for id: String?) -> String {
        preset(for: id)?.name ?? "Default"
    }
}

private struct AccountAvatar: View {
    var presetId: String?
    var showsEditBadge = false
    var size: CGFloat = 44

    private var preset: AccountAvatarPreset? {
        AccountAvatarPreset.preset(for: presetId)
    }

    private var imageSize: CGFloat {
        size * 0.62
    }

    private var editBadgeSize: CGFloat {
        max(16, size * 0.38)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Image(systemName: preset?.systemImage ?? "person.crop.circle.fill")
                .font(.system(size: QubricTheme.iPadFontSize(imageSize), weight: preset == nil ? .regular : .semibold))
                .foregroundStyle(preset?.color ?? Color.qubricPrimaryStrong)
                .frame(width: size, height: size)
                .background((preset?.color ?? Color.qubricPrimary).opacity(0.12), in: Circle())
                .overlay {
                    Circle()
                        .stroke((preset?.color ?? Color.qubricPrimary).opacity(0.25), lineWidth: QubricTheme.hairlineWidth)
                }

            if showsEditBadge {
                Image(systemName: "pencil")
                    .font(.system(size: QubricTheme.iPadFontSize(editBadgeSize * 0.48), weight: .semibold))
                    .foregroundStyle(Color.qubricPrimaryStrong)
                    .frame(width: editBadgeSize, height: editBadgeSize)
                    .background(Color.qubricSurface, in: Circle())
                    .overlay {
                        Circle()
                            .stroke(Color.qubricLine, lineWidth: QubricTheme.hairlineWidth)
                    }
            }
        }
        .accessibilityHidden(true)
    }
}

private struct AccountAvatarPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let selectedPresetId: String?
    let onSelect: (String?) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 72), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    AccountAvatarOption(
                        title: "Default",
                        presetId: nil,
                        selected: selectedPresetId == nil
                    ) {
                        select(nil)
                    }

                    ForEach(AccountAvatarPreset.all) { preset in
                        AccountAvatarOption(
                            title: preset.name,
                            presetId: preset.id,
                            selected: selectedPresetId == preset.id
                        ) {
                            select(preset.id)
                        }
                    }
                }
                .padding(16)
            }
            .background(Color.qubricGrouped.ignoresSafeArea())
            .navigationTitle("Profile picture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func select(_ presetId: String?) {
        onSelect(presetId)
        dismiss()
    }
}

private struct AccountAvatarOption: View {
    let title: String
    let presetId: String?
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    AccountAvatar(presetId: presetId, size: 52)

                    if selected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: QubricTheme.iPadFontSize(16), weight: .semibold))
                            .foregroundStyle(Color.qubricPrimaryStrong)
                            .background(Color.qubricSurface, in: Circle())
                    }
                }

                Text(title)
                    .font(.footnote)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.qubricSurface, in: RoundedRectangle(cornerRadius: QubricTheme.cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: QubricTheme.cornerRadius, style: .continuous)
                    .stroke(selected ? Color.qubricPrimary.opacity(0.72) : Color.qubricLine, lineWidth: selected ? 1.5 : QubricTheme.hairlineWidth)
            }
            .contentShape(RoundedRectangle(cornerRadius: QubricTheme.cornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) profile picture")
        .accessibilityValue(selected ? "Selected" : "")
        .accessibilityAddTraits(accessibilityTraits)
    }

    private var accessibilityTraits: AccessibilityTraits {
        selected ? .isSelected : []
    }
}

private struct SyncStatusRow: View {
    let message: String

    var body: some View {
        Label {
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } icon: {
            Image(systemName: "arrow.triangle.2.circlepath")
                .foregroundStyle(Color.qubricPrimary)
        }
    }
}

private func accountNumber(_ value: Int) -> String {
    value.formatted(.number)
}

private func dayCount(_ value: Int) -> String {
    "\(value) \(value == 1 ? "day" : "days")"
}

private enum BadgeFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case open = "To earn"
    case earned = "Earned"

    var id: String { rawValue }
}

private struct BadgeProgress {
    let current: Int
    let target: Int

    var fraction: Double {
        guard target > 0 else { return 0 }
        return max(0, min(1, Double(current) / Double(target)))
    }

    var valueText: String {
        "\(min(current, target))/\(target)"
    }
}

private struct BadgeOverviewRow: View {
    let earnedCount: Int
    let totalCount: Int
    let completion: Double
    let nextBadge: QubricBadge?

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(earnedCount)/\(totalCount) earned")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer(minLength: 12)
                Text(percentText)
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: completion)
                .tint(Color.qubricPrimary)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Image(systemName: nextBadge == nil ? "checkmark.seal.fill" : "target")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(nextBadge == nil ? Color.qubricPrimaryStrong : Color.qubricPrimary)
                    .frame(width: 16)

                Text(nextText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 3)
        .accessibilityElement(children: .combine)
    }

    private var percentText: String {
        "\(Int((completion * 100).rounded()))%"
    }

    private var nextText: String {
        guard let nextBadge else { return "All badges earned." }
        if let progress = nextBadge.progressLabel {
            return "Next: \(nextBadge.label) · \(progress)"
        }
        return "Next: \(nextBadge.label)"
    }
}

private struct BadgeEmptyRow: View {
    let filter: BadgeFilter

    var body: some View {
        Label(message, systemImage: filter == .earned ? "rosette" : "checkmark.seal")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.vertical, 3)
            .accessibilityElement(children: .combine)
    }

    private var message: String {
        switch filter {
        case .all:
            return "No badges yet."
        case .open:
            return "All badges earned."
        case .earned:
            return "No earned badges yet."
        }
    }
}

private struct BadgeRow: View {
    let badge: QubricBadge
    let progress: BadgeProgress
    let isNext: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            BadgeIcon(symbol: symbolName, state: iconState)

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(badge.label)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.86)

                    Spacer(minLength: 8)

                    if let statusText {
                        Text(statusText)
                            .font(.caption.weight(statusText == "Next" ? .semibold : .regular))
                            .foregroundStyle(statusColor)
                    }
                }

                HStack(alignment: .firstTextBaseline) {
                    Text(detailText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    Spacer(minLength: 8)

                    Text(progress.valueText)
                        .font(.footnote.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                if progress.target > 1 {
                    ProgressView(value: progress.fraction)
                        .tint(progressTint)
                        .opacity(badge.earned || isNext ? 1 : 0.58)
                }
            }
        }
        .opacity(badge.earned || isNext ? 1 : 0.82)
        .accessibilityElement(children: .combine)
        .accessibilityValue("\(statusText ?? "In progress"), \(progress.valueText)")
    }

    private var symbolName: String {
        switch badge.id {
        case "first-split":
            return "target"
        case "bell-builder":
            return "link"
        case "swap-minimalist":
            return "arrow.left.arrow.right"
        case "clean-solver":
            return "checkmark.seal"
        case "reflective-solver":
            return "text.bubble"
        case "five-puzzle-streak":
            return "flame"
        case "qubric-mastery":
            return "crown"
        default:
            return "rosette"
        }
    }

    private var iconState: BadgeIcon.State {
        if badge.earned { return .earned }
        return isNext ? .next : .open
    }

    private var detailText: String {
        if badge.earned { return "Complete" }
        return badge.progressLabel ?? "In progress"
    }

    private var statusText: String? {
        if badge.earned { return "Earned" }
        return isNext ? "Next" : nil
    }

    private var statusColor: Color {
        if badge.earned { return .secondary }
        return Color.qubricPrimary
    }

    private var progressTint: Color {
        if badge.earned { return Color.qubricPrimaryStrong }
        return isNext ? Color.qubricPrimary : Color.secondary
    }
}

private struct BadgeIcon: View {
    enum State {
        case earned
        case next
        case open
    }

    let symbol: String
    let state: State

    var body: some View {
        RoundedRectangle(cornerRadius: QubricTheme.smallCornerRadius, style: .continuous)
            .fill(backgroundColor)
            .frame(width: 38, height: 38)
            .overlay {
                RoundedRectangle(cornerRadius: QubricTheme.smallCornerRadius, style: .continuous)
                    .stroke(borderColor, lineWidth: QubricTheme.hairlineWidth)
            }
            .overlay {
                Image(systemName: symbol)
                    .font(.system(size: QubricTheme.iPadFontSize(17), weight: .semibold))
                    .foregroundStyle(foregroundColor)
            }
            .accessibilityHidden(true)
    }

    private var backgroundColor: Color {
        switch state {
        case .earned:
            return Color.qubricPrimary.opacity(0.12)
        case .next:
            return Color.qubricPrimary.opacity(0.10)
        case .open:
            return Color.qubricSecondaryGrouped
        }
    }

    private var borderColor: Color {
        switch state {
        case .earned:
            return Color.qubricPrimary.opacity(0.32)
        case .next:
            return Color.qubricPrimary.opacity(0.36)
        case .open:
            return Color.qubricLine
        }
    }

    private var foregroundColor: Color {
        switch state {
        case .earned:
            return Color.qubricPrimaryStrong
        case .next:
            return Color.qubricPrimary
        case .open:
            return Color.secondary
        }
    }
}

private extension View {
    func accountTile(padding: CGFloat) -> some View {
        self
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(padding)
            .background(Color.qubricSurface, in: RoundedRectangle(cornerRadius: QubricTheme.cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: QubricTheme.cornerRadius, style: .continuous)
                    .stroke(Color.qubricTileLine, lineWidth: QubricTheme.tileStrokeWidth)
            }
            .iPadReadableWidth()
    }

    func badgeTile() -> some View {
        self
            .padding(.horizontal, 12)
            .padding(.vertical, 13)
            .background(Color.qubricSurface, in: RoundedRectangle(cornerRadius: QubricTheme.cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: QubricTheme.cornerRadius, style: .continuous)
                    .stroke(Color.qubricTileLine, lineWidth: QubricTheme.tileStrokeWidth)
            }
            .iPadReadableWidth()
    }
}

private func badgeProgress(for badge: QubricBadge, profile: PlayerProfile) -> BadgeProgress {
    let completedCount = profile.completed.values.filter { $0 }.count
    let perfectCount = profile.solveStats.values.filter(\.perfect).count
    let reflectionCount = profile.solveStats.values.filter(\.reflectionCorrect).count

    switch badge.id {
    case "first-split":
        return BadgeProgress(current: profile.completed["1.1"] == true ? 1 : 0, target: 1)
    case "bell-builder":
        return BadgeProgress(current: profile.completed["2.5"] == true ? 1 : 0, target: 1)
    case "swap-minimalist":
        return BadgeProgress(current: profile.completed["3.2"] == true ? 1 : 0, target: 1)
    case "clean-solver":
        return BadgeProgress(current: perfectCount, target: 3)
    case "reflective-solver":
        return BadgeProgress(current: reflectionCount, target: 10)
    case "five-puzzle-streak":
        return BadgeProgress(current: completedCount, target: 5)
    case "qubric-mastery":
        return BadgeProgress(current: completedCount, target: QubricData.allPuzzles.count)
    default:
        return BadgeProgress(current: badge.earned ? 1 : 0, target: 1)
    }
}
