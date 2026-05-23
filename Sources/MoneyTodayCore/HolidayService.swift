import Foundation

public enum HolidaySyncState: Equatable, Sendable {
    case idle
    case syncing
    case synced(Date)
    case failed(String)
}

public final class HolidayService: HolidayCalendarProviding, @unchecked Sendable {
    private let cacheURL: URL
    private let session: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    public init(cacheDirectory: URL? = nil, session: URLSession = .shared) {
        let baseDirectory = cacheDirectory ?? FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.temporaryDirectory

        self.cacheURL = baseDirectory
            .appendingPathComponent("MoneyToday", isDirectory: true)
            .appendingPathComponent("holiday-cache.json")
        self.session = session
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    public func calendar(for year: Int) async -> HolidayCalendar {
        if let cached = loadCachedCalendar(year: year) {
            return cached
        }
        return HolidayCalendar(year: year)
    }

    public func sync(year: Int) async -> Result<HolidayCalendar, Error> {
        do {
            let calendar = try await fetchCalendar(year: year)
            try save(calendar)
            return .success(calendar)
        } catch {
            return .failure(error)
        }
    }

    public func loadCachedCalendar(year: Int) -> HolidayCalendar? {
        guard let data = try? Data(contentsOf: cacheURL),
              let calendars = try? decoder.decode([HolidayCalendar].self, from: data)
        else {
            return nil
        }
        return calendars.first { $0.year == year }
    }

    private func fetchCalendar(year: Int) async throws -> HolidayCalendar {
        let attempts = [
            URL(string: "https://holiday.ailcc.com/api/holiday/year/\(year)"),
            URL(string: "https://api.jiejiariapi.com/v1/holidays/\(year)")
        ].compactMap { $0 }

        var lastError: Error?
        for url in attempts {
            do {
                let (data, response) = try await session.data(from: url)
                guard let http = response as? HTTPURLResponse,
                      (200..<300).contains(http.statusCode)
                else {
                    throw URLError(.badServerResponse)
                }

                let parsed = try Self.parseHolidayPayload(data: data, year: year)
                if !parsed.days.isEmpty {
                    return parsed
                }
            } catch {
                lastError = error
            }
        }

        throw lastError ?? URLError(.cannotParseResponse)
    }

    private func save(_ calendar: HolidayCalendar) throws {
        try FileManager.default.createDirectory(
            at: cacheURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        var calendars = [HolidayCalendar]()
        if let data = try? Data(contentsOf: cacheURL),
           let cached = try? decoder.decode([HolidayCalendar].self, from: data) {
            calendars = cached.filter { $0.year != calendar.year }
        }

        calendars.append(calendar)
        try encoder.encode(calendars).write(to: cacheURL, options: .atomic)
    }

    public static func parseHolidayPayload(data: Data, year: Int) throws -> HolidayCalendar {
        let root = try JSONSerialization.jsonObject(with: data)
        let entries = collectObjects(in: root).compactMap { object -> WorkDayInfo? in
            guard let date = stringValue(object, keys: ["date", "day", "ymd", "time"])?.normalizedDate(year: year) else {
                return nil
            }

            let name = stringValue(object, keys: ["name", "holiday", "festival", "desc", "cnName"]) ?? ""
            let restValue = boolValue(object, keys: ["holiday", "isHoliday", "rest", "isOffDay", "offDay"])
            let workValue = boolValue(object, keys: ["workday", "isWorkday", "is_workday", "work", "adjustedWorkday"])

            let isWorkday: Bool
            if let workValue {
                isWorkday = workValue
            } else if let restValue {
                isWorkday = !restValue
            } else {
                return nil
            }

            return WorkDayInfo(date: date, isWorkday: isWorkday, name: name)
        }

        var days = [String: WorkDayInfo]()
        for entry in entries {
            days[entry.date] = entry
        }
        return HolidayCalendar(year: year, days: days, fetchedAt: Date())
    }

    private static func collectObjects(in value: Any) -> [[String: Any]] {
        if let object = value as? [String: Any] {
            return [object] + object.values.flatMap { collectObjects(in: $0) }
        }
        if let array = value as? [Any] {
            return array.flatMap { collectObjects(in: $0) }
        }
        return []
    }

    private static func stringValue(_ object: [String: Any], keys: [String]) -> String? {
        for key in keys {
            if let string = object[key] as? String, !string.isEmpty {
                return string
            }
            if let number = object[key] as? NSNumber {
                return number.stringValue
            }
        }
        return nil
    }

    private static func boolValue(_ object: [String: Any], keys: [String]) -> Bool? {
        for key in keys {
            if let bool = object[key] as? Bool {
                return bool
            }
            if let number = object[key] as? NSNumber {
                return number.intValue != 0
            }
            if let string = object[key] as? String {
                let lowercased = string.lowercased()
                if ["true", "yes", "1", "work", "workday"].contains(lowercased) {
                    return true
                }
                if ["false", "no", "0", "rest", "holiday"].contains(lowercased) {
                    return false
                }
            }
        }
        return nil
    }
}

private extension String {
    func normalizedDate(year: Int) -> String? {
        if range(of: #"^\d{4}-\d{2}-\d{2}$"#, options: .regularExpression) != nil {
            return self
        }

        if range(of: #"^\d{8}$"#, options: .regularExpression) != nil {
            let y = prefix(4)
            let m = dropFirst(4).prefix(2)
            let d = suffix(2)
            return "\(y)-\(m)-\(d)"
        }

        if range(of: #"^\d{2}-\d{2}$"#, options: .regularExpression) != nil {
            return "\(year)-\(self)"
        }

        return nil
    }
}

