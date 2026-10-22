import AppKit
import KeelCore
import SwiftUI

/// The small square that stands for a provider. Keel draws its own marks:
/// Anthropic's and OpenAI's logos need their written permission, so they can
/// replace these in this one place if that is granted.
struct ProviderMark: View {
    let kind: AIConnection.Kind
    var size: CGFloat = 36

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
            .fill(background)
            .frame(width: size, height: size)
            .overlay { glyph }
            .accessibilityHidden(true)
    }

    private var background: Color {
        switch kind {
        case .claudeCode: Color(hex: 0xF6E7DC)
        case .chatGPT: Color(hex: 0xE4ECE9)
        case .apple: Color(hex: 0xEDE8F7)
        }
    }

    @ViewBuilder
    private var glyph: some View {
        switch kind {
        case .claudeCode:
            Text("C")
                .font(.keel(size * 0.5, .extraBold))
                .foregroundStyle(Color(hex: 0x9A4A2E))
        case .chatGPT:
            Text("G")
                .font(.keel(size * 0.5, .extraBold))
                .foregroundStyle(Palette.hull)
        case .apple:
            Image(systemName: "apple.intelligence")
                .font(.system(size: size * 0.48, weight: .semibold))
                .foregroundStyle(Color(hex: 0x6B4FC4))
        }
    }
}

/// ChatGPT, Claude and Apple Intelligence, each with its account actions.
struct ProvidersPanel: View {
    @Environment(AssistantModel.self) private var model

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(AssistantModel.providers, id: \.self) { kind in
                ProviderCard(kind: kind)
            }
        }
        .task { await model.accounts.refreshAll() }
    }
}

private struct ProviderCard: View {
    @Environment(AssistantModel.self) private var model
    let kind: AIConnection.Kind
    @State private var showsInstall = false

    private var phase: Accounts.Phase { model.accounts.phase(kind) }
    private var isCurrent: Bool { model.connection?.kind == kind }
    private var isReady: Bool { model.accounts.isReady(kind) }
    private var tool: CLITool? { Accounts.tool(for: kind) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                if isReady { model.use(kind) }
            } label: {
                header
            }
            .buttonStyle(.plain)
            .help(isReady && !isCurrent ? "\(title) ile sohbet et" : "")

            actions
            if showsInstall, phase == .notInstalled, let tool {
                InstallHelp(tool: tool)
            }
        }
        .padding(14)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(isCurrent ? Palette.keelGreen : Palette.border, lineWidth: isCurrent ? 2 : 1)
        }
        .animation(.easeOut(duration: 0.15), value: phase)
    }

    private var header: some View {
        HStack(spacing: 12) {
            ProviderMark(kind: kind, size: 40)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.keel(16, .bold))
                    .foregroundStyle(Palette.hull)
                Text(subtitle)
                    .font(.keel(12, .medium))
                    .foregroundStyle(Palette.slate)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                StatusLine(text: status.text, tone: status.tone)
            }
            Spacer(minLength: 4)
            if isCurrent {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Palette.keelGreen)
                    .accessibilityLabel("Kullanılıyor")
            }
        }
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var actions: some View {
        switch phase {
        case .checking:
            EmptyView()
        case .notInstalled:
            if kind != .apple {
                HStack(spacing: 6) {
                    Button(showsInstall ? "Gizle" : "Nasıl kurulur?") { showsInstall.toggle() }
                        .buttonStyle(TileButtonStyle())
                    Button("Tekrar kontrol et") { Task { await model.accounts.refresh(kind) } }
                        .buttonStyle(TileButtonStyle())
                }
            }
        case .signedOut:
            HStack(spacing: 6) {
                Button("Giriş yap") { model.accounts.signIn(kind) }
                    .buttonStyle(TileButtonStyle(prominent: true))
            }
        case .signingIn(let link):
            HStack(spacing: 6) {
                if let link {
                    Button("Sayfayı aç") { NSWorkspace.shared.open(link) }
                        .buttonStyle(TileButtonStyle())
                }
                Button("Terminal'de") { model.accounts.signInInTerminal(kind) }
                    .buttonStyle(TileButtonStyle())
                    .help("Tarayıcı açılmadıysa girişi Terminal'de yap")
                Button("Vazgeç") { model.accounts.cancelSignIn(kind) }
                    .buttonStyle(TileButtonStyle())
            }
        case .signedIn:
            HStack(spacing: 6) {
                if !isCurrent {
                    Button("Kullan") { model.use(kind) }
                        .buttonStyle(TileButtonStyle(prominent: true))
                }
                if kind != .apple {
                    Button("Hesap değiştir") { Task { await model.accounts.switchAccount(kind) } }
                        .buttonStyle(TileButtonStyle())
                    Button("Çıkış yap") { Task { await model.accounts.signOut(kind) } }
                        .buttonStyle(TileButtonStyle(tone: .danger))
                }
            }
        }
    }

    private var title: String {
        AIConnection(kind: kind).providerName
    }

    private var subtitle: String {
        switch (kind, phase) {
        case (.apple, .notInstalled):
            if case .unavailable(let reason) = AppleIntelligence.status { return reason }
            return "Bu Mac'te kullanılamıyor"
        case (.apple, _):
            return "Bu Mac'te çalışır; veriler Mac'ten çıkmaz"
        case (_, .signedIn(let detail?)):
            return detail
        case (.chatGPT, _):
            return "ChatGPT hesabınla, Codex üzerinden"
        default:
            return "Claude hesabınla, Claude Code üzerinden"
        }
    }

    private var status: (text: String, tone: StatusLine.Tone) {
        switch phase {
        case .checking:
            return ("Kontrol ediliyor…", .neutral)
        case .notInstalled:
            return kind == .apple ? ("Kullanılamıyor", .neutral) : ("\(tool?.command ?? "") kurulu değil", .warning)
        case .signedOut:
            return ("Giriş yapılmadı", .neutral)
        case .signingIn:
            return ("Tarayıcıda girişi tamamla…", .busy)
        case .signedIn:
            if isCurrent, let connection = model.connection {
                let name = model.stats.model.map(ModelNames.display) ?? connection.modelName
                return ("Kullanılıyor · \(name)", .positive)
            }
            return (kind == .apple ? "Hazır · ücretsiz" : "Girişli", .positive)
        }
    }
}

/// "● Girişli" under a provider's name.
private struct StatusLine: View {
    enum Tone { case neutral, positive, warning, busy }

    let text: String
    let tone: Tone

    var body: some View {
        HStack(spacing: 6) {
            if tone == .busy {
                ProgressView().controlSize(.mini)
            } else {
                Circle().fill(color).frame(width: 7, height: 7)
            }
            Text(text)
                .font(.keel(12, .bold))
                .foregroundStyle(tone == .positive ? Palette.mintText : Palette.slate)
                .lineLimit(1)
        }
        .padding(.top, 2)
    }

    private var color: Color {
        switch tone {
        case .positive: Palette.keelGreen
        case .warning: Palette.warningText
        case .neutral, .busy: Palette.controlBorder
        }
    }
}

/// Small square-cornered action buttons under a provider card.
struct TileButtonStyle: ButtonStyle {
    enum Tone { case normal, danger }

    var prominent = false
    var tone: Tone = .normal

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.keel(12, .bold))
            .foregroundStyle(prominent ? .white : (tone == .danger ? Palette.danger : Palette.hull))
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, 11)
            .frame(height: 30)
            .background(prominent ? Palette.hull : Palette.mist, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                if !prominent {
                    RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(Palette.border)
                }
            }
            .opacity(configuration.isPressed ? 0.75 : 1)
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

/// The one-line install command, to paste into Terminal.
private struct InstallHelp: View {
    let tool: CLITool
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Terminal'e yapıştır, kurulunca \"Tekrar kontrol et\"e bas:")
                .font(.keel(12, .medium))
                .foregroundStyle(Palette.slate)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                Text(tool.installCommand)
                    .font(.keelMono(10, .medium))
                    .foregroundStyle(Palette.hull)
                    .textSelection(.enabled)
                    .lineLimit(2)
                Spacer(minLength: 4)
                Button(copied ? "Kopyalandı" : "Kopyala") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(tool.installCommand, forType: .string)
                    copied = true
                }
                .buttonStyle(.plain)
                .font(.keel(12, .bold))
                .foregroundStyle(Palette.mintText)
            }
            .padding(10)
            .background(Palette.mist, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            Link("Kurulum rehberi", destination: tool.setupGuide)
                .font(.keel(12, .bold))
        }
    }
}
