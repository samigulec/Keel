import KeelCore
import SwiftUI

struct ApplicationsView: View {
    @Environment(ApplicationsModel.self) private var model
    @State private var pending: [UninstallPlan] = []
    @State private var confirming = false

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(alignment: .bottom) {
                PageHeader(
                    title: "Uygulamalar",
                    subtitle: "Kullanmadığın uygulamaları artık dosyalarıyla birlikte kaldır. Her şey Çöp Kutusu'na gider; oradan geri alabilirsin."
                )
                Spacer(minLength: 16)
                if model.phase == .ready {
                    Button("Yeniden tara", action: model.scan)
                        .buttonStyle(.keelSecondary)
                }
            }

            if let report = model.lastReport {
                UninstallBanner(report: report, dismiss: model.dismissReport)
            }

            switch model.phase {
            case .idle:
                ScanningApps()
            case .scanning where model.apps.isEmpty:
                ScanningApps()
            default:
                SummaryTiles()
                Toolbar()
                HStack(alignment: .top, spacing: 20) {
                    AppList()
                    DetailPanel { plans in
                        pending = plans
                        confirming = true
                    }
                    .frame(width: 340)
                }
                if !model.selection.isEmpty {
                    SelectionBar {
                        Task {
                            pending = await model.plans(for: Array(model.selection), removingApps: true)
                            confirming = true
                        }
                    }
                }
            }
        }
        .task {
            if model.phase == .idle { model.scan() }
        }
        .confirmationDialog(confirmationTitle, isPresented: $confirming, titleVisibility: .visible) {
            Button(pending.contains(where: \.removesApp) ? "Kaldır" : "Sıfırla") {
                let plans = pending
                Task { await model.perform(plans) }
            }
            Button("Vazgeç", role: .cancel) {}
        } message: {
            Text(confirmationMessage)
        }
    }

    private var confirmationTitle: String {
        let names = pending.map(\.app.name)
        let removes = pending.contains(where: \.removesApp)
        if names.count == 1, let name = names.first {
            return removes ? "\(name) kaldırılsın mı?" : "\(name) sıfırlansın mı?"
        }
        return "\(names.count) uygulama kaldırılsın mı?"
    }

    private var confirmationMessage: String {
        let total = pending.reduce(0) { $0 + $1.totalBytes }
        let files = pending.reduce(0) { $0 + $1.files.count }
        var text = "\(ByteFormat.string(total)) Çöp Kutusu'na taşınacak; oradan geri alabilirsin."
        if pending.contains(where: \.removesApp) {
            text += " \(files) ilgili dosya da uygulamayla birlikte gider."
        } else {
            text += " Uygulama kalır; ayarları ve verileri ilk açılıştaki haline döner."
        }
        return text
    }
}

// MARK: - Summary and filters

private struct SummaryTiles: View {
    @Environment(ApplicationsModel.self) private var model

    var body: some View {
        HStack(spacing: 14) {
            tile(.all, title: "Uygulama", value: "\(model.apps.count)", detail: model.isMeasuring ? "boyutlar ölçülüyor…" : ByteFormat.string(model.totalBytes), mascot: .blok)
            tile(.unused, title: "Kullanılmayan", value: "\(model.count(.unused))", detail: "90 günden uzun süredir açılmadı", mascot: .kee)
            tile(.intel, title: "Intel", value: "\(model.count(.intel))", detail: "Rosetta ile çalışıyor", mascot: .zip)
            tile(.large, title: "Büyük", value: "\(model.count(.large))", detail: "1 GB'tan büyük", mascot: .puf)
        }
    }

    private func tile(_ filter: ApplicationsModel.Filter, title: String, value: String, detail: String, mascot: Mascot.Character) -> some View {
        let isOn = model.filter == filter
        return Button {
            model.filter = isOn ? .all : filter
        } label: {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title).eyebrowStyle(color: isOn ? Palette.Sidebar.eyebrow : Palette.slate)
                    Text(value)
                        .font(.keelMono(28, .semibold))
                        .tracking(-1.5)
                        .foregroundStyle(Palette.text)
                    Text(detail)
                        .font(.keel(12, .medium))
                        .foregroundStyle(isOn ? Palette.Sidebar.text : Palette.slate)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                Mascot(character: mascot, size: 34)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isOn ? AnyShapeStyle(Palette.summary) : AnyShapeStyle(Palette.card), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(isOn ? Color.white.opacity(0.18) : Palette.border)
            }
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

private struct Toolbar: View {
    @Environment(ApplicationsModel.self) private var model

    var body: some View {
        @Bindable var model = model
        HStack(spacing: 10) {
            ScrollView(.horizontal) {
                HStack(spacing: 6) {
                    ForEach(ApplicationsModel.Filter.allCases) { filter in
                        let isOn = model.filter == filter
                        Button {
                            model.filter = filter
                        } label: {
                            Text("\(filter.title) \(model.count(filter))")
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
            }
            .scrollIndicators(.never)

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Palette.slate)
                TextField("Ara", text: $model.search)
                    .textFieldStyle(.plain)
                    .font(.keel(14, .medium))
            }
            .padding(.horizontal, 12)
            .frame(width: 200, height: 34)
            .background(Palette.mist, in: Capsule())
            .overlay { Capsule().strokeBorder(Palette.border) }

            Menu {
                Picker("Sırala", selection: $model.sort) {
                    ForEach(ApplicationsModel.Sort.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.inline)
            } label: {
                Label(model.sort.title, systemImage: "arrow.up.arrow.down")
                    .font(.keel(13, .bold))
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
    }
}

// MARK: - List

private struct AppList: View {
    @Environment(ApplicationsModel.self) private var model

    var body: some View {
        let entries = model.visibleApps
        VStack(spacing: 0) {
            if entries.isEmpty {
                Text(model.search.isEmpty ? "Bu filtrede uygulama yok." : "\"\(model.search)\" ile eşleşen uygulama yok.")
                    .font(.keel(14, .medium))
                    .foregroundStyle(Palette.slate)
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                    AppRow(entry: entry)
                    if index < entries.count - 1 {
                        Divider().overlay(Palette.divider).padding(.leading, 76)
                    }
                }
            }
        }
        .padding(.vertical, 6)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(Palette.border) }
        .frame(maxWidth: .infinity)
    }
}

private struct AppRow: View {
    @Environment(ApplicationsModel.self) private var model
    let entry: AppEntry

    private var app: InstalledApp { entry.app }
    private var isFocused: Bool { model.focusedID == entry.id }
    private var canRemove: Bool { !app.isSystem }

    var body: some View {
        HStack(spacing: 14) {
            Toggle("", isOn: Binding(
                get: { model.selection.contains(entry.id) },
                set: { isOn in
                    if isOn { model.selection.insert(entry.id) } else { model.selection.remove(entry.id) }
                }
            ))
            .toggleStyle(.checkbox)
            .labelsHidden()
            .disabled(!canRemove)
            .accessibilityLabel("\(app.name) kaldırılacaklara eklensin")

            Button {
                model.focusedID = entry.id
            } label: {
                HStack(spacing: 12) {
                    Image(nsImage: model.icon(for: app))
                        .resizable()
                        .frame(width: 36, height: 36)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(app.name)
                                .font(.keel(15, .bold))
                                .foregroundStyle(Palette.text)
                                .lineLimit(1)
                            if model.isRunning(app) {
                                Circle().fill(Palette.keelGreen).frame(width: 7, height: 7)
                                    .help("Açık")
                                    .accessibilityLabel("Açık")
                            }
                        }
                        Text(subtitle)
                            .font(.keel(12, .medium))
                            .foregroundStyle(model.isUnused(entry) ? Palette.warningText : Palette.slate)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 8)
                    if app.architecture == .intel {
                        Pill(text: "Intel", background: Palette.warningTint, foreground: Palette.warningText)
                    }
                    if let size = entry.sizeBytes {
                        ByteAmount(bytes: size, size: 14)
                    } else {
                        ProgressView().controlSize(.small)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 60)
        .background(isFocused ? Palette.Sidebar.selectedBackground : .clear, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(.horizontal, 6)
    }

    private var subtitle: String {
        var parts: [String] = []
        if let version = app.version { parts.append(version) }
        parts.append(AppText.lastUsed(entry.lastUsed))
        return parts.joined(separator: " · ")
    }
}

// MARK: - Detail

private struct DetailPanel: View {
    @Environment(ApplicationsModel.self) private var model
    let confirm: ([UninstallPlan]) -> Void

    var body: some View {
        Group {
            if let entry = model.focused {
                AppDetail(entry: entry, confirm: confirm)
                    .id(entry.id)
            } else {
                VStack(spacing: 14) {
                    Mascot(character: .blok, size: 64)
                    Text("Bir uygulama seç")
                        .font(.keel(17, .extraBold))
                        .foregroundStyle(Palette.text)
                    Text("Boyutunu, son ne zaman açıldığını ve geride bıraktığı dosyaları burada görürsün.")
                        .font(.keel(13, .medium))
                        .foregroundStyle(Palette.slate)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(28)
                .frame(maxWidth: .infinity, minHeight: 280)
            }
        }
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(Palette.border) }
    }
}

private struct AppDetail: View {
    @Environment(ApplicationsModel.self) private var model
    let entry: AppEntry
    let confirm: ([UninstallPlan]) -> Void

    private var app: InstalledApp { entry.app }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                Image(nsImage: model.icon(for: app))
                    .resizable()
                    .frame(width: 56, height: 56)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text(app.name)
                        .font(.keel(19, .extraBold))
                        .foregroundStyle(Palette.text)
                        .lineLimit(2)
                    Text([app.version, app.bundleID].compactMap { $0 }.joined(separator: " · "))
                        .font(.keel(12, .medium))
                        .foregroundStyle(Palette.slate)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .textSelection(.enabled)
                }
            }

            FlowLayout(spacing: 6) {
                Pill(text: AppText.source(app.source), background: Palette.mist, foreground: Palette.text)
                Pill(
                    text: AppText.architecture(app.architecture),
                    background: app.architecture == .intel ? Palette.warningTint : Palette.mist,
                    foreground: app.architecture == .intel ? Palette.warningText : Palette.text
                )
                if model.isRunning(app) { Pill(text: "Açık") }
            }

            VStack(spacing: 8) {
                fact("Son kullanım", AppText.lastUsed(entry.lastUsed))
                fact("Uygulama", entry.sizeBytes.map { ByteFormat.string($0) } ?? "ölçülüyor…")
                fact("İlgili dosyalar", model.relatedBytes(for: entry).map { ByteFormat.string($0) } ?? "aranıyor…")
            }

            if app.isSystem {
                note("macOS'un parçası; kaldırılamaz.", warning: false)
            } else if model.isRunning(app) {
                HStack(spacing: 10) {
                    note("Açıkken kaldırılamaz.", warning: true)
                    Spacer(minLength: 0)
                    Button("Kapat") { model.quit(app) }
                        .buttonStyle(TileButtonStyle())
                }
            }

            RelatedFilesList(entry: entry)

            if !app.isSystem {
                VStack(spacing: 8) {
                    Button {
                        Task { confirm(await model.plans(for: [entry.id], removingApps: true)) }
                    } label: {
                        Text("Kaldır")
                    }
                    .buttonStyle(.keelAccent)
                    .disabled(model.isRunning(app) || model.phase != .ready)

                    HStack(spacing: 8) {
                        Button("Sıfırla") {
                            Task { confirm(await model.plans(for: [entry.id], removingApps: false)) }
                        }
                        .buttonStyle(TileButtonStyle())
                        .disabled(model.isRunning(app) || model.phase != .ready || (model.relatedBytes(for: entry) ?? 0) == 0)
                        .help("Uygulamayı bırakır, ayarlarını ve verilerini siler")
                        Button("Finder'da göster") { model.reveal(app.url) }
                            .buttonStyle(TileButtonStyle())
                    }
                }
            }
        }
        .padding(20)
        .task { await model.loadRelated(for: entry) }
    }

    private func fact(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(.keel(13, .medium))
                .foregroundStyle(Palette.slate)
            Spacer()
            Text(value)
                .font(.keel(13, .bold))
                .foregroundStyle(Palette.text)
        }
    }

    private func note(_ text: String, warning: Bool) -> some View {
        Label(text, systemImage: warning ? "exclamationmark.triangle.fill" : "lock.fill")
            .font(.keel(13, .semibold))
            .foregroundStyle(warning ? Palette.warningText : Palette.slate)
    }
}

private struct RelatedFilesList: View {
    @Environment(ApplicationsModel.self) private var model
    let entry: AppEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("İlgili dosyalar").eyebrowStyle()
            if let files = model.related[entry.id] {
                if files.isEmpty {
                    Text("Geride dosya bırakmamış.")
                        .font(.keel(13, .medium))
                        .foregroundStyle(Palette.slate)
                } else {
                    ScrollView {
                        VStack(spacing: 2) {
                            ForEach(files) { file in
                                row(file)
                            }
                        }
                    }
                    .frame(maxHeight: 240)
                }
            } else {
                ProgressView().controlSize(.small)
            }
        }
        .padding(14)
        .background(Palette.mist, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func row(_ file: RelatedFile) -> some View {
        HStack(spacing: 8) {
            Toggle("", isOn: Binding(
                get: { !model.keptFiles.contains(file.id) },
                set: { isOn in
                    if isOn { model.keptFiles.remove(file.id) } else { model.keptFiles.insert(file.id) }
                }
            ))
            .toggleStyle(.checkbox)
            .labelsHidden()
            .accessibilityLabel(file.url.lastPathComponent)
            VStack(alignment: .leading, spacing: 1) {
                Text(AppText.kind(file.kind))
                    .font(.keel(12, .bold))
                    .foregroundStyle(Palette.text)
                Text(file.url.lastPathComponent)
                    .font(.keelMono(10, .medium))
                    .foregroundStyle(Palette.slate)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer(minLength: 6)
            Text(ByteFormat.string(file.sizeBytes))
                .font(.keelMono(11, .semibold))
                .foregroundStyle(Palette.text)
        }
        .frame(minHeight: 34)
        .help(file.url.path)
    }
}

// MARK: - Bars and states

private struct SelectionBar: View {
    @Environment(ApplicationsModel.self) private var model
    let remove: () -> Void

    var body: some View {
        let chosen = model.apps.filter { model.selection.contains($0.id) }
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(chosen.count) uygulama seçildi")
                    .font(.keel(15, .bold))
                    .foregroundStyle(Palette.text)
                Text("\(ByteFormat.string(chosen.reduce(0) { $0 + ($1.sizeBytes ?? 0) })) ve ilgili dosyaları")
                    .font(.keel(13, .medium))
                    .foregroundStyle(Palette.Sidebar.text)
            }
            Spacer()
            Button("Seçimi temizle") { model.selection = [] }
                .buttonStyle(TileButtonStyle())
            Button("Seçilenleri kaldır", action: remove)
                .buttonStyle(.keelPrimary)
                .disabled(model.phase != .ready)
        }
        .keelSummaryCard(padding: 18)
    }
}

private struct ScanningApps: View {
    var body: some View {
        HStack(spacing: 14) {
            ProgressView().controlSize(.small)
            Text("Uygulamalar taranıyor…")
                .font(.keel(15, .semibold))
                .foregroundStyle(Palette.slate)
        }
        .keelCard()
    }
}

private struct UninstallBanner: View {
    let report: UninstallReport
    let dismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: report.failed.isEmpty && report.skipped.isEmpty ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(report.failed.isEmpty && report.skipped.isEmpty ? Palette.mintText : Palette.warningText)
            VStack(alignment: .leading, spacing: 4) {
                Text("\(ByteFormat.string(report.freedBytes)) Çöp Kutusu'na taşındı")
                    .font(.keel(15, .bold))
                    .foregroundStyle(Palette.text)
                ForEach(Array((report.skipped + report.failed).prefix(5).enumerated()), id: \.offset) { _, outcome in
                    Text("\(outcome.url.lastPathComponent): \(outcome.message)")
                        .font(.keel(12, .medium))
                        .foregroundStyle(Palette.slate)
                }
            }
            Spacer()
            Button("Kapat", action: dismiss)
                .buttonStyle(.plain)
                .font(.keel(13, .bold))
                .foregroundStyle(Palette.mintText)
        }
        .keelCard(padding: 18)
    }
}

/// Turkish wording for app facts.
enum AppText {
    static func lastUsed(_ date: Date?) -> String {
        guard let date else { return "Kullanım bilgisi yok" }
        let days = Int(Date().timeIntervalSince(date) / 86_400)
        switch days {
        case ..<1: return "Bugün kullanıldı"
        case 1: return "Dün kullanıldı"
        case 2..<60: return "\(days) gün önce kullanıldı"
        case 60..<730: return "\(days / 30) ay önce kullanıldı"
        default: return "\(days / 365) yıl önce kullanıldı"
        }
    }

    static func source(_ source: InstalledApp.Source) -> String {
        switch source {
        case .appStore: "App Store"
        case .apple: "Apple"
        case .other: "İnternetten"
        }
    }

    static func architecture(_ architecture: AppArchitecture) -> String {
        switch architecture {
        case .universal: "Universal"
        case .appleSilicon: "Apple silicon"
        case .intel: "Intel (Rosetta)"
        case .unknown: "Mimari bilinmiyor"
        }
    }

    static func kind(_ kind: RelatedFile.Kind) -> String {
        switch kind {
        case .supportFiles: "Destek dosyaları"
        case .caches: "Önbellek"
        case .preferences: "Ayarlar"
        case .containers: "Uygulama verileri"
        case .savedState: "Pencere durumu"
        case .logs: "Günlükler"
        case .webData: "Web verileri"
        case .launchAgents: "Arka plan görevi"
        }
    }
}
