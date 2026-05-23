import Foundation

public struct IncomeCalculator: Sendable {
    public init() {}

    public func snapshot(
        at now: Date,
        settings: AppSettings,
        holidayCalendar: HolidayCalendar,
        calendar inputCalendar: Calendar = .current
    ) -> MoneySnapshot {
        var calendar = inputCalendar
        calendar.timeZone = inputCalendar.timeZone

        let workdayCount = max(holidayCalendar.workdayCount(calendar: calendar), 1)
        let dailyIncome = max(settings.annualSalary, 0) / Double(workdayCount)

        guard settings.annualSalary > 0 else {
            return MoneySnapshot(
                earnedToday: 0,
                dailyIncome: dailyIncome,
                perSecondIncome: 0,
                progress: 0,
                workdayCount: workdayCount,
                status: .noSalary
            )
        }

        let dayInfo = holidayCalendar.workdayInfo(for: now, calendar: calendar)
        guard settings.testMode || dayInfo.isWorkday else {
            return MoneySnapshot(
                earnedToday: 0,
                dailyIncome: dailyIncome,
                perSecondIncome: 0,
                progress: 0,
                workdayCount: workdayCount,
                status: .nonWorkingDay(reason: dayInfo.name.isEmpty ? "非工作日" : dayInfo.name)
            )
        }

        guard let start = date(onSameDayAs: now, time: settings.workStart, calendar: calendar),
              let end = date(onSameDayAs: now, time: settings.workEnd, calendar: calendar),
              end > start
        else {
            return MoneySnapshot(
                earnedToday: 0,
                dailyIncome: dailyIncome,
                perSecondIncome: 0,
                progress: 0,
                workdayCount: workdayCount,
                status: .beforeWork
            )
        }

        let totalSeconds = end.timeIntervalSince(start)
        let perSecondIncome = dailyIncome / totalSeconds

        if now < start {
            return MoneySnapshot(
                earnedToday: 0,
                dailyIncome: dailyIncome,
                perSecondIncome: perSecondIncome,
                progress: 0,
                workdayCount: workdayCount,
                status: .beforeWork
            )
        }

        if now >= end {
            return MoneySnapshot(
                earnedToday: dailyIncome,
                dailyIncome: dailyIncome,
                perSecondIncome: perSecondIncome,
                progress: 1,
                workdayCount: workdayCount,
                status: .afterWork
            )
        }

        let elapsed = now.timeIntervalSince(start)
        let progress = elapsed / totalSeconds
        return MoneySnapshot(
            earnedToday: dailyIncome * progress,
            dailyIncome: dailyIncome,
            perSecondIncome: perSecondIncome,
            progress: progress,
            workdayCount: workdayCount,
            status: .working
        )
    }

    private func date(onSameDayAs date: Date, time: TimeOfDay, calendar: Calendar) -> Date? {
        let day = calendar.dateComponents([.year, .month, .day], from: date)
        return calendar.date(from: DateComponents(
            timeZone: calendar.timeZone,
            year: day.year,
            month: day.month,
            day: day.day,
            hour: time.hour,
            minute: time.minute
        ))
    }
}
