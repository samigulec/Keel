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
                    InputBar()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            if model.connection != nil {
                aside.frame(width: 280)
            }
        }
        .sheet(isPresented: $editingConnection) {
            VStack(alignment: .leading, spacing: 18) {
                Text("Yapay zeka bağlantısı")
                    .font(.keel(20, .extraBold))
                    .foregroundStyle(Palette.hull)
                ConnectionForm { editingConnection = false }
            }
            .padding(28)
            .frame(width: 460)
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
        HStack(alignment: .center) {
            PageHeader(
                title: "Keel AI",
                subtitle: "Bilgisayarın hakkında soru sor; Keel analiz eder, çözüm önerir. Hiçbir şey onayın olmadan yapılmaz."
            )
            Spacer(minLength: 16)
            if let connection = model.connection {
                HStack(spacing: 8) {
                    Circle().fill(Palette.keelGreen).frame(width: 8, height: 8)
                    Text("\(connection.providerName) · \(connection.modelName)")
                        .font(.keel(13, .bold))
                        .foregroundStyle(Palette.mintText)
                        .lineLimit(1)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Palette.mint, in: Capsule())
            }
        }
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
            if let connection = model.connection {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Bağlantı").eyebrowStyle(color: Palette.Sidebar.eyebrow)
                    Text(connection.providerName)
                        .font(.keel(20, .extraBold))
                        .foregroundStyle(.white)
                    Text(connection.modelName)
                        .font(.keelMono(13, .medium))
                        .foregroundStyle(Palette.Sidebar.text)
                    HStack(spacing: 16) {
                        Button(connection.kind == .apple ? "Daha güçlü model bağla" : "Değiştir") { editingConnection = true }
                        if connection.kind != .apple {
                            Button("Bağlantıyı kaldır", action: model.disconnect)
                        }
                    }
                    .buttonStyle(.plain)
                    .font(.keel(13, .bold))
                    .foregroundStyle(Palette.keelGreen)
                    .frame(minHeight: 44)
                }
                .keelCard(padding: 22, radius: 20, fill: Palette.hull)
            }

            if model.connection?.isLocal == true {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Tamamen bu Mac'te", systemImage: "lock.fill")
                        .font(.keel(16, .extraBold))
                        .foregroundStyle(Palette.hull)
                    Text("Model bilgisayarında çalışıyor; sorduğun hiçbir şey ve hiçbir sistem verisi Mac'inden çıkmıyor.")
                        .font(.keel(13, .medium))
                        .foregroundStyle(Palette.slate)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .keelCard(padding: 22, radius: 20)
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

private struct InputBar: View {
    @Environment(AssistantModel.self) private var model

    var body: some View {
        @Bindable var model = model
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Keel'e bir şey sor… örn. \"Hangi uygulama pili tüketiyor?\"", text: $model.draft, axis: .vertical)
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
                        .background(Palette.hull, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Durdur")
            } else {
                Button { model.send() } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Palette.hull)
                        .frame(width: 44, height: 44)
                        .background(Palette.keelGreen, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(model.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityLabel("Gönder")
            }
        }
        .padding(.leading, 16)
        .padding(.trailing, 8)
        .padding(.vertical, 6)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Palette.controlBorder) }
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
