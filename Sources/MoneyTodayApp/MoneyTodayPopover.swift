import AppKit
import MoneyTodayCore
import SwiftUI

private enum UITheme {
    static let panelWidth: CGFloat = 392
    static let panelHeight: CGFloat = 560
    static let pagePadding: CGFloat = 24
    static let corner: CGFloat = 18
    static let cardCorner: CGFloat = 14
    static let mint = Color(red: 0.37, green: 0.86, blue: 0.62)
    static let mintDeep = Color(red: 0.12, green: 0.58, blue: 0.34)
    static let gold = Color(red: 0.95, green: 0.72, blue: 0.28)
    static let ink = Color(red: 0.93, green: 0.91, blue: 0.86)
    static let muted = Color(red: 0.68, green: 0.70, blue: 0.68)
    static let hairline = Color.white.opacity(0.12)
    static let fill = Color.white.opacity(0.065)
    static let fillStrong = Color.white.opacity(0.10)
}

struct MoneyTodayPopover: View {
    @ObservedObject var viewModel: MoneyTickerViewModel
    @State private var isShowingSettings = false

    private var needsInitialSetup: Bool {
        !viewModel.hasCompletedInitialSetup || viewModel.settings.annualSalary <= 0
    }

    var body: some View {
        ZStack {
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.09, blue: 0.09).opacity(0.52),
                    Color(red: 0.03, green: 0.04, blue: 0.04).opacity(0.30)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            if needsInitialSetup || isShowingSettings {
                SettingsScreen(
                    viewModel: viewModel,
                    mode: needsInitialSetup ? .initial : .edit,
                    onDone: { isShowingSettings = false }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.985)))
            } else {
                DashboardScreen(viewModel: viewModel, onSettings: { isShowingSettings = true })
                    .transition(.opacity.combined(with: .scale(scale: 0.985)))
            }
        }
        .frame(width: UITheme.panelWidth, height: UITheme.panelHeight)
        .clipShape(RoundedRectangle(cornerRadius: UITheme.corner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: UITheme.corner, style: .continuous)
                .stroke(.white.opacity(0.16), lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.18), value: needsInitialSetup)
        .animation(.easeInOut(duration: 0.18), value: isShowingSettings)
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

    var body: some View {
        VStack(spacing: 18) {
            header
            periodPicker
            earningsBlock
            metricStrip
            if isDay {
                rewardScene
            } else {
                periodSummary
            }
        }
        .padding(UITheme.pagePadding)
    }

    private var header: some View {
        HStack(spacing: 12) {
            AppIconMark()
                .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 3) {
                Text("窝囊费查看器")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(UITheme.ink)
                Text("\(viewModel.snapshot.status.title) · 芝麻陪班中")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(UITheme.muted)
                    .lineLimit(1)
            }

            Spacer(minLength: 10)

            IconButton(systemName: hidden ? "eye.slash.fill" : "eye.fill", help: hidden ? "显示金额" : "隐藏金额") {
                viewModel.toggleDashboardPrivacy()
            }
            IconButton(systemName: "gearshape.fill", help: "设置", action: onSettings)
        }
    }

    private var periodPicker: some View {
        HStack(spacing: 6) {
            ForEach(PeriodKind.allCases, id: \.self) { period in
                Button {
                    viewModel.setPeriod(period)
                } label: {
                    Text(period.title)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(viewModel.selectedPeriod == period ? Color.black.opacity(0.82) : UITheme.muted)
                        .frame(maxWidth: .infinity)
                        .frame(height: 30)
                        .background(
                            Capsule(style: .continuous)
                                .fill(viewModel.selectedPeriod == period ? UITheme.ink : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Capsule(style: .continuous).fill(.black.opacity(0.18)))
        .overlay(Capsule(style: .continuous).stroke(UITheme.hairline, lineWidth: 1))
    }

    private var earningsBlock: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(alignment: .firstTextBaseline) {
                Text(viewModel.selectedPeriod.metricTitle)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(UITheme.muted)
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

            Text(viewModel.displayMoney(mainAmount, fractionDigits: isDay ? 4 : 2, hidden: hidden))
                .font(.system(size: 42, weight: .semibold, design: .monospaced))
                .foregroundStyle(UITheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.45)
                .contentTransition(.numericText())
                .animation(.linear(duration: 0.08), value: mainAmount)
                .frame(maxWidth: .infinity, alignment: .leading)

            GreenProgressBar(value: mainProgress)
                .frame(height: 7)
        }
        .padding(18)
        .background(GlassCard(tint: UITheme.fillStrong))
    }

    private var metricStrip: some View {
        HStack(spacing: 8) {
            if isDay {
                MetricPill(title: "每秒收入", value: viewModel.displayMoney(viewModel.snapshot.perSecondIncome, fractionDigits: 4, hidden: hidden))
                MetricPill(title: "今日上限", value: viewModel.displayMoney(viewModel.snapshot.dailyIncome, hidden: hidden))
                MetricPill(title: "全年工作日", value: "\(viewModel.snapshot.workdayCount) 天")
            } else {
                MetricPill(title: "\(viewModel.selectedPeriod.title)工作日", value: "\(viewModel.snapshot.period.workdayCount) 天")
                MetricPill(title: "周期上限", value: viewModel.displayMoney(mainLimit, hidden: hidden))
                MetricPill(title: "今日上限", value: viewModel.displayMoney(viewModel.snapshot.dailyIncome, hidden: hidden))
            }
        }
    }

    private var rewardScene: some View {
        let reward = viewModel.rewardMessage
        return HStack(spacing: 14) {
            ZStack(alignment: .bottomTrailing) {
                RewardAssetIcon(assetName: reward.assetName, fallbackKind: reward.iconKind)
                    .frame(width: 72, height: 72)
                    .offset(x: -8, y: -2)
                PetSpriteView(state: .waving, active: viewModel.isPanelVisible)
                    .frame(width: 50, height: 54)
                    .offset(x: 18, y: 10)
            }
            .frame(width: 104, height: 82)

            VStack(alignment: .leading, spacing: 7) {
                Text(reward.title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(UITheme.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                Text(reward.detail)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(UITheme.muted)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(GlassCard(tint: UITheme.mint.opacity(0.10), stroke: UITheme.mint.opacity(0.22)))
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
        .background(GlassCard())
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
        VStack(spacing: 16) {
            header
            content
        }
        .padding(UITheme.pagePadding)
    }

    private var header: some View {
        HStack(spacing: 12) {
            AppIconMark()
                .frame(width: 38, height: 38)

            VStack(alignment: .leading, spacing: 4) {
                Text(headerTitle)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(UITheme.ink)
                Text(headerSubtitle)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(UITheme.muted)
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
        VStack(spacing: 14) {
            ScrollView {
                VStack(spacing: 12) {
                    settingsForm
                    navigationRows
                    switches
                    holidaySync
                }
                .padding(16)
            }
            .frame(maxHeight: 380)
            .background(GlassCard())

            primaryButton
            footer
        }
    }

    private var settingsForm: some View {
        VStack(spacing: 12) {
            SettingRow(label: "年薪") {
                salaryField
            }

            SettingRow(label: "货币") {
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
                .frame(width: 126)
            }

            SettingRow(label: "工作时间") {
                HStack(spacing: 7) {
                    TimeField(text: $viewModel.startText, onSubmit: save)
                    Text("至")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(UITheme.muted)
                    TimeField(text: $viewModel.endText, onSubmit: save)
                }
            }
        }
    }

    @ViewBuilder
    private var salaryField: some View {
        if viewModel.settings.hideSettingsAmounts {
            SecureField("例如 300000", text: $viewModel.salaryText)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 13, design: .monospaced))
                .frame(maxWidth: 160)
                .onSubmit { save() }
        } else {
            TextField("例如 300000", text: $viewModel.salaryText)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 13, design: .monospaced))
                .frame(maxWidth: 160)
                .onSubmit { save() }
        }
    }

    private var navigationRows: some View {
        VStack(spacing: 8) {
            NavigationRow(title: "休息日设置", detail: "\(viewModel.settings.customWeekendOverrides.count) 个自定义") { page = .weekends }
            NavigationRow(title: "兑换物对照表", detail: "\(viewModel.rewardEntries.count) 个锚点") { page = .rewards }
        }
    }

    private var switches: some View {
        VStack(spacing: 10) {
            ToggleRow(title: "开机启动", detail: nil, isOn: Binding(
                get: { viewModel.settings.launchAtLogin },
                set: { viewModel.setLaunchAtLogin($0) }
            ))
            ToggleRow(title: "测试模式", detail: "忽略周末和节假日，方便验收实时跳动。", isOn: Binding(
                get: { viewModel.settings.testMode },
                set: { enabled in
                    viewModel.settings.testMode = enabled
                    _ = viewModel.saveSettings()
                }
            ))
        }
    }

    private var holidaySync: some View {
        HStack(spacing: 10) {
            Text(viewModel.syncMessage)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(UITheme.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Spacer()
            Button {
                Task { await viewModel.syncHolidays() }
            } label: {
                Text("同步节假日")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(UITheme.mint)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 4)
    }

    private var primaryButton: some View {
        Button(action: save) {
            HStack(spacing: 7) {
                Image(systemName: "checkmark.circle.fill")
                Text(mode == .initial ? "保存并开始" : "保存设置")
            }
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(Color.black.opacity(0.82))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [UITheme.mint, Color(red: 0.68, green: 0.94, blue: 0.72)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
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
                            Text("\(entry.category) · 约 ¥\(Int(entry.priceCNY)) / \(entry.unit)")
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
    var title: String
    var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(UITheme.muted)
                .lineLimit(1)
            Text(value)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(UITheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.54)
        }
        .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
        .padding(.horizontal, 10)
        .background(GlassCard(tint: .white.opacity(0.045), radius: 12))
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
                .padding(5)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(UITheme.gold.opacity(0.13))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(UITheme.gold.opacity(0.18), lineWidth: 1)
                        )
                )
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
        } else if let url = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "RewardsV2/final-47") {
            image = NSImage(contentsOf: url)
        } else if let url = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "Rewards") {
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
        guard let url = Bundle.main.url(forResource: "spritesheet", withExtension: "webp", subdirectory: "Pets/zhima"),
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
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(UITheme.ink.opacity(0.86))
                .frame(width: 28, height: 28)
                .background(Circle().fill(.white.opacity(0.07)))
                .overlay(Circle().stroke(UITheme.hairline, lineWidth: 1))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .help(help)
    }
}

private struct NavigationRow: View {
    var title: String
    var detail: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(UITheme.ink)
                Spacer()
                Text(detail)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(UITheme.muted)
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(UITheme.muted.opacity(0.65))
            }
            .padding(11)
            .background(RowBackground())
        }
        .buttonStyle(.plain)
    }
}

private struct ToggleRow: View {
    var title: String
    var detail: String?
    @Binding var isOn: Bool

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
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
        .padding(11)
        .background(RowBackground())
    }
}

private struct SettingRow<Content: View>: View {
    var label: String
    @ViewBuilder var content: Content

    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(UITheme.muted)
                .frame(width: 62, alignment: .leading)
            Spacer(minLength: 6)
            content
        }
        .padding(11)
        .background(RowBackground())
    }
}

private struct TimeField: View {
    @Binding var text: String
    var onSubmit: () -> Void

    var body: some View {
        TextField("09:00", text: $text)
            .textFieldStyle(.roundedBorder)
            .font(.system(size: 12, design: .monospaced))
            .frame(width: 62)
            .onSubmit(onSubmit)
    }
}

private struct GlassCard: View {
    var tint: Color = UITheme.fill
    var stroke: Color = UITheme.hairline
    var radius: CGFloat = UITheme.cardCorner

    var body: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(tint)
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(stroke, lineWidth: 1)
            )
    }
}

private struct RowBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 11, style: .continuous)
            .fill(.white.opacity(0.045))
            .overlay(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(.white.opacity(0.08), lineWidth: 1)
            )
    }
}

private struct GreenProgressBar: View {
    var value: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(.black.opacity(0.24))
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [UITheme.mintDeep, UITheme.mint, Color(red: 0.75, green: 0.95, blue: 0.68)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(7, proxy.size.width * CGFloat(min(max(value, 0), 1))))
                    .shadow(color: UITheme.mint.opacity(0.30), radius: 5, x: 0, y: 0)
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
                .fill(configuration.isOn ? UITheme.mint.opacity(0.92) : Color.gray.opacity(0.34))
                .frame(width: 42, height: 24)
                .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                    Circle()
                        .fill(.white)
                        .frame(width: 20, height: 20)
                        .padding(2)
                        .shadow(color: .black.opacity(0.18), radius: 2, x: 0, y: 1)
                }
        }
        .buttonStyle(.plain)
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
        case .camera: return "camera.fill"
        case .hotel: return "bed.double.fill"
        case .travel: return "suitcase.fill"
        case .phone: return "iphone"
        case .laptop: return "laptopcomputer"
        case .spark: return "sparkle"
        }
    }
}
