//
//  ContentView.swift
//  Qubric
//
//  Root view hosting top-level tab navigation.
//

import SwiftUI

private enum QubricTab: String, Hashable {
    case journey
    case daily
    case account
}

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject var store: QubricStore
    @State private var selectedTab: QubricTab = .journey
    @State private var activePuzzle: QuantumPuzzle?
    @State private var shouldShowLaunchAnimation = !Self.skipsLaunchAnimation
    @State private var didOpenLaunchPuzzle = false
    @State private var didApplySmartLanding = false
    @AppStorage("qubric.onboarded.v1") private var hasOnboarded = false

    var body: some View {
        ZStack {
            Group {
                if store.profile == nil || Self.forcesAuthScreen {
                    if store.isRestoringSession && !Self.forcesAuthScreen {
                        ProgressView("Restoring session...")
                    } else {
                        AuthView(store: store, onPlayFirstPuzzle: openFirstPuzzleFromAuth)
                    }
                } else if let activePuzzle {
                    PuzzleRunView(
                        puzzle: activePuzzle,
                        store: store,
                        onBack: { self.activePuzzle = nil },
                        onNext: { id in self.activePuzzle = QubricData.puzzle(id: id) }
                    )
                } else {
                    TabView(selection: $selectedTab) {
                        JourneyView(store: store, onOpenPuzzle: { activePuzzle = $0 })
                            .tabItem { Label("Journey", systemImage: selectedTab == .journey ? "map.fill" : "map") }
                            .tag(QubricTab.journey)

                        DailyView(store: store, onOpenPuzzle: { activePuzzle = $0 })
                            .tabItem { Label("Daily", systemImage: selectedTab == .daily ? "calendar.circle.fill" : "calendar") }
                            .tag(QubricTab.daily)

                        AccountView(store: store)
                            .tabItem { Label("Account", systemImage: selectedTab == .account ? "person.crop.circle.fill" : "person.crop.circle") }
                            .tag(QubricTab.account)
                    }
                    .background(Color.qubricGrouped.ignoresSafeArea())
                    .toolbarBackground(Color.qubricElevatedSurface, for: .tabBar)
                    .toolbarBackground(.visible, for: .tabBar)
                }
            }

            if shouldShowLaunchAnimation {
                QubricLaunchAnimationView(onFinished: finishLaunchAnimation)
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .tint(.qubricPrimary)
        .overlay(alignment: .top) {
            if !shouldShowLaunchAnimation {
                badgeEarnedOverlay
            }
        }
        .animation(.easeInOut(duration: 0.22), value: store.badgeEarnedEvent?.id)
        .onAppear {
            store.setAppActive(scenePhase == .active)
            applyLaunchRoutingIfPossible()
        }
        .onChange(of: scenePhase) { _, phase in
            store.setAppActive(phase == .active)
        }
        .onChange(of: store.profile?.id) { _, _ in
            applyLaunchRoutingIfPossible()
        }
        .fullScreenCover(item: $store.levelUpEvent) { event in
            LevelUpOverlayView(event: event) {
                store.levelUpEvent = nil
            }
            .overlay(alignment: .top) {
                badgeEarnedOverlay
            }
        }
    }

    @ViewBuilder
    private var badgeEarnedOverlay: some View {
        if let event = store.badgeEarnedEvent {
            BadgeEarnedBanner(
                event: event,
                onTap: openAccountFromBadge,
                onDismiss: store.dismissBadgeEarnedEvent
            )
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    private func openAccountFromBadge() {
        activePuzzle = nil
        selectedTab = .account
        store.levelUpEvent = nil
        store.dismissBadgeEarnedEvent()
    }

    private func openFirstPuzzleFromAuth() {
        hasOnboarded = true
        activePuzzle = QubricData.puzzle(id: QubricData.firstPuzzleId)
    }

    private func finishLaunchAnimation() {
        guard shouldShowLaunchAnimation else { return }
        withAnimation(.easeOut(duration: 0.22)) {
            shouldShowLaunchAnimation = false
        }
        applyLaunchRoutingIfPossible()
    }

    private func applyLaunchRoutingIfPossible() {
        guard !shouldShowLaunchAnimation else { return }

        if launchPuzzleId != nil {
            openLaunchPuzzleIfNeeded()
            return
        }

        guard activePuzzle == nil else { return }

        if let tab = launchTab {
            hasOnboarded = true
            selectedTab = tab
            return
        }

        applySmartLandingIfNeeded()
    }

    private func openLaunchPuzzleIfNeeded() {
        guard !didOpenLaunchPuzzle, store.profile != nil, let puzzleId = launchPuzzleId else { return }
        didOpenLaunchPuzzle = true
        hasOnboarded = true
        activePuzzle = QubricData.puzzle(id: puzzleId)
    }

    private func applySmartLandingIfNeeded() {
        guard
            !didApplySmartLanding,
            let profile = store.profile
        else { return }

        didApplySmartLanding = true
        hasOnboarded = true
        selectedTab = QubricData.isDailyEligible(completed: profile.completed) ? .daily : .journey
    }

    private var launchPuzzleId: String? {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        guard
            let index = args.firstIndex(of: "--qubric-open-puzzle"),
            args.indices.contains(index + 1)
        else {
            return nil
        }
        return args[index + 1]
        #else
        nil
        #endif
    }

    private var launchTab: QubricTab? {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        guard
            let index = args.firstIndex(of: "--qubric-open-tab"),
            args.indices.contains(index + 1)
        else {
            return nil
        }
        return QubricTab(rawValue: args[index + 1])
        #else
        nil
        #endif
    }

    private static var skipsLaunchAnimation: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("--qubric-skip-launch-animation")
        #else
        false
        #endif
    }

    private static var forcesAuthScreen: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("--qubric-open-auth")
        #else
        false
        #endif
    }
}

private struct BadgeEarnedBanner: View {
    let event: BadgeEarnedEvent
    let onTap: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Image(systemName: "rosette")
                    .font(.system(size: QubricTheme.iPadFontSize(18), weight: .semibold))
                    .foregroundStyle(Color.qubricPrimaryStrong)
                    .frame(width: 28, height: 28)
                    .background(Color.qubricPrimary.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("New badge")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(event.label)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: 420)
            .background(Color.qubricSurface)
            .clipShape(RoundedRectangle(cornerRadius: QubricTheme.cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: QubricTheme.cornerRadius, style: .continuous)
                    .stroke(Color.qubricTileLine, lineWidth: QubricTheme.tileStrokeWidth)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("New badge, \(event.label)")
        .task(id: event.id) {
            do {
                try await Task.sleep(nanoseconds: 4_000_000_000)
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            onDismiss()
        }
    }
}

private struct LevelUpOverlayView: View {
    let event: LevelUpEvent
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.qubricSecondaryGrouped
                .opacity(0.92)
                .ignoresSafeArea()
            VStack(spacing: 12) {
                Text("Level up")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text("Level \(event.to)")
                    .font(.title.weight(.semibold))
                    .foregroundStyle(.primary)
                Button("Keep playing", action: onDismiss)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }
            .padding(24)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: QubricTheme.largeCornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: QubricTheme.largeCornerRadius, style: .continuous)
                    .stroke(Color.qubricTileLine, lineWidth: QubricTheme.tileStrokeWidth)
            }
        }
        .task {
            try? await Task.sleep(nanoseconds: 6_000_000_000)
            onDismiss()
        }
    }
}
