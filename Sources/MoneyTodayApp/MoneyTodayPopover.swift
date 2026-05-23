import MoneyTodayCore
import AppKit
import SwiftUI

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

            VStack(spacing: 0) {
                if needsInitialSetup || isShowingSettings {
                    SettingsScreen(
                        viewModel: viewModel,
                        mode: needsInitialSetup ? .initial : .edit,
                        onDone: { isShowingSettings = false }
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                } else {
                    DashboardScreen(
                        viewModel: viewModel,
                        onSettings: { isShowingSettings = true }
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                }
            }
            .padding(18)
        }
        .frame(width: 334, height: needsInitialSetup || isShowingSettings ? 456 : 386)
        .animation(.easeInOut(duration: 0.18), value: needsInitialSetup)
        .animation(.easeInOut(duration: 0.18), value: isShowingSettings)
    }
}

private struct DashboardScreen: View {
    @ObservedObject var viewModel: MoneyTickerViewModel
    var onSettings: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            header
            earningsCard
            metricsGrid
            rewardCard
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(nsImage: MoneyFlowIcon.makeStatusImage())
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(.secondary)
                .frame(width: 18, height: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text("MoneyToday")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                HStack(spacing: 6) {
                    Text(viewModel.snapshot.status.title)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                    if viewModel.settings.testMode {
                        Text("测试")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(.mint)
                    }
                }
            }

            Spacer()

            Button(action: onSettings) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("设置")
        }
    }

    private var earningsCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            VStack(alignment: .leading, spacing: 8) {
                Text("今日已赚")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)

                Text(viewModel.formatMoney(viewModel.snapshot.earnedToday, fractionDigits: 4))
                    .font(.system(size: 38, weight: .semibold, design: .monospaced))
                    .animation(.linear(duration: 0.08), value: viewModel.snapshot.earnedToday)
                    .lineLimit(1)
                    .minimumScaleFactor(0.50)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            GreenProgressBar(value: viewModel.snapshot.progress)
                .frame(height: 8)
        }
        .padding(16)
        .background(panelBackground)
    }

    private var metricsGrid: some View {
        HStack(spacing: 10) {
            MetricTile(title: "每秒收入", value: viewModel.formatMoney(viewModel.snapshot.perSecondIncome, fractionDigits: 4))
            MetricTile(title: "全年工作日", value: "\(viewModel.snapshot.workdayCount) 天")
            MetricTile(title: "今日上限", value: viewModel.formatMoney(viewModel.snapshot.dailyIncome))
        }
    }

    private var rewardCard: some View {
        let reward = viewModel.rewardMessage
        return HStack(alignment: .top, spacing: 10) {
            PixelRewardIcon(kind: reward.iconKind)
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 5) {
                Text(reward.title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                Text(reward.detail)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.mint.opacity(0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(.mint.opacity(0.22), lineWidth: 1)
                )
        )
    }

    private var panelBackground: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(.white.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(.white.opacity(0.14), lineWidth: 1)
            )
    }
}

private struct SettingsScreen: View {
    enum Mode {
        case initial
        case edit
    }

    @ObservedObject var viewModel: MoneyTickerViewModel
    var mode: Mode
    var onDone: () -> Void
    @State private var validationMessage = ""

    var body: some View {
        VStack(spacing: 16) {
            header
            formPanel
            primaryButton
            footer
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            AppIconMark()
                .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 4) {
                Text(mode == .initial ? "开始计算你的今日收入" : "设置")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                Text(mode == .initial ? "填入年薪后，MoneyToday 会按工作时间实时跳动。" : "调整后点击保存即可生效。")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            if mode == .edit {
                Button(action: onDone) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("关闭设置")
            }
        }
    }

    private var formPanel: some View {
        VStack(spacing: 12) {
            SettingRow(label: "年薪") {
                TextField("例如 300000", text: $viewModel.salaryText)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 13, design: .monospaced))
                    .onSubmit { save() }
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
                .frame(width: 128)
            }

            SettingRow(label: "工作时间") {
                HStack(spacing: 7) {
                    TextField("09:00", text: $viewModel.startText)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12, design: .monospaced))
                        .frame(width: 66)
                        .onSubmit { save() }
                    Text("至")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                    TextField("19:00", text: $viewModel.endText)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12, design: .monospaced))
                        .frame(width: 66)
                        .onSubmit { save() }
                }
            }

            HStack {
                Text("开机启动")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { viewModel.settings.launchAtLogin },
                    set: { viewModel.setLaunchAtLogin($0) }
                ))
                .labelsHidden()
                .toggleStyle(MoneyToggleStyle())
            }

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("测试模式")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                    Text("忽略周末和节假日，方便验收实时跳动。")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.tertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { viewModel.settings.testMode },
                    set: { enabled in
                        viewModel.settings.testMode = enabled
                        _ = viewModel.saveSettings()
                    }
                ))
                .labelsHidden()
                .toggleStyle(MoneyToggleStyle())
            }

            Divider()

            HStack(spacing: 10) {
                Text(viewModel.syncMessage)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Spacer()
                Button {
                    Task { await viewModel.syncHolidays() }
                } label: {
                    Text("同步节假日")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(.white.opacity(0.14), lineWidth: 1)
                )
        )
    }

    private var primaryButton: some View {
        Button(action: save) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                Text(mode == .initial ? "保存并开始" : "保存设置")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.mint.opacity(0.22))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(.mint.opacity(0.38), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var footer: some View {
        HStack {
            Text(validationMessage.isEmpty ? "年薪只保存在本机，不会上传。" : validationMessage)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(validationMessage.isEmpty ? .secondary : .red)
                .frame(maxWidth: .infinity, alignment: .leading)

            if mode == .edit {
                Button("退出") {
                    NSApp.terminate(nil)
                }
                .font(.system(size: 11, weight: .semibold, design: .rounded))
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

private struct MetricTile: View {
    var title: String
    var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .lineLimit(1)
                .minimumScaleFactor(0.58)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
        .padding(.horizontal, 9)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(.white.opacity(0.12), lineWidth: 1)
                )
        )
    }
}

private struct PixelRewardIcon: View {
    var kind: RewardIconKind

    var body: some View {
        PixelCanvas(cells: icon.cells)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(icon.background.opacity(0.16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(icon.background.opacity(0.24), lineWidth: 1)
                    )
            )
            .accessibilityHidden(true)
    }

    private var icon: PixelIconData {
        PixelIconData.icon(for: kind)
    }
}

private struct PixelCanvas: View {
    var cells: [PixelCell]

    var body: some View {
        GeometryReader { proxy in
            let unit = proxy.size.width / 24
            ZStack {
                ForEach(cells) { cell in
                    Rectangle()
                        .fill(cell.color)
                        .frame(width: unit * CGFloat(cell.w), height: unit * CGFloat(cell.h))
                        .position(
                            x: unit * (CGFloat(cell.x) + CGFloat(cell.w) / 2),
                            y: unit * (CGFloat(cell.y) + CGFloat(cell.h) / 2)
                        )
                }
            }
        }
        .padding(5)
    }
}

private struct PixelCell: Identifiable {
    let id = UUID()
    var x: Int
    var y: Int
    var w: Int
    var h: Int
    var color: Color
}

private struct PixelIconData {
    var background: Color
    var cells: [PixelCell]

    static func icon(for kind: RewardIconKind) -> PixelIconData {
        switch kind {
        case .coffee:
            return cup(liquid: .brown, accent: .mint)
        case .tea:
            return cup(liquid: .pink, accent: .green)
        case .meal:
            return meal()
        case .ride:
            return car()
        case .movie:
            return ticket()
        case .wellness:
            return sparkle(color: .mint)
        case .keyboard:
            return keyboard()
        case .mouse:
            return mouse()
        case .beauty:
            return bottle()
        case .headphones:
            return headphones()
        case .camera:
            return camera()
        case .hotel:
            return hotel()
        case .travel:
            return suitcase()
        case .phone:
            return phone()
        case .laptop:
            return laptop()
        case .spark:
            return sparkle(color: .yellow)
        }
    }

    private static func c(_ x: Int, _ y: Int, _ w: Int, _ h: Int, _ color: Color) -> PixelCell {
        PixelCell(x: x, y: y, w: w, h: h, color: color)
    }

    private static func cup(liquid: Color, accent: Color) -> PixelIconData {
        PixelIconData(background: accent, cells: [
            c(7, 6, 10, 2, .white), c(6, 8, 12, 2, .white), c(7, 10, 10, 8, .white),
            c(8, 10, 8, 2, liquid), c(17, 10, 3, 5, .white), c(18, 12, 2, 4, .white),
            c(9, 4, 1, 2, accent.opacity(0.9)), c(12, 3, 1, 2, .white.opacity(0.7)), c(15, 4, 1, 2, accent.opacity(0.9)),
            c(8, 18, 9, 1, .gray.opacity(0.40)), c(9, 19, 7, 1, .gray.opacity(0.30))
        ])
    }

    private static func meal() -> PixelIconData {
        PixelIconData(background: .orange, cells: [
            c(4, 13, 16, 5, .orange), c(5, 11, 14, 3, .yellow), c(6, 9, 4, 3, .green),
            c(11, 8, 5, 4, .red), c(15, 10, 3, 2, .green), c(5, 18, 14, 2, .white),
            c(3, 20, 18, 1, .gray.opacity(0.4)), c(5, 6, 1, 7, .white.opacity(0.75)), c(19, 6, 1, 7, .white.opacity(0.75))
        ])
    }

    private static func car() -> PixelIconData {
        PixelIconData(background: .blue, cells: [
            c(4, 11, 16, 5, .blue), c(7, 7, 10, 4, .cyan), c(8, 8, 4, 3, .white.opacity(0.75)),
            c(13, 8, 4, 3, .white.opacity(0.55)), c(5, 16, 4, 4, .black), c(15, 16, 4, 4, .black),
            c(6, 17, 2, 2, .gray), c(16, 17, 2, 2, .gray), c(4, 12, 2, 2, .yellow), c(18, 12, 2, 2, .red)
        ])
    }

    private static func ticket() -> PixelIconData {
        PixelIconData(background: .purple, cells: [
            c(4, 6, 16, 12, .purple), c(6, 8, 12, 8, .white.opacity(0.9)),
            c(10, 8, 1, 8, .purple), c(14, 8, 1, 8, .purple), c(4, 9, 2, 2, .white.opacity(0.55)),
            c(18, 15, 2, 2, .white.opacity(0.55)), c(7, 18, 10, 1, .gray.opacity(0.35))
        ])
    }

    private static func keyboard() -> PixelIconData {
        PixelIconData(background: .mint, cells: [
            c(3, 8, 18, 9, .white), c(4, 9, 16, 1, .gray.opacity(0.35)),
            c(5, 11, 2, 2, .gray), c(8, 11, 2, 2, .gray), c(11, 11, 2, 2, .gray), c(14, 11, 2, 2, .gray), c(17, 11, 2, 2, .gray),
            c(5, 14, 8, 2, .mint), c(14, 14, 2, 2, .gray), c(17, 14, 2, 2, .gray), c(4, 17, 16, 1, .gray.opacity(0.4))
        ])
    }

    private static func mouse() -> PixelIconData {
        PixelIconData(background: .mint, cells: [
            c(8, 4, 8, 16, .white), c(10, 5, 4, 3, .gray.opacity(0.45)), c(11, 9, 2, 4, .mint),
            c(8, 17, 8, 2, .gray.opacity(0.38)), c(7, 8, 1, 7, .white.opacity(0.7)), c(16, 8, 1, 7, .white.opacity(0.7))
        ])
    }

    private static func bottle() -> PixelIconData {
        PixelIconData(background: .pink, cells: [
            c(10, 4, 4, 4, .pink), c(8, 8, 8, 12, .white), c(9, 10, 6, 6, .pink),
            c(10, 11, 4, 4, .white.opacity(0.35)), c(8, 20, 8, 1, .gray.opacity(0.45)), c(11, 3, 2, 1, .white.opacity(0.85))
        ])
    }

    private static func headphones() -> PixelIconData {
        PixelIconData(background: .indigo, cells: [
            c(6, 8, 2, 8, .white), c(16, 8, 2, 8, .white), c(8, 5, 8, 2, .white),
            c(5, 13, 4, 6, .mint), c(15, 13, 4, 6, .mint), c(7, 6, 2, 2, .white.opacity(0.7)), c(15, 6, 2, 2, .white.opacity(0.7))
        ])
    }

    private static func camera() -> PixelIconData {
        PixelIconData(background: .green, cells: [
            c(4, 8, 16, 10, .white), c(8, 6, 6, 2, .white), c(9, 10, 6, 6, .black),
            c(10, 11, 4, 4, .mint), c(17, 10, 2, 2, .red), c(5, 18, 14, 1, .gray.opacity(0.4)), c(6, 9, 2, 2, .green)
        ])
    }

    private static func hotel() -> PixelIconData {
        PixelIconData(background: .blue, cells: [
            c(7, 4, 10, 16, .white), c(9, 6, 2, 2, .blue), c(13, 6, 2, 2, .blue),
            c(9, 10, 2, 2, .blue), c(13, 10, 2, 2, .blue), c(9, 14, 2, 2, .blue), c(13, 14, 2, 2, .blue),
            c(11, 17, 2, 3, .orange), c(6, 20, 12, 1, .gray.opacity(0.4))
        ])
    }

    private static func suitcase() -> PixelIconData {
        PixelIconData(background: .orange, cells: [
            c(6, 8, 12, 10, .orange), c(10, 5, 4, 3, .white), c(8, 10, 2, 6, .white.opacity(0.78)),
            c(14, 10, 2, 6, .white.opacity(0.78)), c(8, 18, 2, 2, .black), c(14, 18, 2, 2, .black), c(6, 12, 12, 1, .yellow)
        ])
    }

    private static func phone() -> PixelIconData {
        PixelIconData(background: .cyan, cells: [
            c(8, 3, 8, 18, .white), c(9, 5, 6, 13, .cyan), c(11, 19, 2, 1, .gray),
            c(10, 6, 4, 1, .white.opacity(0.55)), c(13, 15, 1, 1, .white.opacity(0.75))
        ])
    }

    private static func laptop() -> PixelIconData {
        PixelIconData(background: .mint, cells: [
            c(5, 5, 14, 9, .white), c(7, 7, 10, 5, .mint), c(3, 16, 18, 2, .gray),
            c(7, 18, 10, 1, .gray.opacity(0.65)), c(16, 8, 1, 1, .white.opacity(0.8))
        ])
    }

    private static func sparkle(color: Color) -> PixelIconData {
        PixelIconData(background: color, cells: [
            c(11, 3, 2, 5, color), c(9, 8, 6, 2, color), c(5, 10, 14, 4, .white),
            c(9, 14, 6, 2, color), c(11, 16, 2, 5, color), c(4, 5, 2, 2, .white.opacity(0.8)), c(18, 17, 2, 2, .white.opacity(0.8))
        ])
    }
}

private struct GreenProgressBar: View {
    var value: Double

    private var clampedValue: Double {
        min(max(value, 0), 1)
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.black.opacity(0.14))

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: proxy.size.width * clampedValue)
                    .animation(.linear(duration: 0.08), value: clampedValue)
            }
        }
        .accessibilityLabel("今日进度")
        .accessibilityValue("\(Int(clampedValue * 100))%")
    }
}

private struct MoneyToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            withAnimation(.spring(response: 0.22, dampingFraction: 0.82)) {
                configuration.isOn.toggle()
            }
        } label: {
            ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                Capsule()
                    .fill(configuration.isOn ? Color.green.opacity(0.86) : Color.gray.opacity(0.28))
                    .frame(width: 44, height: 24)
                    .overlay(
                        Capsule()
                            .stroke(configuration.isOn ? Color.mint.opacity(0.55) : Color.primary.opacity(0.10), lineWidth: 1)
                    )

                Circle()
                    .fill(Color.white.opacity(0.96))
                    .frame(width: 18, height: 18)
                    .shadow(color: .black.opacity(0.18), radius: 2, x: 0, y: 1)
                    .padding(.horizontal, 3)
            }
        }
        .buttonStyle(.plain)
        .accessibilityValue(configuration.isOn ? "开启" : "关闭")
    }
}

private struct SettingRow<Content: View>: View {
    var label: String
    @ViewBuilder var content: Content

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .frame(width: 64, alignment: .leading)
            Spacer()
            content
        }
    }
}

private struct AppIconMark: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.04, green: 0.08, blue: 0.08), Color(red: 0.03, green: 0.30, blue: 0.22)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Path { path in
                path.move(to: CGPoint(x: 14, y: 22))
                path.addCurve(to: CGPoint(x: 28, y: 22), control1: CGPoint(x: 17, y: 26), control2: CGPoint(x: 25, y: 26))
                path.addCurve(to: CGPoint(x: 32, y: 16), control1: CGPoint(x: 31, y: 20), control2: CGPoint(x: 32, y: 18))
                path.addCurve(to: CGPoint(x: 21, y: 11), control1: CGPoint(x: 31, y: 12), control2: CGPoint(x: 27, y: 11))
                path.addCurve(to: CGPoint(x: 10, y: 16), control1: CGPoint(x: 15, y: 11), control2: CGPoint(x: 11, y: 12))
                path.addCurve(to: CGPoint(x: 14, y: 22), control1: CGPoint(x: 10, y: 18), control2: CGPoint(x: 11, y: 20))
            }
            .stroke(.mint.opacity(0.95), style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))

            Path { path in
                path.move(to: CGPoint(x: 16, y: 24))
                path.addLine(to: CGPoint(x: 14, y: 31))
                path.addLine(to: CGPoint(x: 18, y: 29))
                path.move(to: CGPoint(x: 26, y: 24))
                path.addLine(to: CGPoint(x: 28, y: 31))
                path.addLine(to: CGPoint(x: 24, y: 29))
                path.move(to: CGPoint(x: 17, y: 23))
                path.addLine(to: CGPoint(x: 25, y: 23))
                path.move(to: CGPoint(x: 21, y: 20))
                path.addLine(to: CGPoint(x: 21, y: 14))
                path.move(to: CGPoint(x: 18, y: 18))
                path.addLine(to: CGPoint(x: 24, y: 18))
            }
            .stroke(.white.opacity(0.94), style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
        }
    }
}

private struct CurrencyOption: Identifiable {
    var id: String { code }
    var code: String
    var symbol: String

    static let cny = CurrencyOption(code: "CNY", symbol: "¥")
    static let options = [
        cny,
        CurrencyOption(code: "USD", symbol: "$"),
        CurrencyOption(code: "EUR", symbol: "€"),
        CurrencyOption(code: "GBP", symbol: "£"),
        CurrencyOption(code: "JPY", symbol: "¥")
    ]
}
