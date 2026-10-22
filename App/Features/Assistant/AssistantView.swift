import KeelCore
import SwiftUI

struct AssistantView: View {
    @Environment(AssistantModel.self) private var model
    @State private var editingConnection = false
    @State private var pendingProposal: CleanupProposal?

    var body: some View {
        HStack(alignment: .top, spacing: 24) {
            VStack(alignment: .leading, spacing: 18) {
                header
                if model.connection == nil {
                    ScrollView {
                        ConnectCard()
                    }
                } else {
                    conversation
                    Composer { editingConnection = true }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            if model.connection != nil {
                aside.frame(width: 280)
            }
        }
        .sheet(isPresented: $editingConnection) {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text("Yapay zeka bağlantısı")
                        .font(.keel(20, .extraBold))
                        .foregroundStyle(Palette.hull)
                    Spacer()
                    Button("Bitti") { editingConnection = false }
                        .buttonStyle(RowButtonStyle())
                        .keyboardShortcut(.defaultAction)
                }
                ScrollView {
                    ConnectionForm { editingConnection = false }
                }
            }
            .padding(28)
            .frame(width: 640, height: 600)
            .background(Palette.mist)
            .environment(model)
            .preferredColorScheme(.light)
        }
        .confirmationDialog(
            "\(ByteFormat.string(model.cleanupConfirmationBytes)) temizlensin mi?",
            isPresented: Binding(get: { pendingProposal != nil }, set: { if !$0 { pendingProposal = nil } }),
            titleVisibility: .visible,
            presenting: pendingProposal
        ) { proposal in
            Button("Temizle", role: model.cleanupPermanentBytes > 0 ? ButtonRole.destructive : nil) {
                Task { await model.apply(proposal) }
            }
            Button("Vazgeç", role: .cancel) {}
        } message: { _ in
            Text(confirmationMessage)
        }
    }

    private var header: some View {
        PageHeader(
            title: "Keel AI",
            subtitle: "Bilgisayarın hakkında soru sor; Keel analiz eder, çözüm önerir. Hiçbir şey onayın olmadan yapılmaz."
        )
    }

    // MARK: Conversation

    private var conversation: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    if model.items.isEmpty {
                        EmptyChat()
                    }
                    ForEach(model.items) { item in
                        ChatRow(item: item, applied: appliedBytes(item)) { proposal in
                            if model.prepare(proposal) { pendingProposal = proposal }
                        }
                        .id(item.id)
                    }
                    if model.isRunning, !isStreamingText {
                        HStack(spacing: 10) {
                            ProgressView().controlSize(.small)
                            Text("Düşünüyor…")
                                .font(.keel(14, .semibold))
                                .foregroundStyle(Palette.slate)
                        }
                        .padding(.leading, 44)
                        .id("thinking")
                    }
                }
                .padding(24)
            }
            .background(Palette.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Palette.border) }
            .onChange(of: model.items.last?.text) { _, _ in scrollToEnd(proxy) }
            .onChange(of: model.items.count) { _, _ in scrollToEnd(proxy) }
        }
    }

    private var isStreamingText: Bool {
        guard let last = model.items.last, case .assistant = last.kind else { return false }
        return !last.isFinished
    }

    private func scrollToEnd(_ proxy: ScrollViewProxy) {
        if let last = model.items.last {
            proxy.scrollTo(last.id, anchor: .bottom)
        }
    }

    private func appliedBytes(_ item: ChatItem) -> Int64? {
        if case .proposal(let proposal) = item.kind { model.appliedProposals[proposal.id] } else { nil }
    }

    private var confirmationMessage: String {
        let permanent = model.cleanupPermanentBytes
        let toTrash = model.cleanupConfirmationBytes - permanent
        var lines: [String] = []
        if toTrash > 0 {
            lines.append("\(ByteFormat.string(toTrash)) Çöp Kutusu'na taşınacak; oradan geri alabilirsin.")
        }
        if permanent > 0 {
            lines.append("Çöp Kutusu'ndaki \(ByteFormat.string(permanent)) kalıcı olarak silinecek ve geri alınamaz.")
        }
        return lines.joined(separator: "\n\n")
    }

    // MARK: Aside

    private var aside: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("AI modelleri")
                    .eyebrowStyle()
                    .padding(.bottom, 6)
                ForEach(model.quickConnections, id: \.keychainAccount) { option in
                    let isCurrent = model.connection?.kind == option.kind
                        && (option.kind != .openAICompatible || model.connection?.baseURL == option.baseURL)
                    Button {
                        if !isCurrent { model.switchTo(option) }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: isCurrent ? "largecircle.fill.circle" : "circle")
                                .foregroundStyle(isCurrent ? Palette.mintText : Palette.slate)
                            Text(option.providerName)
                                .font(.keel(14, isCurrent ? .bold : .semibold))
                                .foregroundStyle(Palette.hull)
                            Spacer()
                        }
                        .frame(minHeight: 34)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                Button("Yönet…") { editingConnection = true }
                    .buttonStyle(.plain)
                    .font(.keel(13, .bold))
                    .foregroundStyle(Palette.mintText)
                    .frame(minHeight: 34)
            }
            .keelCard(padding: 20, radius: 18)

            if model.connection?.isLocal == true {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Tamamen bu Mac'te", systemImage: "lock.fill")
                        .font(.keel(15, .extraBold))
                        .foregroundStyle(Palette.hull)
                    Text("Model bilgisayarında çalışıyor; sorduğun hiçbir şey ve hiçbir sistem verisi Mac'inden çıkmıyor.")
                        .font(.keel(13, .medium))
                        .foregroundStyle(Palette.slate)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .keelCard(padding: 20, radius: 18)
            } else {
                sharingCard
            }

            Button {
                model.startNewChat()
            } label: {
                Label("Yeni sohbet", systemImage: "plus.bubble")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.keelSecondary)
            .disabled(model.items.isEmpty)
        }
    }

    private var sharingCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Neler paylaşılır?")
                .font(.keel(16, .extraBold))
                .foregroundStyle(Palette.hull)
            ForEach(Self.sharing, id: \.self) { line in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Palette.mintText)
                    Text(line)
                        .font(.keel(13, .medium))
                        .foregroundStyle(Palette.slate)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Palette.danger)
                Text("Dosyalarının içeriği asla gönderilmez.")
                    .font(.keel(13, .bold))
                    .foregroundStyle(Palette.hull)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .keelCard(padding: 22, radius: 20)
    }

    private static let sharing = [
        "Sistem özeti: işlemci, bellek, GPU, disk, pil",
        "Önbellek klasörlerinin adları ve boyutları",
        "Açık uygulamaların ve arka plan servislerinin adları",
    ]
}

// MARK: - Pieces

private struct ConnectCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 14) {
                KeelLogoTile(size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Kendi yapay zekanı bağla")
                        .font(.keel(20, .extraBold))
                        .foregroundStyle(Palette.hull)
                    Text("Apple Intelligence, Claude, OpenAI, Gemini, OpenRouter ya da bilgisayarında çalışan Ollama / LM Studio.")
                        .font(.keel(14, .medium))
                        .foregroundStyle(Palette.slate)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            ConnectionForm()
        }
        .keelCard(padding: 28, radius: 22)
        .frame(maxWidth: 620, alignment: .leading)
    }
}

private struct EmptyChat: View {
    @Environment(AssistantModel.self) private var model

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Ne öğrenmek istersin?")
                .font(.keel(18, .extraBold))
                .foregroundStyle(Palette.hull)
            Text("Keel AI bilgisayarının gerçek durumuna bakarak yanıt verir: bellek, işlemci, disk, pil ve temizlenebilir alan.")
                .font(.keel(14, .medium))
                .foregroundStyle(Palette.slate)
                .fixedSize(horizontal: false, vertical: true)
            FlowLayout(spacing: 8) {
                ForEach(AssistantModel.suggestions, id: \.self) { suggestion in
                    Button(suggestion) { model.send(suggestion) }
                        .buttonStyle(.plain)
                        .font(.keel(13, .semibold))
                        .foregroundStyle(Palette.hull)
                        .padding(.horizontal, 14)
                        .frame(minHeight: 40)
                        .background(Palette.card, in: Capsule())
                        .overlay { Capsule().strokeBorder(Palette.controlBorder) }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

private struct ChatRow: View {
    let item: ChatItem
    let applied: Int64?
    let review: (CleanupProposal) -> Void

    var body: some View {
        switch item.kind {
        case .user:
            HStack {
                Spacer(minLength: 80)
                Text(item.text)
                    .font(.keel(15, .medium))
                    .foregroundStyle(.white)
                    .textSelection(.enabled)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Palette.hull, in: UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 16, bottomTrailingRadius: 4, topTrailingRadius: 16, style: .continuous))
            }

        case .assistant:
            HStack(alignment: .top, spacing: 12) {
                KeelLogoTile(size: 30)
                Text(Self.markdown(item.text))
                    .font(.keel(15, .medium))
                    .foregroundStyle(Palette.hull)
                    .lineSpacing(3)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

        case .tool(let name):
            HStack(spacing: 8) {
                if item.isFinished {
                    Image(systemName: item.isFailed ? "exclamationmark.triangle" : "checkmark.circle.fill")
                        .foregroundStyle(item.isFailed ? Palette.warningText : Palette.mintText)
                } else {
                    ProgressView().controlSize(.mini)
                }
                Text(toolLabel(name))
                    .font(.keel(12, .bold))
                    .foregroundStyle(Palette.slate)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Palette.mist, in: Capsule())
            .padding(.leading, 42)

        case .proposal(let proposal):
            ProposalCard(proposal: proposal, freedBytes: applied) { review(proposal) }
                .padding(.leading, 42)

        case .notice(let isError):
            Text(item.text)
                .font(.keel(13, .semibold))
                .foregroundStyle(isError ? Palette.danger : Palette.slate)
                .padding(.leading, 42)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func toolLabel(_ name: String) -> String {
        let title = KeelTools.displayNames[name] ?? name
        if !item.isFinished { return "\(title) okunuyor…" }
        return item.isFailed ? "\(title): hata" : title
    }

    /// Inline Markdown (bold, code, links); line breaks are kept as written.
    static func markdown(_ text: String) -> AttributedString {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        return (try? AttributedString(markdown: text, options: options)) ?? AttributedString(text)
    }
}

private struct ProposalCard: View {
    let proposal: CleanupProposal
    let freedBytes: Int64?
    let review: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Temizlik önerisi").eyebrowStyle()
                Spacer()
                ByteAmount(bytes: proposal.bytes, size: 18)
            }
            if !proposal.reason.isEmpty {
                Text(proposal.reason)
                    .font(.keel(14, .medium))
                    .foregroundStyle(Palette.hull)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text(proposal.titles.joined(separator: " · "))
                .font(.keel(13, .semibold))
                .foregroundStyle(Palette.slate)
            if let freedBytes {
                Label("\(ByteFormat.string(freedBytes)) temizlendi", systemImage: "checkmark.circle.fill")
                    .font(.keel(14, .bold))
                    .foregroundStyle(Palette.mintText)
            } else {
                Button("Gözden geçir ve temizle", action: review)
                    .buttonStyle(.keelPrimary)
            }
        }
        .padding(18)
        .frame(maxWidth: 520, alignment: .leading)
        .background(Palette.mist, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Palette.border) }
    }
}

/// The message box with the model controls above it: provider, model and
/// effort menus, and a line with cost, turns and how full the context is.
private struct Composer: View {
    @Environment(AssistantModel.self) private var model
    let manageModels: () -> Void

    var body: some View {
        @Bindable var model = model
        VStack(alignment: .leading, spacing: 0) {
            if let connection = model.connection {
                HStack(spacing: 20) {
                    providerMenu(connection)
                    modelMenu(connection)
                    if connection.supportsEffort {
                        effortMenu(connection)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                StatsLine(stats: model.stats, connection: connection)
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
                    .padding(.bottom, 10)
            }

            Divider().overlay(Palette.divider)

            HStack(alignment: .bottom, spacing: 10) {
                TextField("Mesaj yaz… örn. \"Hangi uygulama pili tüketiyor?\"", text: $model.draft, axis: .vertical)
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
                            .frame(width: 40, height: 40)
                            .background(Palette.hull, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Durdur")
                } else {
                    Button { model.send() } label: {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Palette.hull)
                            .frame(width: 40, height: 40)
                            .background(Palette.keelGreen, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
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
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Palette.controlBorder) }
    }

    // MARK: Menus

    private func providerMenu(_ connection: AIConnection) -> some View {
        Menu {
            ForEach(model.quickConnections, id: \.keychainAccount) { option in
                Button {
                    model.switchTo(option)
                } label: {
                    if option.kind == connection.kind {
                        Label(option.providerName, systemImage: "checkmark")
                    } else {
                        Text(option.providerName)
                    }
                }
            }
            Divider()
            Button("AI modellerini yönet…", action: manageModels)
        } label: {
            MenuLabel(text: connection.providerName)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .help("Sağlayıcıyı değiştirmek yeni bir sohbet başlatır")
    }

    @ViewBuilder
    private func modelMenu(_ connection: AIConnection) -> some View {
        let choices = connection.modelChoices
        if choices.count <= 1 {
            MenuLabel(text: modelTitle(connection), showsChevron: false)
        } else {
            Menu {
                ForEach(choices, id: \.id) { choice in
                    Button {
                        model.update(model: choice.id)
                    } label: {
                        if choice.id == connection.model {
                            Label(choice.name, systemImage: "checkmark")
                        } else {
                            Text(choice.name)
                        }
                    }
                }
            } label: {
                MenuLabel(text: modelTitle(connection))
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
        }
    }

    private func effortMenu(_ connection: AIConnection) -> some View {
        Menu {
            Button {
                model.update(effort: .some(nil))
            } label: {
                if connection.effort == nil {
                    Label("Varsayılan", systemImage: "checkmark")
                } else {
                    Text("Varsayılan")
                }
            }
            ForEach(AIConnection.effortLevels, id: \.self) { level in
                Button {
                    model.update(effort: .some(level))
                } label: {
                    if level == connection.effort {
                        Label(level, systemImage: "checkmark")
                    } else {
                        Text(level)
                    }
                }
            }
        } label: {
            MenuLabel(text: connection.effort ?? "effort")
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .help("Düşünme seviyesi: yükseldikçe yanıtlar daha özenli ama daha yavaş ve pahalı olur")
    }

    /// The model name to show: the one that actually answered when known.
    private func modelTitle(_ connection: AIConnection) -> String {
        switch connection.kind {
        case .apple:
            return "Cihaz modeli"
        case .claudeCode:
            if let answered = model.stats.model { return ModelNames.display(answered) }
            return connection.modelName
        case .claude:
            return ModelNames.display(connection.model)
        case .openAICompatible:
            return connection.model
        }
    }
}

private struct MenuLabel: View {
    let text: String
    var showsChevron = true

    var body: some View {
        HStack(spacing: 6) {
            Text(text)
                .font(.keel(14, .semibold))
                .foregroundStyle(Palette.hull)
                .lineLimit(1)
            if showsChevron {
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Palette.slate)
            }
        }
        .frame(minHeight: 28)
        .contentShape(Rectangle())
    }
}

/// "≈$0,12 · 3 tur · bağlam ▮▮▯▯ %4"
private struct StatsLine: View {
    let stats: ChatStats
    let connection: AIConnection

    var body: some View {
        HStack(spacing: 8) {
            Text(costText)
                .help(costHelp)
            Text("·")
            Text("\(stats.turns) tur")
            if let fraction = stats.contextFraction {
                Text("·")
                Text("bağlam")
                ProgressBar(fraction: max(fraction, 0.01), tint: Palette.slate, height: 4)
                    .frame(width: 90)
                Text("%\(Int((fraction * 100).rounded()))")
            }
        }
        .font(.keelMono(12, .medium))
        .foregroundStyle(Palette.slate)
        .lineLimit(1)
    }

    private var costText: String {
        if connection.isLocal { return "ücretsiz · cihazda" }
        guard let cost = stats.costUSD else { return "maliyet —" }
        if cost > 0, cost < 0.01 { return "maliyet <$0,01" }
        let formatted = String(format: "%.2f", cost).replacingOccurrences(of: ".", with: ",")
        return "maliyet ≈$\(formatted)"
    }

    private var costHelp: String {
        switch connection.kind {
        case .claudeCode: "Claude Code'un API fiyatlarıyla tahmini. Aboneliğinden ayrıca ücret alınmaz; kullanım limitlerine sayılır."
        case .claude: "Liste fiyatlarıyla tahmini; asıl fatura Anthropic'ten gelir."
        default: "Bu sağlayıcı maliyet bilgisi vermiyor."
        }
    }
}

/// Lays children out left to right and wraps to new lines, like suggestion chips.
private struct FlowLayout: Layout {
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
