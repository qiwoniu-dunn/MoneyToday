import Foundation

public struct RewardMessage: Equatable, Sendable {
    public var title: String
    public var detail: String
    public var itemName: String
    public var count: Int
    public var iconKind: RewardIconKind

    public init(title: String, detail: String, itemName: String, count: Int, iconKind: RewardIconKind) {
        self.title = title
        self.detail = detail
        self.itemName = itemName
        self.count = count
        self.iconKind = iconKind
    }
}

public enum RewardIconKind: String, Equatable, Sendable {
    case spark
    case coffee
    case tea
    case meal
    case ride
    case movie
    case wellness
    case keyboard
    case mouse
    case beauty
    case headphones
    case camera
    case hotel
    case travel
    case phone
    case laptop
}

public enum RewardCatalog {
    public static func reward(
        earned: Double,
        dailyIncome: Double,
        currencyCode: String,
        date: Date,
        calendar: Calendar = .current
    ) -> RewardMessage {
        let earnedCNY = max(earned, 0) * cnyRate(for: currencyCode)
        let dailyCNY = max(dailyIncome, 1) * cnyRate(for: currencyCode)
        if earnedCNY < 8 {
            return RewardMessage(
                title: "今天刚开始，也算正式启动。",
                detail: "先让数字跑起来，第一份小确幸马上就到。",
                itemName: "启动奖励",
                count: 0,
                iconKind: .spark
            )
        }
        let tier = SalaryTier(dailyIncomeCNY: dailyCNY)
        let bucket = ProgressBucket(progress: earnedCNY / dailyCNY)
        let pool = items
            .filter { $0.tiers.contains(tier) && $0.buckets.contains(bucket) && $0.priceCNY <= max(earnedCNY, 8) }

        let candidates = pool.isEmpty
            ? items.filter { $0.tiers.contains(tier) && $0.priceCNY <= max(earnedCNY, 8) }
            : pool
        let fallback = items.filter { $0.tiers.contains(tier) }.min { $0.priceCNY < $1.priceCNY }
        let selectedPool = candidates.isEmpty ? [fallback].compactMap { $0 } : candidates
        let index = stableIndex(
            key: "\(dayKey(for: date, calendar: calendar))|\(currencyCode)|\(tier.rawValue)|\(bucket.rawValue)|\(Int(dailyCNY))",
            count: selectedPool.count
        )
        let item = selectedPool[index]
        let count = max(1, Int(floor(earnedCNY / item.priceCNY)))
        return RewardMessage(
            title: item.titles[stableIndex(key: "\(index)|title|\(dayKey(for: date, calendar: calendar))", count: item.titles.count)],
            detail: item.detail(count: count, seed: "\(index)|detail|\(dayKey(for: date, calendar: calendar))"),
            itemName: item.name,
            count: count,
            iconKind: item.iconKind
        )
    }

    private static func cnyRate(for currencyCode: String) -> Double {
        switch currencyCode.uppercased() {
        case "CNY", "RMB":
            return 1
        case "USD":
            return 7.2
        case "EUR":
            return 7.8
        case "GBP":
            return 9.1
        case "JPY":
            return 0.046
        default:
            return 1
        }
    }

    private static func dayKey(for date: Date, calendar inputCalendar: Calendar) -> String {
        var calendar = inputCalendar
        calendar.timeZone = inputCalendar.timeZone
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
    }

    private static func stableIndex(key: String, count: Int) -> Int {
        guard count > 0 else { return 0 }
        var hash = 5381
        for scalar in key.unicodeScalars {
            hash = ((hash << 5) &+ hash) &+ Int(scalar.value)
        }
        return abs(hash) % count
    }

    private static let items: [RewardItem] = [
        RewardItem("便利店咖啡", 8, "杯", .coffee, [.low, .mid], [.start, .early], ["今天的咖啡自由已经到账。", "先给清醒的自己加一杯。"], ["约等于 %@，开工的小火苗亮起来了。", "%@已经稳稳拿下，今天有个轻快开头。", "先攒到%@，这一口清醒是你自己赚的。"]),
        RewardItem("拿铁", 28, "杯", .coffee, [.low, .mid, .high], [.early, .morning], ["一杯体面的拿铁已经收入囊中。", "今天的咖啡仪式感有了。"], ["约等于%@，早上的努力已经有香气了。", "%@在手，今天的状态可以再往前推一格。", "你已经赚出%@，给自己一点顺滑的奖励。"]),
        RewardItem("奶茶", 18, "杯", .tea, [.low, .mid], [.early, .morning], ["甜一点的奖励已经赚出来了。", "奶茶小确幸到账。"], ["约等于%@，苦日子里也有甜的部分。", "%@已经出现，今天不是只有待办事项。", "你给自己赚到%@，小快乐合理到账。"]),
        RewardItem("热乎早餐", 15, "份", .meal, [.low, .mid], [.start, .early], ["早餐钱已经稳稳拿下。", "今天从一份热乎早餐开始回血。"], ["约等于%@，胃和心情都可以被照顾一下。", "%@已经到手，今天的底气从热气开始。", "你已经赚出%@，这一天不是空启动。"]),
        RewardItem("工作日午餐", 35, "顿", .meal, [.low, .mid], [.morning, .noon], ["一顿踏实午饭已经到账。", "中午可以吃得更安心一点。"], ["约等于%@，午饭可以不用太委屈。", "%@稳了，今天的能量补给有着落。", "你已经赚到%@，给认真干活的人加餐。"]),
        RewardItem("麦当劳套餐", 42, "份", .meal, [.low, .mid], [.morning, .noon], ["快乐套餐被你赚出来了。", "今天的快餐快乐已经有了。"], ["约等于%@，快乐可以简单但不能缺席。", "%@已经到账，打工人的小胜利很具体。", "你赚到了%@，今天可以拥有一点熟悉的快乐。"]),
        RewardItem("打车短途", 45, "次", .ride, [.low, .mid], [.morning, .noon], ["少挤一段路的底气有了。", "今天已经赚到一次舒服回程。"], ["约等于%@，身体可以少吃一点通勤的苦。", "%@已经攒下，今天有资格舒服一点。", "你赚到%@，回家的路可以更松弛。"]),
        RewardItem("电影票", 50, "张", .movie, [.low, .mid], [.noon, .afternoon], ["一场电影的放松已经到账。", "今晚的银幕时间被你攒出来了。"], ["约等于%@，现实之外的两个小时有了。", "%@已经到手，今天可以给大脑放个短假。", "你赚出%@，晚上的剧情可以由你选择。"]),
        RewardItem("健身单次课", 80, "次", .wellness, [.low, .mid], [.afternoon, .late], ["给身体充电的钱已经有了。", "今天也给健康攒了一点预算。"], ["约等于%@，照顾身体也算今天的成果。", "%@已经攒下，别忘了给自己回血。", "你赚到%@，今天的力量感不是假的。"]),
        RewardItem("周末早午餐", 120, "顿", .meal, [.low, .mid], [.afternoon, .late], ["一顿漂亮早午餐已经收入囊中。", "周末的小体面正在变真实。"], ["约等于%@，松弛感被你一点点攒出来了。", "%@已经落袋，周末可以更像周末。", "你赚出%@，生活感正在回到桌上。"]),
        RewardItem("城市按摩", 168, "次", .wellness, [.mid, .high], [.noon, .afternoon, .late], ["肩颈救援资金已经到位。", "辛苦归辛苦，放松的钱你赚到了。"], ["约等于%@，紧绷的肩膀有救了。", "%@已经攒下，今天可以把自己从疲惫里捞一下。", "你赚到%@，放松不是奢侈，是补给。"]),
        RewardItem("机械键盘键帽", 199, "套", .keyboard, [.mid, .high], [.afternoon, .late], ["桌面的快乐升级有了。", "今天已经攒下一套键帽。"], ["约等于%@，桌面快乐可以更新一格。", "%@已经到手，敲字的心情都变响亮了。", "你赚出%@，生产力也可以有点审美。"]),
        RewardItem("高级鼠标", 399, "只", .mouse, [.mid, .high], [.afternoon, .late, .done], ["顺手的生产力工具已经被你赚出雏形。", "今天也给桌面装备加了把劲。"], ["约等于%@，顺手的装备正在靠近。", "%@已经有了，今天的操作感更有盼头。", "你赚到%@，给高频使用的手一点体面。"]),
        RewardItem("香水小瓶", 450, "瓶", .beauty, [.mid, .high], [.afternoon, .late, .done], ["一点精致生活已经到账。", "今天攒下了一瓶好闻的奖励。"], ["约等于%@，今天也有属于自己的气味记忆。", "%@已经到手，精致不是口号，是余额里的进度。", "你赚出%@，生活可以多一点好闻的细节。"]),
        RewardItem("米其林风格晚餐", 650, "顿", .meal, [.mid, .high], [.late, .done], ["一顿好好犒劳自己的晚餐已经有了。", "今天的体面晚餐被你拿下了。"], ["约等于%@，今晚可以认真庆祝一下自己。", "%@已经落袋，辛苦值得被好好招待。", "你赚到%@，今天的努力有资格上桌。"]),
        RewardItem("降噪耳机", 999, "副", .headphones, [.mid, .high], [.late, .done], ["安静世界的门票已经收入囊中。", "今天已经赚到一副清净。"], ["约等于%@，安静感被你亲手攒出来了。", "%@已经到位，世界可以小声一点。", "你赚出%@，给自己的专注力添一层保护。"]),
        RewardItem("运动相机", 1799, "台", .camera, [.high], [.afternoon, .late, .done], ["下一段记录生活的小设备已经靠近了。", "今天的冒险感被你赚出来了。"], ["约等于%@，下一次出发可以被好好记录。", "%@已经出现，生活不只在工位上发生。", "你赚到%@，把今天的努力换成未来的画面。"]),
        RewardItem("短途酒店", 899, "晚", .hotel, [.high], [.noon, .afternoon, .late], ["一晚换个地方醒来的预算有了。", "今天已经攒下一晚短途松弛感。"], ["约等于%@，换个城市醒来的可能性有了。", "%@已经攒下，松弛感不是空想。", "你赚出%@，周末可以离日常远一点。"]),
        RewardItem("周边城市旅行", 2200, "次", .travel, [.high], [.late, .done], ["一个小旅行目标已经收入囊中。", "今天赚到的不只是钱，还有出发的底气。"], ["约等于%@，出发这件事变得更具体。", "%@已经在路上，今天的努力带着风景感。", "你赚到%@，地图上又多了一个可以点亮的地方。"]),
        RewardItem("旗舰手机基金", 5999, "份", .phone, [.high], [.done], ["一台新手机的小目标正在被你拿下。", "今天的努力正在变成真正的大件。"], ["约等于%@，大件目标也在被你一点点推进。", "%@已经成形，今天的进度很硬核。", "你赚出%@，不是小确幸，是实打实的大目标。"]),
        RewardItem("轻薄电脑基金", 7999, "份", .laptop, [.high], [.done], ["生产力大件也不是遥不可及。", "今天已经给下一台电脑添了一大笔。"], ["约等于%@，下一台生产力工具有了实感。", "%@已经写进今天的成果里，漂亮。", "你赚到%@，给未来的效率添了一块砖。"])
    ]
}

private enum SalaryTier: String, Sendable {
    case low
    case mid
    case high

    init(dailyIncomeCNY: Double) {
        if dailyIncomeCNY < 500 {
            self = .low
        } else if dailyIncomeCNY <= 1500 {
            self = .mid
        } else {
            self = .high
        }
    }
}

private enum ProgressBucket: String, Sendable {
    case start
    case early
    case morning
    case noon
    case afternoon
    case late
    case done

    init(progress: Double) {
        switch progress {
        case ..<0.06:
            self = .start
        case ..<0.14:
            self = .early
        case ..<0.28:
            self = .morning
        case ..<0.45:
            self = .noon
        case ..<0.68:
            self = .afternoon
        case ..<0.90:
            self = .late
        default:
            self = .done
        }
    }
}

private struct RewardItem: Sendable {
    var name: String
    var priceCNY: Double
    var unit: String
    var iconKind: RewardIconKind
    var tiers: [SalaryTier]
    var buckets: [ProgressBucket]
    var titles: [String]
    var details: [String]

    init(_ name: String, _ priceCNY: Double, _ unit: String, _ iconKind: RewardIconKind, _ tiers: [SalaryTier], _ buckets: [ProgressBucket], _ titles: [String], _ details: [String]) {
        self.name = name
        self.priceCNY = priceCNY
        self.unit = unit
        self.iconKind = iconKind
        self.tiers = tiers
        self.buckets = buckets
        self.titles = titles
        self.details = details
    }

    func detail(count: Int, seed: String) -> String {
        let phrase = "\(count)\(unit)\(name)"
        let index = Self.stableIndex(key: seed, count: details.count)
        return details[index].replacingOccurrences(of: "%@", with: phrase)
    }

    private static func stableIndex(key: String, count: Int) -> Int {
        guard count > 0 else { return 0 }
        var hash = 5381
        for scalar in key.unicodeScalars {
            hash = ((hash << 5) &+ hash) &+ Int(scalar.value)
        }
        return abs(hash) % count
    }
}
