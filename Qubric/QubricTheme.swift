//
//  QubricTheme.swift
//  Qubric
//
//  Design tokens: colors, typography, and spacing.
//

import SwiftUI
import UIKit

enum QubricTheme {
    static let cornerRadius: CGFloat = 10
    static let smallCornerRadius: CGFloat = 8
    static let largeCornerRadius: CGFloat = 12
    static let hairlineWidth: CGFloat = 1
    static let tileStrokeWidth: CGFloat = 1

    static var iPadReadableWidth: CGFloat {
        iPadAdaptiveMetric(minimum: 760, maximum: 900)
    }

    static var iPadPuzzleWidth: CGFloat {
        iPadAdaptiveMetric(minimum: 880, maximum: 1040)
    }

    static var iPadFontScale: CGFloat {
        iPadAdaptiveScale(minimum: 1.24, maximum: 1.38)
    }

    static var iPadControlScale: CGFloat {
        iPadAdaptiveScale(minimum: 1.18, maximum: 1.32)
    }

    static var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    static func iPadFontSize(_ baseSize: CGFloat) -> CGFloat {
        isPad ? baseSize * iPadFontScale : baseSize
    }

    static func iPadMetric(_ baseSize: CGFloat) -> CGFloat {
        isPad ? baseSize * iPadControlScale : baseSize
    }

    private static func iPadAdaptiveScale(minimum: CGFloat, maximum: CGFloat) -> CGFloat {
        guard isPad else { return 1 }
        return minimum + (maximum - minimum) * iPadWindowProgress
    }

    private static func iPadAdaptiveMetric(minimum: CGFloat, maximum: CGFloat) -> CGFloat {
        guard isPad else { return minimum }
        return minimum + (maximum - minimum) * iPadWindowProgress
    }

    private static var iPadWindowProgress: CGFloat {
        let shortSide = min(activeWindowSize.width, activeWindowSize.height)
        let clamped = min(max(shortSide, 744), 1032)
        return (clamped - 744) / (1032 - 744)
    }

    private static var activeWindowSize: CGSize {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        if let keyWindow = scenes.flatMap(\.windows).first(where: \.isKeyWindow) {
            return keyWindow.bounds.size
        }
        return scenes.first?.screen.bounds.size ?? UIScreen.main.bounds.size
    }
}

extension Color {
    static let qubricPrimary = Color.dynamic(light: 0x007F66, dark: 0x007F66)
    static let qubricPrimaryStrong = Color.dynamic(light: 0x006353, dark: 0x1BBF9B)
    static let qubricPhase = Color.dynamic(light: 0x9F5F3C, dark: 0xD1865C)
    static let qubricAccent = Color.dynamic(light: 0xF0A500, dark: 0xF7B733)
    static let qubricAccentSoft = Color.dynamic(light: 0xF0A500, dark: 0xF7B733, lightAlpha: 0.16, darkAlpha: 0.20)
    static let qubricSuccess = Color(.systemGreen)
    static let qubricWarning = Color(.systemOrange)
    static let qubricError = Color(.systemRed)
    static let qubricGrouped = Color.dynamic(light: 0xF3F3EE, dark: 0x0E100C)
    static let qubricSecondaryGrouped = Color.dynamic(light: 0xFFFFFF, dark: 0x171A15)
    static let qubricSurface = Color.dynamic(light: 0xFFFFFF, dark: 0x11130F)
    static let qubricElevatedSurface = Color.dynamic(light: 0xF8F8F4, dark: 0x181B16)
    static let qubricLine = Color(.separator).opacity(0.58)
    static let qubricLineStrong = Color(.separator).opacity(0.82)
    static let qubricTileLine = Color.dynamic(light: 0xC4C4BF, dark: 0x383A36, lightAlpha: 0.62, darkAlpha: 0.78)
    static let qubricTrack = Color.dynamic(light: 0xDADAD2, dark: 0x2A2D28)

    private static func dynamic(light: UInt32, dark: UInt32, lightAlpha: CGFloat = 1, darkAlpha: CGFloat = 1) -> Color {
        Color(
            UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(hex: dark, alpha: darkAlpha)
                    : UIColor(hex: light, alpha: lightAlpha)
            }
        )
    }
}

private extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(
            red: CGFloat((hex >> 16) & 0xff) / 255,
            green: CGFloat((hex >> 8) & 0xff) / 255,
            blue: CGFloat(hex & 0xff) / 255,
            alpha: alpha
        )
    }
}

extension View {
    func groupedCard() -> some View {
        self
            .padding()
            .background(Color.qubricSecondaryGrouped)
            .clipShape(RoundedRectangle(cornerRadius: QubricTheme.cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: QubricTheme.cornerRadius, style: .continuous)
                    .stroke(Color.qubricTileLine, lineWidth: QubricTheme.tileStrokeWidth)
            }
    }

    func iPadReadableWidth(maxWidth: CGFloat = QubricTheme.iPadReadableWidth) -> some View {
        modifier(IPadReadableWidthModifier(maxWidth: maxWidth))
    }

    func iPadTypographyScale() -> some View {
        modifier(IPadTypographyScaleModifier())
    }
}

private struct IPadTypographyScaleModifier: ViewModifier {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @ViewBuilder
    func body(content: Content) -> some View {
        if QubricTheme.isPad {
            content.environment(\.dynamicTypeSize, promotedDynamicTypeSize)
        } else {
            content
        }
    }

    private var promotedDynamicTypeSize: DynamicTypeSize {
        let preferredBase: DynamicTypeSize = QubricTheme.iPadFontScale >= 1.32 ? .xxxLarge : .xxLarge

        switch dynamicTypeSize {
        case .xSmall, .small, .medium, .large, .xLarge:
            return preferredBase
        default:
            return dynamicTypeSize
        }
    }
}

private struct IPadReadableWidthModifier: ViewModifier {
    let maxWidth: CGFloat

    @ViewBuilder
    func body(content: Content) -> some View {
        if QubricTheme.isPad {
            content
                .frame(maxWidth: maxWidth, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .center)
        } else {
            content
        }
    }
}
