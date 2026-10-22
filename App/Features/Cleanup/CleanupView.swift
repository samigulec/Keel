import KeelCore
import SwiftUI

struct CleanupView: View {
    @Environment(CleanupModel.self) private var model
    @Environment(SystemStatus.self) private var status
    @State private var confirming = false
    @State private var hasFullDiskAccess = FullDiskAccess.isGranted

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
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
                ReportBanner(report: report)
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
                HStack(alignment: .top, spacing: 24) {
                    categoryList
                    summary.frame(width: 300)
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

    // MARK: - List

    private var categoryList: some View {
        VStack(spacing: 0) {
            ForEach(Array(model.results.enumerated()), id: \.element.category.id) { index, result in
                CategoryRow(
                    result: result,
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
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Palette.border) }
        .disabled(model.phase == .cleaning)
    }

    // MARK: - Summary

    private var summary: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Seçilen").eyebrowStyle(color: Palette.Sidebar.eyebrow)
            ByteAmount(bytes: model.selectedBytes, size: 44, color: .white)
            Text("\(model.selectedResults.count) kategori seçili")
                .font(.keel(14, .medium))
                .foregroundStyle(Palette.Sidebar.text)
            ProgressBar(
                fraction: model.totalBytes > 0 ? Double(model.selectedBytes) / Double(model.totalBytes) : 0,
                tint: Palette.keelGreen,
                track: Palette.Sidebar.widgetTrack,
                height: 10
            )
            if let disk = status.disk {
                Text("Temizlik sonrası boş alan yaklaşık **\(ByteFormat.string(disk.availableBytes + model.selectedBytes))** olacak.")
                    .font(.keel(13, .medium))
                    .foregroundStyle(Palette.Sidebar.text)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                confirming = true
            } label: {
                if model.phase == .cleaning {
                    ProgressView().controlSize(.small).tint(Palette.hull)
                } else {
                    Text("Temizle")
                }
            }
            .buttonStyle(.keelAccent)
            .disabled(model.selectedBytes == 0 || model.phase == .cleaning)

            Button("Yeniden tara", action: model.scan)
                .buttonStyle(.plain)
                .font(.keel(14, .bold))
                .foregroundStyle(Palette.Sidebar.eyebrow)
                .frame(maxWidth: .infinity, minHeight: 44)
                .disabled(model.isBusy)
        }
        .padding(28)
        .background(Palette.hull, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
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

// MARK: - Rows

private struct CategoryRow: View {
    let result: CategoryScanResult
    @Binding var isSelected: Bool
    @State private var expanded = false

    private var isEmpty: Bool { result.items.isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 16) {
                Toggle("", isOn: $isSelected)
                    .toggleStyle(.checkbox)
                    .labelsHidden()
                    .disabled(isEmpty)
                    .accessibilityLabel(result.category.title)

                CategoryBadge(category: result.category.id)

                VStack(alignment: .leading, spacing: 2) {
                    Text(result.category.title)
                        .font(.keel(15, .bold))
                        .foregroundStyle(Palette.hull)
                    Text(detailText)
                        .font(.keel(13, .medium))
                        .foregroundStyle(result.category.removal == .deletePermanently ? Palette.warningText : Palette.slate)
                }

                Spacer(minLength: 12)

                if isEmpty {
                    Text("Temiz")
                        .font(.keel(14, .bold))
                        .foregroundStyle(Palette.mintText)
                } else {
                    ByteAmount(bytes: result.totalBytes, size: 15)
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) { expanded.toggle() }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .bold))
                            .rotationEffect(.degrees(expanded ? 90 : 0))
                            .foregroundStyle(Palette.slate)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(expanded ? "Ayrıntıları gizle" : "Neyin silineceğini göster")
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .frame(minHeight: 68)

            if expanded {
                ItemList(items: result.items)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
            }
        }
        .opacity(isEmpty ? 0.6 : 1)
    }

    private var detailText: String {
        var text = result.category.summary
        let busy = result.skipped.filter {
            if case .appRunning = $0.reason { true } else { false }
        }.count
        if busy > 0 {
            text += " · \(busy) öğe atlandı (uygulama açık)"
        }
        return text
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
                        .foregroundStyle(Palette.hull)
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

private struct CategoryBadge: View {
    let category: CleanupCategoryID

    var body: some View {
        Text(label)
            .font(.keel(13, .extraBold))
            .foregroundStyle(Palette.hull)
            .frame(width: 40, height: 40)
            .background(tint, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .accessibilityHidden(true)
    }

    private var label: String {
        switch category {
        case .userCaches: "ÖB"
        case .logs: "GK"
        case .browserCaches: "TR"
        case .developer: "XC"
        case .oldDownloads: "İN"
        case .trash: "ÇK"
        }
    }

    private var tint: Color {
        switch category {
        case .userCaches, .trash: Palette.mint
        case .logs, .browserCaches: Color(hex: 0xE8EEF8)
        case .developer: Color(hex: 0xF1EEF8)
        case .oldDownloads: Palette.warningTint
        }
    }
}

// MARK: - States and banners

private struct IdleCard: View {
    let scan: @MainActor () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Henüz taranmadı")
                .font(.keel(20, .extraBold))
                .foregroundStyle(Palette.hull)
            Text("Tarama yalnızca okur; neyin ne kadar yer kapladığını gösterir. Silme için ayrıca onayın istenir.")
                .font(.keel(15, .medium))
                .foregroundStyle(Palette.slate)
                .fixedSize(horizontal: false, vertical: true)
            Button(action: scan) {
                Label("Taramayı başlat", systemImage: "magnifyingglass")
            }
            .buttonStyle(.keelPrimary)
            .padding(.top, 4)
        }
        .keelCard(padding: 28, radius: 20)
    }
}

private struct ScanningCard: View {
    let cancel: @MainActor () -> Void

    var body: some View {
        HStack(spacing: 16) {
            ProgressView().controlSize(.regular)
            VStack(alignment: .leading, spacing: 2) {
                Text("Taranıyor…")
                    .font(.keel(17, .extraBold))
                    .foregroundStyle(Palette.hull)
                Text("Önbellekler, günlükler ve indirmeler ölçülüyor")
                    .font(.keel(14, .medium))
                    .foregroundStyle(Palette.slate)
            }
            Spacer()
            Button("Durdur", action: cancel)
                .buttonStyle(.keelSecondary)
        }
        .keelCard(padding: 24, radius: 20)
    }
}

private struct FullDiskAccessBanner: View {
    let recheck: @MainActor () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            Image(systemName: "lock.shield")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Palette.warningText)
            VStack(alignment: .leading, spacing: 2) {
                Text("Tam Disk Erişimi gerekli")
                    .font(.keel(15, .bold))
                    .foregroundStyle(Palette.hull)
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

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: report.failed.isEmpty ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 22))
                .foregroundStyle(report.failed.isEmpty ? Palette.mintText : Palette.warningText)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(ByteFormat.string(report.freedBytes)) temizlendi")
                    .font(.keel(15, .bold))
                    .foregroundStyle(Palette.hull)
                Text(detail)
                    .font(.keel(13, .medium))
                    .foregroundStyle(Palette.slate)
            }
            Spacer()
        }
        .keelCard(padding: 18, radius: 16, fill: Palette.mint)
    }

    private var detail: String {
        var parts = ["\(report.removed.count) öğe kaldırıldı"]
        if !report.skipped.isEmpty { parts.append("\(report.skipped.count) öğe güvenlik nedeniyle atlandı") }
        if !report.failed.isEmpty { parts.append("\(report.failed.count) öğe kaldırılamadı") }
        return parts.joined(separator: " · ")
    }
}
