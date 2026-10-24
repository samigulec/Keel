import KeelCore
import SwiftUI

struct LargeFilesView: View {
    @Environment(LargeFilesModel.self) private var model
    @Environment(\.compactLayout) private var compact
    @State private var confirming = false

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(alignment: .bottom) {
                PageHeader(
                    title: "Büyük Dosyalar",
                    subtitle: "Klasörlerindeki ve uygulamaların verilerindeki büyük, uzun süredir açılmamış dosyalar. Hiçbir şey sen seçmeden silinmez; seçtiklerin Çöp Kutusu'na gider."
                )
                Spacer(minLength: 16)
                if model.phase == .ready {
                    Button("Yeniden tara", action: model.scan)
                        .buttonStyle(.keelSecondary)
                }
            }

            if let report = model.lastReport {
                RemovalBanner(report: report) {
                    Task { await model.undoLastRemoval() }
                }
            }
            if let restore = model.lastRestore {
                Label(Undo.summary(restore), systemImage: restore.failed.isEmpty ? "arrow.uturn.backward.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.keel(14, .semibold))
                    .foregroundStyle(restore.failed.isEmpty ? Palette.mintText : Palette.warningText)
                    .fixedSize(horizontal: false, vertical: true)
                    .keelCard(padding: 16, radius: 16)
            }

            switch model.phase {
            case .idle:
                StartCard(scan: model.scan)
            case .scanning where model.files.isEmpty:
                HStack(spacing: 14) {
                    ProgressView().controlSize(.small)
                    Text("Dosyalar taranıyor… Büyük bir ana klasörde bir dakika sürebilir.")
                        .font(.keel(15, .semibold))
                        .foregroundStyle(Palette.slate)
                }
                .keelCard()
            default:
                Tiles()
                Filters()
                FileList()
                if !model.selection.isEmpty {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(model.selection.count) dosya seçildi")
                                .font(.keel(15, .bold))
                                .foregroundStyle(Palette.text)
                            Text(ByteFormat.string(model.selectedBytes))
                                .font(.keel(13, .medium))
                                .foregroundStyle(Palette.Sidebar.text)
                        }
                        Spacer()
                        Button("Seçimi temizle") { model.selection = [] }
                            .buttonStyle(TileButtonStyle())
                        Button("Çöp Kutusu'na taşı") { confirming = true }
                            .buttonStyle(.keelPrimary)
                            .disabled(model.phase != .ready)
                    }
                    .keelSummaryCard(padding: 18)
                }
            }
        }
        .task {
            if model.phase == .idle { model.scan() }
        }
        .confirmationDialog(
            "\(model.selection.count) dosya Çöp Kutusu'na taşınsın mı?",
            isPresented: $confirming,
            titleVisibility: .visible
        ) {
            Button("Taşı") { Task { await model.removeSelected() } }
            Button("Vazgeç", role: .cancel) {}
        } message: {
            Text(confirmationText)
        }
    }

    private var confirmationText: String {
        var text = "\(ByteFormat.string(model.selectedBytes)) Çöp Kutusu'na gider; oradan ya da \"Geri al\" ile eski yerine koyabilirsin. Çöp Kutusu boşaltılınca yer açılır."
        if model.selectionHasAppData {
            text += "\n\nSeçimde uygulama verileri var: o uygulama bu dosyaları yeniden indirebilir ya da onlarsız bazı içeriklerini (oyun, sanal makine, indirilen medya) kaybedebilir. Açık uygulamaların dosyaları atlanır."
        }
        return text
    }
}

private struct StartCard: View {
    let scan: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Henüz taranmadı")
                .font(.keel(20, .extraBold))
                .foregroundStyle(Palette.text)
            Text("Tarama yalnızca okur. Masaüstü, Belgeler, İndirilenler gibi klasörlerindeki ve uygulamaların ~/Library'deki verilerindeki büyük dosyaları bulur. Apple'ın sistem verileri, Mail, Mesajlar, iCloud ve uygulamaların programları ile veritabanları listelenmez.")
                .font(.keel(14, .medium))
                .foregroundStyle(Palette.slate)
                .fixedSize(horizontal: false, vertical: true)
            Button("Taramayı başlat", action: scan)
                .buttonStyle(.keelPrimary)
        }
        .keelCard()
    }
}

private struct Tiles: View {
    @Environment(LargeFilesModel.self) private var model
    @Environment(\.compactLayout) private var compact

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: compact ? 2 : 4), spacing: 14) {
            tile("Bulunan", ByteFormat.string(model.totalBytes), "\(model.files.count) dosya, 50 MB+", highlighted: true)
            tile("1 yıldır açılmamış", ByteFormat.string(model.oldBytes), "Unutulmuş olabilir")
            tile("İndirilenler", ByteFormat.string(model.downloadsBytes), "Çoğu yeniden indirilebilir")
            tile("Uygulama verileri", ByteFormat.string(model.appDataBytes), "\(model.appDataCount) dosya, ~/Library'de")
        }
    }

    private func tile(_ title: String, _ value: String, _ detail: String, highlighted: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).eyebrowStyle(color: highlighted ? Palette.Sidebar.eyebrow : Palette.slate)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(value)
                .font(.keelMono(24, .semibold))
                .tracking(-1.2)
                .foregroundStyle(Palette.text)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(detail)
                .font(.keel(12, .medium))
                .foregroundStyle(highlighted ? Palette.Sidebar.text : Palette.slate)
                .lineLimit(1)
        }
        .modifier(TileSurface(highlighted: highlighted))
    }
}

private struct TileSurface: ViewModifier {
    let highlighted: Bool

    func body(content: Content) -> some View {
        if highlighted {
            content.keelSummaryCard(padding: 18, radius: 20)
        } else {
            content.keelCard(padding: 18, radius: 20)
        }
    }
}

private struct Filters: View {
    @Environment(LargeFilesModel.self) private var model

    var body: some View {
        @Bindable var model = model
        VStack(alignment: .leading, spacing: 10) {
            ScrollView(.horizontal) {
                HStack(spacing: 6) {
                    chip(nil, "Tümü")
                    ForEach(LargeFile.Kind.allCases, id: \.self) { kind in
                        if model.count(kind) > 0 { chip(kind, FileText.kind(kind)) }
                    }
                }
            }
            .scrollIndicators(.never)

            HStack(spacing: 10) {
                Picker("Konum", selection: $model.place) {
                    ForEach(LargeFilesModel.Place.allCases) { Text($0.title).tag($0) }
                }
                .fixedSize()
                Picker("Son açılış", selection: $model.age) {
                    ForEach(LargeFilesModel.Age.allCases) { Text($0.title).tag($0) }
                }
                .fixedSize()
                Picker("En az", selection: $model.minimumSize) {
                    ForEach(LargeFilesModel.MinimumSize.allCases) { Text($0.title).tag($0) }
                }
                .fixedSize()
                Spacer()
            }
            .font(.keel(13, .semibold))
        }
    }

    private func chip(_ kind: LargeFile.Kind?, _ title: String) -> some View {
        let isOn = model.kind == kind
        return Button {
            model.kind = kind
        } label: {
            Text("\(title) \(model.count(kind))")
                .font(.keel(13, .bold))
                .foregroundStyle(isOn ? Palette.onAccent : Palette.text)
                .padding(.horizontal, 14)
                .frame(height: 34)
                .background(isOn ? AnyShapeStyle(Palette.accent) : AnyShapeStyle(Palette.mist), in: Capsule())
                .overlay { Capsule().strokeBorder(isOn ? .clear : Palette.border) }
        }
        .buttonStyle(.plain)
    }
}

private struct FileList: View {
    @Environment(LargeFilesModel.self) private var model

    var body: some View {
        let files = model.visibleFiles
        VStack(spacing: 0) {
            if files.isEmpty {
                Text("Bu filtrelerle eşleşen dosya yok.")
                    .font(.keel(14, .medium))
                    .foregroundStyle(Palette.slate)
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                ForEach(Array(files.prefix(200).enumerated()), id: \.element.id) { index, file in
                    FileRow(file: file)
                    if index < min(files.count, 200) - 1 {
                        Divider().overlay(Palette.divider).padding(.leading, 76)
                    }
                }
                if files.count > 200 {
                    Text("En büyük 200 dosya gösteriliyor; daha azını görmek için boyutu artır.")
                        .font(.keel(12, .medium))
                        .foregroundStyle(Palette.slate)
                        .padding(16)
                }
            }
        }
        .padding(.vertical, 6)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(Palette.border) }
    }
}

private struct FileRow: View {
    @Environment(LargeFilesModel.self) private var model
    let file: LargeFile

    var body: some View {
        HStack(spacing: 14) {
            Toggle("", isOn: Binding(
                get: { model.selection.contains(file.id) },
                set: { isOn in
                    if isOn { model.selection.insert(file.id) } else { model.selection.remove(file.id) }
                }
            ))
            .toggleStyle(.checkbox)
            .labelsHidden()
            .accessibilityLabel(file.url.lastPathComponent)

            Image(nsImage: model.icon(for: file))
                .resizable()
                .frame(width: 34, height: 34)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(file.url.lastPathComponent)
                    .font(.keel(14, .bold))
                    .foregroundStyle(Palette.text)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(detail)
                    .font(.keel(12, .medium))
                    .foregroundStyle(model.isOlder(file, than: .oneYear) ? Palette.warningText : Palette.slate)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .layoutPriority(1)

            Spacer(minLength: 8)

            if let location = file.appData {
                Pill(text: model.ownerName(location), background: Palette.mist, foreground: Palette.subtle)
                    .lineLimit(1)
                    .help("\(model.ownerName(location)) uygulamasının verisi (\(location.area))")
            }

            Menu {
                Button("Finder'da göster") { model.reveal(file) }
                Button("Aç") { model.open(file) }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(Palette.slate)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .accessibilityLabel("Dosya seçenekleri")

            ByteAmount(bytes: file.sizeBytes, size: 14)
                .fixedSize()
                .frame(minWidth: 64, alignment: .trailing)
        }
        .padding(.horizontal, 22)
        .frame(minHeight: 56)
        .help(file.url.path)
    }

    /// "~/Downloads · 3 ay önce", or for app data the folder inside the app's own.
    private var detail: String {
        guard let location = file.appData else {
            return "\(FileText.folder(file.url)) · \(FileText.lastOpened(file.lastActivity))"
        }
        return "\(location.area) › \(location.owner) · \(FileText.lastOpened(file.lastActivity))"
    }
}

private struct RemovalBanner: View {
    let report: LargeFilesReport
    let undo: () -> Void

    private var clean: Bool { report.failed.isEmpty && report.skipped.isEmpty }

    /// One line per file that was not moved, and why.
    private var lines: [String] {
        report.missing.map { "\($0.url.lastPathComponent): artık yerinde yok (başka yerden silinmiş); listeden çıkarıldı" }
            + (report.skipped + report.failed).map { "\($0.url.lastPathComponent): \($0.message)" }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: clean ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(clean ? Palette.mintText : Palette.warningText)
            VStack(alignment: .leading, spacing: 2) {
                Text(report.removed.isEmpty ? "Hiçbir dosya taşınmadı" : "\(ByteFormat.string(report.freedBytes)) Çöp Kutusu'na taşındı")
                    .font(.keel(15, .bold))
                    .foregroundStyle(Palette.text)
                ForEach(Array(lines.prefix(4).enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(.keel(12, .medium))
                        .foregroundStyle(Palette.slate)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer()
            if !report.trashed.isEmpty {
                Button(action: undo) {
                    Label("Geri al", systemImage: "arrow.uturn.backward")
                }
                .buttonStyle(TileButtonStyle())
            }
        }
        .keelCard(padding: 18)
    }
}

/// Turkish wording for files.
enum FileText {
    static func kind(_ kind: LargeFile.Kind) -> String {
        switch kind {
        case .video: "Video"
        case .archive: "Arşiv"
        case .diskImage: "Disk görüntüsü"
        case .installer: "Yükleyici"
        case .audio: "Ses"
        case .image: "Görsel"
        case .document: "Belge"
        case .other: "Diğer"
        }
    }

    /// "~/Downloads"
    static func folder(_ url: URL) -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let folder = url.deletingLastPathComponent().path
        return folder.hasPrefix(home) ? "~" + folder.dropFirst(home.count) : folder
    }

    static func lastOpened(_ date: Date?) -> String {
        guard let date else { return "açılma bilgisi yok" }
        let days = Int(Date().timeIntervalSince(date) / 86_400)
        switch days {
        case ..<1: return "bugün"
        case 1: return "dün"
        case 2..<60: return "\(days) gün önce"
        case 60..<730: return "\(days / 30) ay önce"
        default: return "\(days / 365) yıl önce"
        }
    }
}
