import SwiftUI

struct RootView: View {
    @Environment(AssistantModel.self) private var assistant
    @Environment(ApplicationsModel.self) private var applications
    @Environment(CleanupModel.self) private var cleanup
    @Environment(LargeFilesModel.self) private var largeFiles
    @Environment(AppNavigation.self) private var navigation
    @AppStorage(Preference.companionButtonVisible) private var companionButtonVisible = true
    /// Keel AI beside the current screen; remembered between launches.
    @AppStorage("keel.companion.open") private var companionOpen = false
    @State private var contentWidth: CGFloat = 1_000

    var body: some View {
        @Bindable var navigation = navigation
        HStack(spacing: 0) {
            Sidebar(selection: $navigation.selection)
                .frame(width: 244)

            Group {
                if navigation.selection == .assistant {
                    // The chat scrolls its own messages and keeps the input bar in view.
                    AssistantView()
                        .padding(.horizontal, 40)
                        .padding(.top, 40)
                        .padding(.bottom, 32)
                } else {
                    ScrollView {
                        detail
                            .padding(.horizontal, 48)
                            .padding(.top, 40)
                            // Room to scroll the last row clear of the Keel AI button.
                            .padding(.bottom, 110)
                            .frame(maxWidth: 1100, alignment: .leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .overlay(alignment: .bottomTrailing) {
                        // The open panel has its own close button.
                        if !companionOpen, companionButtonVisible {
                            CompanionButton(isOpen: false) { toggleCompanion() }
                                .padding(24)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { contentWidth = $0 }
            .environment(\.compactLayout, contentWidth < 900)

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
                .padding(.top, 28) // clears the window's traffic lights row
                .frame(width: 380)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .background { KeelBackground() }
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
        withAnimation(.easeOut(duration: 0.2)) { companionOpen.toggle() }
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
            // Shown on its own above, outside the scroll view.
            EmptyView()
        }
    }
}
