import SwiftUI

struct RootView: View {
    @State private var selection: AppSection = .smartScan

    var body: some View {
        HStack(spacing: 0) {
            Sidebar(selection: $selection)
                .frame(width: 244)

            ScrollView {
                detail
                    .padding(.horizontal, 48)
                    .padding(.top, 40)
                    .padding(.bottom, 48)
                    .frame(maxWidth: 1100, alignment: .leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Palette.mist)
        }
        .ignoresSafeArea()
        .preferredColorScheme(.light)
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
