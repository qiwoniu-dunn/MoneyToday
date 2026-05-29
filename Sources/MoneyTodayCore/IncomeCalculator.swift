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
        calendar.firstWeekday = 2

        let workdayCount = max(holidayCalendar.workdayCount(calendar: calendar, weekendOverrides: settings.customWeekendOverrides), 1)
        let dailyIncome = max(settings.annualSalary, 0) / Double(workdayCount)

        guard settings.annualSalary > 0 else {
            return MoneySnapshot(
                earnedToday: 0,
                dailyIncome: dailyIncome,
                perSecondIncome: 0,
                progress: 0,
                workdayCount: workdayCount,
                status: .noSalary,
                period: MoneyPeriodSnapshot(kind: settings.selectedPeriod, earned: 0, limit: 0, progress: 0, workdayCount: 0)
            )
        }

        let selectedPeriod = periodSnapshot(
            settings.selectedPeriod,
            at: now,
            settings: settings,
            holidayCalendar: holidayCalendar,
            dailyIncome: dailyIncome,
            calendar: calendar
        )

        let dayInfo = holidayCalendar.workdayInfo(for: now, calendar: calendar, weekendOverrides: settings.customWeekendOverrides)
        guard settings.testMode || dayInfo.isWorkday else {
            return MoneySnapshot(
                earnedToday: 0,
                dailyIncome: dailyIncome,
                perSecondIncome: 0,
                progress: 0,
                workdayCount: workdayCount,
                status: .nonWorkingDay(reason: dayInfo.name.isEmpty ? "非工作日" : dayInfo.name),
                period: selectedPeriod
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
                status: .beforeWork,
                period: selectedPeriod
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
                status: .beforeWork,
                period: selectedPeriod
            )
        }

        if now >= end {
            return MoneySnapshot(
                earnedToday: dailyIncome,
                dailyIncome: dailyIncome,
                perSecondIncome: perSecondIncome,
                progress: 1,
                workdayCount: workdayCount,
                status: .afterWork,
                period: selectedPeriod
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
            status: .working,
            period: selectedPeriod
        )
    }

    public func periodSnapshot(
        _ kind: PeriodKind,
        at now: Date,
        settings: AppSettings,
        holidayCalendar: HolidayCalendar,
        calendar inputCalendar: Calendar = .current
    ) -> MoneyPeriodSnapshot {
        var calendar = inputCalendar
        calendar.timeZone = inputCalendar.timeZone
        calendar.firstWeekday = 2
        let workdayCount = max(holidayCalendar.workdayCount(calendar: calendar, weekendOverrides: settings.customWeekendOverrides), 1)
        let dailyIncome = max(settings.annualSalary, 0) / Double(workdayCount)
        return periodSnapshot(kind, at: now, settings: settings, holidayCalendar: holidayCalendar, dailyIncome: dailyIncome, calendar: calendar)
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

    private func periodSnapshot(
        _ kind: PeriodKind,
        at now: Date,
        settings: AppSettings,
        holidayCalendar: HolidayCalendar,
        dailyIncome: Double,
        calendar: Calendar
    ) -> MoneyPeriodSnapshot {
        guard settings.annualSalary > 0 else {
            return MoneyPeriodSnapshot(kind: kind, earned: 0, limit: 0, progress: 0, workdayCount: 0)
        }

        let range = periodRange(kind, containing: now, calendar: calendar)
        var date = range.start
        var earned = 0.0
        var limit = 0.0
        var workdays = 0

        while date < range.end {
            let info = holidayCalendar.workdayInfo(for: date, calendar: calendar, weekendOverrides: settings.customWeekendOverrides)
            let isCountedWorkday = settings.testMode || info.isWorkday
            if isCountedWorkday {
                workdays += 1
                limit += dailyIncome
                earned += earnedOnDay(date, now: now, dailyIncome: dailyIncome, settings: settings, calendar: calendar)
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: date) else { break }
            date = next
        }

        return MoneyPeriodSnapshot(
            kind: kind,
            earned: earned,
            limit: limit,
            progress: limit > 0 ? earned / limit : 0,
            workdayCount: workdays
        )
    }

    private func earnedOnDay(
        _ day: Date,
        now: Date,
        dailyIncome: Double,
        settings: AppSettings,
        calendar: Calendar
    ) -> Double {
        guard let start = date(onSameDayAs: day, time: settings.workStart, calendar: calendar),
              let end = date(onSameDayAs: day, time: settings.workEnd, calendar: calendar),
              end > start
        else {
            return 0
        }

        if end <= now {
            return dailyIncome
        }
        if start >= now {
            return 0
        }
        return dailyIncome * (now.timeIntervalSince(start) / end.timeIntervalSince(start))
    }

    private func periodRange(_ kind: PeriodKind, containing date: Date, calendar: Calendar) -> (start: Date, end: Date) {
        switch kind {
        case .day:
            let start = calendar.startOfDay(for: date)
            return (start, calendar.date(byAdding: .day, value: 1, to: start) ?? date)
        case .week:
            let comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
            let start = calendar.date(from: comps).map { calendar.startOfDay(for: $0) } ?? calendar.startOfDay(for: date)
            return (start, calendar.date(byAdding: .day, value: 7, to: start) ?? date)
        case .month:
            let comps = calendar.dateComponents([.year, .month], from: date)
            let start = calendar.date(from: comps).map { calendar.startOfDay(for: $0) } ?? calendar.startOfDay(for: date)
            return (start, calendar.date(byAdding: .month, value: 1, to: start) ?? date)
        case .year:
            let comps = calendar.dateComponents([.year], from: date)
            let start = calendar.date(from: comps).map { calendar.startOfDay(for: $0) } ?? calendar.startOfDay(for: date)
            return (start, calendar.date(byAdding: .year, value: 1, to: start) ?? date)
        }
    }
}
