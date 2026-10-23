import AppKit
import KeelCore
import ServiceManagement
import SwiftUI

/// Keel's preferences window (⌘,).
struct SettingsView: View {
    @Environment(AssistantModel.self) private var assistant
    @AppStorage(Preference.menuBarVisible) private var menuBarVisible = true
    @AppStorage(Preference.companionButtonVisible) private var companionButtonVisible = true
    @AppStorage(Preference.saveChatHistory) private var saveChatHistory = true
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var loginMessage: String?
    @State private var confirmingDelete = false

    var body: some View {
        Form {
            Section("Genel") {
                Toggle("Oturum açılınca Keel'i başlat", isOn: Binding(
                    get: { launchAtLogin },
                    set: { setLaunchAtLogin($0) }
                ))
                if let loginMessage {
                    Text(loginMessage)
                        .font(.keel(12, .medium))
                        .foregroundStyle(Palette.warningText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Toggle("Menü çubuğunda göster", isOn: $menuBarVisible)
                Text("İşlemci, bellek, disk, sıcaklık ve ağ menü çubuğundaki pencerede görünür.")
                    .font(.keel(12, .medium))
                    .foregroundStyle(Palette.slate)
            }

            Section("Keel AI") {
                Toggle("Her ekranda Keel AI düğmesini göster", isOn: $companionButtonVisible)
                Text("Düğme kapalıyken de paneli ⌘J ile açabilirsin.")
                    .font(.keel(12, .medium))
                    .foregroundStyle(Palette.slate)
                Toggle("Sohbet geçmişini bu Mac'te sakla", isOn: $saveChatHistory)
                HStack {
                    Text("\(assistant.history.count) kayıtlı sohbet")
                        .foregroundStyle(Palette.slate)
                    Spacer()
                    Button("Geçmişi sil", role: .destructive) { confirmingDelete = true }
                        .disabled(assistant.history.isEmpty)
                }
            }

            Section("Gizlilik ve kayıtlar") {
                Text("Keel'in sildiği, atladığı ve geri aldığı her öğe bir kayıt dosyasına yazılır. Dosyalarının içeriği hiçbir yere gönderilmez.")
                    .font(.keel(12, .medium))
                    .foregroundStyle(Palette.slate)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Kayıt dosyasını Finder'da göster") {
                    let log = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Logs/Keel/actions.log")
                    if FileManager.default.fileExists(atPath: log.path) {
                        NSWorkspace.shared.activateFileViewerSelecting([log])
                    } else {
                        NSWorkspace.shared.open(log.deletingLastPathComponent().deletingLastPathComponent())
                    }
                }
            }

            Section("Hakkında") {
                LabeledContent("Sürüm", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—")
                LabeledContent("Kısayollar", value: "⌘1–⌘6 bölümler · ⌘J Keel AI · ⌘, Ayarlar")
            }
        }
        .formStyle(.grouped)
        .font(.keel(13, .medium))
        .frame(width: 520, height: 560)
        .scrollContentBackground(.hidden)
        .background(Palette.raised)
        .preferredColorScheme(.dark)
        .tint(Palette.keelGreen)
        .confirmationDialog("Tüm sohbet geçmişi silinsin mi?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("Sil", role: .destructive) { assistant.deleteAllChats() }
            Button("Vazgeç", role: .cancel) {}
        } message: {
            Text("\(assistant.history.count) sohbet bu Mac'ten kalıcı olarak silinir.")
        }
    }

    private func setLaunchAtLogin(_ on: Bool) {
        do {
            if on {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            loginMessage = SMAppService.mainApp.status == .requiresApproval
                ? "macOS onay istiyor: Sistem Ayarları > Genel > Giriş Öğeleri'nden Keel'e izin ver."
                : nil
        } catch {
            loginMessage = "Ayarlanamadı: \(error.localizedDescription). Keel'i Uygulamalar klasörüne taşıyıp tekrar dene."
        }
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }
}
