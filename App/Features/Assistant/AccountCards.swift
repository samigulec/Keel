import AppKit
import KeelCore
import SwiftUI

/// "Sign in with your Claude account": runs Claude Code's own sign-in and
/// uses the user's subscription through it.
struct ClaudeAccountCard: View {
    @Environment(AssistantModel.self) private var model
    var onDone: (() -> Void)?

    @State private var status: ClaudeCodeCLI.Status?
    @State private var isLoggingIn = false
    @State private var loginLink: URL?
    @State private var loginTask: Task<Void, any Error>?
    @State private var modelAlias = "default"
    @State private var copied = false

    var body: some View {
        AccountCardShell(title: "Claude", badge: badge) {
            if let status {
                if !status.isInstalled {
                    notInstalled
                } else if status.isLoggedIn {
                    loggedIn(status)
                } else {
                    loggedOut
                }
            } else {
                ProgressView().controlSize(.small)
            }
        }
        .task { await refresh() }
        .onDisappear { loginTask?.cancel() }
    }

    private var badge: (String, Bool) {
        guard let status else { return ("kontrol ediliyor", false) }
        if !status.isInstalled { return ("kurulu değil", false) }
        if model.connection?.kind == .claudeCode, status.isLoggedIn { return ("kullanılıyor", true) }
        return status.isLoggedIn ? ("girişli", true) : ("giriş yok", false)
    }

    // MARK: States

    private var notInstalled: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Claude hesabınla bağlanmak için önce Claude Code'u kur. Terminal'e şunu yapıştır:")
                .font(.keel(13, .medium))
                .foregroundStyle(Palette.slate)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                Text(ClaudeCodeCLI.installCommand)
                    .font(.keelMono(11, .medium))
                    .foregroundStyle(Palette.hull)
                    .textSelection(.enabled)
                    .lineLimit(1)
                    .truncationMode(.middle)
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
            .background(Palette.card, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            HStack(spacing: 14) {
                Button("Tekrar kontrol et") { Task { await refresh() } }
                    .buttonStyle(.keelSecondary)
                Link("Kurulum rehberi", destination: ClaudeCodeCLI.setupGuide)
                    .font(.keel(13, .bold))
            }
        }
    }

    private var loggedOut: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Claude Pro/Max hesabınla giriş yap. Giriş Anthropic'in kendi sayfasında yapılır; Keel şifreni görmez.")
                .font(.keel(13, .medium))
                .foregroundStyle(Palette.slate)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 12) {
                Button(action: login) {
                    if isLoggingIn {
                        HStack(spacing: 8) {
                            ProgressView().controlSize(.small).tint(.white)
                            Text("Tarayıcıda bekleniyor…")
                        }
                    } else {
                        Text("Giriş yap")
                    }
                }
                .buttonStyle(.keelPrimary)
                .disabled(isLoggingIn)
            }
            if isLoggingIn {
                if let loginLink {
                    Link("Tarayıcı açılmadıysa buraya tıkla", destination: loginLink)
                        .font(.keel(13, .bold))
                }
                Button("Terminal'de giriş yap") {
                    Task { await ClaudeCodeCLI.loginInTerminal() }
                }
                .buttonStyle(.plain)
                .font(.keel(13, .bold))
                .foregroundStyle(Palette.mintText)
            }
        }
    }

    private func loggedIn(_ status: ClaudeCodeCLI.Status) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(accountLine(status))
                .font(.keel(13, .medium))
                .foregroundStyle(Palette.slate)
                .fixedSize(horizontal: false, vertical: true)
            Picker("Model", selection: $modelAlias) {
                ForEach(AIConnection.claudeCodeModels, id: \.alias) { option in
                    Text(option.name).tag(option.alias)
                }
            }
            .labelsHidden()
            HStack(spacing: 12) {
                Button("Kullan") {
                    try? model.connect(AIConnection(kind: .claudeCode, model: modelAlias), apiKey: nil)
                    onDone?()
                }
                .buttonStyle(.keelPrimary)
                Button("Hesap değiştir") {
                    Task {
                        await ClaudeCodeCLI.logout()
                        await refresh()
                        login()
                    }
                }
                .buttonStyle(.keelSecondary)
            }
        }
    }

    private func accountLine(_ status: ClaudeCodeCLI.Status) -> String {
        let account = status.email.map { " (\($0))" } ?? ""
        if status.authMethod == "api_key" {
            return "Claude Code bir API anahtarıyla girişli\(account); kullanım o anahtara faturalanır."
        }
        return "Claude hesabın\(account) Claude Code üzerinden kullanılır."
    }

    // MARK: Actions

    private func refresh() async {
        status = await ClaudeCodeCLI.status()
        if model.connection?.kind == .claudeCode, let current = model.connection?.model {
            modelAlias = current
        }
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

struct ComingSoonAccountCard: View {
    let title: String
    let detail: String

    var body: some View {
        AccountCardShell(title: title, badge: ("yakında", false)) {
            Text(detail)
                .font(.keel(13, .medium))
                .foregroundStyle(Palette.slate)
                .fixedSize(horizontal: false, vertical: true)
        }
        .opacity(0.7)
    }
}

/// The card frame shared by account providers: title, status badge, content.
private struct AccountCardShell<Content: View>: View {
    let title: String
    let badge: (text: String, isPositive: Bool)
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.keel(18, .extraBold))
                    .foregroundStyle(Palette.hull)
                Spacer()
                Pill(
                    text: badge.text,
                    background: badge.isPositive ? Palette.mint : Palette.track,
                    foreground: badge.isPositive ? Palette.mintText : Palette.slate
                )
            }
            content
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Palette.mist, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Palette.border) }
    }
}
