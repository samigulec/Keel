import AppKit
import KeelCore
import SwiftUI

/// What slows the Mac down and what starts on its own: heavy apps, apps
/// that open at login and background services. One list at a time, picked
/// with the tiles at the top.
struct OptimizationView: View {
    @Environment(PerformanceModel.self) private var model
    @Environment(\.compactLayout) private var compact
    @AppStorage("keel.optimization.tab") private var tab: Tab = .heavy
    @AppStorage("keel.loginItems.allowed") private var loginItemsAllowed = false

    enum Tab: String {
        case heavy, login, services
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            PageHeader(
                title: "Optimizasyon",
                subtitle: "Mac'i yavaşlatan uygulamalar, girişte açılanlar ve arka planda kendiliğinden çalışan servisler."
            )

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 3), spacing: 14) {
                tile(.heavy, title: "Yoğun uygulamalar", value: heaviestValue, detail: heaviestDetail, mascot: .zip)
                tile(
                    .login, title: "Girişte açılan",
                    value: model.loginItemsLoaded ? "\(model.loginItems.count)" : "—",
                    detail: model.loginItemsLoaded ? "uygulama" : "listelemek için izin gerekir",
                    mascot: .kee
                )
                tile(
                    .services, title: "Arka plan",
                    value: model.launchItemsLoaded ? "\(model.activeLaunchItems.count)" : "—",
                    detail: "kendiliğinden başlayan servis",
                    mascot: .roket
                )
            }

            switch tab {
            case .heavy:
                HeavyAppsCard(model: model)
            case .login:
                LoginItemsCard(model: model)
            case .services:
                LaunchItemsCard(
                    items: model.launchItems,
                    activeCount: model.activeLaunchItems.count,
                    loaded: model.launchItemsLoaded,
                    switching: model.switchingItems,
                    message: model.startupMessage,
                    reload: { Task { await model.refreshLaunchItems() } },
                    toggle: { item, enabled in Task { await model.setLaunchItems([item], enabled: enabled) } }
                )
            }
        }
        .task {
            await model.refreshLaunchItems()
            if loginItemsAllowed, !model.loginItemsLoaded { await model.refreshLoginItems() }
        }
        .task {
            // Per-app memory is only worth measuring while someone is looking.
            while !Task.isCancelled {
                await model.refreshApps()
                try? await Task.sleep(for: .seconds(4))
            }
        }
    }

    private var heaviestValue: String {
        model.topApps.first.map { ByteFormat.string(Int64(clamping: $0.footprintBytes), base: .binary) } ?? "—"
    }

    private var heaviestDetail: String {
        model.topApps.first.map { "en çok: \($0.name)" } ?? "ölçülüyor…"
    }

    private func tile(_ target: Tab, title: String, value: String, detail: String, mascot: Mascot.Character) -> some View {
        let isOn = tab == target
        return Button {
            tab = target
        } label: {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title).eyebrowStyle(color: isOn ? Palette.Sidebar.eyebrow : Palette.slate)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(value)
                        .font(.keelMono(compact ? 22 : 28, .semibold))
                        .tracking(-1.5)
                        .foregroundStyle(Palette.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text(detail)
                        .font(.keel(12, .medium))
                        .foregroundStyle(isOn ? Palette.Sidebar.text : Palette.slate)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .layoutPriority(1)
                Spacer(minLength: 0)
                if !compact { Mascot(character: mascot, size: 30) }
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

// MARK: - Lists

/// The apps holding the most memory, with a button to quit each.
private struct HeavyAppsCard: View {
    let model: PerformanceModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ListHeader(title: "En çok bellek kullananlar", detail: "Yardımcı süreçler dahil")
            if model.topApps.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                ForEach(model.topApps) { app in
                    HStack(spacing: 14) {
                        if let icon = app.icon {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 28, height: 28)
                                .accessibilityHidden(true)
                        }
                        Text(app.name)
                            .font(.keel(15, .semibold))
                            .foregroundStyle(Palette.text)
                            .lineLimit(1)
                        Spacer(minLength: 12)
                        ByteAmount(bytes: Int64(clamping: app.footprintBytes), size: 14, base: .binary)
                            .fixedSize()
                        if app.id != ProcessInfo.processInfo.processIdentifier {
                            Button("Kapat") { model.quit(app) }
                                .buttonStyle(TileButtonStyle())
                                .help("\(app.name) uygulamasından çık; kaydedilmemiş işin varsa önce sorar")
                        }
                    }
                    .padding(.horizontal, 24)
                    .frame(minHeight: 52)
                    .overlay(alignment: .top) { Divider().overlay(Palette.divider) }
                }
            }
            Text("Bir uygulamadan çıkmak kullandığı belleği hemen boşaltır. Bellek kullanımı tek başına sorun değildir; asıl önemli olan bellek baskısıdır.")
                .font(.keel(11, .medium))
                .foregroundStyle(Palette.slate)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
        }
        .padding(.bottom, 8)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Palette.border) }
    }
}

private struct LaunchItemsCard: View {
    let items: [LaunchItem]
    let activeCount: Int
    let loaded: Bool
    let switching: Set<String>
    let message: String?
    let reload: @MainActor () -> Void
    let toggle: @MainActor (LaunchItem, Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ListHeader(title: "Arka plan servisleri", detail: "\(activeCount) tanesi kendiliğinden başlıyor") {
                Button("Yenile", action: reload)
                    .buttonStyle(.plain)
                    .font(.keel(13, .bold))
                    .foregroundStyle(Palette.mintText)
            }
            if let message {
                Text(message)
                    .font(.keel(12, .medium))
                    .foregroundStyle(Palette.warningText)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 10)
            }
            if !loaded {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else if items.isEmpty {
                Text("Kendiliğinden başlayan servis bulunamadı.")
                    .font(.keel(14, .medium))
                    .foregroundStyle(Palette.slate)
                    .padding(24)
            } else {
                ForEach(items) { item in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.displayName)
                                .font(.keel(15, .semibold))
                                .foregroundStyle(item.isDisabled ? Palette.slate : Palette.text)
                                .lineLimit(1)
                            HStack(spacing: 4) {
                                if LaunchControl.needsAdministrator(item) {
                                    Image(systemName: "lock.fill").font(.system(size: 9, weight: .bold))
                                }
                                Text("\(scopeText(item.scope)) · \(stateText(item))")
                                    .lineLimit(1)
                            }
                            .font(.keel(12, .medium))
                            .foregroundStyle(Palette.slate)
                        }
                        Spacer(minLength: 12)
                        control(for: item)
                    }
                    .padding(.horizontal, 24)
                    .frame(minHeight: 52)
                    .overlay(alignment: .top) { Divider().overlay(Palette.divider) }
                    .help(item.program ?? item.url.path)
                }
            }
            Text("Kapattığın servis Mac yeniden başlasa da kapalı kalır; anahtarı açınca geri gelir. Kilitli olanlar yönetici şifresi ister.")
                .font(.keel(11, .medium))
                .foregroundStyle(Palette.slate)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 24)
                .padding(.top, 10)
            Button("Uygulamaların açılış ayarları", action: PerformanceModel.openLoginItemsSettings)
                .buttonStyle(.plain)
                .font(.keel(13, .bold))
                .foregroundStyle(Palette.mintText)
                .padding(.horizontal, 24)
                .frame(minHeight: 44)
        }
        .padding(.bottom, 8)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Palette.border) }
    }

    @ViewBuilder
    private func control(for item: LaunchItem) -> some View {
        if let refusal = LaunchControl.refusal(for: item) {
            Pill(text: "macOS", background: Palette.track, foreground: Palette.slate)
                .help("Keel bunu değiştirmez: \(refusal).")
        } else if switching.contains(item.id) {
            ProgressView().controlSize(.small)
        } else {
            Toggle("", isOn: Binding(get: { !item.isDisabled }, set: { toggle(item, $0) }))
                .toggleStyle(.switch)
                .controlSize(.small)
                .labelsHidden()
                .tint(Palette.keelGreen)
                .disabled(!switching.isEmpty)
                .accessibilityLabel("\(item.displayName) \(item.isDisabled ? "kapalı" : "açık")")
        }
    }

    private func scopeText(_ scope: LaunchItem.Scope) -> String {
        switch scope {
        case .user: "Senin hesabın"
        case .allUsers: "Tüm kullanıcılar"
        case .system: "Sistem"
        }
    }

    private func stateText(_ item: LaunchItem) -> String {
        if item.isDisabled { return "kapalı" }
        if item.keepsAlive { return "sürekli çalışır" }
        if item.runsAtLoad { return "açılışta başlar" }
        return "gerektiğinde"
    }
}

/// Apps that open when the user logs in ("Open at Login").
private struct LoginItemsCard: View {
    let model: PerformanceModel
    /// Reading the list asks once for permission to use System Events.
    @AppStorage("keel.loginItems.allowed") private var allowed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ListHeader(title: "Oturum açılışında", detail: model.loginItemsLoaded ? "\(model.loginItems.count) uygulama açılıyor" : "") {
                if model.loginItemsLoaded {
                    Button("Yenile") { Task { await model.refreshLoginItems() } }
                        .buttonStyle(.plain)
                        .font(.keel(13, .bold))
                        .foregroundStyle(Palette.mintText)
                }
            }
            if let error = model.loginItemsError {
                Text(error)
                    .font(.keel(12, .medium))
                    .foregroundStyle(Palette.warningText)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 10)
            }
            if !model.loginItemsLoaded {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Mac'e giriş yaptığında kendiliğinden açılan uygulamalar. Keel listeyi okumak için bir kez System Events izni ister.")
                        .font(.keel(13, .medium))
                        .foregroundStyle(Palette.slate)
                        .fixedSize(horizontal: false, vertical: true)
                    Button("Listeyi göster") {
                        allowed = true
                        Task { await model.refreshLoginItems() }
                    }
                    .buttonStyle(TileButtonStyle(prominent: true))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            } else if model.loginItems.isEmpty, model.removedLoginItems.isEmpty {
                Text("Girişte açılan uygulama yok.")
                    .font(.keel(14, .medium))
                    .foregroundStyle(Palette.slate)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
            } else {
                ForEach(model.loginItems) { item in
                    row(item.name, detail: item.path.isEmpty ? nil : URL(fileURLWithPath: item.path).deletingLastPathComponent().path) {
                        Button("Kaldır") { Task { await model.removeLoginItem(item) } }
                            .buttonStyle(TileButtonStyle())
                    }
                }
                ForEach(model.removedLoginItems) { item in
                    row(item.name, detail: "Girişte açılmayacak", dimmed: true) {
                        if LoginItemScript.add(item) != nil {
                            Button("Geri ekle") { Task { await model.restoreLoginItem(item) } }
                                .buttonStyle(TileButtonStyle())
                        }
                    }
                }
            }
        }
        .padding(.bottom, 8)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Palette.border) }
    }

    private func row<Accessory: View>(_ name: String, detail: String?, dimmed: Bool = false, @ViewBuilder accessory: () -> Accessory) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.keel(15, .semibold))
                    .foregroundStyle(dimmed ? Palette.slate : Palette.text)
                    .lineLimit(1)
                if let detail {
                    Text(detail)
                        .font(.keel(12, .medium))
                        .foregroundStyle(Palette.slate)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            Spacer(minLength: 12)
            accessory()
        }
        .padding(.horizontal, 24)
        .frame(minHeight: 52)
        .overlay(alignment: .top) { Divider().overlay(Palette.divider) }
    }
}

private struct ListHeader<Accessory: View>: View {
    let title: String
    let detail: String
    @ViewBuilder var accessory: Accessory

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title)
                .font(.keel(18, .extraBold))
                .foregroundStyle(Palette.text)
            Text(detail)
                .font(.keel(13, .medium))
                .foregroundStyle(Palette.slate)
            Spacer()
            accessory
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }
}

extension ListHeader where Accessory == EmptyView {
    init(title: String, detail: String) {
        self.init(title: title, detail: detail) { EmptyView() }
    }
}
