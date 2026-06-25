//
//  QubricLaunchAnimationView.swift
//  Qubric
//
//  Animated launch screen shown at startup.
//

import SwiftUI

struct QubricLaunchAnimationView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let onFinished: () -> Void

    @State private var railProgress: CGFloat = 0
    @State private var gateIndex = 0
    @State private var pulseOffset: CGFloat = -0.18
    @State private var circuitOpacity = 1.0
    @State private var wordmarkVisible = false
    @State private var markScale: CGFloat = 0.98
    @State private var didStart = false

    var body: some View {
        ZStack {
            Color.qubricGrouped
                .ignoresSafeArea()

            VStack(spacing: 24) {
                CircuitAssembleMark(
                    railProgress: railProgress,
                    gateIndex: gateIndex,
                    pulseOffset: pulseOffset,
                    circuitOpacity: circuitOpacity,
                    markScale: markScale
                )
                .frame(maxWidth: 320)

                Text("Qubric")
                    .font(.system(size: QubricTheme.iPadFontSize(34), weight: .semibold))
                    .foregroundStyle(.primary)
                    .opacity(wordmarkVisible ? 1 : 0)
                    .offset(y: wordmarkVisible ? 0 : 5)
            }
            .padding(.horizontal, 34)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Qubric loading")
        .task {
            await startAnimationIfNeeded()
        }
    }

    private func startAnimationIfNeeded() async {
        guard !didStart else { return }
        await MainActor.run { didStart = true }

        if reduceMotion {
            await runReducedMotionSequence()
        } else {
            await runCircuitSequence()
        }

        await MainActor.run {
            onFinished()
        }
    }

    private func runReducedMotionSequence() async {
        await MainActor.run {
            railProgress = 1
            gateIndex = 4
            pulseOffset = 0.52
            markScale = 1
            wordmarkVisible = true
        }
        await sleep(seconds: 0.62)
    }

    private func runCircuitSequence() async {
        await MainActor.run {
            withAnimation(.easeOut(duration: 0.30)) {
                railProgress = 1
                markScale = 1
            }
        }
        await sleep(seconds: 0.12)

        for index in 1...4 {
            await MainActor.run {
                withAnimation(.spring(response: 0.22, dampingFraction: 0.86)) {
                    gateIndex = index
                }
            }
            await sleep(seconds: 0.11)
        }

        await MainActor.run {
            withAnimation(.easeInOut(duration: 0.48)) {
                pulseOffset = 1.12
            }
        }
        await sleep(seconds: 0.36)

        await MainActor.run {
            withAnimation(.easeOut(duration: 0.20)) {
                wordmarkVisible = true
            }
        }
        await sleep(seconds: 0.20)

        await MainActor.run {
            withAnimation(.easeOut(duration: 0.18)) {
                circuitOpacity = 0.16
                markScale = 0.96
            }
        }
        await sleep(seconds: 0.12)
    }

    private func sleep(seconds: Double) async {
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}

private struct CircuitAssembleMark: View {
    let railProgress: CGFloat
    let gateIndex: Int
    let pulseOffset: CGFloat
    let circuitOpacity: Double
    let markScale: CGFloat

    private let gates = [
        LaunchGate(label: "H", x: 0.22, order: 1),
        LaunchGate(label: "Z", x: 0.42, order: 2),
        LaunchGate(label: "H", x: 0.62, order: 3)
    ]

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let topY = proxy.size.height * 0.35
            let bottomY = proxy.size.height * 0.70
            let cnotX = width * 0.80

            ZStack {
                LaunchRail(progress: railProgress)
                    .frame(height: 3)
                    .position(x: width / 2, y: topY)

                LaunchRail(progress: railProgress)
                    .frame(height: 3)
                    .position(x: width / 2, y: bottomY)

                ForEach(gates) { gate in
                    LaunchGateTile(label: gate.label, visible: gateIndex >= gate.order)
                        .position(x: width * gate.x, y: topY)
                }

                LaunchCNOTGate(
                    topY: topY,
                    bottomY: bottomY,
                    visible: gateIndex >= 4
                )
                .position(x: cnotX, y: (topY + bottomY) / 2)

                LaunchPulse(progress: pulseOffset, y: topY)
                LaunchPulse(progress: pulseOffset - 0.18, y: bottomY)
            }
            .frame(width: width, height: proxy.size.height)
        }
        .frame(height: 138)
        .opacity(circuitOpacity)
        .scaleEffect(markScale)
    }
}

private struct LaunchGate: Identifiable {
    let id = UUID()
    let label: String
    let x: CGFloat
    let order: Int
}

private struct LaunchRail: View {
    let progress: CGFloat

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.qubricTrack)

                Capsule()
                    .fill(Color.qubricPrimaryStrong)
                    .frame(width: proxy.size.width * max(0, min(1, progress)))
            }
        }
    }
}

private struct LaunchGateTile: View {
    let label: String
    let visible: Bool

    var body: some View {
        Text(label)
            .font(.custom("JetBrainsMono-SemiBold", size: QubricTheme.iPadFontSize(18), relativeTo: .body))
            .foregroundStyle(.primary)
            .frame(width: 40, height: 34)
            .background(Color.qubricSurface, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(visible ? Color.qubricPrimaryStrong : Color.qubricLineStrong, lineWidth: QubricTheme.hairlineWidth)
            }
            .opacity(visible ? 1 : 0)
            .scaleEffect(visible ? 1 : 0.92)
    }
}

private struct LaunchCNOTGate: View {
    let topY: CGFloat
    let bottomY: CGFloat
    let visible: Bool

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.qubricPrimaryStrong)
                .frame(width: 2, height: bottomY - topY)

            Circle()
                .fill(Color.qubricPrimaryStrong)
                .frame(width: 12, height: 12)
                .offset(y: -(bottomY - topY) / 2)

            Circle()
                .stroke(Color.qubricPrimaryStrong, lineWidth: 2)
                .frame(width: 22, height: 22)
                .offset(y: (bottomY - topY) / 2)
        }
        .opacity(visible ? 1 : 0)
        .scaleEffect(visible ? 1 : 0.92)
    }
}

private struct LaunchPulse: View {
    let progress: CGFloat
    let y: CGFloat

    private var clampedProgress: CGFloat {
        max(0, min(1, progress))
    }

    private var visible: Bool {
        progress > 0 && progress < 1
    }

    var body: some View {
        GeometryReader { proxy in
            Circle()
                .fill(Color.qubricAccent)
                .frame(width: 9, height: 9)
                .overlay {
                    Circle()
                        .stroke(Color.qubricAccent.opacity(0.45), lineWidth: 5)
                }
                .opacity(visible ? 1 : 0)
                .position(x: proxy.size.width * clampedProgress, y: y)
        }
        .allowsHitTesting(false)
    }
}
