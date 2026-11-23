import KeelCore
import SwiftUI

/// CleanMyMac Smart Care-inspired centered stage: orbital health gauge,
/// signature pill CTA, glanceable Sensei ring bento tiles, and actionable findings.
struct SmartScanView: View {
    var navigate: (AppSection) -> Void
    @Environment(SmartCareModel.self) private var care
    @Environment(ApplicationsModel.self) private var applications
    @Environment(LargeFilesModel.self) private var largeFiles
    @Environment(SystemStatus.self) private var status
    @Environment(\.compactLayout) private var compact
    @State private var confirmingClean = false

    var body: some View {
        VStack(alignment: .leading, spacing: 26) {
            heroStage

            if care.isRunning {
                scanStepsRail
            } else if !care.findings.isEmpty {
                findingsGrid
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Canlı Sistem Özeti").eyebrowStyle()
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 14, alignment: .top), count: compact ? 2 : 4),
                    spacing: 14
                ) {
                    storageTile
                    memoryTile
                    cpuTile
                    temperatureTile
                }
            }
        }
        .onAppear { if !care.isRunning, care.lastRun != nil { care.evaluate() } }
        .confirmationDialog(
            "\(ByteFormat.string(care.recommendedBytes)) temizlensin mi?",
            isPresented: $confirmingClean,
            titleVisibility: .visible
        ) {
            Button("Temizle") { Task { await care.cleanRecommended() } }
            Button("Vazgeç", role: .cancel) {}
        } message: {
            Text("Önerilen kategoriler (önbellekler, günlükler, tarayıcı önbellekleri) Çöp Kutusu'na taşınır; Temizlik ekranından geri alabilirsin.")
        }
    }

    // MARK: - Centered Hero Stage (CleanMyMac Smart Care signature)

    private var heroStage: some View {
        VStack(spacing: 18) {
            if let lastRun = care.lastRun, !care.isRunning {
                Pill(
                    text: "Son tarama · \(lastRun.formatted(date: .omitted, time: .shortened))",
                    background: scoreAccent.opacity(0.14),
                    foreground: scoreAccent
                )
            } else if care.isRunning {
                Pill(
                    text: "Sistem taranıyor · \(care.finished.count)/\(SmartCareModel.Step.allCases.count)",
                    background: Palette.info.opacity(0.14),
                    foreground: Palette.info
                )
            } else {
                Pill(text: "Akıllı Bakım", background: Palette.mint, foreground: Palette.mintText)
            }

            OrbitalScoreRing(
                score: care.score,
                isRunning: care.isRunning,
                progress: Double(care.finished.count) / Double(SmartCareModel.Step.allCases.count)
            )
            .frame(width: 188, height: 188)

            VStack(spacing: 8) {
                Text(headline)
                    .font(.keel(24, .extraBold))
                    .tracking(-0.5)
                    .foregroundStyle(Palette.text)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 560)

                Text(subheadline)
                    .font(.keel(13.5, .medium))
                    .foregroundStyle(Palette.slate)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2.5)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 520)
            }

            HStack(spacing: 12) {
                if care.lastRun != nil, !care.isRunning, care.recommendedBytes >= 100_000_000 {
                    Button {
                        confirmingClean = true
                    } label: {
                        Label("Önerilenleri Temizle · \(ByteFormat.string(care.recommendedBytes))", systemImage: "sparkles")
                    }
                    .buttonStyle(.keelHeroPill)

                    Button("Yeniden Tara", action: care.run)
                        .buttonStyle(.keelSecondary)
                } else {
                    Button(action: care.run) {
                        Label(
                            care.isRunning
                                ? "Taranıyor…"
                                : (care.lastRun == nil ? "Akıllı Taramayı Başlat" : "Yeniden Tara"),
                            systemImage: care.isRunning ? "hourglass" : "sparkle.magnifyingglass"
                        )
                    }
                    .buttonStyle(.keelHeroPill)
                    .disabled(care.isRunning)
                }
            }
            .padding(.top, 4)

            if care.lastRun == nil, !care.isRunning {
                HStack(spacing: 18) {
                    trustChip(symbol: "eye", text: "Yalnızca okur")
                    trustChip(symbol: "trash", text: "Çöp Kutusu'na taşır")
                    trustChip(symbol: "hand.raised.fill", text: "Onaysız silmez")
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 30)
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Palette.card)
                RadialGradient(
                    colors: [scoreAccent.opacity(care.isRunning ? 0.20 : 0.14), .clear],
                    center: .top,
                    startRadius: 10,
                    endRadius: 340
                )
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Palette.borderHighlight, lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.24), radius: 22, y: 10)
    }

    private func trustChip(symbol: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Palette.mintText)
            Text(text)
                .font(.keel(12, .semibold))
                .foregroundStyle(Palette.slate)
        }
    }

    private var scoreAccent: Color {
        guard let score = care.score else { return Palette.keelGreen }
        switch score {
        case 85...: return Palette.keelGreen
        case 65..<85: return Palette.warningText
        default: return Palette.danger
        }
    }

    private var headline: String {
        if care.isRunning { return "Mac'in kapsamlı kontrol ediliyor…" }
        guard let score = care.score else {
            return "Mac'ine tek tıkla bakım yap"
        }
        let actionable = care.findings.filter { $0.severity >= .attention }.count
        switch score {
        case 90...: return actionable == 0 ? "Mac'in harika durumda." : "Mac'in iyi durumda; \(actionable) öneri var."
        case 70..<90: return "Mac'in fena değil; \(max(actionable, 1)) konu ilgini bekliyor."
        default: return "Mac'in bakım istiyor; \(max(actionable, 1)) önemli bulgu var."
        }
    }

    private var subheadline: String {
        if care.isRunning {
            return "Önbellekler, uygulamalar, büyük dosyalar ve canlı donanım sağlığı paralel olarak ölçülüyor."
        }
        if care.lastRun == nil {
            return "Neyin yer kapladığını, neyin yavaşlattığını ve neyin güvenle temizlenebileceğini tek taramada gör."
        }
        return "Tarama yalnızca okur. Hiçbir şey sen onaylamadan silinmez; silinenler Çöp Kutusu'na gider ve geri alınabilir."
    }

    // MARK: - Scan Steps Rail & Findings

    private var scanStepsRail: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: compact ? 2 : 4),
            spacing: 12
        ) {
            ForEach(SmartCareModel.Step.allCases, id: \.self) { step in
                let done = care.finished.contains(step)
                HStack(spacing: 10) {
                    if done {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Palette.keelGreen)
                    } else {
                        ProgressView().controlSize(.small)
                    }
                    Text(step.title)
                        .font(.keel(13, .semibold))
                        .foregroundStyle(done ? Palette.text : Palette.slate)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 14)
                .frame(height: 44)
                .background(
                    done ? Palette.mint : Palette.card,
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(done ? Palette.keelGreen.opacity(0.32) : Palette.border, lineWidth: 1)
                }
            }
        }
    }

    private var findingsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Tarama Bulguları").eyebrowStyle()
                Spacer()
                Text("\(care.findings.count) kalem")
                    .font(.keelMono(11, .medium))
                    .foregroundStyle(Palette.muted)
            }
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 14, alignment: .top), count: compact ? 1 : 2),
                spacing: 14
            ) {
                ForEach(care.findings) { finding in
                    FindingCard(finding: finding) { perform(finding.action) }
                }
            }
        }
    }

    private func perform(_ action: CareFinding.Action?) {
        switch action {
        case .cleanRecommended: confirmingClean = true
        case .open(let section): navigate(section)
        case .unusedApps:
            applications.filter = .unused
            navigate(.applications)
        case .oldFiles:
            largeFiles.age = .oneYear
            largeFiles.place = .personal
            navigate(.largeFiles)
        case nil: break
        }
    }

    // MARK: - Sensei-Style Live Bento Tiles

    private var storageTile: some View {
        let used = status.disk?.usedFraction ?? 0
        let tint = used > 0.88 ? Palette.warning : Color(hex: 0x38BDF8)
        return Button { navigate(.cleanup) } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center) {
                    Text("Depolama").eyebrowStyle()
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Palette.muted)
                }
                HStack(spacing: 14) {
                    CircularGauge(
                        fraction: used,
                        tint: tint,
                        secondaryTint: used > 0.88 ? Palette.danger : Palette.keelGreen,
                        lineWidth: 5.5,
                        size: 52,
                        centerText: status.disk.map { "%\(Int(($0.usedFraction * 100).rounded()))" } ?? "—"
                    )
                    VStack(alignment: .leading, spacing: 2) {
                        ByteAmount(bytes: status.disk?.availableBytes, size: 19)
                        Text("boş alan")
                            .font(.keel(12, .medium))
                            .foregroundStyle(Palette.slate)
                    }
                    Spacer(minLength: 0)
                }
            }
            .keelInteractiveCard(padding: 16, radius: 16, accent: tint)
        }
        .buttonStyle(.plain)
    }

    private var memoryTile: some View {
        let used = status.memory?.usedFraction ?? 0
        let tint: Color = switch status.memory?.pressure {
        case .critical: Palette.danger
        case .warning: Palette.warning
        default: Palette.keelGreen
        }
        return Button { navigate(.performance) } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center) {
                    Text("Bellek (RAM)").eyebrowStyle()
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Palette.muted)
                }
                HStack(spacing: 14) {
                    CircularGauge(
                        fraction: used,
                        tint: tint,
                        secondaryTint: Palette.info,
                        lineWidth: 5.5,
                        size: 52,
                        centerText: status.memory.map { "%\(Int(($0.usedFraction * 100).rounded()))" } ?? "—"
                    )
                    VStack(alignment: .leading, spacing: 2) {
                        ByteAmount(bytes: status.memory.map { Int64($0.usedBytes) }, size: 19, base: .binary)
                        Text(status.memory.map(memoryPressureLabel) ?? "Ölçülüyor…")
                            .font(.keel(12, .medium))
                            .foregroundStyle(Palette.slate)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                }
            }
            .keelInteractiveCard(padding: 16, radius: 16, accent: tint)
        }
        .buttonStyle(.plain)
    }

    private var cpuTile: some View {
        let usage = status.cpuUsage ?? 0
        let tint = usage > 0.8 ? Palette.warning : Color(hex: 0xA78BFA)
        return Button { navigate(.performance) } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center) {
                    Text("İşlemci").eyebrowStyle()
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Palette.muted)
                }
                HStack(spacing: 14) {
                    CircularGauge(
                        fraction: usage,
                        tint: tint,
                        secondaryTint: Color(hex: 0x6366F1),
                        lineWidth: 5.5,
                        size: 52,
                        centerText: status.cpuUsage.map { "%\(Int(($0 * 100).rounded()))" } ?? "—"
                    )
                    VStack(alignment: .leading, spacing: 2) {
                        Text(usage > 0.8 ? "Yoğun" : "Rahat")
                            .font(.keel(17, .bold))
                            .foregroundStyle(Palette.text)
                        Text("\(status.info.logicalCores) çekirdek")
                            .font(.keel(12, .medium))
                            .foregroundStyle(Palette.slate)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                }
            }
            .keelInteractiveCard(padding: 16, radius: 16, accent: tint)
        }
        .buttonStyle(.plain)
    }

    private var temperatureTile: some View {
        let cpu = status.thermals?.summary(.cpu)?.hottest ?? status.thermals?.summaries.map(\.hottest).max()
        let tint = cpu.map(Thermal.color) ?? Palette.keelGreen
        let fraction = min(max((cpu ?? 0) / 105.0, 0), 1)
        return Button { navigate(.performance) } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center) {
                    Text("Sıcaklık").eyebrowStyle()
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Palette.muted)
                }
                HStack(spacing: 14) {
                    CircularGauge(
                        fraction: fraction,
                        tint: tint,
                        secondaryTint: tint.opacity(0.7),
                        lineWidth: 5.5,
                        size: 52,
                        centerText: cpu.map { "\(Int($0.rounded()))°" } ?? "—"
                    )
                    VStack(alignment: .leading, spacing: 2) {
                        Text(cpu.map(Thermal.degrees) ?? "—")
                            .font(.keelMono(18, .semibold))
                            .foregroundStyle(Palette.text)
                        Text(cpu.map { Thermal.state($0) } ?? "Sensörler…")
                            .font(.keel(12, .medium))
                            .foregroundStyle(Palette.slate)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                }
            }
            .keelInteractiveCard(padding: 16, radius: 16, accent: tint)
        }
        .buttonStyle(.plain)
    }

    private func memoryPressureLabel(_ memory: MemorySnapshot) -> String {
        switch memory.pressure {
        case .normal: "Baskı normal"
        case .warning: "Baskı yüksek"
        case .critical: "Baskı kritik"
        }
    }
}

/// CleanMyMac-inspired luminous orbital health & scan gauge.
private struct OrbitalScoreRing: View {
    let score: Int?
    let isRunning: Bool
    let progress: Double

    @State private var sweepAngle: Double = 0

    var body: some View {
        ZStack {
            // Soft outer halo
            Circle()
                .fill(
                    RadialGradient(
                        colors: [ringColor.opacity(isRunning ? 0.22 : 0.14), .clear],
                        center: .center,
                        startRadius: 48,
                        endRadius: 96
                    )
                )

            // Concentric radar orbit rings
            Circle()
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
                .padding(4)
            Circle()
                .stroke(Palette.track, lineWidth: 12)
                .padding(14)

            if isRunning {
                // Rotating luminous radar sweep
                Circle()
                    .trim(from: 0, to: 0.28)
                    .stroke(
                        AngularGradient(
                            colors: [Palette.keelGreen.opacity(0), Palette.info, Palette.keelGreen],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .padding(14)
                    .rotationEffect(.degrees(sweepAngle))
                    .shadow(color: Palette.keelGreen.opacity(0.45), radius: 10)
                    .onAppear {
                        sweepAngle = 0
                        withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                            sweepAngle = 360
                        }
                    }

                VStack(spacing: 4) {
                    Text("%\(Int((max(progress, 0.08) * 100).rounded()))")
                        .font(.keelMono(34, .semibold))
                        .tracking(-1.5)
                        .foregroundStyle(Palette.text)
                    Text("taranıyor")
                        .font(.keel(11.5, .bold))
                        .foregroundStyle(Palette.info)
                }
            } else if let score {
                Circle()
                    .trim(from: 0, to: Double(score) / 100)
                    .stroke(
                        LinearGradient(
                            colors: [ringColor, secondaryRingColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .padding(14)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: ringColor.opacity(0.42), radius: 12)
                    .animation(.easeOut(duration: 0.8), value: score)

                VStack(spacing: 2) {
                    Text("\(score)")
                        .font(.keelMono(46, .semibold))
                        .tracking(-2.2)
                        .foregroundStyle(Palette.text)
                    Text(gradeLabel(score))
                        .font(.keel(11.5, .bold))
                        .foregroundStyle(ringColor)
                }
            } else {
                // Ready-to-scan inviting shield medallion
                Circle()
                    .trim(from: 0, to: 1)
                    .stroke(
                        LinearGradient(
                            colors: [Palette.keelGreen.opacity(0.42), Palette.info.opacity(0.28), Palette.keelGreen.opacity(0.10)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [6, 8])
                    )
                    .padding(14)

                Mascot(character: .kee, size: 74)
            }
        }
        .accessibilityElement()
        .accessibilityLabel(score.map { "Sağlık puanı \($0)" } ?? "Henüz taranmadı")
    }

    private var ringColor: Color {
        guard let score else { return Palette.keelGreen }
        switch score {
        case 85...: return Palette.keelGreen
        case 65..<85: return Palette.warningText
        default: return Palette.danger
        }
    }

    private var secondaryRingColor: Color {
        guard let score else { return Palette.info }
        switch score {
        case 85...: return Palette.info
        case 65..<85: return Palette.warning
        default: return Color(hex: 0xFB7185)
        }
    }

    private func gradeLabel(_ score: Int) -> String {
        switch score {
        case 90...: return "MÜKEMMEL"
        case 75..<90: return "İYİ DURUMDA"
        case 60..<75: return "BAKIM ÖNERİLİR"
        default: return "İLGİ GEREKİR"
        }
    }
}

private struct FindingCard: View {
    let finding: CareFinding
    let act: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Mascot(character: finding.mascot, size: 42)
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(finding.title)
                        .font(.keel(15, .bold))
                        .foregroundStyle(Palette.text)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 4)
                    Circle().fill(color).frame(width: 8, height: 8)
                }
                Text(finding.detail)
                    .font(.keel(13, .medium))
                    .foregroundStyle(Palette.slate)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                if let title = finding.actionTitle, finding.action != nil {
                    Button(title, action: act)
                        .buttonStyle(TileButtonStyle(prominent: finding.severity >= .attention))
                        .padding(.top, 4)
                }
            }
            Spacer(minLength: 0)
        }
        .keelInteractiveCard(padding: 18, radius: 18, accent: color)
    }

    private var color: Color {
        switch finding.severity {
        case .good: Palette.keelGreen
        case .info: Palette.info
        case .attention: Palette.warningText
        case .warning: Palette.danger
        }
    }
}
