import AppKit
import SwiftUI

struct RootView: View {
    @Environment(AssistantModel.self) private var assistant
    @Environment(ApplicationsModel.self) private var applications
    @Environment(CleanupModel.self) private var cleanup
    @Environment(LargeFilesModel.self) private var largeFiles
    @Environment(SmartCareModel.self) private var smartCare
    @Environment(AppNavigation.self) private var navigation
    @Environment(\.openSettings) private var openSettings
    @AppStorage(Preference.companionButtonVisible) private var companionButtonVisible = true
    /// Keel AI beside the current screen; remembered between launches.
    @AppStorage("keel.companion.open") private var companionOpen = false
    @State private var contentWidth: CGFloat = 1_000
    @State private var commandPaletteOpen = false

    var body: some View {
        @Bindable var navigation = navigation
        HStack(spacing: 0) {
            Sidebar(selection: $navigation.selection)
                .frame(width: 228)

            VStack(spacing: 0) {
                TopUtilityBar(
                    section: navigation.selection,
                    companionOpen: companionOpen,
                    companionRunning: assistant.isRunning,
                    showCompanionToggle: companionButtonVisible && navigation.selection != .assistant,
                    openPalette: { withAnimation(.easeOut(duration: 0.14)) { commandPaletteOpen = true } },
                    toggleCompanion: { toggleCompanion() }
                )

                HStack(spacing: 0) {
                    Group {
                        if navigation.selection == .assistant {
                            AssistantView()
                                .padding(.horizontal, 28)
                                .padding(.top, 20)
                                .padding(.bottom, 24)
                        } else {
                            ScrollView {
                                detail
                                    .padding(.horizontal, 32)
                                    .padding(.top, 22)
                                    .padding(.bottom, 36)
                                    .frame(maxWidth: 1080, alignment: .leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { contentWidth = $0 }
                    .environment(\.compactLayout, contentWidth < 860)

                    if companionOpen, navigation.selection != .assistant {
                        CompanionPanel(
                            section: navigation.selection,
                            suggestions: CompanionContext.suggestions(for: navigation.selection, applications: applications, cleanup: cleanup),
                            openFull: {
                                companionOpen = false
                                navigation.selection = .assistant
                            },
                            close: { toggleCompanion() }
                        )
                        .frame(width: 368)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background { KeelBackground() }
        .overlay {
            if commandPaletteOpen {
                CommandPalette(commands: paletteCommands) {
                    withAnimation(.easeOut(duration: 0.12)) { commandPaletteOpen = false }
                }
                .transition(.opacity)
            }
        }
        .background {
            // Hidden keyboard triggers so ⌘K and ⌘J always work regardless of button visibility.
            Group {
                Button("") {
                    withAnimation(.easeOut(duration: 0.14)) { commandPaletteOpen.toggle() }
                }
                .keyboardShortcut("k", modifiers: .command)

                Button("") { toggleCompanion() }
                    .keyboardShortcut("j", modifiers: .command)
            }
            .opacity(0)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
        .ignoresSafeArea()
        .modifier(CleanupConfirmation())
        .onChange(of: screen, initial: true) { _, screen in
            assistant.screen = screen
        }
        .tint(Palette.keelGreen)
        .preferredColorScheme(.dark)
    }

    /// What Keel AI should know about the screen; none on its own tab.
    private var screen: ScreenContext? {
        guard navigation.selection != .assistant else { return nil }
        return CompanionContext.screen(for: navigation.selection, applications: applications, cleanup: cleanup, largeFiles: largeFiles)
    }

    private func toggleCompanion() {
        withAnimation(.easeOut(duration: 0.18)) { companionOpen.toggle() }
    }

    private var paletteCommands: [CommandPalette.Command] {
        let navCommands = AppSection.allCases.enumerated().map { index, section in
            CommandPalette.Command(
                id: "nav-\(section.id)",
                title: section.title,
                subtitle: sectionSubtitle(section),
                symbol: section.symbolName,
                tint: section.accentColor,
                shortcut: "⌘\(index + 1)",
                run: { navigation.selection = section }
            )
        }

        let actions: [CommandPalette.Command] = [
            CommandPalette.Command(
                id: "act-smart-scan",
                title: "Akıllı Taramayı Başlat",
                subtitle: "Alan, uygulamalar, büyük dosyalar ve sistem sağlığını tara",
                symbol: "play.fill",
                tint: Palette.keelGreen,
                shortcut: nil,
                run: {
                    navigation.selection = .smartScan
                    smartCare.run()
                }
            ),
            CommandPalette.Command(
                id: "act-cleanup-scan",
                title: "Temizlik Taraması Yap",
                subtitle: "Önbellek, günlük ve tarayıcı dosyalarını yeniden tara",
                symbol: "arrow.clockwise",
                tint: Palette.info,
                shortcut: nil,
                run: {
                    navigation.selection = .cleanup
                    cleanup.scan()
                }
            ),
            CommandPalette.Command(
                id: "act-companion",
                title: companionOpen ? "Keel AI Panelini Kapat" : "Keel AI Panelini Aç",
                subtitle: "Bulunduğun ekranın yanında yapay zeka paneli",
                symbol: "wand.and.stars",
                tint: Color(hex: 0xA78BFA),
                shortcut: "⌘J",
                run: { toggleCompanion() }
            ),
            CommandPalette.Command(
                id: "act-settings",
                title: "Ayarları Aç",
                subtitle: "Başlangıç, menü çubuğu, fan yardımcısı ve gizlilik",
                symbol: "gearshape",
                tint: Palette.slate,
                shortcut: "⌘,",
                run: { openSettings() }
            ),
            CommandPalette.Command(
                id: "act-logs",
                title: "Kayıt Klasörünü Finder'da Göster",
                subtitle: "~/Library/Logs/Keel işlem kayıtları",
                symbol: "doc.text.magnifyingglass",
                tint: Palette.slate,
                shortcut: nil,
                run: {
                    let logs = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Logs/Keel", isDirectory: true)
                    NSWorkspace.shared.open(FileManager.default.fileExists(atPath: logs.path) ? logs : logs.deletingLastPathComponent())
                }
            ),
        ]
        return navCommands + actions
    }

    private func sectionSubtitle(_ section: AppSection) -> String {
        switch section {
        case .smartScan: "Tek tıkla sistem sağlığı ve bakım özeti"
        case .cleanup: "Önbellekler, eski günlükler ve Çöp Kutusu"
        case .performance: "Canlı CPU, GPU, bellek, ağ, sıcaklık ve fanlar"
        case .optimization: "Yoğun uygulamalar, giriş öğeleri ve arka plan servisleri"
        case .applications: "Uygulama kaldırıcı ve sıfırlama"
        case .largeFiles: "Büyük ve uzun süredir açılmamış dosyalar"
        case .assistant: "Tam ekran Keel AI sohbeti"
        }
    }

    @ViewBuilder
    private var detail: some View {
        switch navigation.selection {
        case .smartScan:
            SmartScanView(navigate: { navigation.selection = $0 })
        case .cleanup:
            CleanupView()
        case .performance:
            PerformanceView()
        case .optimization:
            OptimizationView()
        case .applications:
            ApplicationsView()
        case .largeFiles:
            LargeFilesView()
        case .assistant:
            EmptyView()
        }
    }
}

/// Integrated desktop header bar replacing the floating bottom-right orb.
private struct TopUtilityBar: View {
    let section: AppSection
    let companionOpen: Bool
    let companionRunning: Bool
    let showCompanionToggle: Bool
    let openPalette: () -> Void
    let toggleCompanion: () -> Void

    @State private var searchHovered = false
    @State private var aiHovered = false

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: section.symbolName)
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(section.accentColor)
                Text(section.title)
                    .font(.keel(13, .bold))
                    .foregroundStyle(Palette.subtle)
            }

            Spacer(minLength: 12)

            Button(action: openPalette) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundStyle(Palette.slate)
                    Text("Hızlı ara…")
                        .font(.keel(12, .medium))
                        .foregroundStyle(Palette.slate)
                    Spacer(minLength: 18)
                    ShortcutCap(text: "⌘K")
                }
                .padding(.horizontal, 10)
                .frame(width: 210, height: 28)
                .background(searchHovered ? Palette.mistHover : Palette.mist, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(searchHovered ? Color.white.opacity(0.18) : Palette.border, lineWidth: 1)
                }
                .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
            .onHover { searchHovered = $0 }
            .help("Komut paletini aç (⌘K)")

            if showCompanionToggle {
                Button(action: toggleCompanion) {
                    HStack(spacing: 6) {
                        if companionRunning {
                            ProgressView().controlSize(.mini)
                        } else {
                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 11.5, weight: .semibold))
                                .foregroundStyle(companionOpen ? Color(hex: 0xC4B5FD) : Color(hex: 0xA78BFA))
                        }
                        Text("Keel AI")
                            .font(.keel(12, .bold))
                            .foregroundStyle(companionOpen ? Palette.text : Palette.subtle)
                        ShortcutCap(text: "⌘J")
                    }
                    .padding(.horizontal, 10)
                    .frame(height: 28)
                    .background(
                        companionOpen
                            ? Color(hex: 0x8B5CF6).opacity(0.20)
                            : (aiHovered ? Palette.mistHover : Palette.mist),
                        in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(
                                companionOpen
                                    ? Color(hex: 0xA78BFA).opacity(0.45)
                                    : (aiHovered ? Color.white.opacity(0.18) : Palette.border),
                                lineWidth: 1
                            )
                    }
                    .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .onHover { aiHovered = $0 }
                .help(companionOpen ? "Keel AI panelini kapat (⌘J)" : "Keel AI panelini aç (⌘J)")
            }
        }
        .padding(.horizontal, 24)
        .frame(height: 46)
        .background(Color(hex: 0x0B1018).opacity(0.75))
        .overlay(alignment: .bottom) {
            Rectangle().fill(Palette.divider).frame(height: 1)
        }
    }
}
