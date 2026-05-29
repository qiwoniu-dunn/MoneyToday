import Foundation

public struct TimeOfDay: Codable, Equatable, Sendable {
    public var hour: Int
    public var minute: Int

    public init(hour: Int, minute: Int) {
        self.hour = min(max(hour, 0), 23)
        self.minute = min(max(minute, 0), 59)
    }

    public static let defaultStart = TimeOfDay(hour: 9, minute: 0)
    public static let defaultEnd = TimeOfDay(hour: 19, minute: 0)
}

public struct AppSettings: Codable, Equatable, Sendable {
    public var annualSalary: Double
    public var currencyCode: String
    public var currencySymbol: String
    public var workStart: TimeOfDay
    public var workEnd: TimeOfDay
    public var launchAtLogin: Bool
    public var testMode: Bool
    public var selectedPeriod: PeriodKind
    public var hideDashboardAmounts: Bool
    public var hideSettingsAmounts: Bool
    public var customWeekendOverrides: [String: Bool]

    public init(
        annualSalary: Double = 0,
        currencyCode: String = "CNY",
        currencySymbol: String = "¥",
        workStart: TimeOfDay = .defaultStart,
        workEnd: TimeOfDay = .defaultEnd,
        launchAtLogin: Bool = false,
        testMode: Bool = false,
        selectedPeriod: PeriodKind = .day,
        hideDashboardAmounts: Bool = false,
        hideSettingsAmounts: Bool = false,
        customWeekendOverrides: [String: Bool] = [:]
    ) {
        self.annualSalary = annualSalary
        self.currencyCode = currencyCode
        self.currencySymbol = currencySymbol
        self.workStart = workStart
        self.workEnd = workEnd
        self.launchAtLogin = launchAtLogin
        self.testMode = testMode
        self.selectedPeriod = selectedPeriod
        self.hideDashboardAmounts = hideDashboardAmounts
        self.hideSettingsAmounts = hideSettingsAmounts
        self.customWeekendOverrides = customWeekendOverrides
    }

    private enum CodingKeys: String, CodingKey {
        case annualSalary
        case currencyCode
        case currencySymbol
        case workStart
        case workEnd
        case launchAtLogin
        case testMode
        case selectedPeriod
        case hideDashboardAmounts
        case hideSettingsAmounts
        case customWeekendOverrides
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        annualSalary = try container.decodeIfPresent(Double.self, forKey: .annualSalary) ?? 0
        currencyCode = try container.decodeIfPresent(String.self, forKey: .currencyCode) ?? "CNY"
        currencySymbol = try container.decodeIfPresent(String.self, forKey: .currencySymbol) ?? "¥"
        workStart = try container.decodeIfPresent(TimeOfDay.self, forKey: .workStart) ?? .defaultStart
        workEnd = try container.decodeIfPresent(TimeOfDay.self, forKey: .workEnd) ?? .defaultEnd
        launchAtLogin = try container.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? false
        testMode = try container.decodeIfPresent(Bool.self, forKey: .testMode) ?? false
        selectedPeriod = try container.decodeIfPresent(PeriodKind.self, forKey: .selectedPeriod) ?? .day
        hideDashboardAmounts = try container.decodeIfPresent(Bool.self, forKey: .hideDashboardAmounts) ?? false
        hideSettingsAmounts = try container.decodeIfPresent(Bool.self, forKey: .hideSettingsAmounts) ?? false
        customWeekendOverrides = try container.decodeIfPresent([String: Bool].self, forKey: .customWeekendOverrides) ?? [:]
    }
}

public enum PeriodKind: String, CaseIterable, Codable, Equatable, Sendable {
    case day
    case week
    case month
    case year

    public var title: String {
        switch self {
        case .day: return "日"
        case .week: return "周"
        case .month: return "月"
        case .year: return "年"
        }
    }

    public var metricTitle: String {
        switch self {
        case .day: return "今日已赚"
        case .week: return "本周已赚"
        case .month: return "本月已赚"
        case .year: return "今年已赚"
        }
    }
}

public enum WorkStatus: Equatable, Sendable {
    case noSalary
    case beforeWork
    case working
    case afterWork
    case nonWorkingDay(reason: String)

    public var title: String {
        switch self {
        case .noSalary:
            return "请先设置年薪"
        case .beforeWork:
            return "还没到工作时间"
        case .working:
            return "正在赚钱"
        case .afterWork:
            return "今日工作已结束"
        case .nonWorkingDay(let reason):
            return reason
        }
    }
}

public struct WorkDayInfo: Codable, Equatable, Sendable {
    public var date: String
    public var isWorkday: Bool
    public var name: String

    public init(date: String, isWorkday: Bool, name: String = "") {
        self.date = date
        self.isWorkday = isWorkday
        self.name = name
    }
}

public struct MoneySnapshot: Equatable, Sendable {
    public var earnedToday: Double
    public var dailyIncome: Double
    public var perSecondIncome: Double
    public var progress: Double
    public var workdayCount: Int
    public var status: WorkStatus
    public var period: MoneyPeriodSnapshot

    public init(
        earnedToday: Double,
        dailyIncome: Double,
        perSecondIncome: Double,
        progress: Double,
        workdayCount: Int,
        status: WorkStatus,
        period: MoneyPeriodSnapshot? = nil
    ) {
        self.earnedToday = earnedToday
        self.dailyIncome = dailyIncome
        self.perSecondIncome = perSecondIncome
        self.progress = min(max(progress, 0), 1)
        self.workdayCount = workdayCount
        self.status = status
        self.period = period ?? MoneyPeriodSnapshot(
            kind: .day,
            earned: earnedToday,
            limit: dailyIncome,
            progress: min(max(progress, 0), 1),
            workdayCount: status == .noSalary ? 0 : 1
        )
    }
}

public struct MoneyPeriodSnapshot: Equatable, Sendable {
    public var kind: PeriodKind
    public var earned: Double
    public var limit: Double
    public var progress: Double
    public var workdayCount: Int

    public init(
        kind: PeriodKind,
        earned: Double,
        limit: Double,
        progress: Double,
        workdayCount: Int
    ) {
        self.kind = kind
        self.earned = max(earned, 0)
        self.limit = max(limit, 0)
        self.progress = min(max(progress, 0), 1)
        self.workdayCount = max(workdayCount, 0)
    }
}
