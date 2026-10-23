import SwiftUI

struct RootView: View {
    @Environment(AssistantModel.self) private var assistant
    @Environment(ApplicationsModel.self) private var applications
    @Environment(CleanupModel.self) private var cleanup
    @State private var selection: AppSection = .smartScan
    /// Keel AI beside the current screen; remembered between launches.
    @AppStorage("keel.companion.open") private var companionOpen = false

    var body: some View {
        HStack(spacing: 0) {
            Sidebar(selection: $selection)
                .frame(width: 244)

            Group {
                if selection == .assistant {
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
                        CompanionButton(isOpen: companionOpen) { toggleCompanion() }
                            .padding(24)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if companionOpen, selection != .assistant {
                CompanionPanel(
                    section: selection,
                    suggestions: CompanionContext.suggestions(for: selection, applications: applications, cleanup: cleanup),
                    openFull: {
                        companionOpen = false
                        selection = .assistant
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
        guard selection != .assistant else { return nil }
        return CompanionContext.screen(for: selection, applications: applications, cleanup: cleanup)
    }

    private func toggleCompanion() {
        withAnimation(.easeOut(duration: 0.2)) { companionOpen.toggle() }
    }

    @ViewBuilder
    private var detail: some View {
        switch selection {
        case .smartScan:
            SmartScanView(openCleanup: { selection = .cleanup })
        case .cleanup:
            CleanupView()
        case .performance:
            PerformanceView()
        case .applications:
            ApplicationsView()
        default:
            ComingSoonView(section: selection)
        }
    }
}
