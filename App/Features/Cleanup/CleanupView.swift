import KeelCore
import SwiftUI

struct CleanupView: View {
    @Environment(CleanupModel.self) private var model
    @Environment(SystemStatus.self) private var status
    @State private var confirming = false
    @State private var hasFullDiskAccess = FullDiskAccess.isGranted
    @Environment(\.compactLayout) private var compact

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(alignment: .bottom) {
                PageHeader(
                    title: "Temizlik",
                    subtitle: "Silmek istediğin kategorileri seç. Silinenler Çöp Kutusu'na taşınır, oradan geri alabilirsin."
                )
                Spacer(minLength: 16)
                if model.phase == .ready, !model.results.isEmpty {
                    Button(model.allSelected ? "Seçimi kaldır" : "Tümünü seç", action: model.toggleAll)
                        .buttonStyle(.keelSecondary)
                }
            }

            if !hasFullDiskAccess {
                FullDiskAccessBanner { hasFullDiskAccess = FullDiskAccess.isGranted }
            }
            if let report = model.lastReport {
                ReportBanner(report: report) {
                    Task { await model.undoLastCleanup() }
                }
            }
            if let restore = model.lastRestore {
                Label(Undo.summary(restore), systemImage: restore.failed.isEmpty ? "arrow.uturn.backward.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.keel(14, .semibold))
                    .foregroundStyle(restore.failed.isEmpty ? Palette.mintText : Palette.warningText)
                    .fixedSize(horizontal: false, vertical: true)
                    .keelCard(padding: 16, radius: 16)
            }
            if let message = model.errorMessage {
                Text("Tarama tamamlanamadı: \(message)")
                    .font(.keel(14, .semibold))
                    .foregroundStyle(Palette.warningText)
            }

            switch model.phase {
            case .idle:
                IdleCard(scan: model.scan)
            case .scanning:
                ScanningCard(cancel: model.cancelScan)
            case .ready, .cleaning:
                if model.totalBytes > 0 {
                    breakdownCard
                }
                if compact {
                    VStack(spacing: 20) {
                        categoryList
                        summary
                    }
                } else {
                    HStack(alignment: .top, spacing: 22) {
                        categoryList
                        summary.frame(width: 304)
                    }
                }
            }
        }
        .confirmationDialog(confirmationTitle, isPresented: $confirming, titleVisibility: .visible) {
            Button("Temizle", role: model.selectedPermanentBytes > 0 ? ButtonRole.destructive : nil) {
                model.cleanSelection()
            }
            Button("Vazgeç", role: .cancel) {}
        } message: {
            Text(confirmationMessage)
        }
    }

    // MARK: - Storage Breakdown (DaisyDisk / macOS Storage style)

    private var breakdownCard: some View {
        let segments = model.results.map { result in
            SegmentedBar.Segment(
                id: result.category.id.rawValue,
                title: result.category.title,
                value: result.totalBytes,
                color: CategoryStyle.color(for: result.category.id)
            )
        }
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Temizlenebilir Alan Dağılımı").eyebrowStyle()
                Spacer()
                ByteAmount(bytes: model.totalBytes, size: 15, color: Palette.text)
            }
            SegmentedBar(segments: segments, height: 11)
        }
        .keelCard(padding: 18, radius: 16)
    }

    // MARK: - List

    private var categoryList: some View {
        VStack(spacing: 0) {
            ForEach(Array(model.results.enumerated()), id: \.element.category.id) { index, result in
                CategoryRow(
                    result: result,
                    appNames: model.runningAppNames,
                    isSelected: Binding(
                        get: { model.selection.contains(result.category.id) },
                        set: { isOn in
                            if isOn { model.selection.insert(result.category.id) } else { model.selection.remove(result.category.id) }
                        }
                    )
                )
                if index < model.results.count - 1 {
                    Divider().overlay(Palette.divider)
                }
            }
        }
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Palette.borderHighlight) }
        .shadow(color: .black.opacity(0.18), radius: 14, y: 6)
        .disabled(model.phase == .cleaning)
    }

    // MARK: - Summary

    private var summary: some View {
        let ratio = model.totalBytes > 0 ? Double(model.selectedBytes) / Double(model.totalBytes) : 0
        return VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                CircularGauge(
                    fraction: ratio,
                    tint: Palette.keelGreen,
                    secondaryTint: Palette.info,
                    track: Palette.Sidebar.widgetTrack,
                    lineWidth: 6.5,
                    size: 64,
                    centerText: "%\(Int((ratio * 100).rounded()))"
                )
                VStack(alignment: .leading, spacing: 3) {
                    Text("Seçilen").eyebrowStyle(color: Palette.Sidebar.eyebrow)
                    ByteAmount(bytes: model.selectedBytes, size: 28, color: .white)
                    Text("\(model.selectedResults.count) kategori seçili")
                        .font(.keel(12.5, .medium))
                        .foregroundStyle(Palette.Sidebar.text)
                }
            }

            if let disk = status.disk {
                HStack(spacing: 8) {
                    Image(systemName: "externaldrive.badge.checkmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Palette.mintText)
                    Text("Temizlik sonrası boş alan yaklaşık **\(ByteFormat.string(disk.availableBytes + model.selectedBytes))** olacak.")
                        .font(.keel(12.5, .medium))
                        .foregroundStyle(Palette.Sidebar.text)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(11)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            Button {
                confirming = true
            } label: {
                if model.phase == .cleaning {
                    ProgressView().controlSize(.small).tint(Palette.onAccent)
                } else {
                    Label("Temizle", systemImage: "sparkles")
                }
            }
            .buttonStyle(.keelAccent)
            .disabled(model.selectedBytes == 0 || model.phase == .cleaning)

            Button("Yeniden tara", action: model.scan)
                .buttonStyle(.plain)
                .font(.keel(13, .bold))
                .foregroundStyle(Palette.Sidebar.eyebrow)
                .frame(maxWidth: .infinity, minHeight: 32)
                .disabled(model.isBusy)
        }
        .keelSummaryCard(padding: 22, radius: 18)
    }

    private var confirmationTitle: String {
        "\(ByteFormat.string(model.selectedBytes)) temizlensin mi?"
    }

    private var confirmationMessage: String {
        let permanent = model.selectedPermanentBytes
        let toTrash = model.selectedBytes - permanent
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

// MARK: - Category Visual Style

private enum CategoryStyle {
    static func symbol(for category: CleanupCategoryID) -> String {
        switch category {
        case .userCaches: "internaldrive.fill"
        case .logs: "doc.text.fill"
        case .browserCaches: "globe"
        case .developer: "hammer.fill"
        case .oldDownloads: "arrow.down.circle.fill"
        case .trash: "trash.fill"
        }
    }

    static func colors(for category: CleanupCategoryID) -> [Color] {
        switch category {
        case .userCaches: [Color(hex: 0x34D399), Color(hex: 0x0D9488)]
        case .logs: [Color(hex: 0x38BDF8), Color(hex: 0x0284C7)]
        case .browserCaches: [Color(hex: 0x60A5FA), Color(hex: 0x2563EB)]
        case .developer: [Color(hex: 0xA78BFA), Color(hex: 0x6366F1)]
        case .oldDownloads: [Color(hex: 0xFBBF24), Color(hex: 0xEA580C)]
        case .trash: [Color(hex: 0xFB7185), Color(hex: 0xE11D48)]
        }
    }

    static func color(for category: CleanupCategoryID) -> Color {
        colors(for: category).first ?? Palette.keelGreen
    }
}

// MARK: - Rows

private struct CategoryRow: View {
    let result: CategoryScanResult
    let appNames: [String: String]
    @Binding var isSelected: Bool
    @State private var expanded = false
    @State private var isHovered = false

    private var isEmpty: Bool { result.items.isEmpty }
    private var isUnreadable: Bool { isEmpty && !result.unreadableRoots.isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 14) {
                Toggle("", isOn: $isSelected)
                    .toggleStyle(.checkbox)
                    .labelsHidden()
                    .disabled(isEmpty)
                    .accessibilityLabel(result.category.title)

                IconMedallion(
                    symbol: CategoryStyle.symbol(for: result.category.id),
                    colors: CategoryStyle.colors(for: result.category.id),
                    size: 38,
                    symbolScale: 0.45,
                    filled: !isEmpty
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(result.category.title)
                        .font(.keel(15, .bold))
                        .foregroundStyle(Palette.text)
                    Text(detailText)
                        .font(.keel(12.5, .medium))
                        .foregroundStyle(result.category.removal == .deletePermanently ? Palette.warningText : Palette.slate)
                        .fixedSize(horizontal: false, vertical: true)
                    if let note = skipNote {
                        Text(note)
                            .font(.keel(12, .semibold))
                            .foregroundStyle(Palette.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: 12)

                if isUnreadable {
                    Pill(text: "Erişim yok", background: Palette.warningTint, foreground: Palette.warningText)
                        .help("Bu klasörü okumak için Tam Disk Erişimi gerekiyor")
                } else if isEmpty {
                    Pill(text: "Temiz", background: Palette.mint, foreground: Palette.mintText)
                } else {
                    ByteAmount(bytes: result.totalBytes, size: 15)
                    Button {
                        withAnimation(.easeInOut(duration: 0.16)) { expanded.toggle() }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .rotationEffect(.degrees(expanded ? 90 : 0))
                            .foregroundStyle(Palette.slate)
                            .frame(width: 34, height: 34)
                            .background(Palette.mist, in: Circle())
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(expanded ? "Ayrıntıları gizle" : "Neyin silineceğini göster")
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .frame(minHeight: 62)
            .background(isHovered && !isEmpty ? Color.white.opacity(0.03) : .clear)
            .onHover { isHovered = $0 }

            if expanded {
                ItemList(items: result.items)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
            }
        }
        .opacity(isEmpty && !isUnreadable ? 0.65 : 1)
    }

    private var detailText: String {
        isUnreadable
            ? "Okunamadı: Tam Disk Erişimi gerekiyor"
            : result.category.summary
    }

    /// "8 öğe atlandı: Xcode açık"
    private var skipNote: String? {
        let owners = result.skipped.compactMap { item -> String? in
            if case .appRunning(let bundleID) = item.reason { bundleID } else { nil }
        }
        guard !owners.isEmpty else { return nil }
        let names = Set(owners.map { appNames[$0] ?? $0 }).sorted()
        return "\(owners.count) öğe atlandı: \(names.joined(separator: ", ")) açık"
    }
}

private struct ItemList: View {
    let items: [CleanupItem]
    private let limit = 30

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(items.prefix(limit)) { item in
                HStack {
                    Text(displayPath(item.url))
                        .font(.keelMono(12, .medium))
                        .foregroundStyle(Palette.slate)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer(minLength: 12)
                    Text(ByteFormat.string(item.sizeBytes))
                        .font(.keelMono(12, .semibold))
                        .foregroundStyle(Palette.text)
                }
                .help(item.url.path)
            }
            if items.count > limit {
                Text("ve \(items.count - limit) öğe daha")
                    .font(.keel(12, .semibold))
                    .foregroundStyle(Palette.slate)
            }
        }
        .padding(14)
        .background(Palette.mist, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func displayPath(_ url: URL) -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return url.path.hasPrefix(home) ? "~" + url.path.dropFirst(home.count) : url.path
    }
}

// MARK: - States and banners

/// CleanMyMac-style inviting centered idle stage for Cleanup.
private struct IdleCard: View {
    let scan: @MainActor () -> Void

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: 0x38BDF8).opacity(0.24), .clear],
                            center: .center,
                            startRadius: 12,
                            endRadius: 68
                        )
                    )
                    .frame(width: 136, height: 136)
                Mascot(character: .puf, size: 70)
            }

            VStack(spacing: 6) {
                Text("Sistem Gereksizlerini Tara")
                    .font(.keel(22, .extraBold))
                    .tracking(-0.4)
                    .foregroundStyle(Palette.text)
                Text("Önbellekleri, eski günlükleri, tarayıcı artıklarını ve geliştirici verilerini güvenle ölçer. Silme için ayrıca onayın istenir.")
                    .font(.keel(13.5, .medium))
                    .foregroundStyle(Palette.slate)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 480)
            }

            Button(action: scan) {
                Label("Taramayı Başlat", systemImage: "magnifyingglass")
            }
            .buttonStyle(.keelHeroPill(colors: [Color(hex: 0x38BDF8), Color(hex: 0x0EA5E9)]))
            .padding(.top, 4)

            HStack(spacing: 18) {
                badge("trash", "Çöp Kutusu'na taşınır")
                badge("shield.lefthalf.filled", "Açık uygulamalar korunur")
                badge("arrow.uturn.backward.circle", "Geri alınabilir")
            }
            .padding(.top, 6)
        }
        .padding(.vertical, 34)
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity)
        .keelCard(padding: 0, radius: 22)
    }

    private func badge(_ symbol: String, _ text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color(hex: 0x38BDF8))
            Text(text)
                .font(.keel(12, .semibold))
                .foregroundStyle(Palette.slate)
        }
    }
}

private struct ScanningCard: View {
    let cancel: @MainActor () -> Void

    var body: some View {
        HStack(spacing: 16) {
            ProgressView().controlSize(.regular)
            VStack(alignment: .leading, spacing: 2) {
                Text("Kategoriler taranıyor…")
                    .font(.keel(17, .extraBold))
                    .foregroundStyle(Palette.text)
                Text("Önbellekler, günlükler, tarayıcılar ve indirmeler ölçülüyor")
                    .font(.keel(13.5, .medium))
                    .foregroundStyle(Palette.slate)
            }
            Spacer()
            Button("Durdur", action: cancel)
                .buttonStyle(.keelSecondary)
        }
        .keelCard(padding: 24, radius: 18)
    }
}

private struct FullDiskAccessBanner: View {
    let recheck: @MainActor () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            IconMedallion(
                symbol: "lock.shield.fill",
                colors: [Palette.warningText, Palette.warning],
                size: 36,
                symbolScale: 0.46
            )
            VStack(alignment: .leading, spacing: 2) {
                Text("Tam Disk Erişimi gerekli")
                    .font(.keel(15, .bold))
                    .foregroundStyle(Palette.text)
                Text("Çöp Kutusu gibi korumalı klasörleri görebilmek için Sistem Ayarları > Gizlilik ve Güvenlik > Tam Disk Erişimi'nden Keel'i aç.")
                    .font(.keel(13, .medium))
                    .foregroundStyle(Palette.slate)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 12)
            Button("Ayarları aç", action: FullDiskAccess.openSettings)
                .buttonStyle(.keelSecondary)
            Button("Tekrar kontrol et", action: recheck)
                .buttonStyle(.plain)
                .font(.keel(13, .bold))
                .foregroundStyle(Palette.mintText)
        }
        .keelCard(padding: 18, radius: 16, fill: Palette.warningTint)
    }
}

private struct ReportBanner: View {
    let report: CleanupReport
    let undo: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            IconMedallion(
                symbol: report.failed.isEmpty ? "checkmark" : "exclamationmark.triangle.fill",
                colors: report.failed.isEmpty ? [Palette.keelGreen, Color(hex: 0x0D9488)] : [Palette.warningText, Palette.warning],
                size: 34,
                symbolScale: 0.44
            )
            VStack(alignment: .leading, spacing: 2) {
                Text("\(ByteFormat.string(report.freedBytes)) temizlendi")
                    .font(.keel(15, .bold))
                    .foregroundStyle(Palette.text)
                Text(detail)
                    .font(.keel(13, .medium))
                    .foregroundStyle(Palette.slate)
            }
            Spacer()
            if !report.trashed.isEmpty {
                Button(action: undo) {
                    Label("Geri al", systemImage: "arrow.uturn.backward")
                }
                .buttonStyle(TileButtonStyle())
                .help("Çöp Kutusu'na taşınanları eski yerlerine koyar")
            }
        }
        .keelCard(padding: 18, radius: 16, fill: Palette.mint)
    }

    private var detail: String {
        var parts = ["\(report.removed.count) öğe kaldırıldı"]
        if !report.skipped.isEmpty { parts.append("\(report.skipped.count) öğe atlandı (uygulaması açık ya da güvenlik kuralı izin vermedi)") }
        if !report.failed.isEmpty { parts.append("\(report.failed.count) öğe kaldırılamadı") }
        return parts.joined(separator: " · ")
    }
}
