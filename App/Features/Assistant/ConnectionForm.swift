import AppKit
import KeelCore
import SwiftUI

/// Connects Keel AI: Apple's free on-device model with one click, or a
/// stronger cloud model with a guided, tested API key.
struct ConnectionForm: View {
    @Environment(AssistantModel.self) private var model
    var onDone: (() -> Void)?

    private enum Choice: Hashable {
        case claude
        case other
    }

    @State private var choice: Choice = .claude
    @State private var claudeModel = AnthropicBackend.defaultModel
    @State private var presetID = OpenAICompatibleBackend.presets[0].id
    @State private var baseURL = OpenAICompatibleBackend.presets[0].baseURL
    @State private var otherModel = ""
    @State private var fetchedModels: [String] = []
    @State private var apiKey = ""
    @State private var clipboardKey: String?
    @State private var isTesting = false
    @State private var message: (text: String, isError: Bool)?
    @State private var showsKeyOptions = false

    private var preset: OpenAICompatibleBackend.Preset? {
        OpenAICompatibleBackend.presets.first { $0.id == presetID }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("AI modelleri").eyebrowStyle()
            VStack(spacing: 0) {
                ClaudeAccountRow(onDone: onDone)
                Divider().overlay(Palette.divider)
                ProviderRow(
                    icon: "bubble.left.and.bubble.right",
                    title: "ChatGPT",
                    subtitle: "ChatGPT hesabınla, Codex CLI üzerinden",
                    badge: ("yakında", false)
                ) {
                    EmptyView()
                }
                .opacity(0.6)
                Divider().overlay(Palette.divider)
                AppleIntelligenceRow(onDone: onDone)
                Divider().overlay(Palette.divider)
                ProviderRow(
                    icon: "key",
                    title: "API anahtarı",
                    subtitle: "Claude API, OpenAI, Gemini, OpenRouter ya da yerel Ollama / LM Studio",
                    badge: currentUsesKey ? ("kullanılıyor", true) : nil
                ) {
                    Button(showsKeyOptions ? "Gizle" : "Ayarla") {
                        withAnimation(.easeInOut(duration: 0.15)) { showsKeyOptions.toggle() }
                    }
                    .buttonStyle(RowButtonStyle())
                } detail: {
                    if showsKeyOptions {
                        keyOptions
                            .padding(.top, 6)
                            .padding(.leading, 52)
                    }
                }
            }
            .background(Palette.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Palette.border) }
        }
        .onAppear {
            loadCurrent()
            checkClipboard()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            // Back from the browser with a freshly copied key.
            checkClipboard()
        }
    }

    private var currentUsesKey: Bool {
        model.connection?.kind == .claude || model.connection?.kind == .openAICompatible
    }

    // MARK: API keys

    private var keyOptions: some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker("Sağlayıcı", selection: $choice) {
                Text("Claude API").tag(Choice.claude)
                Text("Diğer servisler").tag(Choice.other)
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            switch choice {
            case .claude: claudeSteps
            case .other: otherFields
            }

            if let message {
                Label(message.text, systemImage: message.isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                    .font(.keel(13, .semibold))
                    .foregroundStyle(message.isError ? Palette.danger : Palette.mintText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 12) {
                Button(action: testAndConnect) {
                    if isTesting {
                        ProgressView().controlSize(.small).tint(.white)
                    } else {
                        Text("Test et ve bağlan")
                    }
                }
                .buttonStyle(.keelPrimary)
                .disabled(!canConnect || isTesting)

            }
        }
    }

    // MARK: Claude

    private var claudeSteps: some View {
        VStack(alignment: .leading, spacing: 14) {
            Step(number: 1, title: "Claude Console'da bir anahtar oluştur") {
                Text("Giriş yap → API Keys → Create Key. Anahtarı kopyala ve buraya dön.")
                    .font(.keel(13, .medium))
                    .foregroundStyle(Palette.slate)
                Link(destination: URL(string: "https://console.anthropic.com/settings/keys")!) {
                    Label("Claude Console'u aç", systemImage: "arrow.up.right.square")
                        .font(.keel(13, .bold))
                }
            }

            Step(number: 2, title: "Anahtarı yapıştır") {
                if let clipboardKey, apiKey != clipboardKey {
                    Button {
                        apiKey = clipboardKey
                        message = nil
                    } label: {
                        Label("Panodaki anahtarı kullan (\(Self.masked(clipboardKey)))", systemImage: "doc.on.clipboard")
                            .font(.keel(13, .bold))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Palette.mintText)
                }
                SecureField("sk-ant-…", text: $apiKey)
                    .textFieldStyle(.roundedBorder)
                Text("Anahtar yalnızca bu Mac'in Keychain'inde saklanır.")
                    .font(.keel(12, .medium))
                    .foregroundStyle(Palette.slate)
            }

            Step(number: 3, title: "Model seç") {
                Picker("Model", selection: $claudeModel) {
                    ForEach(AnthropicBackend.models) { option in
                        Text("\(option.name): \(option.summary)").tag(option.id)
                    }
                }
                .labelsHidden()
            }

            Text("Kullandıkça ücretlendirilir. Claude Pro/Max aboneliğin varsa yukarıdaki \"Hesabınla bağlan\" daha kolay.")
                .font(.keel(12, .medium))
                .foregroundStyle(Palette.slate)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Other services

    private var otherFields: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Servis", selection: $presetID) {
                ForEach(OpenAICompatibleBackend.presets) { preset in
                    Text(preset.name).tag(preset.id)
                }
            }
            .onChange(of: presetID) { oldValue, newValue in
                // Follow the preset's address unless the user typed their own.
                let presets = OpenAICompatibleBackend.presets
                guard let next = presets.first(where: { $0.id == newValue }) else { return }
                if baseURL.isEmpty || baseURL == presets.first(where: { $0.id == oldValue })?.baseURL {
                    baseURL = next.baseURL
                }
                fetchedModels = []
                message = nil
            }

            TextField("Sunucu adresi", text: $baseURL)
                .textFieldStyle(.roundedBorder)

            if preset?.needsKey ?? true {
                SecureField("API anahtarı", text: $apiKey)
                    .textFieldStyle(.roundedBorder)
            } else {
                Text("Yerel model: veriler bilgisayarından çıkmaz, anahtar gerekmez.")
                    .font(.keel(12, .medium))
                    .foregroundStyle(Palette.slate)
            }

            HStack(spacing: 10) {
                if fetchedModels.isEmpty {
                    TextField(preset?.modelHint ?? "Model adı", text: $otherModel)
                        .textFieldStyle(.roundedBorder)
                } else {
                    Picker("Model", selection: $otherModel) {
                        ForEach(fetchedModels, id: \.self) { Text($0).tag($0) }
                    }
                    .labelsHidden()
                }
                Button("Modelleri getir") { Task { await fetchOtherModels() } }
                    .buttonStyle(.plain)
                    .font(.keel(13, .bold))
                    .foregroundStyle(Palette.mintText)
                    .disabled(isTesting)
            }

            Text("Araç kullanabilen (function calling) bir model seç; yoksa Keel AI sistem verilerini okuyamaz.")
                .font(.keel(12, .medium))
                .foregroundStyle(Palette.slate)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Actions

    private var draftConnection: AIConnection {
        switch choice {
        case .claude:
            AIConnection(kind: .claude, model: claudeModel)
        case .other:
            AIConnection(
                kind: .openAICompatible,
                model: otherModel.trimmingCharacters(in: .whitespaces),
                presetID: presetID,
                baseURL: baseURL.trimmingCharacters(in: .whitespaces)
            )
        }
    }

    /// The key typed now, or the one already stored for the same account.
    private var effectiveKey: String? {
        let typed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        return typed.isEmpty ? KeychainStore.read(account: draftConnection.keychainAccount) : typed
    }

    private var canConnect: Bool {
        let connection = draftConnection
        guard !connection.model.isEmpty else { return false }
        if connection.kind == .openAICompatible, URL(string: connection.baseURL ?? "")?.scheme == nil { return false }
        return !connection.needsKey || effectiveKey != nil
    }

    private func testAndConnect() {
        let connection = draftConnection
        let key = effectiveKey
        isTesting = true
        message = nil
        Task {
            defer { isTesting = false }
            do {
                // Listing models is free and proves the key and address work.
                let models: [String]
                switch connection.kind {
                case .claude:
                    models = try await ModelCatalog.claudeModels(apiKey: key ?? "")
                case .openAICompatible:
                    models = try await ModelCatalog.openAICompatibleModels(baseURL: URL(string: connection.baseURL ?? "")!, apiKey: key)
                case .apple, .claudeCode:
                    models = []
                }
                if !models.isEmpty, !models.contains(connection.model) {
                    message = ("Anahtar çalışıyor ama \(connection.modelName) bu hesapta görünmüyor. Başka bir model seç.", true)
                    return
                }
                let typed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
                try model.connect(connection, apiKey: typed.isEmpty ? nil : typed)
                apiKey = ""
                message = ("Bağlandı.", false)
                onDone?()
            } catch {
                message = (Self.describeTestFailure(error, connection: connection), true)
            }
        }
    }

    private func fetchOtherModels() async {
        guard let url = URL(string: baseURL.trimmingCharacters(in: .whitespaces)) else { return }
        isTesting = true
        defer { isTesting = false }
        do {
            let models = try await ModelCatalog.openAICompatibleModels(baseURL: url, apiKey: effectiveKey).sorted()
            fetchedModels = models
            if !models.contains(otherModel) { otherModel = models.first ?? "" }
            message = models.isEmpty ? ("Sunucu hiç model döndürmedi.", true) : ("\(models.count) model bulundu.", false)
        } catch {
            message = (Self.describeTestFailure(error, connection: draftConnection), true)
        }
    }

    /// Offers a Claude key found on the clipboard, so the user need not paste it.
    private func checkClipboard() {
        guard let text = NSPasteboard.general.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines),
              text.hasPrefix("sk-ant-"), !text.contains(" "), text.count > 20 else {
            clipboardKey = nil
            return
        }
        clipboardKey = text
        if choice == .claude, apiKey.isEmpty, model.connection?.kind != .claude {
            message = ("Panoda bir Claude anahtarı var.", false)
            showsKeyOptions = true
        }
    }

    private func loadCurrent() {
        guard let current = model.connection else { return }
        switch current.kind {
        case .apple, .claudeCode:
            break
        case .claude:
            choice = .claude
            claudeModel = current.model
            showsKeyOptions = true
        case .openAICompatible:
            choice = .other
            showsKeyOptions = true
            presetID = current.presetID ?? presetID
            baseURL = current.baseURL ?? baseURL
            otherModel = current.model
        }
    }

    private static func masked(_ key: String) -> String {
        "…" + key.suffix(4)
    }

    private static func describeTestFailure(_ error: any Error, connection: AIConnection) -> String {
        if case .http(let status, _)? = error as? AIError, status == 401 || status == 403 {
            return "Anahtar geçersiz. Console'dan yeniden kopyalayıp dene."
        }
        return AssistantModel.describe(error, connection: connection)
    }
}

private struct Step<Content: View>: View {
    let number: Int
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.keel(13, .extraBold))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Palette.hull, in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.keel(14, .bold))
                    .foregroundStyle(Palette.hull)
                content
            }
        }
    }
}
