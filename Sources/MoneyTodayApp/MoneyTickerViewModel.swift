import Combine
import Foundation
import MoneyTodayCore
import ServiceManagement
import SwiftUI

@MainActor
final class MoneyTickerViewModel: ObservableObject {
    @Published var settings: AppSettings
    @Published private(set) var snapshot = MoneySnapshot(
        earnedToday: 0,
        dailyIncome: 0,
        perSecondIncome: 0,
        progress: 0,
        workdayCount: 0,
        status: .noSalary
    )
    @Published private(set) var syncState: HolidaySyncState = .idle
    @Published var salaryText: String = ""
    @Published var startText: String = "09:00"
    @Published var endText: String = "19:00"
    @Published var hasCompletedInitialSetup: Bool
    @Published var weekendEditorMonth: Date = Date()
    @Published private(set) var isPanelVisible: Bool = false

    private let settingsStore = SettingsStore()
    private let holidayService = HolidayService()
    private let calculator = IncomeCalculator()
    private var timer: Timer?
    private var holidayCalendar = HolidayCalendar(year: Calendar.current.component(.year, from: Date()))
    private var cancellables = Set<AnyCancellable>()
    private var moneyFormatters: [String: NumberFormatter] = [:]

    init() {
        let loaded = settingsStore.load()
        settings = loaded
        salaryText = loaded.annualSalary > 0 ? Self.inputFormatter.string(from: NSNumber(value: loaded.annualSalary)) ?? "" : ""
        startText = Self.format(time: loaded.workStart)
        endText = Self.format(time: loaded.workEnd)
        hasCompletedInitialSetup = loaded.annualSalary > 0
        holidayCalendar = holidayService.loadCachedCalendar(year: currentYear) ?? HolidayCalendar(year: currentYear)
        refresh()
        bindSettings()
    }

    var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }

    var syncMessage: String {
        switch syncState {
        case .idle:
            if let fetchedAt = holidayCalendar.fetchedAt {
                return "已同步 \(Self.relativeFormatter.localizedString(for: fetchedAt, relativeTo: Date()))"
            }
            return "暂用周一至周五"
        case .syncing:
            return "正在同步日历..."
        case .synced(let date):
            return "已同步 \(Self.relativeFormatter.localizedString(for: date, relativeTo: Date()))"
        case .failed(let message):
            return message
        }
    }

    var rewardMessage: RewardMessage {
        RewardCatalog.reward(
            earned: snapshot.earnedToday,
            dailyIncome: snapshot.dailyIncome,
            currencyCode: settings.currencyCode,
            date: Date(),
            calendar: Calendar.current
        )
    }

    var selectedPeriod: PeriodKind {
        settings.selectedPeriod
    }

    var rewardEntries: [RewardCatalogEntry] {
        RewardCatalog.catalogEntries
    }

    var weekendDatesForEditor: [WeekendDateOption] {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month], from: weekendEditorMonth)
        guard let start = calendar.date(from: comps),
              let end = calendar.date(byAdding: .month, value: 1, to: start)
        else { return [] }

        var result: [WeekendDateOption] = []
        var date = start
        while date < end {
            let weekday = calendar.component(.weekday, from: date)
            if weekday == 1 || weekday == 7 {
                let key = HolidayCalendar.key(for: date, calendar: calendar)
                let defaultWorking = false
                let isWorking = settings.customWeekendOverrides[key] ?? defaultWorking
                result.append(WeekendDateOption(date: date, key: key, isSaturday: weekday == 7, isWorking: isWorking))
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: date) else { break }
            date = next
        }
        return result
    }

    func start() {
        configureTimer()
        Task {
            await syncHolidays()
        }
    }

    func setPanelVisible(_ visible: Bool) {
        guard isPanelVisible != visible else { return }
        isPanelVisible = visible
        if visible {
            refresh()
        }
        configureTimer()
    }

    func refresh() {
        if holidayCalendar.year != currentYear {
            holidayCalendar = holidayService.loadCachedCalendar(year: currentYear) ?? HolidayCalendar(year: currentYear)
            Task {
                await syncHolidays()
            }
        }

        snapshot = calculator.snapshot(
            at: Date(),
            settings: settings,
            holidayCalendar: holidayCalendar,
            calendar: Calendar.current
        )
    }

    func syncHolidays() async {
        syncState = .syncing
        let result = await holidayService.sync(year: currentYear)
        switch result {
        case .success(let calendar):
            holidayCalendar = calendar
            syncState = .synced(calendar.fetchedAt ?? Date())
            refresh()
        case .failure:
            holidayCalendar = holidayService.loadCachedCalendar(year: currentYear) ?? holidayCalendar
            syncState = .failed(holidayCalendar.fetchedAt == nil ? "离线：暂用周一至周五" : "离线：使用本地节假日缓存")
            refresh()
        }
    }

    @discardableResult
    func applySalaryText() -> Bool {
        let clean = salaryText
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        settings.annualSalary = max(Double(clean) ?? 0, 0)
        persistAndRefresh()
        if settings.annualSalary > 0 {
            hasCompletedInitialSetup = true
            return true
        }
        return false
    }

    func applyTimeText() {
        if let start = Self.parseTime(startText), let end = Self.parseTime(endText) {
            settings.workStart = start
            settings.workEnd = end
        }
        startText = Self.format(time: settings.workStart)
        endText = Self.format(time: settings.workEnd)
        persistAndRefresh()
    }

    func setCurrency(code: String, symbol: String) {
        settings.currencyCode = code
        settings.currencySymbol = symbol
        persistAndRefresh()
    }

    func setPeriod(_ period: PeriodKind) {
        settings.selectedPeriod = period
        persistAndRefresh()
        configureTimer()
    }

    func toggleDashboardPrivacy() {
        settings.hideDashboardAmounts.toggle()
        persistAndRefresh()
    }

    func toggleSettingsPrivacy() {
        settings.hideSettingsAmounts.toggle()
        persistAndRefresh()
    }

    func changeWeekendEditorMonth(by value: Int) {
        weekendEditorMonth = Calendar.current.date(byAdding: .month, value: value, to: weekendEditorMonth) ?? weekendEditorMonth
    }

    func toggleWeekendOverride(_ option: WeekendDateOption) {
        settings.customWeekendOverrides[option.key] = !option.isWorking
        persistAndRefresh()
    }

    func resetWeekendOverride(_ option: WeekendDateOption) {
        settings.customWeekendOverrides.removeValue(forKey: option.key)
        persistAndRefresh()
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            settings.launchAtLogin = enabled
            persistAndRefresh()
        } catch {
            settings.launchAtLogin = false
            syncState = .failed("开机启动需要使用打包后的 App")
            persistAndRefresh()
        }
    }

    func saveSettings() -> Bool {
        applyTimeText()
        return applySalaryText()
    }

    func formatMoney(_ value: Double, fractionDigits: Int = 2) -> String {
        let key = "\(settings.currencyCode)|\(settings.currencySymbol)|\(fractionDigits)"
        let formatter: NumberFormatter
        if let cached = moneyFormatters[key] {
            formatter = cached
        } else {
            let created = NumberFormatter()
            created.numberStyle = .currency
            created.currencySymbol = settings.currencySymbol
            created.currencyCode = settings.currencyCode
            created.minimumFractionDigits = fractionDigits
            created.maximumFractionDigits = fractionDigits
            moneyFormatters[key] = created
            formatter = created
        }
        return formatter.string(from: NSNumber(value: value)) ?? "\(settings.currencySymbol)\(String(format: "%.2f", value))"
    }

    func displayMoney(_ value: Double, fractionDigits: Int = 2, hidden: Bool) -> String {
        hidden ? "***" : formatMoney(value, fractionDigits: fractionDigits)
    }

    func displayPlainNumber(_ value: Double, hidden: Bool) -> String {
        hidden ? "***" : Self.inputFormatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
    }

    private func bindSettings() {
        $settings
            .dropFirst()
            .sink { [weak self] settings in
                self?.settingsStore.save(settings)
            }
            .store(in: &cancellables)
    }

    private func persistAndRefresh() {
        settingsStore.save(settings)
        refresh()
    }

    private func configureTimer() {
        timer?.invalidate()
        timer = nil

        guard isPanelVisible else { return }

        let interval = settings.selectedPeriod == .day ? 0.1 : 1.0
        let scheduled = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
        scheduled.tolerance = settings.selectedPeriod == .day ? 0.02 : 0.25
        timer = scheduled
    }

    private static func parseTime(_ value: String) -> TimeOfDay? {
        let parts = value.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]),
              (0...23).contains(hour),
              (0...59).contains(minute)
        else {
            return nil
        }
        return TimeOfDay(hour: hour, minute: minute)
    }

    private static func format(time: TimeOfDay) -> String {
        String(format: "%02d:%02d", time.hour, time.minute)
    }

    private static let inputFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter
    }()
}

struct WeekendDateOption: Identifiable, Equatable {
    var id: String { key }
    var date: Date
    var key: String
    var isSaturday: Bool
    var isWorking: Bool

    var weekdayLabel: String {
        isSaturday ? "周六" : "周日"
    }
}
