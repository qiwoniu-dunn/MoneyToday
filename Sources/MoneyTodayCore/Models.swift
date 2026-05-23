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

    public init(
        annualSalary: Double = 0,
        currencyCode: String = "CNY",
        currencySymbol: String = "¥",
        workStart: TimeOfDay = .defaultStart,
        workEnd: TimeOfDay = .defaultEnd,
        launchAtLogin: Bool = false,
        testMode: Bool = false
    ) {
        self.annualSalary = annualSalary
        self.currencyCode = currencyCode
        self.currencySymbol = currencySymbol
        self.workStart = workStart
        self.workEnd = workEnd
        self.launchAtLogin = launchAtLogin
        self.testMode = testMode
    }

    private enum CodingKeys: String, CodingKey {
        case annualSalary
        case currencyCode
        case currencySymbol
        case workStart
        case workEnd
        case launchAtLogin
        case testMode
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

    public init(
        earnedToday: Double,
        dailyIncome: Double,
        perSecondIncome: Double,
        progress: Double,
        workdayCount: Int,
        status: WorkStatus
    ) {
        self.earnedToday = earnedToday
        self.dailyIncome = dailyIncome
        self.perSecondIncome = perSecondIncome
        self.progress = min(max(progress, 0), 1)
        self.workdayCount = workdayCount
        self.status = status
    }
}
