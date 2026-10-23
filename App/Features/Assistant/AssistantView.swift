import KeelCore
import SwiftUI

struct AssistantView: View {
    @Environment(AssistantModel.self) private var model

    var body: some View {
        HStack(alignment: .top, spacing: 24) {
            VStack(alignment: .leading, spacing: 18) {
                PageHeader(
                    title: "Keel AI",
                    subtitle: "Bilgisayarın hakkında soru sor; Keel analiz eder, çözüm önerir. Hiçbir şey onayın olmadan yapılmaz."
                )
                if model.connection == nil {
                    ScrollView { ConnectCard() }
                } else {
                    Conversation()
                    Composer()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            if model.connection != nil {
                Aside()
                    .frame(width: 300)
            }
        }
    }
}

/// Asks before a cleanup Keel AI suggested is applied. Attached once at the
/// window's root, so it works from the Keel AI tab and the companion panel.
struct CleanupConfirmation: ViewModifier {
    @Environment(AssistantModel.self) private var model

    func body(content: Content) -> some View {
        content.confirmationDialog(
            "\(ByteFormat.string(model.pendingBytes)) temizlensin mi?",
            isPresented: Binding(
                get: { model.pendingCleanup != nil },
                set: { if !$0 { model.cancelPendingCleanup() } }
            ),
            titleVisibility: .visible
        ) {
            Button("Temizle", role: model.pendingPermanentBytes > 0 ? ButtonRole.destructive : nil) {
                model.confirmPendingCleanup()
            }
            Button("Vazgeç", role: .cancel) { model.cancelPendingCleanup() }
        } message: {
            Text(confirmationMessage)
        }
    }

    private var confirmationMessage: String {
        let permanent = model.pendingPermanentBytes
        let toTrash = model.pendingBytes - permanent
        var lines: [String] = []
        if toTrash > 0 {
            lines.append("\(ByteFormat.string(toTrash)) Çöp Kutusu'na taşınacak; oradan geri alabilirsin.")
        }
        if permanent > 0 {
            lines.append("Çöp Kutusu'ndaki \(ByteFormat.string(permanent)) kalıcı olarak silinecek ve geri alınamaz.")
        }
        return lines.joined(separator: "\n\n")
    }
}

// MARK: - Side panel

private struct Aside: View {
    @Environment(AssistantModel.self) private var model

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("AI modelleri").eyebrowStyle()
                ProvidersPanel()

                Button {
                    model.startNewChat()
                } label: {
                    Label("Yeni sohbet", systemImage: "plus.bubble")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.keelSecondary)
                .disabled(model.items.isEmpty)
                .padding(.top, 6)

                if !model.history.isEmpty {
                    ChatHistory()
                }

                PrivacyNote(isLocal: model.connection?.isLocal == true)
                    .padding(.top, 6)
            }
        }
        .scrollIndicators(.never)
    }
}

/// Earlier conversations; a click reopens one.
private struct ChatHistory: View {
    @Environment(AssistantModel.self) private var model
    @State private var showsAll = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Geçmiş sohbetler").eyebrowStyle()
                .padding(.top, 8)
            ForEach(showsAll ? model.history : Array(model.history.prefix(6))) { chat in
                let isCurrent = model.savedChatID == chat.id
                Button {
                    model.open(chat)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(chat.title)
                            .font(.keel(13, isCurrent ? .bold : .semibold))
                            .foregroundStyle(Palette.text)
                            .lineLimit(1)
                        Text(chat.updatedAt.formatted(.relative(presentation: .named)))
                            .font(.keel(11, .medium))
                            .foregroundStyle(Palette.slate)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isCurrent ? Palette.Sidebar.selectedBackground : Palette.mist, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(model.isRunning)
                .contextMenu {
                    Button("Sil", role: .destructive) { model.deleteChat(chat.id) }
                }
            }
            if model.history.count > 6 {
                Button(showsAll ? "Daha az göster" : "Tümünü göster (\(model.history.count))") { showsAll.toggle() }
                    .buttonStyle(.plain)
                    .font(.keel(12, .bold))
                    .foregroundStyle(Palette.mintText)
            }
        }
    }
}

private struct PrivacyNote: View {
    let isLocal: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(isLocal ? "Tamamen bu Mac'te" : "Neler paylaşılır?", systemImage: isLocal ? "lock.fill" : "eye")
                .font(.keel(14, .extraBold))
                .foregroundStyle(Palette.text)
            Text(isLocal
                ? "Model bilgisayarında çalışıyor; hiçbir veri Mac'inden çıkmıyor."
                : "Sistem özeti, önbellek klasörlerinin adları ve boyutları, uygulama ve servis adları. Dosyalarının içeriği asla gönderilmez.")
                .font(.keel(12, .medium))
                .foregroundStyle(Palette.slate)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.track.opacity(0.5), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Conversation

/// The messages. `compact` fits the companion panel beside other screens.
struct Conversation: View {
    @Environment(AssistantModel.self) private var model
    var compact = false
    var suggestions: [String] = AssistantModel.suggestions

    /// Consecutive tool calls are shown together as one row of chips.
    private enum Row: Identifiable {
        case item(ChatItem)
        case tools([ChatItem])

        var id: UUID {
            switch self {
            case .item(let item): item.id
            case .tools(let items): items[0].id
            }
        }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    if model.items.isEmpty {
                        EmptyChat(suggestions: suggestions, compact: compact)
                    }
                    ForEach(rows) { row in
                        switch row {
                        case .item(let item):
                            ChatRow(item: item, freedBytes: appliedBytes(item))
                        case .tools(let items):
                            ToolChips(items: items)
                        }
                    }
                    if model.isRunning, !isStreamingText {
                        HStack(spacing: 10) {
                            ProgressView().controlSize(.small)
                            Text("Düşünüyor…")
                                .font(.keel(14, .semibold))
                                .foregroundStyle(Palette.slate)
                        }
                        .padding(.leading, 44)
                    }
                    Color.clear.frame(height: 1).id("end")
                }
                .padding(compact ? 16 : 24)
            }
            .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(Palette.border) }
            .onChange(of: model.items.last?.text) { _, _ in proxy.scrollTo("end", anchor: .bottom) }
            .onChange(of: model.items.count) { _, _ in proxy.scrollTo("end", anchor: .bottom) }
        }
    }

    private var rows: [Row] {
        var rows: [Row] = []
        for item in model.items {
            if case .tool = item.kind {
                if case .tools(let group)? = rows.last {
                    rows[rows.count - 1] = .tools(group + [item])
                } else {
                    rows.append(.tools([item]))
                }
            } else {
                rows.append(.item(item))
            }
        }
        return rows
    }

    private var isStreamingText: Bool {
        guard let last = model.items.last, case .assistant = last.kind else { return false }
        return !last.isFinished
    }

    private func appliedBytes(_ item: ChatItem) -> Int64? {
        if case .proposal(let proposal) = item.kind { model.appliedProposals[proposal.id] } else { nil }
    }
}

private struct ToolChips: View {
    let items: [ChatItem]

    var body: some View {
        FlowLayout(spacing: 6) {
            ForEach(items) { item in
                HStack(spacing: 6) {
                    if item.isFinished {
                        Image(systemName: item.isFailed ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(item.isFailed ? Palette.warningText : Palette.mintText)
                    } else {
                        ProgressView().controlSize(.mini)
                    }
                    Text(label(item))
                        .font(.keel(12, .bold))
                        .foregroundStyle(Palette.slate)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Palette.mist, in: Capsule())
            }
        }
        .padding(.leading, 42)
    }

    private func label(_ item: ChatItem) -> String {
        guard case .tool(let name) = item.kind else { return "" }
        let title = KeelTools.displayNames[name] ?? name
        return item.isFinished ? title : "\(title)…"
    }
}

private struct ChatRow: View {
    let item: ChatItem
    let freedBytes: Int64?

    var body: some View {
        switch item.kind {
        case .user:
            HStack {
                Spacer(minLength: 80)
                Text(item.text)
                    .font(.keel(15, .semibold))
                    .foregroundStyle(Palette.onAccent)
                    .textSelection(.enabled)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        Palette.accent,
                        in: UnevenRoundedRectangle(topLeadingRadius: 18, bottomLeadingRadius: 18, bottomTrailingRadius: 4, topTrailingRadius: 18, style: .continuous)
                    )
            }

        case .assistant:
            HStack(alignment: .top, spacing: 12) {
                Mascot(character: .bilge, size: 34)
                Text(Self.markdown(item.text))
                    .font(.keel(15, .medium))
                    .foregroundStyle(Palette.text)
                    .lineSpacing(3)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

        case .tool:
            EmptyView()

        case .proposal(let proposal):
            ProposalCard(proposal: proposal, freedBytes: freedBytes)
                .padding(.leading, 42)

        case .notice(let isError):
            Label(item.text, systemImage: isError ? "exclamationmark.triangle.fill" : "info.circle")
                .font(.keel(13, .semibold))
                .foregroundStyle(isError ? Palette.danger : Palette.slate)
                .padding(.leading, 42)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Inline Markdown (bold, code, links); line breaks are kept as written.
    static func markdown(_ text: String) -> AttributedString {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        return (try? AttributedString(markdown: text, options: options)) ?? AttributedString(text)
    }
}

/// A suggested cleanup with every item listed; the user can untick any
/// item before confirming.
private struct ProposalCard: View {
    @Environment(AssistantModel.self) private var model
    let proposal: CleanupProposal
    let freedBytes: Int64?

    @State private var excluded: Set<String> = []
    @State private var showsAll = false

    private static let collapsedCount = 6

    private var selected: [CleanupItem] {
        proposal.items.filter { !excluded.contains($0.id) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Label("Temizlik önerisi", systemImage: "sparkles")
                    .font(.keel(13, .extraBold))
                    .foregroundStyle(Palette.mintText)
                Spacer()
                ByteAmount(bytes: selected.reduce(0) { $0 + $1.sizeBytes }, size: 18)
            }
            if !proposal.reason.isEmpty {
                Text(proposal.reason)
                    .font(.keel(14, .medium))
                    .foregroundStyle(Palette.text)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 0) {
                ForEach(visibleItems) { item in
                    itemRow(item)
                    if item.id != visibleItems.last?.id {
                        Divider().overlay(Palette.divider)
                    }
                }
                if proposal.items.count > Self.collapsedCount {
                    Button(showsAll ? "Daha az göster" : "Tümünü göster (\(proposal.items.count) öğe)") {
                        showsAll.toggle()
                    }
                    .buttonStyle(.plain)
                    .font(.keel(12, .bold))
                    .foregroundStyle(Palette.mintText)
                    .frame(maxWidth: .infinity, minHeight: 32)
                }
            }
            .padding(.horizontal, 12)
            .background(Palette.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Palette.border) }

            if let freedBytes, freedBytes == 0 {
                Label("Hiçbir şey temizlenmedi; nedeni aşağıda.", systemImage: "exclamationmark.circle.fill")
                    .font(.keel(14, .bold))
                    .foregroundStyle(Palette.warningText)
            } else if model.undoneProposals.contains(proposal.id) {
                Label("Geri alındı; öğeler eski yerlerinde", systemImage: "arrow.uturn.backward.circle.fill")
                    .font(.keel(14, .bold))
                    .foregroundStyle(Palette.slate)
            } else if let freedBytes {
                HStack(spacing: 12) {
                    Label("\(ByteFormat.string(freedBytes)) temizlendi", systemImage: "checkmark.circle.fill")
                        .font(.keel(14, .bold))
                        .foregroundStyle(Palette.mintText)
                    Spacer(minLength: 8)
                    if model.undoableProposals[proposal.id] != nil {
                        Button {
                            model.undoProposal(proposal.id)
                        } label: {
                            Label("Geri al", systemImage: "arrow.uturn.backward")
                        }
                        .buttonStyle(TileButtonStyle())
                    }
                }
            } else {
                HStack(spacing: 12) {
                    Button("Seçilenleri temizle (\(selected.count))") {
                        model.review(proposal, items: selected)
                    }
                    .buttonStyle(TileButtonStyle(prominent: true))
                    .disabled(selected.isEmpty)
                    Text(selected.contains { $0.removal == .deletePermanently }
                        ? "Çöp Kutusu'ndakiler kalıcı silinir"
                        : "Çöp Kutusu'na taşınır, geri alınabilir")
                        .font(.keel(12, .medium))
                        .foregroundStyle(Palette.slate)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: 560, alignment: .leading)
        .background(Palette.mist, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Palette.border) }
    }

    private var visibleItems: [CleanupItem] {
        showsAll ? proposal.items : Array(proposal.items.prefix(Self.collapsedCount))
    }

    private func itemRow(_ item: CleanupItem) -> some View {
        HStack(spacing: 10) {
            Toggle("", isOn: Binding(
                get: { !excluded.contains(item.id) },
                set: { isOn in
                    if isOn { excluded.remove(item.id) } else { excluded.insert(item.id) }
                }
            ))
            .toggleStyle(.checkbox)
            .labelsHidden()
            .disabled(freedBytes != nil)
            .accessibilityLabel(HomePath.display(item.url))

            Text(HomePath.display(item.url))
                .font(.keelMono(12, .medium))
                .foregroundStyle(excluded.contains(item.id) ? Palette.slate.opacity(0.6) : Palette.text)
                .strikethrough(excluded.contains(item.id))
                .lineLimit(1)
                .truncationMode(.middle)
                .help(item.url.path)
            Spacer(minLength: 8)
            Text(ByteFormat.string(item.sizeBytes))
                .font(.keelMono(12, .semibold))
                .foregroundStyle(Palette.text)
        }
        .frame(minHeight: 34)
    }
}

// MARK: - Empty states

struct ConnectCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 14) {
                KeelLogoTile(size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Bir yapay zeka bağla")
                        .font(.keel(20, .extraBold))
                        .foregroundStyle(Palette.text)
                    Text("ChatGPT ya da Claude hesabınla giriş yap, veya Mac'indeki Apple Intelligence'ı kullan.")
                        .font(.keel(14, .medium))
                        .foregroundStyle(Palette.slate)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            ProvidersPanel()
            Text("Giriş, sağlayıcının kendi sayfasında yapılır; Keel şifreni ya da oturum bilgilerini görmez, saklamaz.")
                .font(.keel(12, .medium))
                .foregroundStyle(Palette.slate)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: 520, alignment: .leading)
    }
}

private struct EmptyChat: View {
    @Environment(AssistantModel.self) private var model
    let suggestions: [String]
    var compact = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(compact ? "Nasıl yardımcı olayım?" : "Ne öğrenmek istersin?")
                .font(.keel(compact ? 16 : 18, .extraBold))
                .foregroundStyle(Palette.text)
            Text("Keel AI bilgisayarının gerçek durumuna bakarak yanıt verir: bellek, işlemci, disk, pil ve temizlenebilir alan.")
                .font(.keel(14, .medium))
                .foregroundStyle(Palette.slate)
                .fixedSize(horizontal: false, vertical: true)
            FlowLayout(spacing: 8) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button(suggestion) { model.send(suggestion) }
                        .buttonStyle(.plain)
                        .font(.keel(13, .semibold))
                        .foregroundStyle(Palette.text)
                        .padding(.horizontal, 14)
                        .frame(minHeight: 36)
                        .background(Palette.card, in: Capsule())
                        .overlay { Capsule().strokeBorder(Palette.controlBorder) }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Composer

/// The message box with the model picker, effort and usage above it.
struct Composer: View {
    @Environment(AssistantModel.self) private var model

    var body: some View {
        @Bindable var model = model
        VStack(alignment: .leading, spacing: 0) {
            if let connection = model.connection {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) {
                        controls(connection)
                        Spacer(minLength: 12)
                        StatsLine(stats: model.stats, connection: connection)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) { controls(connection) }
                        StatsLine(stats: model.stats, connection: connection)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)

                Divider().overlay(Palette.divider)
            }

            HStack(alignment: .bottom, spacing: 10) {
                TextField("Mesaj yaz… örn. \"Sadece Firefox önbelleğini sil\"", text: $model.draft, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.keel(15, .medium))
                    .lineLimit(1...5)
                    .padding(.vertical, 12)
                    .onSubmit { model.send() }
                    .accessibilityLabel("Keel AI'a sor")

                if model.isRunning {
                    Button(action: model.stop) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Durdur")
                } else {
                    Button { model.send() } label: {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Palette.assistant, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(model.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityLabel("Gönder")
                }
            }
            .padding(.leading, 16)
            .padding(.trailing, 8)
            .padding(.vertical, 6)
        }
        // The design's input: dark glass with a soft violet ring.
        .background(Palette.navy.opacity(0.6), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Color(hex: 0xA08BFF).opacity(0.5)) }
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(hex: 0xA08BFF).opacity(0.10))
                .padding(-4)
        }
    }

    @ViewBuilder
    private func controls(_ connection: AIConnection) -> some View {
        ModelPicker()
        if connection.supportsEffort {
            EffortPicker(effort: connection.effort)
        }
    }
}

/// A chip that opens a popover, like the model and effort pickers.
private struct ChipLabel<Leading: View>: View {
    let text: String
    @ViewBuilder var leading: Leading

    var body: some View {
        HStack(spacing: 7) {
            leading
            Text(text)
                .font(.keel(13, .bold))
                .foregroundStyle(Palette.text)
                .lineLimit(1)
            Image(systemName: "chevron.down")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Palette.slate)
        }
        .padding(.horizontal, 10)
        .frame(height: 32)
        .background(Palette.mist, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        .contentShape(Rectangle())
    }
}

/// Provider column on the left, that provider's models by number on the right.
private struct ModelPicker: View {
    @Environment(AssistantModel.self) private var model

    @State private var isOpen = false
    @State private var browsing: AIConnection.Kind = .claudeCode

    var body: some View {
        Button {
            browsing = model.connection?.kind ?? .claudeCode
            isOpen = true
        } label: {
            ChipLabel(text: title) {
                if let kind = model.connection?.kind {
                    ProviderMark(kind: kind, size: 20)
                }
            }
        }
        .buttonStyle(.plain)
        .popover(isPresented: $isOpen, arrowEdge: .top) { picker }
        .help("Model seç")
    }

    private var title: String {
        guard let connection = model.connection else { return "Model" }
        if connection.kind == .apple { return "Apple Intelligence" }
        if connection.usesAccountDefault, let answered = model.stats.model {
            return ModelNames.display(answered)
        }
        return connection.modelName
    }

    private var picker: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(spacing: 6) {
                ForEach(AssistantModel.providers, id: \.self) { kind in
                    Button { browsing = kind } label: {
                        ProviderMark(kind: kind, size: 30)
                            .padding(4)
                            .background(
                                browsing == kind ? Palette.track : .clear,
                                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                            )
                    }
                    .buttonStyle(.plain)
                    .help(AIConnection(kind: kind).providerName)
                }
                Spacer(minLength: 0)
            }
            .padding(8)
            .frame(width: 56)

            Divider()

            VStack(alignment: .leading, spacing: 0) {
                Text("Model · \(AIConnection(kind: browsing).providerName)").eyebrowStyle()
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                    .padding(.bottom, 6)
                if model.accounts.isReady(browsing) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(choices, id: \.id) { choice in
                                modelRow(choice)
                            }
                        }
                    }
                } else {
                    notReady
                }
            }
            .frame(width: 290)
        }
        .frame(height: 420)
        .background(Palette.card)
    }

    /// The numbered models, plus the account's default while Keel is using
    /// it because the chosen model was not open to the account.
    private var choices: [(id: String, name: String)] {
        var choices = AIConnection(kind: browsing).modelChoices
        if let connection = model.connection, connection.kind == browsing, connection.usesAccountDefault {
            choices.insert((AIConnection.accountDefault, AIConnection.accountDefaultName(for: browsing)), at: 0)
        }
        return choices
    }

    private var notReady: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(browsing == .apple
                ? "Apple Intelligence bu Mac'te kullanılamıyor."
                : "\(AIConnection(kind: browsing).providerName) modellerini kullanmak için önce hesabınla giriş yap.")
                .font(.keel(13, .medium))
                .foregroundStyle(Palette.slate)
                .fixedSize(horizontal: false, vertical: true)
            if browsing != .apple, model.accounts.phase(browsing) == .signedOut {
                Button("Giriş yap") { model.accounts.signIn(browsing) }
                    .buttonStyle(TileButtonStyle(prominent: true))
            }
            Spacer()
        }
        .padding(14)
    }

    private func modelRow(_ choice: (id: String, name: String)) -> some View {
        let isCurrent = model.connection?.kind == browsing && model.connection?.model == choice.id
        return Button {
            model.update(kind: browsing, model: choice.id)
            isOpen = false
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Palette.keelGreen)
                    .opacity(isCurrent ? 1 : 0)
                Text(choice.name)
                    .font(.keel(14, isCurrent ? .bold : .medium))
                    .foregroundStyle(Palette.text)
                    .lineLimit(1)
                Spacer(minLength: 8)
                if browsing != .apple, choice.id == AIConnection.defaultModel(for: browsing) {
                    Pill(text: "VARSAYILAN")
                }
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 36)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct EffortPicker: View {
    @Environment(AssistantModel.self) private var model
    let effort: String?
    @State private var isOpen = false

    private var title: String {
        guard let effort else { return "Otomatik" }
        return AIConnection.effortLevels.first { $0.id == effort }?.name ?? effort
    }

    var body: some View {
        Button { isOpen = true } label: {
            ChipLabel(text: title) {
                Image(systemName: "gauge.with.dots.needle.50percent")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Palette.slate)
            }
        }
        .buttonStyle(.plain)
        .help("Düşünme seviyesi")
        .popover(isPresented: $isOpen, arrowEdge: .top) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Düşünme seviyesi").eyebrowStyle()
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                row(id: nil, name: "Otomatik", detail: "Hesabın ayarı")
                ForEach(AIConnection.effortLevels, id: \.id) { level in
                    row(id: level.id, name: level.name, detail: level.detail)
                }
                Text("Yükseldikçe yanıt daha özenli olur ama daha yavaş gelir ve planından daha çok kullanır.")
                    .font(.keel(11, .medium))
                    .foregroundStyle(Palette.slate)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(14)
            }
            .frame(width: 270)
            .background(Palette.card)
        }
    }

    private func row(id: String?, name: String, detail: String) -> some View {
        Button {
            model.update(effort: .some(id))
            isOpen = false
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Palette.keelGreen)
                    .opacity(effort == id ? 1 : 0)
                Text(name)
                    .font(.keel(14, effort == id ? .bold : .medium))
                    .foregroundStyle(Palette.text)
                Spacer()
                Text(detail)
                    .font(.keel(12, .medium))
                    .foregroundStyle(Palette.slate)
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 32)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// "≈$0,12 · 3 tur · bağlam ▮▮▯▯ %4"
private struct StatsLine: View {
    let stats: ChatStats
    let connection: AIConnection

    var body: some View {
        HStack(spacing: 7) {
            Text(costText)
                .help(costHelp)
            Text("·")
            Text("\(stats.turns) tur")
            if let fraction = stats.contextFraction {
                Text("·")
                Text("bağlam")
                ProgressBar(fraction: max(fraction, 0.01), tint: Palette.slate, height: 4)
                    .frame(width: 70)
                Text("%\(Int((fraction * 100).rounded()))")
            }
        }
        .font(.keelMono(11, .medium))
        .foregroundStyle(Palette.slate)
        .lineLimit(1)
        .fixedSize()
    }

    private var costText: String {
        switch connection.kind {
        case .apple: return "ücretsiz"
        case .chatGPT: return "ChatGPT planınla"
        case .claudeCode:
            guard let cost = stats.costUSD else { return "Claude planınla" }
            if cost > 0, cost < 0.01 { return "<$0,01" }
            return "≈$" + String(format: "%.2f", cost).replacingOccurrences(of: ".", with: ",")
        }
    }

    private var costHelp: String {
        switch connection.kind {
        case .claudeCode: "Claude Code'un API fiyatlarıyla tahmini. Aboneliğinden ayrıca ücret alınmaz; kullanım limitlerine sayılır."
        case .chatGPT: "ChatGPT planının Codex kullanımına sayılır; ayrıca ücret alınmaz."
        case .apple: "Cihazda çalışır, ücretsizdir."
        }
    }
}

/// Lays children out left to right and wraps to new lines, like chips.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(width: proposal.width ?? .infinity, subviews: subviews)
        let height = rows.last.map { $0.y + $0.height } ?? 0
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for row in arrange(width: bounds.width, subviews: subviews) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: bounds.minY + row.y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
        }
    }

    private struct Row {
        var indices: [Int] = []
        var y: CGFloat = 0
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let needed = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            if needed > width, !current.indices.isEmpty {
                rows.append(current)
                current = Row(y: current.y + current.height + spacing)
            }
            current.width = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            current.height = max(current.height, size.height)
            current.indices.append(index)
        }
        if !current.indices.isEmpty { rows.append(current) }
        return rows
    }
}
