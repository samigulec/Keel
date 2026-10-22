import KeelCore
import SwiftUI

/// Connects Keel AI to the user's own AI: Claude, or any OpenAI-compatible service.
struct ConnectionForm: View {
    @Environment(AssistantModel.self) private var model
    var onDone: (() -> Void)?

    @State private var kind: AIConnection.Kind = .claude
    @State private var claudeModel = AnthropicBackend.defaultModel
    @State private var presetID = OpenAICompatibleBackend.presets[0].id
    @State private var baseURL = OpenAICompatibleBackend.presets[0].baseURL
    @State private var otherModel = ""
    @State private var apiKey = ""
    @State private var error: String?

    private var preset: OpenAICompatibleBackend.Preset? {
        OpenAICompatibleBackend.presets.first { $0.id == presetID }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Picker("Sağlayıcı", selection: $kind) {
                Text("Claude").tag(AIConnection.Kind.claude)
                Text("Diğer (OpenAI uyumlu)").tag(AIConnection.Kind.openAICompatible)
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            switch kind {
            case .claude: claudeFields
            case .openAICompatible: otherFields
            }

            if let error {
                Text(error)
                    .font(.keel(13, .semibold))
                    .foregroundStyle(Palette.danger)
            }

            HStack(spacing: 12) {
                Button("Bağlan", action: connect)
                    .buttonStyle(.keelPrimary)
                    .disabled(!canConnect)
                if let onDone {
                    Button("Vazgeç", action: onDone)
                        .buttonStyle(.keelSecondary)
                }
            }
        }
        .onAppear(perform: loadCurrent)
    }

    private var claudeFields: some View {
        VStack(alignment: .leading, spacing: 14) {
            FieldLabel("Model")
            Picker("Model", selection: $claudeModel) {
                ForEach(AnthropicBackend.models) { option in
                    Text("\(option.name): \(option.summary)").tag(option.id)
                }
            }
            .labelsHidden()

            FieldLabel("Claude API anahtarı")
            SecureField("sk-ant-…", text: $apiKey)
                .textFieldStyle(.roundedBorder)
            Text("Anahtarı Claude Console'dan alırsın; kullandıkça ücretlendirilir. Claude.ai aboneliği (Pro/Max) API kullanımını kapsamaz.")
                .font(.keel(12, .medium))
                .foregroundStyle(Palette.slate)
                .fixedSize(horizontal: false, vertical: true)
            Link("Claude Console'da anahtar oluştur", destination: URL(string: "https://console.anthropic.com/settings/keys")!)
                .font(.keel(13, .bold))
        }
    }

    private var otherFields: some View {
        VStack(alignment: .leading, spacing: 14) {
            FieldLabel("Servis")
            Picker("Servis", selection: $presetID) {
                ForEach(OpenAICompatibleBackend.presets) { preset in
                    Text(preset.name).tag(preset.id)
                }
            }
            .labelsHidden()
            .onChange(of: presetID) { oldValue, newValue in
                // Follow the preset's address unless the user typed their own.
                let presets = OpenAICompatibleBackend.presets
                guard let next = presets.first(where: { $0.id == newValue }) else { return }
                if baseURL.isEmpty || baseURL == presets.first(where: { $0.id == oldValue })?.baseURL {
                    baseURL = next.baseURL
                }
            }

            FieldLabel("Sunucu adresi")
            TextField("https://…/v1", text: $baseURL)
                .textFieldStyle(.roundedBorder)

            FieldLabel("Model")
            TextField(preset?.modelHint ?? "Model adı", text: $otherModel)
                .textFieldStyle(.roundedBorder)

            if preset?.needsKey ?? true {
                FieldLabel("API anahtarı")
                SecureField("Anahtar", text: $apiKey)
                    .textFieldStyle(.roundedBorder)
            } else {
                Text("Yerel model: veriler bilgisayarından çıkmaz, anahtar gerekmez.")
                    .font(.keel(12, .medium))
                    .foregroundStyle(Palette.slate)
            }
            Text("Araç kullanabilen (function calling) bir model seç; yoksa Keel AI sistem verilerini okuyamaz.")
                .font(.keel(12, .medium))
                .foregroundStyle(Palette.slate)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var draftConnection: AIConnection {
        switch kind {
        case .claude:
            AIConnection(kind: .claude, model: claudeModel)
        case .openAICompatible:
            AIConnection(
                kind: .openAICompatible,
                model: otherModel.trimmingCharacters(in: .whitespaces),
                presetID: presetID,
                baseURL: baseURL.trimmingCharacters(in: .whitespaces)
            )
        }
    }

    /// A key is required unless one is already stored for the same account.
    private var hasKey: Bool {
        !apiKey.isEmpty || KeychainStore.read(account: draftConnection.keychainAccount) != nil
    }

    private var canConnect: Bool {
        let connection = draftConnection
        guard !connection.model.isEmpty else { return false }
        if connection.kind == .openAICompatible, URL(string: connection.baseURL ?? "")?.scheme == nil { return false }
        return !connection.needsKey || hasKey
    }

    private func connect() {
        do {
            try model.connect(draftConnection, apiKey: apiKey.isEmpty ? nil : apiKey)
            apiKey = ""
            error = nil
            onDone?()
        } catch {
            self.error = "Anahtar Keychain'e kaydedilemedi."
        }
    }

    private func loadCurrent() {
        guard let current = model.connection else { return }
        kind = current.kind
        switch current.kind {
        case .claude:
            claudeModel = current.model
        case .openAICompatible:
            presetID = current.presetID ?? presetID
            baseURL = current.baseURL ?? baseURL
            otherModel = current.model
        }
    }
}

private struct FieldLabel: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text).eyebrowStyle()
    }
}
