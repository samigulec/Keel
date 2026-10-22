import AppKit
import KeelCore
import SwiftUI

/// One provider in the "AI modelleri" list: icon, name, a line of detail,
/// a status badge and its actions, which never wrap.
struct ProviderRow<Actions: View, Detail: View>: View {
    let mark: ProviderMark.Style
    let title: String
    let subtitle: String
    var badge: (text: String, isPositive: Bool)?
    @ViewBuilder var actions: Actions
    @ViewBuilder var detail: Detail

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 14) {
                ProviderMark(style: mark, size: 38)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.keel(15, .bold))
                            .foregroundStyle(Palette.hull)
                        if let badge {
                            Pill(
                                text: badge.text,
                                background: badge.isPositive ? Palette.mint : Palette.track,
                                foreground: badge.isPositive ? Palette.mintText : Palette.slate
                            )
                        }
                    }
                    Text(subtitle)
                        .font(.keel(13, .medium))
                        .foregroundStyle(Palette.slate)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                actions
                    .fixedSize()
            }
            detail
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }
}

extension ProviderRow where Detail == EmptyView {
    init(mark: ProviderMark.Style, title: String, subtitle: String, badge: (text: String, isPositive: Bool)? = nil, @ViewBuilder actions: () -> Actions) {
        self.init(mark: mark, title: title, subtitle: subtitle, badge: badge, actions: actions, detail: { EmptyView() })
    }
}

/// Small bordered button for row actions.
struct RowButtonStyle: ButtonStyle {
    var prominent = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.keel(13, .bold))
            .foregroundStyle(prominent ? .white : Palette.hull)
            .padding(.horizontal, 14)
            .frame(minHeight: 34)
            .background(prominent ? Palette.hull : Palette.card, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            .overlay {
                if !prominent {
                    RoundedRectangle(cornerRadius: 9, style: .continuous).strokeBorder(Palette.controlBorder)
                }
            }
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

struct InUseLabel: View {
    var body: some View {
        Label("Kullanılıyor", systemImage: "checkmark.circle.fill")
            .font(.keel(13, .bold))
            .foregroundStyle(Palette.mintText)
    }
}

/// Claude through the user's own account and Claude Code's own sign-in.
struct ClaudeAccountRow: View {
    @Environment(AssistantModel.self) private var model
    var onDone: (() -> Void)?

    @State private var status: ClaudeCodeCLI.Status?
    @State private var isLoggingIn = false
    @State private var loginLink: URL?
    @State private var loginTask: Task<Void, any Error>?
    @State private var showsInstall = false
    @State private var copied = false

    private var isInUse: Bool { model.connection?.kind == .claudeCode }

    var body: some View {
        ProviderRow(mark: .claude, title: "Claude", subtitle: subtitle, badge: badge) {
            HStack(spacing: 8) {
                if let status {
                    if !status.isInstalled {
                        Button(showsInstall ? "Gizle" : "Nasıl kurulur?") { showsInstall.toggle() }
                            .buttonStyle(RowButtonStyle())
                    } else if !status.isLoggedIn {
                        Button(isLoggingIn ? "Bekleniyor…" : "Giriş yap", action: login)
                            .buttonStyle(RowButtonStyle(prominent: true))
                            .disabled(isLoggingIn)
                    } else if isInUse {
                        InUseLabel()
                    } else {
                        Button("Kullan") {
                            model.switchTo(AIConnection(kind: .claudeCode, model: AIConnection.recommendedClaudeModel))
                            onDone?()
                        }
                        .buttonStyle(RowButtonStyle(prominent: true))
                    }
                    if status.isLoggedIn {
                        Menu {
                            Button("Hesap değiştir") {
                                Task {
                                    await ClaudeCodeCLI.logout()
                                    await refresh()
                                    login()
                                }
                            }
                            Button("Çıkış yap") {
                                Task {
                                    await ClaudeCodeCLI.logout()
                                    await refresh()
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .frame(width: 30, height: 30)
                        }
                        .menuStyle(.borderlessButton)
                        .menuIndicator(.hidden)
                        .frame(width: 30)
                        .accessibilityLabel("Hesap seçenekleri")
                    }
                } else {
                    ProgressView().controlSize(.small)
                }
            }
        } detail: {
            if isLoggingIn {
                HStack(spacing: 14) {
                    ProgressView().controlSize(.small)
                    Text("Tarayıcıda girişi tamamla.")
                        .font(.keel(13, .medium))
                        .foregroundStyle(Palette.slate)
                    if let loginLink {
                        Link("Sayfayı aç", destination: loginLink)
                    }
                    Button("Terminal'de giriş yap") { Task { await ClaudeCodeCLI.loginInTerminal() } }
                        .buttonStyle(.plain)
                        .foregroundStyle(Palette.mintText)
                }
                .font(.keel(13, .bold))
                .padding(.leading, 52)
            }
            if showsInstall, status?.isInstalled == false {
                installSteps.padding(.leading, 52)
            }
        }
        .task { await refresh() }
        .onDisappear { loginTask?.cancel() }
    }

    private var subtitle: String {
        guard let status else { return "Claude Code kontrol ediliyor…" }
        if !status.isInstalled { return "Claude Pro/Max hesabınla; önce Claude Code'u kur" }
        if !status.isLoggedIn { return "Claude Pro/Max hesabınla, Claude Code üzerinden" }
        if status.authMethod == "api_key" { return "Claude Code bir API anahtarıyla girişli" }
        return status.email ?? "Claude hesabın, Claude Code üzerinden"
    }

    private var badge: (text: String, isPositive: Bool)? {
        guard let status else { return nil }
        if !status.isInstalled { return ("kurulu değil", false) }
        return status.isLoggedIn ? ("girişli", true) : ("giriş yok", false)
    }

    private var installSteps: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Terminal'e yapıştır, kurulunca \"Tekrar kontrol et\"e bas:")
                .font(.keel(12, .medium))
                .foregroundStyle(Palette.slate)
            HStack(spacing: 10) {
                Text(ClaudeCodeCLI.installCommand)
                    .font(.keelMono(11, .medium))
                    .foregroundStyle(Palette.hull)
                    .textSelection(.enabled)
                    .lineLimit(1)
                Spacer(minLength: 8)
                Button(copied ? "Kopyalandı" : "Kopyala") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(ClaudeCodeCLI.installCommand, forType: .string)
                    copied = true
                }
                .buttonStyle(.plain)
                .font(.keel(12, .bold))
                .foregroundStyle(Palette.mintText)
            }
            .padding(10)
            .background(Palette.mist, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            HStack(spacing: 14) {
                Button("Tekrar kontrol et") { Task { await refresh() } }
                    .buttonStyle(RowButtonStyle())
                Link("Kurulum rehberi", destination: ClaudeCodeCLI.setupGuide)
                    .font(.keel(13, .bold))
            }
        }
    }

    private func refresh() async {
        status = await ClaudeCodeCLI.status()
    }

    private func login() {
        isLoggingIn = true
        loginLink = nil
        Task {
            loginTask = try? await ClaudeCodeCLI.startLogin { link in loginLink = link }
            // Poll until Claude Code reports the account, for up to five minutes.
            for _ in 0..<150 {
                try? await Task.sleep(for: .seconds(2))
                let current = await ClaudeCodeCLI.status()
                if current.isLoggedIn {
                    status = current
                    break
                }
            }
            loginTask?.cancel()
            isLoggingIn = false
        }
    }
}

/// Apple's on-device model.
struct AppleIntelligenceRow: View {
    @Environment(AssistantModel.self) private var model
    var onDone: (() -> Void)?

    var body: some View {
        let status = AppleIntelligence.status
        ProviderRow(mark: .apple, title: "Apple Intelligence", subtitle: subtitle(status), badge: ("ücretsiz", true)) {
            if model.connection?.kind == .apple {
                InUseLabel()
            } else {
                Button("Kullan") {
                    model.switchTo(.apple)
                    onDone?()
                }
                .buttonStyle(RowButtonStyle(prominent: true))
                .disabled(status != .available)
            }
        }
    }

    private func subtitle(_ status: AppleIntelligence.Status) -> String {
        switch status {
        case .available: "Bu Mac'te çalışır; hesap gerekmez, veriler Mac'ten çıkmaz"
        case .unavailable(let reason): reason
        }
    }
}
