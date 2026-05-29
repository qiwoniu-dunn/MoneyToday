import Foundation
import MoneyTodayCore
import AppKit

@main
struct MoneyTodayChecks {
    static func main() throws {
        try incomeCalculatorChecks()
        try holidayServiceChecks()
        try rewardCatalogChecks()
        try resourceChecks()
        print("MoneyTodayChecks passed")
    }

    private static func incomeCalculatorChecks() throws {
        let calculator = IncomeCalculator()
        let calendar = shanghaiCalendar()

        let midpoint = calculator.snapshot(
            at: try date("2026-05-25 14:00:00"),
            settings: AppSettings(annualSalary: 260_000),
            holidayCalendar: HolidayCalendar(year: 2026),
            calendar: calendar
        )
        assert(midpoint.status == .working)
        assert(abs(midpoint.progress - 0.5) < 0.001)
        assert(abs(midpoint.earnedToday - midpoint.dailyIncome * 0.5) < 0.01)

        let beforeWork = calculator.snapshot(
            at: try date("2026-05-25 08:30:00"),
            settings: AppSettings(annualSalary: 260_000),
            holidayCalendar: HolidayCalendar(year: 2026),
            calendar: calendar
        )
        assert(beforeWork.status == .beforeWork)
        assert(beforeWork.earnedToday == 0)

        let afterWork = calculator.snapshot(
            at: try date("2026-05-25 20:00:00"),
            settings: AppSettings(annualSalary: 260_000),
            holidayCalendar: HolidayCalendar(year: 2026),
            calendar: calendar
        )
        assert(afterWork.status == .afterWork)
        assert(afterWork.earnedToday == afterWork.dailyIncome)

        let holidayCalendar = HolidayCalendar(year: 2026, days: [
            "2026-10-01": WorkDayInfo(date: "2026-10-01", isWorkday: false, name: "National Day"),
            "2026-09-27": WorkDayInfo(date: "2026-09-27", isWorkday: true, name: "Adjusted workday")
        ])

        let holiday = calculator.snapshot(
            at: try date("2026-10-01 12:00:00"),
            settings: AppSettings(annualSalary: 260_000),
            holidayCalendar: holidayCalendar,
            calendar: calendar
        )
        assert(holiday.status == .nonWorkingDay(reason: "National Day"))
        assert(holiday.earnedToday == 0)

        let testModeHoliday = calculator.snapshot(
            at: try date("2026-10-01 12:00:00"),
            settings: AppSettings(annualSalary: 260_000, testMode: true),
            holidayCalendar: holidayCalendar,
            calendar: calendar
        )
        assert(testModeHoliday.status == .working)
        assert(testModeHoliday.earnedToday > 0)

        let adjustedWorkday = calculator.snapshot(
            at: try date("2026-09-27 12:00:00"),
            settings: AppSettings(annualSalary: 260_000),
            holidayCalendar: holidayCalendar,
            calendar: calendar
        )
        assert(adjustedWorkday.status == .working)
        assert(adjustedWorkday.earnedToday > 0)

        let plainCount = HolidayCalendar(year: 2026).workdayCount(calendar: calendar)
        let oneHolidayCount = HolidayCalendar(year: 2026, days: [
            "2026-05-25": WorkDayInfo(date: "2026-05-25", isWorkday: false, name: "Company holiday")
        ]).workdayCount(calendar: calendar)
        assert(oneHolidayCount == plainCount - 1)

        let weekSnapshot = calculator.snapshot(
            at: try date("2026-05-25 14:00:00"),
            settings: AppSettings(annualSalary: 260_000, selectedPeriod: .week),
            holidayCalendar: HolidayCalendar(year: 2026),
            calendar: calendar
        )
        assert(weekSnapshot.period.kind == .week)
        assert(weekSnapshot.period.workdayCount == 5)
        assert(abs(weekSnapshot.period.earned - weekSnapshot.dailyIncome * 0.5) < 0.01)

        let monthSnapshot = calculator.snapshot(
            at: try date("2026-05-25 14:00:00"),
            settings: AppSettings(annualSalary: 260_000, selectedPeriod: .month),
            holidayCalendar: HolidayCalendar(year: 2026),
            calendar: calendar
        )
        assert(monthSnapshot.period.kind == .month)
        assert(monthSnapshot.period.earned > monthSnapshot.dailyIncome * 10)

        let saturdayKey = "2026-05-23"
        let saturdayOverride = calculator.snapshot(
            at: try date("2026-05-23 12:00:00"),
            settings: AppSettings(annualSalary: 260_000, customWeekendOverrides: [saturdayKey: true]),
            holidayCalendar: HolidayCalendar(year: 2026),
            calendar: calendar
        )
        assert(saturdayOverride.status == .working)
        assert(saturdayOverride.earnedToday > 0)
        assert(HolidayCalendar(year: 2026).workdayCount(calendar: calendar, weekendOverrides: [saturdayKey: true]) == plainCount + 1)
    }

    private static func holidayServiceChecks() throws {
        let restPayload = """
        {
          "data": [
            {"date": "2026-10-01", "name": "National Day", "holiday": true},
            {"date": "2026-09-27", "name": "Adjusted workday", "holiday": false}
          ]
        }
        """.data(using: .utf8)!

        let restCalendar = try HolidayService.parseHolidayPayload(data: restPayload, year: 2026)
        assert(restCalendar.days["2026-10-01"]?.isWorkday == false)
        assert(restCalendar.days["2026-09-27"]?.isWorkday == true)

        let workdayPayload = """
        {
          "result": {
            "days": [
              {"date": "20260501", "name": "Labor Day", "isWorkday": false},
              {"date": "05-09", "name": "Adjusted workday", "isWorkday": true}
            ]
          }
        }
        """.data(using: .utf8)!

        let workdayCalendar = try HolidayService.parseHolidayPayload(data: workdayPayload, year: 2026)
        assert(workdayCalendar.days["2026-05-01"]?.isWorkday == false)
        assert(workdayCalendar.days["2026-05-09"]?.isWorkday == true)

        let calendar = shanghaiCalendar()
        let saturday = try dateOnly("2026-05-23")
        let monday = try dateOnly("2026-05-25")
        let fallback = HolidayCalendar(year: 2026)
        assert(fallback.workdayInfo(for: saturday, calendar: calendar).isWorkday == false)
        assert(fallback.workdayInfo(for: monday, calendar: calendar).isWorkday == true)
        assert(fallback.workdayInfo(for: saturday, calendar: calendar, weekendOverrides: ["2026-05-23": true]).isWorkday == true)
    }

    private static func rewardCatalogChecks() throws {
        let calendar = shanghaiCalendar()
        let date = try date("2026-05-25 14:00:00")

        let low = RewardCatalog.reward(earned: 80, dailyIncome: 420, currencyCode: "CNY", date: date, calendar: calendar)
        let mid = RewardCatalog.reward(earned: 500, dailyIncome: 1000, currencyCode: "CNY", date: date, calendar: calendar)
        let high = RewardCatalog.reward(earned: 1800, dailyIncome: 2600, currencyCode: "CNY", date: date, calendar: calendar)
        assert(!low.title.isEmpty && !low.detail.isEmpty)
        assert(!mid.title.isEmpty && !mid.detail.isEmpty)
        assert(!high.title.isEmpty && !high.detail.isEmpty)
        assert(low.count >= 1)
        assert(mid.count >= 1)
        assert(high.count >= 1)
        assert(!low.assetName.isEmpty)
        assert(!mid.assetName.isEmpty)
        assert(!high.assetName.isEmpty)

        let sameDayAgain = RewardCatalog.reward(earned: 500, dailyIncome: 1000, currencyCode: "CNY", date: date, calendar: calendar)
        assert(mid == sameDayAgain)

        var weekMessages = Set<String>()
        for offset in 0..<7 {
            let nextDate = calendar.date(byAdding: .day, value: offset, to: date)!
            let reward = RewardCatalog.reward(earned: 500, dailyIncome: 1000, currencyCode: "CNY", date: nextDate, calendar: calendar)
            weekMessages.insert(reward.title + reward.detail)
        }
        assert(weekMessages.count > 1)

        let usd = RewardCatalog.reward(earned: 100, dailyIncome: 200, currencyCode: "USD", date: date, calendar: calendar)
        assert(!usd.title.isEmpty && !usd.detail.isEmpty)

        let justStarted = RewardCatalog.reward(earned: 0, dailyIncome: 1000, currencyCode: "CNY", date: date, calendar: calendar)
        assert(justStarted.count == 0)
        assert(RewardCatalog.catalogEntries.count == 300)
        assert(RewardCatalog.catalogEntries.allSatisfy { !$0.assetName.isEmpty })
    }

    private static func resourceChecks() throws {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let rewardsDir = root.appendingPathComponent("Sources/MoneyTodayApp/Resources/RewardsV2/final-47")
        for entry in RewardCatalog.catalogEntries where entry.enabled {
            let url = rewardsDir.appendingPathComponent("\(entry.assetName).png")
            assert(FileManager.default.fileExists(atPath: url.path), "Missing reward asset \(entry.assetName)")
            assert(NSImage(contentsOf: url) != nil, "Invalid reward asset \(entry.assetName)")
        }

        let spriteURL = root.appendingPathComponent("Sources/MoneyTodayApp/Resources/Pets/zhima/spritesheet.webp")
        guard let image = NSImage(contentsOf: spriteURL) else {
            assertionFailure("Missing zhima spritesheet")
            return
        }
        assert(Int(image.size.width) == 1536)
        assert(Int(image.size.height) == 1872)
    }

    private static func shanghaiCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        return calendar
    }

    private static func date(_ value: String) throws -> Date {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        guard let date = formatter.date(from: value) else {
            throw CheckError.invalidDate(value)
        }
        return date
    }

    private static func dateOnly(_ value: String) throws -> Date {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: value) else {
            throw CheckError.invalidDate(value)
        }
        return date
    }
}

private enum CheckError: Error {
    case invalidDate(String)
}
