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
    /// Read in the background: asking launchd can take a while, and this view
    /// is built at launch even before the window opens.
    @State private var launchAtLogin = false
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
                LabeledContent("Kısayollar", value: "⌘1–⌘7 bölümler · ⌘J Keel AI · ⌘, Ayarlar")
            }
        }
        .formStyle(.grouped)
        .font(.keel(13, .medium))
        .frame(width: 520, height: 560)
        .scrollContentBackground(.hidden)
        .background(Palette.raised)
        .preferredColorScheme(.dark)
        .tint(Palette.keelGreen)
        .task { launchAtLogin = await Self.loginItemStatus() == .enabled }
        .confirmationDialog("Tüm sohbet geçmişi silinsin mi?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("Sil", role: .destructive) { assistant.deleteAllChats() }
            Button("Vazgeç", role: .cancel) {}
        } message: {
            Text("\(assistant.history.count) sohbet bu Mac'ten kalıcı olarak silinir.")
        }
    }

    private static func loginItemStatus() async -> SMAppService.Status {
        await Task.detached(priority: .utility) { SMAppService.mainApp.status }.value
    }

    private func setLaunchAtLogin(_ on: Bool) {
        launchAtLogin = on
        Task {
            let error: String? = await Task.detached(priority: .userInitiated) {
                do {
                    if on {
                        try SMAppService.mainApp.register()
                    } else {
                        try SMAppService.mainApp.unregister()
                    }
                    return nil
                } catch {
                    return error.localizedDescription
                }
            }.value
            let status = await Self.loginItemStatus()
            if let error {
                loginMessage = "Ayarlanamadı: \(error). Keel'i Uygulamalar klasörüne taşıyıp tekrar dene."
            } else if status == .requiresApproval {
                loginMessage = "macOS onay istiyor: Sistem Ayarları > Genel > Giriş Öğeleri'nden Keel'e izin ver."
            } else {
                loginMessage = nil
            }
            launchAtLogin = status == .enabled
        }
    }
}
