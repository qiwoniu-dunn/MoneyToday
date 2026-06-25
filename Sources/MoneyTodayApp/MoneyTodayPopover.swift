import AppKit
import MoneyTodayCore
import SwiftUI

private enum UITheme {
    static let panelWidth: CGFloat = 410
    static let panelHeight: CGFloat = 612
    static let compactPanelHeight: CGFloat = 528
    static let settingsPanelHeight: CGFloat = 648
    static let pagePadding: CGFloat = 20
    static let pageTopPadding: CGFloat = 56
    static let pageBottomPadding: CGFloat = 18
    static let notchHeight: CGFloat = 18
    static let corner: CGFloat = 26
    static let cardCorner: CGFloat = 20
    static let mint = Color(red: 0.46, green: 0.88, blue: 0.43)
    static let mintDeep = Color(red: 0.20, green: 0.63, blue: 0.28)
    static let gold = Color(red: 0.90, green: 0.64, blue: 0.30)
    static let goldBright = Color(red: 1.00, green: 0.82, blue: 0.50)
    static let goldDeep = Color(red: 0.48, green: 0.34, blue: 0.18)
    static let ink = Color(red: 0.95, green: 0.88, blue: 0.72)
    static let inkDim = Color(red: 0.72, green: 0.67, blue: 0.56)
    static let muted = Color(red: 0.50, green: 0.50, blue: 0.45)
    static let panelDark = Color(red: 0.055, green: 0.060, blue: 0.052)
    static let panelWarm = Color(red: 0.16, green: 0.14, blue: 0.105)
    static let panelMoss = Color(red: 0.08, green: 0.115, blue: 0.085)
    static let hairline = Color.white.opacity(0.10)
    static let goldLine = Color(red: 0.88, green: 0.68, blue: 0.44).opacity(0.58)
    static let fill = Color.black.opacity(0.30)
    static let fillStrong = Color.black.opacity(0.44)
    static let rowFill = Color.white.opacity(0.045)

    static func dashboardHeight(for period: PeriodKind) -> CGFloat {
        period == .day ? panelHeight : compactPanelHeight
    }
}

private enum MoneyTodayResources {
    static func url(forResource name: String, withExtension ext: String?, subdirectory: String? = nil) -> URL? {
        for bundle in candidates {
            if let url = bundle.url(forResource: name, withExtension: ext, subdirectory: subdirectory) {
                return url
            }
        }
        return nil
    }

    private static var candidates: [Bundle] {
        var bundles = [Bundle.main, Bundle.module]
        var seen = Set<String>()
        bundles.removeAll { bundle in
            let path = bundle.bundlePath
            if seen.contains(path) { return true }
            seen.insert(path)
            return false
        }
        return bundles
    }
}

private struct MoneyPopoverShape: Shape {
    var cornerRadius: CGFloat
    var notchHeight: CGFloat

    func path(in rect: CGRect) -> Path {
        let radius = min(cornerRadius, min(rect.width, rect.height) / 2)
        let bodyTop = rect.minY + notchHeight
        let notchHalfWidth: CGFloat = 22
        let notchShoulder: CGFloat = 34
        let midX = rect.midX

        var path = Path()
        path.move(to: CGPoint(x: rect.minX + radius, y: bodyTop))
        path.addLine(to: CGPoint(x: midX - notchShoulder, y: bodyTop))
        path.addQuadCurve(
            to: CGPoint(x: midX - notchHalfWidth, y: bodyTop - 3),
            control: CGPoint(x: midX - notchShoulder + 7, y: bodyTop)
        )
        path.addLine(to: CGPoint(x: midX - 8, y: rect.minY + 3))
        path.addQuadCurve(
            to: CGPoint(x: midX + 8, y: rect.minY + 3),
            control: CGPoint(x: midX, y: rect.minY - 3)
        )
        path.addLine(to: CGPoint(x: midX + notchHalfWidth, y: bodyTop - 3))
        path.addQuadCurve(
            to: CGPoint(x: midX + notchShoulder, y: bodyTop),
            control: CGPoint(x: midX + notchShoulder - 7, y: bodyTop)
        )
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: bodyTop))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: bodyTop + radius), control: CGPoint(x: rect.maxX, y: bodyTop))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - radius, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - radius), control: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: bodyTop + radius))
        path.addQuadCurve(to: CGPoint(x: rect.minX + radius, y: bodyTop), control: CGPoint(x: rect.minX, y: bodyTop))
        path.closeSubpath()
        return path
    }
}

struct MoneyTodayPopover: View {
    @ObservedObject var viewModel: MoneyTickerViewModel
    var onPanelHeightChange: (CGFloat) -> Void = { _ in }
    @State private var isShowingSettings = ProcessInfo.processInfo.environment["MONEYTODAY_SNAPSHOT_PAGE"] == "settings"

    private var needsInitialSetup: Bool {
        !viewModel.hasCompletedInitialSetup || viewModel.settings.annualSalary <= 0
    }

    private var desiredPanelHeight: CGFloat {
        needsInitialSetup || isShowingSettings
            ? UITheme.settingsPanelHeight
            : UITheme.dashboardHeight(for: viewModel.selectedPeriod)
    }

    var body: some View {
        ZStack {
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    UITheme.panelWarm.opacity(0.94),
                    UITheme.panelDark.opacity(0.98),
                    UITheme.panelMoss.opacity(0.92)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            SubtlePanelTexture()
                .opacity(0.55)
                .ignoresSafeArea()

            if needsInitialSetup || isShowingSettings {
                SettingsScreen(
                    viewModel: viewModel,
                    mode: needsInitialSetup ? .initial : .edit,
                    onDone: { isShowingSettings = false }
                )
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .trailing)),
                    removal: .opacity.combined(with: .move(edge: .leading))
                ))
            } else {
                DashboardScreen(viewModel: viewModel, onSettings: { isShowingSettings = true })
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .leading)),
                        removal: .opacity.combined(with: .move(edge: .trailing))
                    ))
            }
        }
        .frame(width: UITheme.panelWidth, height: desiredPanelHeight)
        .clipShape(MoneyPopoverShape(cornerRadius: UITheme.corner, notchHeight: UITheme.notchHeight))
        .overlay(
            MoneyPopoverShape(cornerRadius: UITheme.corner, notchHeight: UITheme.notchHeight)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.42),
                            UITheme.goldBright.opacity(0.56),
                            Color.white.opacity(0.10),
                            UITheme.gold.opacity(0.32)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.35
                )
        )
        .overlay(
            MoneyPopoverShape(cornerRadius: UITheme.corner - 5, notchHeight: UITheme.notchHeight)
                .stroke(Color.black.opacity(0.42), lineWidth: 1)
                .padding(4)
        )
        .shadow(color: .black.opacity(0.58), radius: 26, x: 0, y: 18)
        .animation(.spring(response: 0.30, dampingFraction: 0.88), value: needsInitialSetup)
        .animation(.spring(response: 0.30, dampingFraction: 0.88), value: isShowingSettings)
        .animation(.spring(response: 0.30, dampingFraction: 0.90), value: viewModel.selectedPeriod)
        .onAppear { onPanelHeightChange(desiredPanelHeight) }
        .onChange(of: desiredPanelHeight) { height in
            onPanelHeightChange(height)
        }
    }
}

private struct DashboardScreen: View {
    @ObservedObject var viewModel: MoneyTickerViewModel
    var onSettings: () -> Void

    private var isDay: Bool { viewModel.selectedPeriod == .day }
    private var mainAmount: Double { isDay ? viewModel.snapshot.earnedToday : viewModel.snapshot.period.earned }
    private var mainLimit: Double { isDay ? viewModel.snapshot.dailyIncome : viewModel.snapshot.period.limit }
    private var mainProgress: Double { isDay ? viewModel.snapshot.progress : viewModel.snapshot.period.progress }
    private var hidden: Bool { viewModel.settings.hideDashboardAmounts }
    private var progressPercent: String {
        hidden ? "***" : "\(Int((mainProgress * 100).rounded()))%"
    }

    var body: some View {
        VStack(spacing: 9) {
            header
            periodPicker
            earningsBlock
            metricStrip
            ZStack(alignment: .top) {
                if isDay {
                    rewardScene
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.985, anchor: .top)),
                            removal: .opacity.combined(with: .move(edge: .bottom)).combined(with: .opacity)
                        ))
                } else {
                    periodSummary
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .bottom)),
                            removal: .opacity.combined(with: .scale(scale: 0.985, anchor: .top)).combined(with: .opacity)
                        ))
                }
            }
        }
        .padding(.top, UITheme.pageTopPadding)
        .padding(.horizontal, UITheme.pagePadding)
        .padding(.bottom, UITheme.pageBottomPadding)
        .animation(.spring(response: 0.30, dampingFraction: 0.90), value: viewModel.selectedPeriod)
    }

    private var header: some View {
        HStack(spacing: 13) {
            AppIconMark()
                .frame(width: 44, height: 44)
                .shadow(color: UITheme.gold.opacity(0.35), radius: 10, x: 0, y: 5)

            VStack(alignment: .leading, spacing: 2) {
                Text("窝囊费查看器")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(UITheme.ink)
                    .shadow(color: .black.opacity(0.42), radius: 2, x: 0, y: 1)
                HStack(spacing: 6) {
                    Circle()
                        .fill(UITheme.mint)
                        .frame(width: 6, height: 6)
                        .shadow(color: UITheme.mint.opacity(0.8), radius: 4, x: 0, y: 0)
                    Text("\(viewModel.snapshot.status.title) · 芝麻陪班中")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(UITheme.inkDim)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 10)

            IconButton(systemName: hidden ? "eye.slash.fill" : "eye.fill", help: hidden ? "显示金额" : "隐藏金额") {
                viewModel.toggleDashboardPrivacy()
            }
            IconButton(systemName: "gearshape.fill", help: "设置", action: onSettings)
        }
    }

    private var periodPicker: some View {
        HStack(spacing: 0) {
            ForEach(PeriodKind.allCases, id: \.self) { period in
                Button {
                    viewModel.setPeriod(period)
                } label: {
                    Text(period.title)
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(viewModel.selectedPeriod == period ? UITheme.ink : UITheme.inkDim.opacity(0.78))
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(
                            RoundedRectangle(cornerRadius: 19, style: .continuous)
                                .fill(
                                    viewModel.selectedPeriod == period
                                        ? AnyShapeStyle(LinearGradient(
                                            colors: [UITheme.goldBright.opacity(0.86), UITheme.gold.opacity(0.62), UITheme.goldDeep.opacity(0.46)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ))
                                        : AnyShapeStyle(Color.clear)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 19, style: .continuous)
                                        .stroke(viewModel.selectedPeriod == period ? UITheme.goldBright.opacity(0.64) : Color.clear, lineWidth: 1)
                                )
                                .shadow(color: viewModel.selectedPeriod == period ? UITheme.gold.opacity(0.20) : .clear, radius: 6, x: 0, y: 2)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(.black.opacity(0.30)))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(UITheme.goldLine.opacity(0.46), lineWidth: 1))
    }

    private var earningsBlock: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .firstTextBaseline) {
                Text(viewModel.selectedPeriod.metricTitle)
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(UITheme.inkDim.opacity(0.82))
                Spacer()
                if viewModel.settings.testMode {
                    Text("测试模式")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(UITheme.mint)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(UITheme.mint.opacity(0.12)))
                }
            }

            InstrumentAmountText(
                text: viewModel.displayMoney(mainAmount, fractionDigits: isDay ? 3 : 2, hidden: hidden)
            )
            .contentTransition(.numericText())
            .animation(.linear(duration: 0.08), value: mainAmount)

            GreenProgressBar(value: mainProgress)
                .frame(height: 10)

            HStack {
                Text("进度")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(UITheme.inkDim)
                Text(progressPercent)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(UITheme.mint)
                    .monospacedDigit()
                Spacer()
                Text("上限 \(viewModel.displayMoney(mainLimit, hidden: hidden))")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(UITheme.inkDim)
                    .monospacedDigit()
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 18)
        .background(
            GlassCard(
                tint: LinearGradient(
                    colors: [Color.white.opacity(0.055), UITheme.gold.opacity(0.055), Color.black.opacity(0.20)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                stroke: UITheme.goldLine.opacity(0.55),
                radius: UITheme.cardCorner
            )
        )
    }

    private var metricStrip: some View {
        HStack(spacing: 0) {
            MetricPill(
                icon: isDay ? "clock.fill" : "calendar",
                title: isDay ? "每秒收入" : "\(viewModel.selectedPeriod.title)工作日",
                value: isDay ? viewModel.displayMoney(viewModel.snapshot.perSecondIncome, fractionDigits: 4, hidden: hidden) : "\(viewModel.snapshot.period.workdayCount) 天"
            )
            MetricDivider()
            MetricPill(
                icon: "crown.fill",
                title: isDay ? "今日上限" : "周期上限",
                value: viewModel.displayMoney(mainLimit, hidden: hidden)
            )
            MetricDivider()
            MetricPill(
                icon: isDay ? "calendar" : "sun.max.fill",
                title: isDay ? "全年工作日" : "今日上限",
                value: isDay ? "\(viewModel.snapshot.workdayCount) 天" : viewModel.displayMoney(viewModel.snapshot.dailyIncome, hidden: hidden)
            )
        }
        .padding(.vertical, 7)
        .background(GlassCard(tint: .black.opacity(0.30), stroke: UITheme.goldLine.opacity(0.38), radius: 18))
    }

    private var rewardScene: some View {
        let reward = viewModel.rewardMessage
        return HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                Text(reward.title)
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundStyle(UITheme.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.70)
                Text(reward.detail)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(UITheme.inkDim.opacity(0.88))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 7) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 13, weight: .bold))
                    Text(reward.itemName)
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(UITheme.ink)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.black.opacity(0.30))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(UITheme.goldLine.opacity(0.70), lineWidth: 1)
                        )
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            RewardCompanionScene(
                itemName: reward.itemName,
                assetName: reward.assetName,
                fallbackKind: reward.iconKind,
                active: viewModel.isPanelVisible
            )
            .frame(width: 152)
            .frame(minHeight: 104)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 15)
        .frame(minHeight: 128)
        .background(
            GlassCard(
                tint: LinearGradient(
                    colors: [Color.white.opacity(0.060), UITheme.gold.opacity(0.060), Color.black.opacity(0.24)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                stroke: UITheme.goldLine.opacity(0.68),
                radius: 20
            )
        )
    }

    private var periodSummary: some View {
        HStack(spacing: 12) {
            PetSpriteView(state: .review, active: viewModel.isPanelVisible)
                .frame(width: 52, height: 56)
            VStack(alignment: .leading, spacing: 6) {
                Text("这段窝囊费已经悄悄攒起来了")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(UITheme.ink)
                Text("非日视图先不折算物品，只看累计战果。")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(UITheme.muted)
            }
            Spacer()
        }
        .padding(16)
        .background(GlassCard(tint: .black.opacity(0.18), stroke: .white.opacity(0.09)))
    }
}

private struct SettingsScreen: View {
    enum Mode { case initial, edit }
    enum Page { case main, rewards, weekends }

    @ObservedObject var viewModel: MoneyTickerViewModel
    var mode: Mode
    var onDone: () -> Void
    @State private var validationMessage = ""
    @State private var page: Page = .main

    var body: some View {
        VStack(spacing: 13) {
            header
            content
                .id(page)
                .transition(.opacity.combined(with: .move(edge: .trailing)))
        }
        .padding(.top, UITheme.pageTopPadding)
        .padding(.horizontal, UITheme.pagePadding)
        .padding(.bottom, UITheme.pageBottomPadding)
        .animation(.spring(response: 0.26, dampingFraction: 0.90), value: page)
    }

    private var header: some View {
        HStack(spacing: 12) {
            AppIconMark()
                .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 4) {
                Text(headerTitle)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(UITheme.ink)
                Text(headerSubtitle)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(UITheme.inkDim.opacity(0.72))
                    .lineLimit(2)
            }

            Spacer(minLength: 10)

            if page != .main {
                IconButton(systemName: "chevron.left", help: "返回") { page = .main }
            } else {
                IconButton(systemName: viewModel.settings.hideSettingsAmounts ? "eye.slash.fill" : "eye.fill", help: "隐藏年薪") {
                    viewModel.toggleSettingsPrivacy()
                }
            }

            if mode == .edit {
                IconButton(systemName: "xmark.circle.fill", help: "关闭设置", action: onDone)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch page {
        case .main:
            mainSettings
        case .rewards:
            RewardCatalogScreen(entries: viewModel.rewardEntries)
        case .weekends:
            WeekendEditorScreen(viewModel: viewModel)
        }
    }

    private var headerTitle: String {
        switch page {
        case .main: return mode == .initial ? "开始查看窝囊费" : "设置"
        case .rewards: return "兑换物对照表"
        case .weekends: return "休息日设置"
        }
    }

    private var headerSubtitle: String {
        switch page {
        case .main: return "你的窝囊费规则都在这里"
        case .rewards: return "创作者维护的物价锚点，App 内只读展示"
        case .weekends: return "把具体周六周日标成工作或休息"
        }
    }

    private var mainSettings: some View {
        ScrollView {
            VStack(spacing: 13) {
                VStack(spacing: 13) {
                    settingsForm
                    navigationRows
                    switches
                    holidaySync
                }
                .padding(13)
                .background(GlassCard(tint: .black.opacity(0.24), stroke: UITheme.goldLine.opacity(0.40), radius: 18))

                primaryButton
                footer
            }
        }
        .scrollIndicators(.hidden)
    }

    private var settingsForm: some View {
        VStack(spacing: 0) {
            SettingRow(icon: "yensign.circle", label: "年薪") {
                salaryField
            }

            DividerLine()

            SettingRow(icon: "globe.asia.australia", label: "货币") {
                Picker("", selection: Binding(
                    get: { viewModel.settings.currencyCode },
                    set: { code in
                        let option = CurrencyOption.options.first { $0.code == code } ?? .cny
                        viewModel.setCurrency(code: option.code, symbol: option.symbol)
                    }
                )) {
                    ForEach(CurrencyOption.options) { option in
                        Text("\(option.symbol) \(option.code)").tag(option.code)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: 126)
            }

            DividerLine()

            SettingRow(icon: "clock", label: "工作时间") {
                HStack(spacing: 7) {
                    TimeField(text: $viewModel.startText, onSubmit: save)
                    Text("至")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(UITheme.muted)
                    TimeField(text: $viewModel.endText, onSubmit: save)
                }
            }
        }
        .background(SettingsGroupBackground())
    }

    @ViewBuilder
    private var salaryField: some View {
        if viewModel.settings.hideSettingsAmounts {
            SecureField("例如 300000", text: $viewModel.salaryText)
                .textFieldStyle(.plain)
                .font(.system(size: 13, design: .monospaced))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: 166)
                .background(FieldBackground())
                .onSubmit { save() }
        } else {
            TextField("例如 300000", text: $viewModel.salaryText)
                .textFieldStyle(.plain)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(Color.black.opacity(0.86))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: 166)
                .background(FieldBackground())
                .onSubmit { save() }
        }
    }

    private var navigationRows: some View {
        VStack(spacing: 0) {
            NavigationRow(icon: "calendar.badge.checkmark", title: "休息日设置", detail: "\(viewModel.settings.customWeekendOverrides.count) 个自定义") { page = .weekends }
            DividerLine()
            NavigationRow(icon: "gift", title: "兑换物对照表", detail: "\(viewModel.rewardEntries.count) 个锚点") { page = .rewards }
        }
        .background(SettingsGroupBackground())
    }

    private var switches: some View {
        VStack(spacing: 0) {
            ToggleRow(icon: "power", title: "开机启动", detail: nil, isOn: Binding(
                get: { viewModel.settings.launchAtLogin },
                set: { viewModel.setLaunchAtLogin($0) }
            ))
            DividerLine()
            ToggleRow(icon: "flask", title: "测试模式", detail: "忽略周末和节假日，方便验收实时跳动。", isOn: Binding(
                get: { viewModel.settings.testMode },
                set: { enabled in
                    viewModel.settings.testMode = enabled
                    _ = viewModel.saveSettings()
                }
            ))
        }
        .background(SettingsGroupBackground())
    }

    private var holidaySync: some View {
        Button {
            Task { await viewModel.syncHolidays() }
        } label: {
            HStack(spacing: 12) {
                RowIcon(systemName: "icloud.and.arrow.down")
                Text("节假日数据同步")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(UITheme.ink)
                Spacer()
                Text(viewModel.syncMessage)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(UITheme.inkDim.opacity(0.65))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(UITheme.inkDim.opacity(0.62))
            }
            .padding(13)
            .background(SettingsGroupBackground())
        }
        .buttonStyle(.plain)
    }

    private var primaryButton: some View {
        Button(action: save) {
            HStack(spacing: 7) {
                Image(systemName: "checkmark.circle.fill")
                Text(mode == .initial ? "保存并开始" : "保存设置")
            }
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(Color(red: 0.12, green: 0.10, blue: 0.06))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [UITheme.goldBright.opacity(0.92), UITheme.gold.opacity(0.78), UITheme.goldDeep.opacity(0.62)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .stroke(Color.white.opacity(0.28), lineWidth: 1)
                    )
            )
            .shadow(color: UITheme.gold.opacity(0.18), radius: 8, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }

    private var footer: some View {
        HStack {
            Text(validationMessage.isEmpty ? "年薪只保存在本机，不会上传。" : validationMessage)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(validationMessage.isEmpty ? UITheme.muted : .red)
                .frame(maxWidth: .infinity, alignment: .leading)

            if mode == .edit {
                Button("退出") { NSApp.terminate(nil) }
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(UITheme.muted)
                    .buttonStyle(.plain)
            }
        }
    }

    private func save() {
        if viewModel.saveSettings() {
            validationMessage = ""
            onDone()
        } else {
            validationMessage = "请输入大于 0 的年薪。"
        }
    }
}

private struct WeekendEditorScreen: View {
    @ObservedObject var viewModel: MoneyTickerViewModel

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy 年 M 月"
        return formatter
    }()

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                IconButton(systemName: "chevron.left", help: "上个月") { viewModel.changeWeekendEditorMonth(by: -1) }
                Spacer()
                Text(Self.monthFormatter.string(from: viewModel.weekendEditorMonth))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(UITheme.ink)
                Spacer()
                IconButton(systemName: "chevron.right", help: "下个月") { viewModel.changeWeekendEditorMonth(by: 1) }
            }

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(viewModel.weekendDatesForEditor) { option in
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("\(option.key) \(option.weekdayLabel)")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundStyle(UITheme.ink)
                                Text(option.isWorking ? "按工作日计算窝囊费" : "按休息日处理")
                                    .font(.system(size: 10, weight: .medium, design: .rounded))
                                    .foregroundStyle(UITheme.muted)
                            }
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { option.isWorking },
                                set: { _ in viewModel.toggleWeekendOverride(option) }
                            ))
                            .labelsHidden()
                            .toggleStyle(MoneyToggleStyle())
                            if viewModel.settings.customWeekendOverrides[option.key] != nil {
                                Button("重置") { viewModel.resetWeekendOverride(option) }
                                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                                    .foregroundStyle(UITheme.muted)
                                    .buttonStyle(.plain)
                            }
                        }
                        .padding(11)
                        .background(RowBackground())
                    }
                }
            }
        }
        .padding(16)
        .background(GlassCard())
    }
}

private struct RewardCatalogScreen: View {
    var entries: [RewardCatalogEntry]

    var body: some View {
        ScrollView {
            VStack(spacing: 9) {
                ForEach(entries) { entry in
                    HStack(spacing: 11) {
                        RewardAssetIcon(assetName: entry.assetName, fallbackKind: .spark)
                            .frame(width: 38, height: 38)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(entry.name)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(UITheme.ink)
                            Text("\(entry.category) · 生活想象锚点")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(UITheme.muted)
                        }
                        Spacer()
                        Text(entry.enabled ? "启用" : "停用")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(entry.enabled ? UITheme.mint : UITheme.muted)
                    }
                    .padding(10)
                    .background(RowBackground())
                }
            }
        }
        .padding(16)
        .background(GlassCard())
    }
}

private struct MetricPill: View {
    var icon: String
    var title: String
    var value: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [UITheme.goldBright, UITheme.gold],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(UITheme.inkDim.opacity(0.86))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text(value)
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundStyle(UITheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.54)
                    .monospacedDigit()
            }
        }
        .frame(maxWidth: .infinity, minHeight: 66)
        .padding(.horizontal, 8)
    }
}

private struct MetricDivider: View {
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.clear, UITheme.goldLine.opacity(0.52), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 1, height: 52)
    }
}

private struct InstrumentAmountText: View {
    var text: String

    var body: some View {
        ViewThatFits(in: .horizontal) {
            amount(size: 42)
            amount(size: 36)
            amount(size: 30)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .frame(height: 50, alignment: .center)
        .clipped()
    }

    private func amount(size: CGFloat) -> some View {
        Text(text)
            .font(.system(size: size, weight: .semibold, design: .monospaced))
            .foregroundStyle(
                LinearGradient(
                    colors: [UITheme.goldBright, UITheme.ink, Color(red: 0.82, green: 0.57, blue: 0.28)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .shadow(color: UITheme.gold.opacity(0.22), radius: 7, x: 0, y: 0)
            .shadow(color: .black.opacity(0.50), radius: 2, x: 0, y: 2)
            .lineLimit(1)
            .minimumScaleFactor(0.30)
            .allowsTightening(true)
            .monospacedDigit()
            .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

private struct RewardCompanionScene: View {
    var itemName: String
    var assetName: String
    var fallbackKind: RewardIconKind
    var active: Bool
    @State private var poseID = RewardAnimationPose.snapshotID
    private var layout: RewardSceneLayout { RewardSceneLayout.layout(for: assetName) }

    private var frozen: Bool {
        ProcessInfo.processInfo.environment["MONEYTODAY_FREEZE_ANIMATION"] == "1"
    }

    private var displayedPoseID: String {
        frozen ? RewardAnimationPose.snapshotID : poseID
    }

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [UITheme.goldDeep.opacity(0.42), Color(red: 0.20, green: 0.12, blue: 0.06).opacity(0.68)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: layout.shelfSize.width, height: layout.shelfSize.height)
                    .offset(layout.shelfOffset)
                    .shadow(color: .black.opacity(0.40), radius: 8, x: 0, y: 7)
                    .zIndex(1)

                Ellipse()
                    .fill(.black.opacity(0.32))
                    .frame(width: layout.shadowSize.width, height: layout.shadowSize.height)
                    .blur(radius: 5)
                    .offset(layout.shadowOffset)

                RewardAssetIcon(assetName: assetName, fallbackKind: fallbackKind)
                    .frame(width: layout.productSize.width, height: layout.productSize.height)
                    .offset(layout.productOffset)
                    .shadow(color: .black.opacity(0.42), radius: 7, x: 0, y: 8)
                    .zIndex(layout.productZ)

                RewardLoopSpriteView(poseID: displayedPoseID, active: active && !frozen)
                    .frame(width: layout.catSize.width, height: layout.catSize.height)
                    .offset(layout.catOffset)
                    .zIndex(layout.catZ)
            }
            .frame(width: layout.sceneSize.width, height: layout.sceneSize.height)

            Text(itemName)
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundStyle(UITheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.62)
                .frame(width: layout.plateWidth)
                .offset(x: layout.plateOffsetX)
        }
        .accessibilityHidden(true)
        .onAppear {
            selectPoseIfNeeded()
        }
        .onChange(of: active) { isActive in
            if isActive && !frozen {
                poseID = RewardAnimationPose.randomID(for: assetName)
            }
        }
        .onChange(of: assetName) { _ in
            selectPoseIfNeeded()
        }
    }

    private func selectPoseIfNeeded() {
        guard active && !frozen else { return }
        poseID = RewardAnimationPose.randomID(for: assetName)
    }
}

private struct RewardSceneLayout {
    var sceneSize: CGSize = CGSize(width: 152, height: 92)
    var productSize: CGSize = CGSize(width: 92, height: 82)
    var productOffset: CGSize = CGSize(width: 31, height: -11)
    var productZ: Double = 3
    var catSize: CGSize = CGSize(width: 100, height: 116)
    var catOffset: CGSize = CGSize(width: -39, height: 12)
    var catZ: Double = 5
    var shadowSize: CGSize = CGSize(width: 124, height: 14)
    var shadowOffset: CGSize = CGSize(width: 7, height: 38)
    var shelfSize: CGSize = CGSize(width: 134, height: 17)
    var shelfOffset: CGSize = CGSize(width: 11, height: 38)
    var plateWidth: CGFloat = 116
    var plateOffsetX: CGFloat = 15

    static func layout(for assetName: String) -> RewardSceneLayout {
        switch assetName {
        case "reward-speaker":
            return RewardSceneLayout(
                productSize: CGSize(width: 98, height: 78),
                productOffset: CGSize(width: 32, height: -12),
                productZ: 3,
                catSize: CGSize(width: 100, height: 116),
                catOffset: CGSize(width: -39, height: 12),
                catZ: 5,
                shadowSize: CGSize(width: 128, height: 14),
                shadowOffset: CGSize(width: 9, height: 38),
                plateWidth: 116,
                plateOffsetX: 28
            )
        case "reward-monitor", "reward-projector", "reward-office-chair":
            return RewardSceneLayout(
                productSize: CGSize(width: 100, height: 82),
                productOffset: CGSize(width: 31, height: -11),
                productZ: 3,
                catSize: CGSize(width: 100, height: 116),
                catOffset: CGSize(width: -40, height: 12),
                catZ: 5,
                shadowSize: CGSize(width: 130, height: 14),
                shadowOffset: CGSize(width: 8, height: 38),
                plateWidth: 118,
                plateOffsetX: 23
            )
        case "reward-hotel", "reward-travel", "reward-massage":
            return RewardSceneLayout(
                productSize: CGSize(width: 96, height: 82),
                productOffset: CGSize(width: 31, height: -11),
                productZ: 3,
                catSize: CGSize(width: 102, height: 118),
                catOffset: CGSize(width: -37, height: 11),
                catZ: 5,
                shadowSize: CGSize(width: 130, height: 14),
                shadowOffset: CGSize(width: 8, height: 38),
                plateWidth: 118,
                plateOffsetX: 24
            )
        case "reward-coffee", "reward-tea", "reward-burger-meal", "reward-noodle-bento", "reward-salad", "reward-brunch", "reward-restaurant-meal", "reward-steak", "reward-buffet-hotpot":
            return RewardSceneLayout(
                productSize: CGSize(width: 94, height: 82),
                productOffset: CGSize(width: 31, height: -10),
                productZ: 3,
                catSize: CGSize(width: 100, height: 116),
                catOffset: CGSize(width: -39, height: 12),
                catZ: 5,
                shadowSize: CGSize(width: 126, height: 14),
                shadowOffset: CGSize(width: 9, height: 38),
                plateWidth: 116,
                plateOffsetX: 25
            )
        case "reward-airpods", "reward-earbuds", "reward-headphones", "reward-keyboard", "reward-keycaps", "reward-mouse", "reward-desk-setup", "reward-tablet", "reward-camera", "reward-game-console":
            return RewardSceneLayout(
                productSize: CGSize(width: 96, height: 82),
                productOffset: CGSize(width: 31, height: -11),
                productZ: 3,
                catSize: CGSize(width: 100, height: 116),
                catOffset: CGSize(width: -39, height: 12),
                catZ: 5,
                shadowSize: CGSize(width: 128, height: 14),
                shadowOffset: CGSize(width: 9, height: 38),
                plateWidth: 116,
                plateOffsetX: 27
            )
        default:
            return RewardSceneLayout()
        }
    }
}

private struct RewardItemNamePlate: View {
    var name: String
    var width: CGFloat

    var body: some View {
        Text(name)
            .font(.system(size: 10, weight: .heavy, design: .rounded))
            .foregroundStyle(UITheme.ink)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.62)
            .frame(width: width)
            .frame(minHeight: 24)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.black.opacity(0.24))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(UITheme.gold.opacity(0.22), lineWidth: 1)
                    )
            )
    }
}

private struct RewardLoopSpriteView: View {
    var poseID: String
    var active: Bool
    @State private var frame = 0

    var body: some View {
        Group {
            if let image = RewardLoopSpriteStore.frame(poseID: poseID, index: frame) {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
            } else {
                PetSpriteView(state: .idle, active: active)
            }
        }
        .task(id: "\(poseID)|\(active)") {
            frame = 0
            guard active else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: RewardAnimationPose.frameDuration)
                await MainActor.run {
                    frame = (frame + 1) % RewardAnimationPose.frameCount
                }
            }
        }
    }
}

private enum RewardAnimationPose {
    static let frameCount = 16
    static let frameDuration: UInt64 = 150_000_000
    static let snapshotID = "06_geyou_guard"
    static let ids = [
        "01_run_to_reward",
        "02_careful_touch",
        "03_orbit_inspect",
        "04_push_closer",
        "05_claim_guard",
        "06_geyou_guard",
        "07_happy_roll",
        "08_sleep_nearby",
        "09_star_daydream"
    ]

    static func randomID(for assetName: String) -> String {
        let pool = posePool(for: assetName)
        return pool.randomElement() ?? snapshotID
    }

    private static func posePool(for assetName: String) -> [String] {
        switch assetName {
        case "reward-coffee", "reward-tea", "reward-burger-meal", "reward-noodle-bento", "reward-salad", "reward-brunch":
            return ["02_careful_touch", "07_happy_roll"]
        case "reward-restaurant-meal", "reward-steak", "reward-buffet-hotpot":
            return ["02_careful_touch", "05_claim_guard", "07_happy_roll"]
        case "reward-hotel", "reward-massage":
            return ["06_geyou_guard", "08_sleep_nearby"]
        case "reward-haircare":
            return ["06_geyou_guard", "02_careful_touch"]
        case "reward-fitness-class":
            return ["01_run_to_reward", "07_happy_roll"]
        case "reward-sportswear", "reward-sneakers":
            return ["01_run_to_reward", "07_happy_roll"]
        case "reward-sports-accessory", "reward-city-ride", "reward-bag":
            return ["01_run_to_reward", "04_push_closer"]
        case "reward-health-scale":
            return ["03_orbit_inspect", "02_careful_touch"]
        case "reward-earbuds", "reward-headphones", "reward-airpods":
            return ["03_orbit_inspect", "05_claim_guard", "09_star_daydream"]
        case "reward-speaker":
            return ["03_orbit_inspect", "07_happy_roll"]
        case "reward-keycaps", "reward-mouse", "reward-desk-setup":
            return ["03_orbit_inspect", "04_push_closer"]
        case "reward-keyboard":
            return ["03_orbit_inspect", "04_push_closer", "05_claim_guard"]
        case "reward-monitor", "reward-storage-drive", "reward-tablet":
            return ["03_orbit_inspect", "05_claim_guard"]
        case "reward-office-chair":
            return ["06_geyou_guard", "05_claim_guard"]
        case "reward-air-fryer", "reward-home-appliance", "reward-coffee-machine", "reward-air-purifier", "reward-hair-dryer", "reward-fragrance":
            return ["02_careful_touch", "09_star_daydream"]
        case "reward-toothbrush":
            return ["02_careful_touch", "03_orbit_inspect"]
        case "reward-skincare":
            return ["02_careful_touch", "09_star_daydream"]
        case "reward-train", "reward-flight", "reward-camera":
            return ["01_run_to_reward", "09_star_daydream"]
        case "reward-travel":
            return ["01_run_to_reward", "09_star_daydream", "06_geyou_guard"]
        case "reward-game-console":
            return ["05_claim_guard", "07_happy_roll", "09_star_daydream"]
        case "reward-projector", "reward-movie", "reward-live-show":
            return ["07_happy_roll", "09_star_daydream"]
        default:
            return ids
        }
    }
}

@MainActor
private enum RewardLoopSpriteStore {
    private static var cache: [String: NSImage] = [:]

    static func frame(poseID: String, index: Int) -> NSImage? {
        let normalized = ((index % RewardAnimationPose.frameCount) + RewardAnimationPose.frameCount) % RewardAnimationPose.frameCount
        let cacheKey = "\(poseID)-\(normalized)"
        if let cached = cache[cacheKey] {
            return cached
        }
        let name = String(format: "frame-%02d", normalized)
        guard let url = MoneyTodayResources.url(forResource: name, withExtension: "png", subdirectory: "Pets/zhima/reward-animations/\(poseID)"),
              let image = NSImage(contentsOf: url)
        else { return nil }
        cache[cacheKey] = image
        return image
    }
}

private struct RewardAssetIcon: View {
    var assetName: String
    var fallbackKind: RewardIconKind

    var body: some View {
        if let image = RewardImageStore.image(named: assetName) {
            Image(nsImage: image)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .padding(2)
                .shadow(color: .black.opacity(0.30), radius: 3, x: 0, y: 3)
        } else {
            PixelRewardIcon(kind: fallbackKind)
        }
    }
}
@MainActor
private enum RewardImageStore {
    private static var cache: [String: NSImage] = [:]

    static func image(named name: String) -> NSImage? {
        if let cached = cache[name] {
            return cached
        }
        let image: NSImage?
        if let named = NSImage(named: name) {
            image = named
        } else if let url = MoneyTodayResources.url(forResource: name, withExtension: "png", subdirectory: "RewardsV2/final-47") {
            image = NSImage(contentsOf: url)
        } else if let url = MoneyTodayResources.url(forResource: name, withExtension: "png", subdirectory: "Rewards") {
            image = NSImage(contentsOf: url)
        } else {
            image = nil
        }
        if let image {
            cache[name] = image
        }
        return image
    }
}

private enum PetState {
    case idle
    case waving
    case waiting
    case review

    var row: Int {
        switch self {
        case .idle: return 0
        case .waving: return 3
        case .waiting: return 6
        case .review: return 8
        }
    }

    var frameCount: Int {
        switch self {
        case .idle: return 6
        case .waving: return 4
        case .waiting: return 6
        case .review: return 6
        }
    }
}

private struct PetSpriteView: View {
    var state: PetState
    var active: Bool = true
    @State private var frame = 0
    @State private var timer: Timer?

    var body: some View {
        Group {
            if let image = PetSpriteStore.frame(row: state.row, column: frame % max(state.frameCount, 1)) {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
            } else {
                AppIconMark()
                    .padding(4)
            }
        }
        .onAppear {
            updateTimer()
        }
        .onDisappear {
            stopTimer()
        }
        .onChange(of: active) { _ in
            updateTimer()
        }
        .onChange(of: state.row) { _ in
            frame = 0
            updateTimer()
        }
        .accessibilityHidden(true)
    }

    private func updateTimer() {
        stopTimer()
        guard active else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 0.24, repeats: true) { _ in
            Task { @MainActor in
                frame = (frame + 1) % max(state.frameCount, 1)
            }
        }
        timer?.tolerance = 0.08
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

@MainActor
private enum PetSpriteStore {
    private static let cellWidth = 192
    private static let cellHeight = 208
    private static var cachedSheet: NSImage?
    private static var frameCache: [String: NSImage] = [:]

    static func frame(row: Int, column: Int) -> NSImage? {
        let key = "\(row)-\(column)"
        if let cached = frameCache[key] {
            return cached
        }
        guard let sheet = spritesheet(),
              let cgImage = sheet.cgImage(forProposedRect: nil, context: nil, hints: nil)
        else { return nil }

        let rect = CGRect(x: column * cellWidth, y: row * cellHeight, width: cellWidth, height: cellHeight)
        guard let cropped = cgImage.cropping(to: rect) else { return nil }
        let image = NSImage(cgImage: cropped, size: NSSize(width: cellWidth, height: cellHeight))
        frameCache[key] = image
        return image
    }

    private static func spritesheet() -> NSImage? {
        if let cachedSheet {
            return cachedSheet
        }
        guard let url = MoneyTodayResources.url(forResource: "spritesheet", withExtension: "webp", subdirectory: "Pets/zhima"),
              let image = NSImage(contentsOf: url)
        else {
            return nil
        }
        cachedSheet = image
        return image
    }
}

private struct IconButton: View {
    var systemName: String
    var help: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(UITheme.ink.opacity(0.86))
                .frame(width: 42, height: 42)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.075), Color.black.opacity(0.22)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(Circle().stroke(UITheme.goldLine.opacity(0.38), lineWidth: 1))
                .shadow(color: .black.opacity(0.25), radius: 5, x: 0, y: 3)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .help(help)
    }
}

private struct NavigationRow: View {
    var icon: String
    var title: String
    var detail: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                RowIcon(systemName: icon)
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(UITheme.ink)
                Spacer()
                Text(detail)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(UITheme.inkDim.opacity(0.65))
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(UITheme.inkDim.opacity(0.62))
            }
            .padding(13)
        }
        .buttonStyle(.plain)
    }
}

private struct ToggleRow: View {
    var icon: String
    var title: String
    var detail: String?
    @Binding var isOn: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            RowIcon(systemName: icon)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(UITheme.ink)
                if let detail {
                    Text(detail)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(UITheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(MoneyToggleStyle())
        }
        .padding(13)
    }
}

private struct SettingRow<Content: View>: View {
    var icon: String
    var label: String
    @ViewBuilder var content: Content

    var body: some View {
        HStack(spacing: 12) {
            RowIcon(systemName: icon)
            Text(label)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(UITheme.ink)
                .frame(width: 62, alignment: .leading)
            Spacer(minLength: 6)
            content
        }
        .padding(13)
    }
}

private struct TimeField: View {
    @Binding var text: String
    var onSubmit: () -> Void

    var body: some View {
        TextField("09:00", text: $text)
            .textFieldStyle(.plain)
            .font(.system(size: 12, design: .monospaced))
            .foregroundStyle(Color.black.opacity(0.86))
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .frame(width: 62)
            .background(FieldBackground())
            .onSubmit(onSubmit)
    }
}

private struct GlassCard: View {
    var tint: AnyShapeStyle = AnyShapeStyle(UITheme.fill)
    var stroke: Color = UITheme.hairline
    var radius: CGFloat = UITheme.cardCorner

    init(tint: some ShapeStyle = UITheme.fill, stroke: Color = UITheme.hairline, radius: CGFloat = UITheme.cardCorner) {
        self.tint = AnyShapeStyle(tint)
        self.stroke = stroke
        self.radius = radius
    }

    var body: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(tint)
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(stroke, lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius - 1, style: .continuous)
                    .stroke(Color.white.opacity(0.055), lineWidth: 1)
                    .padding(1)
            )
    }
}

private struct RowBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color.black.opacity(0.20))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(UITheme.goldLine.opacity(0.26), lineWidth: 1)
            )
    }
}

private struct SettingsGroupBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 15, style: .continuous)
            .fill(.black.opacity(0.24))
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(UITheme.goldLine.opacity(0.32), lineWidth: 1)
            )
    }
}

private struct DividerLine: View {
    var body: some View {
        Rectangle()
            .fill(UITheme.goldLine.opacity(0.20))
            .frame(height: 1)
            .padding(.leading, 52)
    }
}

private struct RowIcon: View {
    var systemName: String

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(UITheme.goldBright.opacity(0.92))
            .frame(width: 28, height: 28)
    }
}

private struct FieldBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 9, style: .continuous)
            .fill(Color(red: 0.95, green: 0.90, blue: 0.78).opacity(0.94))
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(UITheme.goldBright.opacity(0.35), lineWidth: 1)
            )
    }
}

private struct GreenProgressBar: View {
    var value: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.black.opacity(0.35))
                    .overlay(Capsule().stroke(UITheme.goldLine.opacity(0.28), lineWidth: 1))
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [UITheme.mintDeep, UITheme.mint, Color(red: 0.75, green: 0.95, blue: 0.68)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(7, proxy.size.width * CGFloat(min(max(value, 0), 1))))
                    .shadow(color: UITheme.mint.opacity(0.38), radius: 6, x: 0, y: 0)
            }
        }
    }
}

private struct MoneyToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(configuration.isOn ? UITheme.mint.opacity(0.92) : Color.black.opacity(0.34))
                .frame(width: 42, height: 24)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(configuration.isOn ? Color.white.opacity(0.24) : UITheme.goldLine.opacity(0.22), lineWidth: 1)
                )
                .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                    Circle()
                        .fill(configuration.isOn ? Color.white : UITheme.inkDim)
                        .frame(width: 20, height: 20)
                        .padding(2)
                        .shadow(color: .black.opacity(0.18), radius: 2, x: 0, y: 1)
                }
        }
        .buttonStyle(.plain)
    }
}

private struct SubtlePanelTexture: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.white.opacity(0.08), .clear, .black.opacity(0.18)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(spacing: 9) {
                ForEach(0..<70, id: \.self) { _ in
                    Rectangle()
                        .fill(.white.opacity(0.018))
                        .frame(height: 1)
                }
            }
            .blendMode(.softLight)
        }
    }
}

private struct CurrencyOption: Identifiable {
    var id: String { code }
    var code: String
    var symbol: String

    static let cny = CurrencyOption(code: "CNY", symbol: "¥")
    static let options = [
        CurrencyOption(code: "CNY", symbol: "¥"),
        CurrencyOption(code: "USD", symbol: "$"),
        CurrencyOption(code: "EUR", symbol: "€"),
        CurrencyOption(code: "GBP", symbol: "£"),
        CurrencyOption(code: "JPY", symbol: "¥")
    ]
}

private struct AppIconMark: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 1.0, green: 0.82, blue: 0.28), Color(red: 0.94, green: 0.58, blue: 0.11)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Image(nsImage: MoneyFlowIcon.makeStatusImage())
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(Color(red: 0.12, green: 0.30, blue: 0.16))
                .padding(8)
        }
    }
}

private struct PixelRewardIcon: View {
    var kind: RewardIconKind

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(UITheme.gold.opacity(0.14))
            Image(systemName: systemName)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(UITheme.gold)
        }
        .accessibilityHidden(true)
    }

    private var systemName: String {
        switch kind {
        case .coffee, .tea: return "cup.and.saucer.fill"
        case .meal: return "fork.knife"
        case .ride: return "car.fill"
        case .movie: return "ticket.fill"
        case .wellness: return "sparkles"
        case .keyboard: return "keyboard.fill"
        case .mouse: return "computermouse.fill"
        case .beauty: return "drop.fill"
        case .headphones: return "headphones"
        case .speaker: return "hifispeaker.fill"
        case .camera: return "camera.fill"
        case .hotel: return "bed.double.fill"
        case .travel: return "suitcase.fill"
        case .phone: return "iphone"
        case .laptop: return "laptopcomputer"
        case .spark: return "sparkle"
        }
    }
}
