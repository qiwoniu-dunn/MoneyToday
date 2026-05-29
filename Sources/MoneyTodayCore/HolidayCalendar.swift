import Foundation

public struct HolidayCalendar: Codable, Equatable, Sendable {
    public var year: Int
    public var days: [String: WorkDayInfo]
    public var fetchedAt: Date?

    public init(year: Int, days: [String: WorkDayInfo] = [:], fetchedAt: Date? = nil) {
        self.year = year
        self.days = days
        self.fetchedAt = fetchedAt
    }

    public func workdayInfo(
        for date: Date,
        calendar: Calendar = .current,
        weekendOverrides: [String: Bool] = [:]
    ) -> WorkDayInfo {
        let key = Self.key(for: date, calendar: calendar)
        let weekday = calendar.component(.weekday, from: date)
        let isWeekend = weekday == 1 || weekday == 7

        if isWeekend, let override = weekendOverrides[key] {
            return WorkDayInfo(date: key, isWorkday: override, name: override ? "自定义周末工作" : "自定义周末休息")
        }

        if let info = days[key] {
            return info
        }

        return WorkDayInfo(date: key, isWorkday: !isWeekend, name: isWeekend ? "周末休息" : "工作日")
    }

    public func workdayCount(calendar: Calendar = .current, weekendOverrides: [String: Bool] = [:]) -> Int {
        guard let first = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
              let nextYear = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1))
        else {
            return 0
        }

        var count = 0
        var date = first
        while date < nextYear {
            if workdayInfo(for: date, calendar: calendar, weekendOverrides: weekendOverrides).isWorkday {
                count += 1
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: date) else { break }
            date = next
        }
        return count
    }

    public static let keyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    public static func key(for date: Date, calendar inputCalendar: Calendar = .current) -> String {
        var calendar = inputCalendar
        calendar.timeZone = inputCalendar.timeZone
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 1, components.day ?? 1)
    }
}

public protocol HolidayCalendarProviding: Sendable {
    func calendar(for year: Int) async -> HolidayCalendar
}

public struct StaticHolidayCalendarProvider: HolidayCalendarProviding {
    private let calendars: [Int: HolidayCalendar]

    public init(_ calendars: [Int: HolidayCalendar]) {
        self.calendars = calendars
    }

    public func calendar(for year: Int) async -> HolidayCalendar {
        calendars[year] ?? HolidayCalendar(year: year)
    }
}
