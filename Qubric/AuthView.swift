//
//  AuthView.swift
//  Qubric
//
//  Sign-in and account creation flow.
//

import SwiftUI
import UIKit

struct AuthView: View {
    @Environment(\.openURL) private var openURL
    @ObservedObject var store: QubricStore
    var onPlayFirstPuzzle: (() -> Void)?

    @State private var phase: Phase = .intro
    @State private var mode: AuthMode = .create
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var error = ""
    @State private var opensFirstPuzzleAfterAuth = false
    @FocusState private var focusedField: FocusedField?

    init(store: QubricStore, onPlayFirstPuzzle: (() -> Void)? = nil) {
        self.store = store
        self.onPlayFirstPuzzle = onPlayFirstPuzzle

        #if DEBUG
        if let launchMode = Self.launchAuthMode {
            _phase = State(initialValue: .form)
            _mode = State(initialValue: launchMode)
        }
        #endif
    }

    private enum Phase {
        case intro
        case form
    }

    private enum AuthMode: String, Hashable {
        case create
        case login

        var title: String {
            switch self {
            case .create: return "Create account"
            case .login: return "Log in"
            }
        }

        var actionTitle: String {
            switch self {
            case .create: return "Create account"
            case .login: return "Log in"
            }
        }
    }

    private enum FocusedField: Hashable {
        case username
        case email
        case password
    }

    private var isCreating: Bool {
        mode == .create
    }

    private var trimmedUsername: String {
        username.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var usernameValid: Bool {
        trimmedUsername.range(of: #"^[A-Za-z0-9][A-Za-z0-9_-]{1,23}$"#, options: .regularExpression) != nil
    }

    private var emailValid: Bool {
        trimmedEmail.range(of: #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#, options: .regularExpression) != nil
    }

    #if DEBUG
    private static var launchAuthMode: AuthMode? {
        let args = ProcessInfo.processInfo.arguments
        guard
            let index = args.firstIndex(of: "--qubric-open-auth"),
            args.indices.contains(index + 1)
        else {
            return nil
        }
        return AuthMode(rawValue: args[index + 1])
    }
    #endif

    var body: some View {
        ZStack {
            switch phase {
            case .intro:
                Color.qubricGrouped.ignoresSafeArea()
                introCover
            case .form:
                accountForm
            }
        }
        .onChange(of: mode) { _, _ in
            error = ""
            focusedField = nil
        }
        .onChange(of: username) { _, _ in clearAuthMessages() }
        .onChange(of: email) { _, _ in clearAuthMessages() }
        .onChange(of: password) { _, _ in clearAuthMessages() }
    }

    private var introCover: some View {
        GeometryReader { proxy in
            let topPadding = introTopPadding(for: proxy)
            let bottomPadding = max(proxy.safeAreaInsets.bottom + 48, 64)
            let horizontalPadding = authHorizontalPadding(for: proxy)

            VStack(alignment: .leading, spacing: 0) {
                TypewriterQubricTitle(titleSize: 66)

                Text("\(QubricData.allPuzzles.count) puzzles. Tap gates. Match the target.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 18)

                Spacer(minLength: 40)

                VStack(alignment: .leading, spacing: 16) {
                    Button {
                        mode = .create
                        opensFirstPuzzleAfterAuth = false
                        phase = .form
                        focusedField = nil
                    } label: {
                        Text("Create account")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Color.qubricPrimaryStrong)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Opens the account creation form")

                    Button {
                        mode = .login
                        opensFirstPuzzleAfterAuth = false
                        phase = .form
                        focusedField = nil
                    } label: {
                        HStack(spacing: 0) {
                            Text("Already have an account? ")
                                .foregroundStyle(.secondary)
                            Text("Log in")
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.qubricPrimaryStrong)
                        }
                        .font(.body)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(
                maxWidth: authContentMaxWidth(for: proxy),
                minHeight: max(0, proxy.size.height - topPadding - bottomPadding),
                alignment: .topLeading
            )
            .padding(.horizontal, horizontalPadding)
            .padding(.top, topPadding)
            .padding(.bottom, bottomPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: authContainerAlignment(for: proxy))
        }
    }

    private func introTopPadding(for proxy: GeometryProxy) -> CGFloat {
        let safeTop = proxy.safeAreaInsets.top
        let proportionalTop = proxy.size.height * 0.23
        return min(max(proportionalTop, safeTop + 104), 218)
    }

    private func authHorizontalPadding(for proxy: GeometryProxy) -> CGFloat {
        isWideAuthLayout(proxy) ? 48 : 24
    }

    private func authContentMaxWidth(for proxy: GeometryProxy) -> CGFloat {
        isWideAuthLayout(proxy) ? 560 : 360
    }

    private func authContainerAlignment(for proxy: GeometryProxy) -> Alignment {
        isWideAuthLayout(proxy) ? .top : .topLeading
    }

    private func authFormOuterMaxWidth(for proxy: GeometryProxy) -> CGFloat {
        guard isWideAuthLayout(proxy) else { return .infinity }
        return authContentMaxWidth(for: proxy) + (authHorizontalPadding(for: proxy) * 2)
    }

    private func isWideAuthLayout(_ proxy: GeometryProxy) -> Bool {
        UIDevice.current.userInterfaceIdiom == .pad && proxy.size.width >= 700
    }

    private var accountForm: some View {
        GeometryReader { proxy in
            ZStack {
                Color.qubricGrouped.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        formTopBar

                        Text(mode.title)
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(.primary)
                            .accessibilityAddTraits(.isHeader)
                            .padding(.top, 52)
                            .padding(.bottom, 34)

                        authFields

                        if !error.isEmpty {
                            AuthMessageLine(text: error, systemImage: "exclamationmark.circle", color: .qubricError)
                                .padding(.top, 14)
                        }

                        primarySubmitButton
                            .padding(.top, 22)

                        Spacer(minLength: 42)

                        secondaryModeButton
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.bottom, 34)
                    }
                    .padding(.horizontal, isWideAuthLayout(proxy) ? 48 : 20)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                    .frame(maxWidth: authFormOuterMaxWidth(for: proxy), alignment: .topLeading)
                    .frame(maxWidth: .infinity, minHeight: proxy.size.height, alignment: authContainerAlignment(for: proxy))
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
    }

    private var authFields: some View {
        VStack(spacing: 12) {
            AuthInputBox(title: isCreating ? "Username" : "Username or email", isFocused: focusedField == .username) {
                TextField("", text: $username)
                    .textInputAutocapitalization(.never)
                    .textContentType(.username)
                    .keyboardType(.asciiCapable)
                    .autocorrectionDisabled()
                    .submitLabel(.next)
                    .focused($focusedField, equals: .username)
                    .onSubmit { focusedField = isCreating ? .email : .password }
                    .accessibilityLabel(isCreating ? "Username" : "Username or email")
            }

            if isCreating {
                AuthInputBox(title: "Email address", isFocused: focusedField == .email) {
                    TextField("", text: $email)
                        .textInputAutocapitalization(.never)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                        .focused($focusedField, equals: .email)
                        .onSubmit { focusedField = .password }
                        .accessibilityLabel("Email address")
                }
            }

            AuthInputBox(title: "Password", isFocused: focusedField == .password) {
                SecureField("", text: $password)
                    .textContentType(passwordTextContentType)
                    .submitLabel(.go)
                    .focused($focusedField, equals: .password)
                    .onSubmit { Task { await submit() } }
                    .accessibilityLabel("Password")
                    .accessibilityHint(isCreating ? "Use at least eight characters." : "Enter your password.")
            }
        }
    }

    private var passwordTextContentType: UITextContentType? {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--qubric-disable-password-autofill") {
            return nil
        }
        #endif

        return isCreating ? .newPassword : .password
    }

    private var primarySubmitButton: some View {
        Button {
            Task { await submit() }
        } label: {
            HStack(spacing: 8) {
                if store.isLoading {
                    ProgressView()
                        .tint(.white)
                }
                Text(store.isLoading ? loadingTitle : mode.actionTitle)
                    .font(.body.weight(.semibold))
            }
            .frame(maxWidth: .infinity, minHeight: 48)
        }
        .buttonStyle(AuthPrimaryButtonStyle())
        .disabled(store.isLoading)
        .accessibilityHint("Submits \(mode.title.lowercased()) to the Qubric backend")
    }

    private var secondaryModeButton: some View {
        Button {
            mode = secondaryMode
        } label: {
            HStack(spacing: 0) {
                Text(secondaryPrompt)
                    .foregroundStyle(.secondary)
                Text(secondaryActionTitle)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.qubricPrimaryStrong)
            }
            .font(.footnote)
        }
        .buttonStyle(.plain)
    }

    private var backToolbarButton: some View {
        Button {
            opensFirstPuzzleAfterAuth = false
            error = ""
            focusedField = nil
            phase = .intro
        } label: {
            Label("Back", systemImage: "chevron.left")
                .labelStyle(.titleAndIcon)
                .font(.body.weight(.semibold))
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
    }

    private var privacyToolbarButton: some View {
        Button(action: openPrivacyPolicy) {
            Label("Privacy Policy", systemImage: "hand.raised")
                .labelStyle(.iconOnly)
                .font(.title3.weight(.medium))
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .accessibilityLabel("Privacy Policy")
    }

    private var formTopBar: some View {
        HStack {
            backToolbarButton

            Spacer()

            privacyToolbarButton
        }
    }

    private var loadingTitle: String {
        switch mode {
        case .create:
            return "Creating..."
        case .login:
            return "Signing in..."
        }
    }

    private var secondaryMode: AuthMode {
        switch mode {
        case .create:
            return .login
        case .login:
            return .create
        }
    }

    private var secondaryPrompt: String {
        switch mode {
        case .create:
            return "Already have an account? "
        case .login:
            return "Don't have an account? "
        }
    }

    private var secondaryActionTitle: String {
        switch mode {
        case .create:
            return "Log in"
        case .login:
            return "Sign up here"
        }
    }

    private func clearAuthMessages() {
        error = ""
    }

    private func validationMessage() -> String? {
        if isCreating && !usernameValid {
            focusedField = .username
            return "Use 2-24 characters: letters, numbers, underscore, or dash."
        }

        if !isCreating && trimmedUsername.isEmpty {
            focusedField = .username
            return "Enter your username or email."
        }

        if isCreating && !emailValid {
            focusedField = .email
            return "Enter a valid email address."
        }

        if isCreating && password.count < 8 {
            focusedField = .password
            return "Use an 8+ character password."
        }

        if !isCreating && password.isEmpty {
            focusedField = .password
            return "Enter your password."
        }

        return nil
    }

    private func openPrivacyPolicy() {
        openURL(QubricAPIClient.privacyPolicyURL)
    }

    private func submit() async {
        guard !store.isLoading else { return }

        if let message = validationMessage() {
            error = message
            return
        }

        error = ""

        let result = isCreating
            ? await store.createAccount(username: trimmedUsername, email: trimmedEmail, password: password)
            : await store.login(username: trimmedUsername, password: password)

        if let result {
            error = result
        } else if opensFirstPuzzleAfterAuth {
            onPlayFirstPuzzle?()
        }
    }
}

private struct AuthBrandHeader: View {
    let modeTitle: String?
    var titleSize: CGFloat = 22

    var body: some View {
        QubricLogo(subtitle: modeTitle, titleSize: titleSize)
    }
}

private struct TypewriterQubricTitle: View {
    let titleSize: CGFloat
    @State private var displayedTitle = ""

    private let title = "Qubric."
    private let characterDelay: UInt64 = 170_000_000
    private let cycleDuration: UInt64 = 7_500_000_000

    var body: some View {
        ZStack(alignment: .leading) {
            Text(title)
                .font(.system(size: QubricTheme.iPadFontSize(titleSize), weight: .semibold))
                .foregroundStyle(.primary)
                .opacity(0)
                .accessibilityHidden(true)

            Text(displayedTitle)
                .font(.system(size: QubricTheme.iPadFontSize(titleSize), weight: .semibold))
                .foregroundStyle(.primary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .task {
            await repeatTypingTitle()
        }
    }

    @MainActor
    private func repeatTypingTitle() async {
        while !Task.isCancelled {
            displayedTitle = ""
            for character in title {
                try? await Task.sleep(nanoseconds: characterDelay)
                guard !Task.isCancelled else { return }
                displayedTitle.append(character)
            }

            let typingDuration = characterDelay * UInt64(title.count)
            try? await Task.sleep(nanoseconds: cycleDuration - typingDuration)
        }
    }
}

private struct AuthInputBox<Field: View>: View {
    let title: String
    let isFocused: Bool
    @ViewBuilder let field: Field

    init(title: String, isFocused: Bool, @ViewBuilder field: () -> Field) {
        self.title = title
        self.isFocused = isFocused
        self.field = field()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            field
                .font(.body)
                .foregroundStyle(.primary)
                .tint(Color.qubricPrimaryStrong)
                .textFieldStyle(.plain)
                .frame(minHeight: 24)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity, minHeight: 74, alignment: .leading)
        .background(Color.qubricSurface, in: RoundedRectangle(cornerRadius: QubricTheme.largeCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: QubricTheme.largeCornerRadius, style: .continuous)
                .stroke(borderColor, lineWidth: isFocused ? 2 : QubricTheme.hairlineWidth)
        }
    }

    private var borderColor: Color {
        isFocused ? Color.primary.opacity(0.86) : Color.qubricLineStrong
    }
}

private struct AuthMessageLine: View {
    let text: String
    let systemImage: String
    let color: Color

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.footnote)
            .foregroundStyle(color)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct AuthPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .background(
                (isEnabled ? Color.qubricPrimary : Color.qubricTrack)
                    .opacity(configuration.isPressed ? 0.82 : 1),
                in: RoundedRectangle(cornerRadius: QubricTheme.smallCornerRadius, style: .continuous)
            )
            .contentShape(RoundedRectangle(cornerRadius: QubricTheme.smallCornerRadius, style: .continuous))
    }
}
