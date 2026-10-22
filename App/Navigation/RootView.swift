import SwiftUI

struct RootView: View {
    @State private var selection: AppSection = .smartScan

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
                            .padding(.bottom, 48)
                            .frame(maxWidth: 1100, alignment: .leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background { KeelBackground() }
        .ignoresSafeArea()
        .tint(Palette.keelGreen)
        .preferredColorScheme(.dark)
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
        default:
            ComingSoonView(section: selection)
        }
    }
}
