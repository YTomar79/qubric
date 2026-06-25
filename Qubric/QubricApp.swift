//
//  QubricApp.swift
//  Qubric
//
//  Application entry point and global appearance configuration.
//

import SwiftUI
import UIKit

@main
struct QubricApp: App {
    @StateObject private var store = QubricStore()

    init() {
        configureTabBarAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
                .preferredColorScheme(.dark)
                .iPadTypographyScale()
        }
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = nil
        appearance.backgroundColor = UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: CGFloat(0x18) / 255, green: CGFloat(0x1B) / 255, blue: CGFloat(0x16) / 255, alpha: 1)
                : UIColor(red: CGFloat(0xF8) / 255, green: CGFloat(0xF8) / 255, blue: CGFloat(0xF4) / 255, alpha: 1)
        }
        appearance.shadowColor = UIColor.separator.withAlphaComponent(0.58)

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
