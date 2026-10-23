import KeelCore
import SwiftUI

/// Keel AI beside every screen: a button in the corner and a panel that
/// slides in from the right. It shares the conversation with the Keel AI
/// tab and knows which screen the user is on.
struct CompanionPanel: View {
    @Environment(AssistantModel.self) private var model
    let section: AppSection
    let suggestions: [String]
    let openFull: () -> Void
    let close: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Mascot(character: .bilge, size: 38)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Keel AI")
                        .font(.keel(17, .extraBold))
                        .foregroundStyle(Palette.text)
                    Text("Şu an: \(section.title)")
                        .font(.keel(12, .medium))
                        .foregroundStyle(Palette.slate)
                        .lineLimit(1)
                }
                Spacer(minLength: 4)
                if !model.history.isEmpty {
                    Menu {
                        ForEach(model.history.prefix(10)) { chat in
                            Button(chat.title) { model.open(chat) }
                        }
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Palette.subtle)
                            .frame(width: 32, height: 32)
                            .background(Palette.mist, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                    }
                    .menuStyle(.borderlessButton)
                    .menuIndicator(.hidden)
                    .fixedSize()
                    .disabled(model.isRunning)
                    .help("Geçmiş sohbetler")
                    .accessibilityLabel("Geçmiş sohbetler")
                }
                iconButton("plus.bubble", help: "Yeni sohbet") { model.startNewChat() }
                    .disabled(model.items.isEmpty)
                iconButton("arrow.up.left.and.arrow.down.right", help: "Keel AI sekmesinde aç", action: openFull)
                iconButton("xmark", help: "Kapat (⌘J)", action: close)
            }

            if model.connection == nil {
                ScrollView { ConnectCard() }
            } else {
                Conversation(compact: true, suggestions: suggestions)
                Composer()
            }
        }
        .padding(16)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Palette.navy.opacity(0.55))
        .background(Color.white.opacity(0.03))
        .overlay(alignment: .leading) {
            Rectangle().fill(Palette.border).frame(width: 1)
        }
    }

    private func iconButton(_ symbol: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Palette.subtle)
                .frame(width: 32, height: 32)
                .background(Palette.mist, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(help)
        .accessibilityLabel(help)
    }
}

/// The round Bilge button in the corner of every screen.
struct CompanionButton: View {
    @Environment(AssistantModel.self) private var model
    let isOpen: Bool
    let toggle: () -> Void

    var body: some View {
        Button(action: toggle) {
            ZStack {
                Circle()
                    .fill(Palette.assistant)
                    .frame(width: 58, height: 58)
                    .overlay { Circle().strokeBorder(Color.white.opacity(0.35), lineWidth: 1.5) }
                    .shadow(color: Color(hex: 0xA08BFF).opacity(0.45), radius: 16, y: 8)
                if isOpen {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Mascot(character: .bilge, size: 40)
                }
            }
            .frame(width: 66, height: 66)
            .overlay(alignment: .topTrailing) {
                // Keel AI is still answering, e.g. after the panel was closed.
                if model.isRunning {
                    ProgressView()
                        .controlSize(.mini)
                        .padding(4)
                        .background(Palette.raised, in: Circle())
                }
            }
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .keyboardShortcut("j", modifiers: .command)
        .help(isOpen ? "Keel AI'ı kapat (⌘J)" : "Keel AI'a sor (⌘J)")
        .accessibilityLabel(isOpen ? "Keel AI panelini kapat" : "Keel AI panelini aç")
    }
}

/// What each screen offers to ask, and what Keel AI should know about it.
@MainActor
enum CompanionContext {
    static func suggestions(
        for section: AppSection,
        applications: ApplicationsModel,
        cleanup: CleanupModel
    ) -> [String] {
        switch section {
        case .smartScan:
            return ["Bilgisayarımın genel durumu nasıl?", "Neleri güvenle silebilirim?", "Diskimde en çok ne yer kaplıyor?"]
        case .cleanup:
            return ["Bu kategoriler ne işe yarıyor?", "Hangilerini silmek güvenli?", "Sadece tarayıcı önbelleklerini sil"]
        case .performance:
            return ["Bilgisayarım neden yavaş?", "En çok kaynağı ne kullanıyor?", "Pilimin durumu nasıl?", "Arka planda neler çalışıyor?"]
        case .applications:
            if let app = applications.focused?.app {
                return ["\(app.name) uygulamasını kaldırmalı mıyım?", "\(app.name) neden bu kadar yer kaplıyor?", "Hangi uygulamaları kaldırabilirim?"]
            }
            return ["Hangi uygulamaları kaldırabilirim?", "Hangi uygulamalar Intel, sorun olur mu?", "En çok yer kaplayan uygulamalar hangileri?"]
        case .largeFiles:
            return ["Bu dosyalardan hangilerini silebilirim?", "İndirilenler klasörümü nasıl toparlarım?", "Disk görüntüleri (.dmg) silinebilir mi?"]
        case .assistant:
            return AssistantModel.suggestions
        }
    }

    static func screen(
        for section: AppSection,
        applications: ApplicationsModel,
        cleanup: CleanupModel,
        largeFiles: LargeFilesModel
    ) -> ScreenContext {
        switch section {
        case .largeFiles:
            let chosen = largeFiles.selectedFiles
            guard !chosen.isEmpty else {
                return ScreenContext(section: section, detail: "\(largeFiles.visibleFiles.count) files shown.")
            }
            let names = chosen.prefix(8).map { "\($0.url.lastPathComponent) (\(ByteFormat.string($0.sizeBytes)), \(FileText.lastOpened($0.lastActivity)))" }
            return ScreenContext(section: section, detail: "Selected files: " + names.joined(separator: "; ") + ".")

        case .applications:
            guard let entry = applications.focused else {
                return ScreenContext(section: section, detail: "Filter: \(applications.filter.title).")
            }
            var facts = ["Selected app: \(entry.app.name)"]
            if let version = entry.app.version { facts.append("version \(version)") }
            if let size = entry.sizeBytes { facts.append("app size \(ByteFormat.string(size))") }
            if let related = applications.relatedBytes(for: entry, ticked: false) { facts.append("related files \(ByteFormat.string(related))") }
            facts.append(AppText.lastUsed(entry.lastUsed))
            facts.append(AppText.architecture(entry.app.architecture))
            facts.append(AppText.source(entry.app.source))
            if applications.isRunning(entry.app) { facts.append("running now") }
            return ScreenContext(section: section, detail: facts.joined(separator: ", ") + ".")

        case .cleanup:
            let chosen = cleanup.selectedResults.map(\.category.title)
            guard !chosen.isEmpty else { return ScreenContext(section: section) }
            return ScreenContext(
                section: section,
                detail: "Ticked categories: \(chosen.joined(separator: ", ")), \(ByteFormat.string(cleanup.selectedBytes)) in total."
            )

        default:
            return ScreenContext(section: section)
        }
    }
}
