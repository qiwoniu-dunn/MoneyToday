import Foundation

public struct RewardMessage: Equatable, Sendable {
    public var title: String
    public var detail: String
    public var itemName: String
    public var count: Int
    public var iconKind: RewardIconKind
    public var assetName: String

    public init(title: String, detail: String, itemName: String, count: Int, iconKind: RewardIconKind, assetName: String) {
        self.title = title
        self.detail = detail
        self.itemName = itemName
        self.count = count
        self.iconKind = iconKind
        self.assetName = assetName
    }
}

public struct RewardCatalogEntry: Identifiable, Equatable, Sendable {
    public var id: String
    public var name: String
    public var priceCNY: Double
    public var unit: String
    public var category: String
    public var assetName: String
    public var enabled: Bool

    public init(id: String, name: String, priceCNY: Double, unit: String, category: String, assetName: String, enabled: Bool = true) {
        self.id = id
        self.name = name
        self.priceCNY = priceCNY
        self.unit = unit
        self.category = category
        self.assetName = assetName
        self.enabled = enabled
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
                title: "芝麻已经坐好，等你开工。",
                detail: "今天已赚 ¥0，先让数字慢慢热起来。",
                itemName: "启动奖励",
                count: 0,
                iconKind: .spark,
                assetName: "reward-spark"
            )
        }

        let tier = nearestTier(for: dailyCNY)
        let step = milestoneStep(earnedCNY: earnedCNY, tier: tier)
        let candidates = items.filter { $0.tier == tier && $0.step == step }
        let pool = candidates.isEmpty ? fallbackItems(for: tier, step: step) : candidates
        let seed = "\(dayKey(for: date, calendar: calendar))|\(currencyCode.uppercased())|\(tier)|\(step)"
        let item = pool[stableIndex(key: "\(seed)|item", count: pool.count)]
        let title = title(for: item, earnedCNY: earnedCNY, seed: "\(seed)|title")
        let detail = detail(for: item, earnedCNY: earnedCNY, seed: "\(seed)|detail")

        return RewardMessage(
            title: title,
            detail: detail,
            itemName: item.name,
            count: 1,
            iconKind: item.iconKind,
            assetName: item.assetName
        )
    }

    public static var catalogEntries: [RewardCatalogEntry] {
        items.map { item in
            RewardCatalogEntry(
                id: item.id,
                name: item.name,
                priceCNY: item.priceCNY,
                unit: "项",
                category: item.category,
                assetName: item.assetName,
                enabled: true
            )
        }
    }

    private static func cnyRate(for currencyCode: String) -> Double {
        switch currencyCode.uppercased() {
        case "CNY", "RMB": return 1
        case "USD": return 7.2
        case "EUR": return 7.8
        case "GBP": return 9.1
        case "JPY": return 0.046
        default: return 1
        }
    }

    private static func nearestTier(for dailyCNY: Double) -> Int {
        [300, 500, 1000, 2000, 3000].min { abs(Double($0) - dailyCNY) < abs(Double($1) - dailyCNY) } ?? 300
    }

    private static func milestoneStep(earnedCNY: Double, tier: Int) -> Int {
        let stepSize = Double(tier) / 10
        let rawStep = Int(floor(earnedCNY / max(stepSize, 1)))
        return min(max(rawStep, 1), 10)
    }

    private static func fallbackItems(for tier: Int, step: Int) -> [RewardItem] {
        let sameTier = items.filter { $0.tier == tier }
        let sorted = sameTier.sorted { abs($0.step - step) < abs($1.step - step) }
        return Array(sorted.prefix(6))
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

    private static func title(for item: RewardItem, earnedCNY: Double, seed: String) -> String {
        let templates = titleTemplates(for: item)
        return templates[stableIndex(key: seed, count: templates.count)]
    }

    private static func detail(for item: RewardItem, earnedCNY: Double, seed: String) -> String {
        let earned = Int(earnedCNY.rounded())
        let templates = detailTemplates(for: item, earned: earned)
        return templates[stableIndex(key: seed, count: templates.count)]
    }

    private static func titleTemplates(for item: RewardItem) -> [String] {
        let name = item.name
        switch item.iconKind {
        case .coffee, .tea:
            return ["芝麻把香气递过来了", "冰冰热热的盼头来了", "\(name)在心里排队"]
        case .meal:
            return ["今天值得好好吃一口", "胃先替你松了一口气", "\(name)让今天具体一点"]
        case .ride:
            return ["通勤路上可以轻一点", "芝麻替你省下一点折腾", "\(name)把路变短一点"]
        case .movie:
            return ["脑子今晚可以放个假", "快乐有了一个小入口", "\(name)像一张暂停键"]
        case .wellness:
            return ["肩膀可以先松一口气", "芝麻已经摆好放松姿势", "\(name)听起来很会安慰人"]
        case .keyboard, .mouse, .laptop:
            return ["桌面突然顺眼一点", "掌控感回到手边", "\(name)让工作少一点别扭"]
        case .beauty:
            return ["房间和自己都可以精致一点", "芝麻替你留了一点香气", "\(name)把今天变柔和一点"]
        case .headphones:
            return ["把世界调小声一点", "安静也可以是一种奖励", "\(name)让外面远一点"]
        case .camera:
            return ["把生活拍得像样一点", "不赶时间的画面出现了", "\(name)给生活一点镜头感"]
        case .hotel:
            return ["脑子先去住一晚", "芝麻替你留了一点喘气空间", "\(name)听起来就很会休息"]
        case .travel:
            return ["心已经先出门了", "芝麻把周末想远了一点", "\(name)让今天有了出口"]
        case .phone:
            return ["新鲜感在屏幕里亮了一下", "\(name)让期待有了形状", "芝麻看见了一点新装备的光"]
        case .spark:
            return ["芝麻把小确幸摆好了", "今天多了一点可期待的东西", "\(name)让数字有了温度"]
        }
    }

    private static func detailTemplates(for item: RewardItem, earned: Int) -> [String] {
        let name = item.name
        switch item.iconKind {
        case .coffee, .tea:
            return [
                "今天已赚 ¥\(earned)，先让脑子有一点顺口的盼头。",
                "今天已赚 ¥\(earned)，芝麻觉得\(name)很适合下班路上慢慢喝。",
                "今天已赚 ¥\(earned)，苦味留给工作，一点甜留给自己。"
            ]
        case .meal:
            return [
                "今天已赚 ¥\(earned)，芝麻觉得今天值得一份不糊弄的吃食。",
                "今天已赚 ¥\(earned)，先把\(name)放进脑内菜单，日子就没那么硬。",
                "今天已赚 ¥\(earned)，认真吃一顿这件事，也可以很有用。"
            ]
        case .ride:
            return [
                "今天已赚 ¥\(earned)，芝麻把\(name)放进今天的省力清单里。",
                "今天已赚 ¥\(earned)，路还是那条路，但可以少一点狼狈。",
                "今天已赚 ¥\(earned)，给自己一点不用硬扛的移动空间。"
            ]
        case .movie:
            return [
                "今天已赚 ¥\(earned)，芝麻把\(name)塞进了你的休息想象里。",
                "今天已赚 ¥\(earned)，今晚的大脑适合交给一段别人的故事。",
                "今天已赚 ¥\(earned)，工作还在，快乐可以先占个座。"
            ]
        case .wellness:
            return [
                "今天已赚 ¥\(earned)，芝麻已经替你想好下班后的放松姿势。",
                "今天已赚 ¥\(earned)，\(name)像是给肩膀写的一张请假条。",
                "今天已赚 ¥\(earned)，身体也该被温柔地记上一笔。"
            ]
        case .keyboard, .mouse, .laptop:
            return [
                "今天已赚 ¥\(earned)，芝麻觉得\(name)很适合把桌面调顺一点。",
                "今天已赚 ¥\(earned)，手边的东西舒服了，工作也少一点钝感。",
                "今天已赚 ¥\(earned)，这份小装备让明天看起来没那么难。"
            ]
        case .beauty:
            return [
                "今天已赚 ¥\(earned)，芝麻替你点了一点\(name)的念头。",
                "今天已赚 ¥\(earned)，精致不一定隆重，也可以是今天的一点补偿。",
                "今天已赚 ¥\(earned)，让房间或自己软下来一点，已经很好。"
            ]
        case .headphones:
            return [
                "今天已赚 ¥\(earned)，芝麻把\(name)放进今天的愿望清单里。",
                "今天已赚 ¥\(earned)，外面的吵闹可以先被关小声。",
                "今天已赚 ¥\(earned)，安静一点，快乐就更容易被听见。"
            ]
        case .camera:
            return [
                "今天已赚 ¥\(earned)，芝麻想象你拿着\(name)，去记录一个不赶时间的下午。",
                "今天已赚 ¥\(earned)，生活偶尔也值得被拍得认真一点。",
                "今天已赚 ¥\(earned)，有些期待已经开始有画面了。"
            ]
        case .hotel:
            return [
                "今天已赚 ¥\(earned)，工作还在继续，但芝麻已经替你留了一点喘气的空间。",
                "今天已赚 ¥\(earned)，\(name)先在脑子里铺好一张干净的床。",
                "今天已赚 ¥\(earned)，不是马上出发，也可以先想象一次好好休息。"
            ]
        case .travel:
            return [
                "今天已赚 ¥\(earned)，芝麻把\(name)放到周末的想象里晃了晃。",
                "今天已赚 ¥\(earned)，有个地方可以想，就不算只是在原地转。",
                "今天已赚 ¥\(earned)，今天撑住的部分，未来会变成一点出门的底气。"
            ]
        case .phone:
            return [
                "今天已赚 ¥\(earned)，芝麻看着\(name)，觉得新鲜感有了轮廓。",
                "今天已赚 ¥\(earned)，一点新装备的念头，让今天没那么平。",
                "今天已赚 ¥\(earned)，期待不用立刻发生，先被看见就很好。"
            ]
        case .spark:
            return [
                "今天已赚 ¥\(earned)，芝麻把这点具体的快乐先替你收好。",
                "今天已赚 ¥\(earned)，数字背后已经有一点生活可以想象。",
                "今天已赚 ¥\(earned)，先不讲大道理，给自己留点小盼头。"
            ]
        }
    }

    private static let items: [RewardItem] = [
        RewardItem(id: "300-1-1", tier: 300, step: 1, priceCNY: 30, name: "星巴克拿铁", category: "咖啡饮品", assetName: "reward-coffee", iconKind: .coffee),
        RewardItem(id: "300-1-2", tier: 300, step: 1, priceCNY: 30, name: "滴滴快车短途", category: "城市出行", assetName: "reward-city-ride", iconKind: .ride),
        RewardItem(id: "300-1-3", tier: 300, step: 1, priceCNY: 30, name: "麦当劳板烧鸡腿堡套餐", category: "快餐套餐", assetName: "reward-burger-meal", iconKind: .meal),
        RewardItem(id: "300-1-4", tier: 300, step: 1, priceCNY: 30, name: "喜茶多肉葡萄", category: "茶饮甜点", assetName: "reward-tea", iconKind: .tea),
        RewardItem(id: "300-1-5", tier: 300, step: 1, priceCNY: 30, name: "瑞幸丝绒拿铁", category: "咖啡饮品", assetName: "reward-coffee", iconKind: .coffee),
        RewardItem(id: "300-1-6", tier: 300, step: 1, priceCNY: 30, name: "肯德基香辣鸡腿堡套餐", category: "快餐套餐", assetName: "reward-burger-meal", iconKind: .meal),
        RewardItem(id: "300-2-1", tier: 300, step: 2, priceCNY: 60, name: "万达影城电影票", category: "电影娱乐", assetName: "reward-movie", iconKind: .movie),
        RewardItem(id: "300-2-2", tier: 300, step: 2, priceCNY: 60, name: "和府捞面招牌面", category: "工作餐食", assetName: "reward-noodle-bento", iconKind: .meal),
        RewardItem(id: "300-2-3", tier: 300, step: 2, priceCNY: 60, name: "Peet's 咖啡甜点", category: "咖啡饮品", assetName: "reward-coffee", iconKind: .coffee),
        RewardItem(id: "300-2-4", tier: 300, step: 2, priceCNY: 60, name: "Manner 咖啡双杯", category: "咖啡饮品", assetName: "reward-coffee", iconKind: .coffee),
        RewardItem(id: "300-2-5", tier: 300, step: 2, priceCNY: 60, name: "汉堡王皇堡套餐", category: "快餐套餐", assetName: "reward-burger-meal", iconKind: .meal),
        RewardItem(id: "300-2-6", tier: 300, step: 2, priceCNY: 60, name: "奈雪霸气芝士草莓", category: "茶饮甜点", assetName: "reward-tea", iconKind: .tea),
        RewardItem(id: "300-3-1", tier: 300, step: 3, priceCNY: 90, name: "Wagas 轻食沙拉", category: "轻食餐食", assetName: "reward-salad", iconKind: .meal),
        RewardItem(id: "300-3-2", tier: 300, step: 3, priceCNY: 90, name: "良子肩颈放松", category: "按摩放松", assetName: "reward-massage", iconKind: .wellness),
        RewardItem(id: "300-3-3", tier: 300, step: 3, priceCNY: 90, name: "Nike Dri-FIT 运动 T 恤", category: "运动服饰", assetName: "reward-sportswear", iconKind: .wellness),
        RewardItem(id: "300-3-4", tier: 300, step: 3, priceCNY: 90, name: "盒马鲜生寿司拼盘", category: "工作餐食", assetName: "reward-noodle-bento", iconKind: .meal),
        RewardItem(id: "300-3-5", tier: 300, step: 3, priceCNY: 90, name: "超级猩猩单次体验", category: "运动课程", assetName: "reward-fitness-class", iconKind: .wellness),
        RewardItem(id: "300-3-6", tier: 300, step: 3, priceCNY: 90, name: "MUJI 香薰精油", category: "香氛护肤", assetName: "reward-fragrance", iconKind: .beauty),
        RewardItem(id: "300-4-1", tier: 300, step: 4, priceCNY: 120, name: "M Stand 周末早午餐", category: "早午餐", assetName: "reward-brunch", iconKind: .meal),
        RewardItem(id: "300-4-2", tier: 300, step: 4, priceCNY: 120, name: "超级猩猩单次课", category: "运动课程", assetName: "reward-fitness-class", iconKind: .wellness),
        RewardItem(id: "300-4-3", tier: 300, step: 4, priceCNY: 120, name: "小米 Redmi Buds", category: "数码耳机", assetName: "reward-earbuds", iconKind: .headphones),
        RewardItem(id: "300-4-4", tier: 300, step: 4, priceCNY: 120, name: "西贝单人正餐", category: "餐厅正餐", assetName: "reward-restaurant-meal", iconKind: .meal),
        RewardItem(id: "300-4-5", tier: 300, step: 4, priceCNY: 120, name: "UCCA 展览门票", category: "演出展览", assetName: "reward-live-show", iconKind: .movie),
        RewardItem(id: "300-4-6", tier: 300, step: 4, priceCNY: 120, name: "Keep 瑜伽垫", category: "运动装备", assetName: "reward-sports-accessory", iconKind: .wellness),
        RewardItem(id: "300-5-1", tier: 300, step: 5, priceCNY: 150, name: "西贝单人正餐", category: "餐厅正餐", assetName: "reward-restaurant-meal", iconKind: .meal),
        RewardItem(id: "300-5-2", tier: 300, step: 5, priceCNY: 150, name: "东田造型理发", category: "头发护理", assetName: "reward-haircare", iconKind: .wellness),
        RewardItem(id: "300-5-3", tier: 300, step: 5, priceCNY: 150, name: "MUJI 桌面收纳", category: "桌面装备", assetName: "reward-desk-setup", iconKind: .keyboard),
        RewardItem(id: "300-5-4", tier: 300, step: 5, priceCNY: 150, name: "Keychron 手托", category: "桌面装备", assetName: "reward-desk-setup", iconKind: .keyboard),
        RewardItem(id: "300-5-5", tier: 300, step: 5, priceCNY: 150, name: "Diptyque 小蜡烛", category: "香氛护肤", assetName: "reward-fragrance", iconKind: .beauty),
        RewardItem(id: "300-5-6", tier: 300, step: 5, priceCNY: 150, name: "万达双人电影票", category: "电影娱乐", assetName: "reward-movie", iconKind: .movie),
        RewardItem(id: "300-6-1", tier: 300, step: 6, priceCNY: 180, name: "泰到位足疗", category: "按摩放松", assetName: "reward-massage", iconKind: .wellness),
        RewardItem(id: "300-6-2", tier: 300, step: 6, priceCNY: 180, name: "Diptyque 香氛蜡烛", category: "香氛护肤", assetName: "reward-fragrance", iconKind: .beauty),
        RewardItem(id: "300-6-3", tier: 300, step: 6, priceCNY: 180, name: "上海地铁月度通勤", category: "城市出行", assetName: "reward-city-ride", iconKind: .ride),
        RewardItem(id: "300-6-4", tier: 300, step: 6, priceCNY: 180, name: "良子足疗按摩", category: "按摩放松", assetName: "reward-massage", iconKind: .wellness),
        RewardItem(id: "300-6-5", tier: 300, step: 6, priceCNY: 180, name: "Marshall 香薰蜡烛", category: "香氛护肤", assetName: "reward-fragrance", iconKind: .beauty),
        RewardItem(id: "300-6-6", tier: 300, step: 6, priceCNY: 180, name: "Nike 运动短裤", category: "运动服饰", assetName: "reward-sportswear", iconKind: .wellness),
        RewardItem(id: "300-7-1", tier: 300, step: 7, priceCNY: 210, name: "盒马鲜生海鲜小火锅", category: "自助火锅", assetName: "reward-buffet-hotpot", iconKind: .meal),
        RewardItem(id: "300-7-2", tier: 300, step: 7, priceCNY: 210, name: "洛斐键帽", category: "桌面装备", assetName: "reward-keycaps", iconKind: .keyboard),
        RewardItem(id: "300-7-3", tier: 300, step: 7, priceCNY: 210, name: "UCCA 展览门票", category: "演出展览", assetName: "reward-live-show", iconKind: .movie),
        RewardItem(id: "300-7-4", tier: 300, step: 7, priceCNY: 210, name: "Keychron 键帽", category: "桌面装备", assetName: "reward-keycaps", iconKind: .keyboard),
        RewardItem(id: "300-7-5", tier: 300, step: 7, priceCNY: 210, name: "MAO Livehouse 预售票", category: "演出展览", assetName: "reward-live-show", iconKind: .movie),
        RewardItem(id: "300-7-6", tier: 300, step: 7, priceCNY: 210, name: "飞利浦电动牙刷", category: "生活电器", assetName: "reward-toothbrush", iconKind: .laptop),
        RewardItem(id: "300-8-1", tier: 300, step: 8, priceCNY: 240, name: "Lululemon 瑜伽体验", category: "运动课程", assetName: "reward-fitness-class", iconKind: .wellness),
        RewardItem(id: "300-8-2", tier: 300, step: 8, priceCNY: 240, name: "欧莱雅护肤礼盒", category: "香氛护肤", assetName: "reward-skincare", iconKind: .beauty),
        RewardItem(id: "300-8-3", tier: 300, step: 8, priceCNY: 240, name: "Anker 快充套装", category: "桌面装备", assetName: "reward-desk-setup", iconKind: .keyboard),
        RewardItem(id: "300-8-4", tier: 300, step: 8, priceCNY: 240, name: "PURE 单次瑜伽课", category: "运动课程", assetName: "reward-fitness-class", iconKind: .wellness),
        RewardItem(id: "300-8-5", tier: 300, step: 8, priceCNY: 240, name: "资生堂护肤套装", category: "香氛护肤", assetName: "reward-skincare", iconKind: .beauty),
        RewardItem(id: "300-8-6", tier: 300, step: 8, priceCNY: 240, name: "小米体脂秤", category: "健康设备", assetName: "reward-health-scale", iconKind: .wellness),
        RewardItem(id: "300-9-1", tier: 300, step: 9, priceCNY: 270, name: "万达双人电影夜", category: "电影娱乐", assetName: "reward-movie", iconKind: .movie),
        RewardItem(id: "300-9-2", tier: 300, step: 9, priceCNY: 270, name: "Boxing Cat 精酿", category: "餐厅正餐", assetName: "reward-restaurant-meal", iconKind: .meal),
        RewardItem(id: "300-9-3", tier: 300, step: 9, priceCNY: 270, name: "Converse 帆布鞋", category: "运动鞋履", assetName: "reward-sneakers", iconKind: .wellness),
        RewardItem(id: "300-9-4", tier: 300, step: 9, priceCNY: 270, name: "CGV 双人电影夜", category: "电影娱乐", assetName: "reward-movie", iconKind: .movie),
        RewardItem(id: "300-9-5", tier: 300, step: 9, priceCNY: 270, name: "Nike 运动腰包", category: "运动装备", assetName: "reward-sports-accessory", iconKind: .wellness),
        RewardItem(id: "300-9-6", tier: 300, step: 9, priceCNY: 270, name: "Baker & Spice 双人早午餐", category: "早午餐", assetName: "reward-brunch", iconKind: .meal),
        RewardItem(id: "300-10-1", tier: 300, step: 10, priceCNY: 300, name: "Blue Frog 晚餐", category: "餐厅正餐", assetName: "reward-restaurant-meal", iconKind: .meal),
        RewardItem(id: "300-10-2", tier: 300, step: 10, priceCNY: 300, name: "丝域头皮护理", category: "头发护理", assetName: "reward-haircare", iconKind: .wellness),
        RewardItem(id: "300-10-3", tier: 300, step: 10, priceCNY: 300, name: "小米空气炸锅", category: "生活电器", assetName: "reward-air-fryer", iconKind: .laptop),
        RewardItem(id: "300-10-4", tier: 300, step: 10, priceCNY: 300, name: "Shake Shack 双人餐", category: "快餐套餐", assetName: "reward-burger-meal", iconKind: .meal),
        RewardItem(id: "300-10-5", tier: 300, step: 10, priceCNY: 300, name: "泰到位肩颈按摩", category: "按摩放松", assetName: "reward-massage", iconKind: .wellness),
        RewardItem(id: "300-10-6", tier: 300, step: 10, priceCNY: 300, name: "宜家桌面灯", category: "桌面装备", assetName: "reward-desk-setup", iconKind: .keyboard),
        RewardItem(id: "500-1-1", tier: 500, step: 1, priceCNY: 50, name: "CGV 巨幕电影票", category: "电影娱乐", assetName: "reward-movie", iconKind: .movie),
        RewardItem(id: "500-1-2", tier: 500, step: 1, priceCNY: 50, name: "滴滴快车跨区", category: "城市出行", assetName: "reward-city-ride", iconKind: .ride),
        RewardItem(id: "500-1-3", tier: 500, step: 1, priceCNY: 50, name: "喜茶轻食套餐", category: "茶饮甜点", assetName: "reward-tea", iconKind: .tea),
        RewardItem(id: "500-1-4", tier: 500, step: 1, priceCNY: 50, name: "星巴克臻选咖啡", category: "咖啡饮品", assetName: "reward-coffee", iconKind: .coffee),
        RewardItem(id: "500-1-5", tier: 500, step: 1, priceCNY: 50, name: "麦当劳双人小食", category: "快餐套餐", assetName: "reward-burger-meal", iconKind: .meal),
        RewardItem(id: "500-1-6", tier: 500, step: 1, priceCNY: 50, name: "奈雪欧包茶饮", category: "茶饮甜点", assetName: "reward-tea", iconKind: .tea),
        RewardItem(id: "500-2-1", tier: 500, step: 2, priceCNY: 100, name: "Shake Shack 单人餐", category: "快餐套餐", assetName: "reward-burger-meal", iconKind: .meal),
        RewardItem(id: "500-2-2", tier: 500, step: 2, priceCNY: 100, name: "泰到位肩颈按摩", category: "按摩放松", assetName: "reward-massage", iconKind: .wellness),
        RewardItem(id: "500-2-3", tier: 500, step: 2, priceCNY: 100, name: "Nike 运动腰包", category: "运动装备", assetName: "reward-sports-accessory", iconKind: .wellness),
        RewardItem(id: "500-2-4", tier: 500, step: 2, priceCNY: 100, name: "Wagas 商务午餐", category: "轻食餐食", assetName: "reward-salad", iconKind: .meal),
        RewardItem(id: "500-2-5", tier: 500, step: 2, priceCNY: 100, name: "万达 IMAX 电影票", category: "电影娱乐", assetName: "reward-movie", iconKind: .movie),
        RewardItem(id: "500-2-6", tier: 500, step: 2, priceCNY: 100, name: "MUJI 香薰机", category: "香氛护肤", assetName: "reward-fragrance", iconKind: .beauty),
        RewardItem(id: "500-3-1", tier: 500, step: 3, priceCNY: 150, name: "东田造型男士理发", category: "头发护理", assetName: "reward-haircare", iconKind: .wellness),
        RewardItem(id: "500-3-2", tier: 500, step: 3, priceCNY: 150, name: "汉堡王双人套餐", category: "快餐套餐", assetName: "reward-burger-meal", iconKind: .meal),
        RewardItem(id: "500-3-3", tier: 500, step: 3, priceCNY: 150, name: "宜家电脑支架", category: "桌面装备", assetName: "reward-desk-setup", iconKind: .keyboard),
        RewardItem(id: "500-3-4", tier: 500, step: 3, priceCNY: 150, name: "西贝单人正餐", category: "餐厅正餐", assetName: "reward-restaurant-meal", iconKind: .meal),
        RewardItem(id: "500-3-5", tier: 500, step: 3, priceCNY: 150, name: "飞利浦电动牙刷", category: "生活电器", assetName: "reward-toothbrush", iconKind: .laptop),
        RewardItem(id: "500-3-6", tier: 500, step: 3, priceCNY: 150, name: "UCCA 展览门票", category: "演出展览", assetName: "reward-live-show", iconKind: .movie),
        RewardItem(id: "500-4-1", tier: 500, step: 4, priceCNY: 200, name: "良子城市按摩", category: "按摩放松", assetName: "reward-massage", iconKind: .wellness),
        RewardItem(id: "500-4-2", tier: 500, step: 4, priceCNY: 200, name: "Jo Malone 旅行香氛", category: "香氛护肤", assetName: "reward-fragrance", iconKind: .beauty),
        RewardItem(id: "500-4-3", tier: 500, step: 4, priceCNY: 200, name: "Keychron 键帽", category: "桌面装备", assetName: "reward-keycaps", iconKind: .keyboard),
        RewardItem(id: "500-4-4", tier: 500, step: 4, priceCNY: 200, name: "曼谷屋泰式按摩", category: "按摩放松", assetName: "reward-massage", iconKind: .wellness),
        RewardItem(id: "500-4-5", tier: 500, step: 4, priceCNY: 200, name: "洛斐键帽", category: "桌面装备", assetName: "reward-keycaps", iconKind: .keyboard),
        RewardItem(id: "500-4-6", tier: 500, step: 4, priceCNY: 200, name: "保利剧院门票", category: "演出展览", assetName: "reward-live-show", iconKind: .movie),
        RewardItem(id: "500-5-1", tier: 500, step: 5, priceCNY: 250, name: "Baker & Spice 双人早午餐", category: "早午餐", assetName: "reward-brunch", iconKind: .meal),
        RewardItem(id: "500-5-2", tier: 500, step: 5, priceCNY: 250, name: "PURE 瑜伽体验课", category: "运动课程", assetName: "reward-fitness-class", iconKind: .wellness),
        RewardItem(id: "500-5-3", tier: 500, step: 5, priceCNY: 250, name: "飞利浦电动牙刷", category: "生活电器", assetName: "reward-toothbrush", iconKind: .laptop),
        RewardItem(id: "500-5-4", tier: 500, step: 5, priceCNY: 250, name: "Lululemon 瑜伽课", category: "运动课程", assetName: "reward-fitness-class", iconKind: .wellness),
        RewardItem(id: "500-5-5", tier: 500, step: 5, priceCNY: 250, name: "Anker 充电套装", category: "桌面装备", assetName: "reward-desk-setup", iconKind: .keyboard),
        RewardItem(id: "500-5-6", tier: 500, step: 5, priceCNY: 250, name: "CGV 双人电影夜", category: "电影娱乐", assetName: "reward-movie", iconKind: .movie),
        RewardItem(id: "500-6-1", tier: 500, step: 6, priceCNY: 300, name: "王品牛排午餐", category: "牛排餐厅", assetName: "reward-steak", iconKind: .meal),
        RewardItem(id: "500-6-2", tier: 500, step: 6, priceCNY: 300, name: "丝域头疗护理", category: "头发护理", assetName: "reward-haircare", iconKind: .wellness),
        RewardItem(id: "500-6-3", tier: 500, step: 6, priceCNY: 300, name: "小米空气炸锅", category: "生活电器", assetName: "reward-air-fryer", iconKind: .laptop),
        RewardItem(id: "500-6-4", tier: 500, step: 6, priceCNY: 300, name: "Blue Frog 晚餐", category: "餐厅正餐", assetName: "reward-restaurant-meal", iconKind: .meal),
        RewardItem(id: "500-6-5", tier: 500, step: 6, priceCNY: 300, name: "Keep 智能体脂秤", category: "健康设备", assetName: "reward-health-scale", iconKind: .wellness),
        RewardItem(id: "500-6-6", tier: 500, step: 6, priceCNY: 300, name: "Boxing Cat 精酿", category: "餐厅正餐", assetName: "reward-restaurant-meal", iconKind: .meal),
        RewardItem(id: "500-7-1", tier: 500, step: 7, priceCNY: 350, name: "MAO Livehouse 门票", category: "演出展览", assetName: "reward-live-show", iconKind: .movie),
        RewardItem(id: "500-7-2", tier: 500, step: 7, priceCNY: 350, name: "Nike 通勤双肩包", category: "运动装备", assetName: "reward-sports-accessory", iconKind: .wellness),
        RewardItem(id: "500-7-3", tier: 500, step: 7, priceCNY: 350, name: "闪迪移动固态硬盘", category: "数码装备", assetName: "reward-storage-drive", iconKind: .keyboard),
        RewardItem(id: "500-7-4", tier: 500, step: 7, priceCNY: 350, name: "Adidas 运动鞋", category: "运动鞋履", assetName: "reward-sneakers", iconKind: .wellness),
        RewardItem(id: "500-7-5", tier: 500, step: 7, priceCNY: 350, name: "Keychron 机械键盘", category: "桌面装备", assetName: "reward-keyboard", iconKind: .keyboard),
        RewardItem(id: "500-7-6", tier: 500, step: 7, priceCNY: 350, name: "大渔铁板烧单人餐", category: "自助火锅", assetName: "reward-buffet-hotpot", iconKind: .meal),
        RewardItem(id: "500-8-1", tier: 500, step: 8, priceCNY: 400, name: "罗技 MX Master 鼠标", category: "桌面装备", assetName: "reward-mouse", iconKind: .mouse),
        RewardItem(id: "500-8-2", tier: 500, step: 8, priceCNY: 400, name: "大渔铁板烧双人餐", category: "自助火锅", assetName: "reward-buffet-hotpot", iconKind: .meal),
        RewardItem(id: "500-8-3", tier: 500, step: 8, priceCNY: 400, name: "亚朵酒店钟点房", category: "酒店度假", assetName: "reward-hotel", iconKind: .hotel),
        RewardItem(id: "500-8-4", tier: 500, step: 8, priceCNY: 400, name: "华为 Watch Fit", category: "健康设备", assetName: "reward-health-scale", iconKind: .wellness),
        RewardItem(id: "500-8-5", tier: 500, step: 8, priceCNY: 400, name: "东田染发护理", category: "头发护理", assetName: "reward-haircare", iconKind: .wellness),
        RewardItem(id: "500-8-6", tier: 500, step: 8, priceCNY: 400, name: "小米 4K 显示器", category: "桌面装备", assetName: "reward-monitor", iconKind: .keyboard),
        RewardItem(id: "500-9-1", tier: 500, step: 9, priceCNY: 450, name: "Maison Margiela 香水", category: "香氛护肤", assetName: "reward-fragrance", iconKind: .beauty),
        RewardItem(id: "500-9-2", tier: 500, step: 9, priceCNY: 450, name: "泰到位深度 SPA", category: "按摩放松", assetName: "reward-massage", iconKind: .wellness),
        RewardItem(id: "500-9-3", tier: 500, step: 9, priceCNY: 450, name: "Adidas Ultraboost", category: "运动鞋履", assetName: "reward-sneakers", iconKind: .wellness),
        RewardItem(id: "500-9-4", tier: 500, step: 9, priceCNY: 450, name: "Jo Malone 香水", category: "香氛护肤", assetName: "reward-fragrance", iconKind: .beauty),
        RewardItem(id: "500-9-5", tier: 500, step: 9, priceCNY: 450, name: "Bose 便携音箱", category: "数码音箱", assetName: "reward-speaker", iconKind: .headphones),
        RewardItem(id: "500-9-6", tier: 500, step: 9, priceCNY: 450, name: "香格里拉自助餐", category: "自助火锅", assetName: "reward-buffet-hotpot", iconKind: .meal),
        RewardItem(id: "500-10-1", tier: 500, step: 10, priceCNY: 500, name: "Wolfgang's Steakhouse 单人餐", category: "牛排餐厅", assetName: "reward-steak", iconKind: .meal),
        RewardItem(id: "500-10-2", tier: 500, step: 10, priceCNY: 500, name: "Ergotron 显示器支架", category: "桌面装备", assetName: "reward-desk-setup", iconKind: .keyboard),
        RewardItem(id: "500-10-3", tier: 500, step: 10, priceCNY: 500, name: "高铁城际往返票", category: "城际出行", assetName: "reward-train", iconKind: .ride),
        RewardItem(id: "500-10-4", tier: 500, step: 10, priceCNY: 500, name: "Sony LinkBuds", category: "数码耳机", assetName: "reward-earbuds", iconKind: .headphones),
        RewardItem(id: "500-10-5", tier: 500, step: 10, priceCNY: 500, name: "大董单人餐", category: "餐厅正餐", assetName: "reward-restaurant-meal", iconKind: .meal),
        RewardItem(id: "500-10-6", tier: 500, step: 10, priceCNY: 500, name: "亚朵酒店一晚", category: "酒店度假", assetName: "reward-hotel", iconKind: .hotel),
        RewardItem(id: "1000-1-1", tier: 1000, step: 1, priceCNY: 100, name: "泰到位肩颈按摩", category: "按摩放松", assetName: "reward-massage", iconKind: .wellness),
        RewardItem(id: "1000-1-2", tier: 1000, step: 1, priceCNY: 100, name: "Wagas 商务午餐", category: "轻食餐食", assetName: "reward-salad", iconKind: .meal),
        RewardItem(id: "1000-1-3", tier: 1000, step: 1, priceCNY: 100, name: "IMAX 电影票", category: "电影娱乐", assetName: "reward-movie", iconKind: .movie),
        RewardItem(id: "1000-1-4", tier: 1000, step: 1, priceCNY: 100, name: "Shake Shack 单人餐", category: "快餐套餐", assetName: "reward-burger-meal", iconKind: .meal),
        RewardItem(id: "1000-1-5", tier: 1000, step: 1, priceCNY: 100, name: "Nike 运动腰包", category: "运动装备", assetName: "reward-sports-accessory", iconKind: .wellness),
        RewardItem(id: "1000-1-6", tier: 1000, step: 1, priceCNY: 100, name: "星巴克臻选咖啡", category: "咖啡饮品", assetName: "reward-coffee", iconKind: .coffee),
        RewardItem(id: "1000-2-1", tier: 1000, step: 2, priceCNY: 200, name: "曼谷屋泰式按摩", category: "按摩放松", assetName: "reward-massage", iconKind: .wellness),
        RewardItem(id: "1000-2-2", tier: 1000, step: 2, priceCNY: 200, name: "Keychron 机械键盘", category: "桌面装备", assetName: "reward-keyboard", iconKind: .keyboard),
        RewardItem(id: "1000-2-3", tier: 1000, step: 2, priceCNY: 200, name: "笑果脱口秀门票", category: "演出展览", assetName: "reward-live-show", iconKind: .movie),
        RewardItem(id: "1000-2-4", tier: 1000, step: 2, priceCNY: 200, name: "良子城市按摩", category: "按摩放松", assetName: "reward-massage", iconKind: .wellness),
        RewardItem(id: "1000-2-5", tier: 1000, step: 2, priceCNY: 200, name: "Jo Malone 旅行香氛", category: "香氛护肤", assetName: "reward-fragrance", iconKind: .beauty),
        RewardItem(id: "1000-2-6", tier: 1000, step: 2, priceCNY: 200, name: "保利剧院门票", category: "演出展览", assetName: "reward-live-show", iconKind: .movie),
        RewardItem(id: "1000-3-1", tier: 1000, step: 3, priceCNY: 300, name: "Blue Frog 晚餐", category: "餐厅正餐", assetName: "reward-restaurant-meal", iconKind: .meal),
        RewardItem(id: "1000-3-2", tier: 1000, step: 3, priceCNY: 300, name: "丝域头疗护理", category: "头发护理", assetName: "reward-haircare", iconKind: .wellness),
        RewardItem(id: "1000-3-3", tier: 1000, step: 3, priceCNY: 300, name: "小米空气炸锅", category: "生活电器", assetName: "reward-air-fryer", iconKind: .laptop),
        RewardItem(id: "1000-3-4", tier: 1000, step: 3, priceCNY: 300, name: "王品牛排午餐", category: "牛排餐厅", assetName: "reward-steak", iconKind: .meal),
        RewardItem(id: "1000-3-5", tier: 1000, step: 3, priceCNY: 300, name: "Keep 智能体脂秤", category: "健康设备", assetName: "reward-health-scale", iconKind: .wellness),
        RewardItem(id: "1000-3-6", tier: 1000, step: 3, priceCNY: 300, name: "MUJI 空气循环扇", category: "生活电器", assetName: "reward-home-appliance", iconKind: .laptop),
        RewardItem(id: "1000-4-1", tier: 1000, step: 4, priceCNY: 400, name: "罗技 MX Master 3S", category: "桌面装备", assetName: "reward-mouse", iconKind: .mouse),
        RewardItem(id: "1000-4-2", tier: 1000, step: 4, priceCNY: 400, name: "炉鱼双人餐", category: "餐厅正餐", assetName: "reward-restaurant-meal", iconKind: .meal),
        RewardItem(id: "1000-4-3", tier: 1000, step: 4, priceCNY: 400, name: "华为 Watch Fit", category: "健康设备", assetName: "reward-health-scale", iconKind: .wellness),
        RewardItem(id: "1000-4-4", tier: 1000, step: 4, priceCNY: 400, name: "大渔铁板烧双人餐", category: "自助火锅", assetName: "reward-buffet-hotpot", iconKind: .meal),
        RewardItem(id: "1000-4-5", tier: 1000, step: 4, priceCNY: 400, name: "东田染发护理", category: "头发护理", assetName: "reward-haircare", iconKind: .wellness),
        RewardItem(id: "1000-4-6", tier: 1000, step: 4, priceCNY: 400, name: "小米 4K 显示器", category: "桌面装备", assetName: "reward-monitor", iconKind: .keyboard),
        RewardItem(id: "1000-5-1", tier: 1000, step: 5, priceCNY: 500, name: "上海杭州高铁往返", category: "城际出行", assetName: "reward-train", iconKind: .ride),
        RewardItem(id: "1000-5-2", tier: 1000, step: 5, priceCNY: 500, name: "Jo Malone 香水", category: "香氛护肤", assetName: "reward-fragrance", iconKind: .beauty),
        RewardItem(id: "1000-5-3", tier: 1000, step: 5, priceCNY: 500, name: "Humanscale 脚踏", category: "桌面装备", assetName: "reward-desk-setup", iconKind: .keyboard),
        RewardItem(id: "1000-5-4", tier: 1000, step: 5, priceCNY: 500, name: "Sony LinkBuds", category: "数码耳机", assetName: "reward-earbuds", iconKind: .headphones),
        RewardItem(id: "1000-5-5", tier: 1000, step: 5, priceCNY: 500, name: "大董单人餐", category: "餐厅正餐", assetName: "reward-restaurant-meal", iconKind: .meal),
        RewardItem(id: "1000-5-6", tier: 1000, step: 5, priceCNY: 500, name: "亚朵酒店一晚", category: "酒店度假", assetName: "reward-hotel", iconKind: .hotel),
        RewardItem(id: "1000-6-1", tier: 1000, step: 6, priceCNY: 600, name: "亚朵酒店一晚", category: "酒店度假", assetName: "reward-hotel", iconKind: .hotel),
        RewardItem(id: "1000-6-2", tier: 1000, step: 6, priceCNY: 600, name: "Nike Pegasus 跑鞋", category: "运动鞋履", assetName: "reward-sneakers", iconKind: .wellness),
        RewardItem(id: "1000-6-3", tier: 1000, step: 6, priceCNY: 600, name: "大董双人简餐", category: "餐厅正餐", assetName: "reward-restaurant-meal", iconKind: .meal),
        RewardItem(id: "1000-6-4", tier: 1000, step: 6, priceCNY: 600, name: "戴尔显示器", category: "桌面装备", assetName: "reward-monitor", iconKind: .keyboard),
        RewardItem(id: "1000-6-5", tier: 1000, step: 6, priceCNY: 600, name: "Bose QuietComfort 耳机", category: "数码耳机", assetName: "reward-headphones", iconKind: .headphones),
        RewardItem(id: "1000-6-6", tier: 1000, step: 6, priceCNY: 600, name: "Coach 小号托特", category: "通勤包袋", assetName: "reward-bag", iconKind: .beauty),
        RewardItem(id: "1000-7-1", tier: 1000, step: 7, priceCNY: 700, name: "桔子水晶酒店一晚", category: "酒店度假", assetName: "reward-hotel", iconKind: .hotel),
        RewardItem(id: "1000-7-2", tier: 1000, step: 7, priceCNY: 700, name: "Beats Studio Buds", category: "数码耳机", assetName: "reward-earbuds", iconKind: .headphones),
        RewardItem(id: "1000-7-3", tier: 1000, step: 7, priceCNY: 700, name: "东田染发护理", category: "头发护理", assetName: "reward-haircare", iconKind: .wellness),
        RewardItem(id: "1000-7-4", tier: 1000, step: 7, priceCNY: 700, name: "Adidas Ultraboost", category: "运动鞋履", assetName: "reward-sneakers", iconKind: .wellness),
        RewardItem(id: "1000-7-5", tier: 1000, step: 7, priceCNY: 700, name: "德龙咖啡机", category: "生活电器", assetName: "reward-coffee-machine", iconKind: .laptop),
        RewardItem(id: "1000-7-6", tier: 1000, step: 7, priceCNY: 700, name: "希尔顿欢朋一晚", category: "酒店度假", assetName: "reward-hotel", iconKind: .hotel),
        RewardItem(id: "1000-8-1", tier: 1000, step: 8, priceCNY: 800, name: "泰到位高端 SPA", category: "按摩放松", assetName: "reward-massage", iconKind: .wellness),
        RewardItem(id: "1000-8-2", tier: 1000, step: 8, priceCNY: 800, name: "携程周边一日游", category: "旅行体验", assetName: "reward-travel", iconKind: .travel),
        RewardItem(id: "1000-8-3", tier: 1000, step: 8, priceCNY: 800, name: "小米 4K 显示器", category: "桌面装备", assetName: "reward-monitor", iconKind: .keyboard),
        RewardItem(id: "1000-8-4", tier: 1000, step: 8, priceCNY: 800, name: "AirPods Pro", category: "数码耳机", assetName: "reward-airpods", iconKind: .headphones),
        RewardItem(id: "1000-8-5", tier: 1000, step: 8, priceCNY: 800, name: "保友金豪人体工学椅", category: "桌面装备", assetName: "reward-office-chair", iconKind: .keyboard),
        RewardItem(id: "1000-8-6", tier: 1000, step: 8, priceCNY: 800, name: "香格里拉自助餐", category: "自助火锅", assetName: "reward-buffet-hotpot", iconKind: .meal),
        RewardItem(id: "1000-9-1", tier: 1000, step: 9, priceCNY: 900, name: "希尔顿欢朋一晚", category: "酒店度假", assetName: "reward-hotel", iconKind: .hotel),
        RewardItem(id: "1000-9-2", tier: 1000, step: 9, priceCNY: 900, name: "Sony LinkBuds", category: "数码耳机", assetName: "reward-earbuds", iconKind: .headphones),
        RewardItem(id: "1000-9-3", tier: 1000, step: 9, priceCNY: 900, name: "香格里拉自助餐", category: "自助火锅", assetName: "reward-buffet-hotpot", iconKind: .meal),
        RewardItem(id: "1000-9-4", tier: 1000, step: 9, priceCNY: 900, name: "Bose QuietComfort 耳机", category: "数码耳机", assetName: "reward-headphones", iconKind: .headphones),
        RewardItem(id: "1000-9-5", tier: 1000, step: 9, priceCNY: 900, name: "亚朵周末房", category: "酒店度假", assetName: "reward-hotel", iconKind: .hotel),
        RewardItem(id: "1000-9-6", tier: 1000, step: 9, priceCNY: 900, name: "戴森 Supersonic 吹风机", category: "生活电器", assetName: "reward-hair-dryer", iconKind: .laptop),
        RewardItem(id: "1000-10-1", tier: 1000, step: 10, priceCNY: 1000, name: "Bose QuietComfort 耳机", category: "数码耳机", assetName: "reward-headphones", iconKind: .headphones),
        RewardItem(id: "1000-10-2", tier: 1000, step: 10, priceCNY: 1000, name: "西昊人体工学椅", category: "桌面装备", assetName: "reward-office-chair", iconKind: .keyboard),
        RewardItem(id: "1000-10-3", tier: 1000, step: 10, priceCNY: 1000, name: "亚朵周末房", category: "酒店度假", assetName: "reward-hotel", iconKind: .hotel),
        RewardItem(id: "1000-10-4", tier: 1000, step: 10, priceCNY: 1000, name: "AirPods Pro", category: "数码耳机", assetName: "reward-airpods", iconKind: .headphones),
        RewardItem(id: "1000-10-5", tier: 1000, step: 10, priceCNY: 1000, name: "德龙咖啡机", category: "生活电器", assetName: "reward-coffee-machine", iconKind: .laptop),
        RewardItem(id: "1000-10-6", tier: 1000, step: 10, priceCNY: 1000, name: "携程周边两日游", category: "旅行体验", assetName: "reward-travel", iconKind: .travel),
        RewardItem(id: "2000-1-1", tier: 2000, step: 1, priceCNY: 200, name: "Keychron 机械键盘", category: "桌面装备", assetName: "reward-keyboard", iconKind: .keyboard),
        RewardItem(id: "2000-1-2", tier: 2000, step: 1, priceCNY: 200, name: "良子城市按摩", category: "按摩放松", assetName: "reward-massage", iconKind: .wellness),
        RewardItem(id: "2000-1-3", tier: 2000, step: 1, priceCNY: 200, name: "保利剧院门票", category: "演出展览", assetName: "reward-live-show", iconKind: .movie),
        RewardItem(id: "2000-1-4", tier: 2000, step: 1, priceCNY: 200, name: "Jo Malone 旅行香氛", category: "香氛护肤", assetName: "reward-fragrance", iconKind: .beauty),
        RewardItem(id: "2000-1-5", tier: 2000, step: 1, priceCNY: 200, name: "洛斐键帽", category: "桌面装备", assetName: "reward-keycaps", iconKind: .keyboard),
        RewardItem(id: "2000-1-6", tier: 2000, step: 1, priceCNY: 200, name: "曼谷屋泰式按摩", category: "按摩放松", assetName: "reward-massage", iconKind: .wellness),
        RewardItem(id: "2000-2-1", tier: 2000, step: 2, priceCNY: 400, name: "罗技 MX Master 3S", category: "桌面装备", assetName: "reward-mouse", iconKind: .mouse),
        RewardItem(id: "2000-2-2", tier: 2000, step: 2, priceCNY: 400, name: "Blue Frog 双人晚餐", category: "餐厅正餐", assetName: "reward-restaurant-meal", iconKind: .meal),
        RewardItem(id: "2000-2-3", tier: 2000, step: 2, priceCNY: 400, name: "华为 Watch Fit", category: "健康设备", assetName: "reward-health-scale", iconKind: .wellness),
        RewardItem(id: "2000-2-4", tier: 2000, step: 2, priceCNY: 400, name: "小米 4K 显示器", category: "桌面装备", assetName: "reward-monitor", iconKind: .keyboard),
        RewardItem(id: "2000-2-5", tier: 2000, step: 2, priceCNY: 400, name: "大渔铁板烧双人餐", category: "自助火锅", assetName: "reward-buffet-hotpot", iconKind: .meal),
        RewardItem(id: "2000-2-6", tier: 2000, step: 2, priceCNY: 400, name: "东田染发护理", category: "头发护理", assetName: "reward-haircare", iconKind: .wellness),
        RewardItem(id: "2000-3-1", tier: 2000, step: 3, priceCNY: 600, name: "亚朵酒店一晚", category: "酒店度假", assetName: "reward-hotel", iconKind: .hotel),
        RewardItem(id: "2000-3-2", tier: 2000, step: 3, priceCNY: 600, name: "Nike Pegasus 跑鞋", category: "运动鞋履", assetName: "reward-sneakers", iconKind: .wellness),
        RewardItem(id: "2000-3-3", tier: 2000, step: 3, priceCNY: 600, name: "大董双人简餐", category: "餐厅正餐", assetName: "reward-restaurant-meal", iconKind: .meal),
        RewardItem(id: "2000-3-4", tier: 2000, step: 3, priceCNY: 600, name: "Bose QuietComfort 耳机", category: "数码耳机", assetName: "reward-headphones", iconKind: .headphones),
        RewardItem(id: "2000-3-5", tier: 2000, step: 3, priceCNY: 600, name: "Coach 小号托特", category: "通勤包袋", assetName: "reward-bag", iconKind: .beauty),
        RewardItem(id: "2000-3-6", tier: 2000, step: 3, priceCNY: 600, name: "戴尔显示器", category: "桌面装备", assetName: "reward-monitor", iconKind: .keyboard),
        RewardItem(id: "2000-4-1", tier: 2000, step: 4, priceCNY: 800, name: "泰到位高端 SPA", category: "按摩放松", assetName: "reward-massage", iconKind: .wellness),
        RewardItem(id: "2000-4-2", tier: 2000, step: 4, priceCNY: 800, name: "携程周边一日游", category: "旅行体验", assetName: "reward-travel", iconKind: .travel),
        RewardItem(id: "2000-4-3", tier: 2000, step: 4, priceCNY: 800, name: "小米 4K 显示器", category: "桌面装备", assetName: "reward-monitor", iconKind: .keyboard),
        RewardItem(id: "2000-4-4", tier: 2000, step: 4, priceCNY: 800, name: "AirPods Pro", category: "数码耳机", assetName: "reward-airpods", iconKind: .headphones),
        RewardItem(id: "2000-4-5", tier: 2000, step: 4, priceCNY: 800, name: "香格里拉自助餐", category: "自助火锅", assetName: "reward-buffet-hotpot", iconKind: .meal),
        RewardItem(id: "2000-4-6", tier: 2000, step: 4, priceCNY: 800, name: "保友金豪人体工学椅", category: "桌面装备", assetName: "reward-office-chair", iconKind: .keyboard),
        RewardItem(id: "2000-5-1", tier: 2000, step: 5, priceCNY: 1000, name: "Bose QuietComfort 耳机", category: "数码耳机", assetName: "reward-headphones", iconKind: .headphones),
        RewardItem(id: "2000-5-2", tier: 2000, step: 5, priceCNY: 1000, name: "西昊人体工学椅", category: "桌面装备", assetName: "reward-office-chair", iconKind: .keyboard),
        RewardItem(id: "2000-5-3", tier: 2000, step: 5, priceCNY: 1000, name: "希尔顿欢朋一晚", category: "酒店度假", assetName: "reward-hotel", iconKind: .hotel),
        RewardItem(id: "2000-5-4", tier: 2000, step: 5, priceCNY: 1000, name: "德龙咖啡机", category: "生活电器", assetName: "reward-coffee-machine", iconKind: .laptop),
        RewardItem(id: "2000-5-5", tier: 2000, step: 5, priceCNY: 1000, name: "AirPods Pro", category: "数码耳机", assetName: "reward-airpods", iconKind: .headphones),
        RewardItem(id: "2000-5-6", tier: 2000, step: 5, priceCNY: 1000, name: "亚朵周末房", category: "酒店度假", assetName: "reward-hotel", iconKind: .hotel),
        RewardItem(id: "2000-6-1", tier: 2000, step: 6, priceCNY: 1200, name: "Jo Malone 香水", category: "香氛护肤", assetName: "reward-fragrance", iconKind: .beauty),
        RewardItem(id: "2000-6-2", tier: 2000, step: 6, priceCNY: 1200, name: "桔子水晶酒店一晚", category: "酒店度假", assetName: "reward-hotel", iconKind: .hotel),
        RewardItem(id: "2000-6-3", tier: 2000, step: 6, priceCNY: 1200, name: "德龙咖啡机", category: "生活电器", assetName: "reward-coffee-machine", iconKind: .laptop),
        RewardItem(id: "2000-6-4", tier: 2000, step: 6, priceCNY: 1200, name: "戴尔 UltraSharp 显示器", category: "桌面装备", assetName: "reward-monitor", iconKind: .keyboard),
        RewardItem(id: "2000-6-5", tier: 2000, step: 6, priceCNY: 1200, name: "Coach 通勤包", category: "通勤包袋", assetName: "reward-bag", iconKind: .beauty),
        RewardItem(id: "2000-6-6", tier: 2000, step: 6, priceCNY: 1200, name: "希尔顿酒店一晚", category: "酒店度假", assetName: "reward-hotel", iconKind: .hotel),
        RewardItem(id: "2000-7-1", tier: 2000, step: 7, priceCNY: 1400, name: "Ruth's Chris 双人晚餐", category: "牛排餐厅", assetName: "reward-steak", iconKind: .meal),
        RewardItem(id: "2000-7-2", tier: 2000, step: 7, priceCNY: 1400, name: "上海北京机票", category: "航空出行", assetName: "reward-flight", iconKind: .ride),
        RewardItem(id: "2000-7-3", tier: 2000, step: 7, priceCNY: 1400, name: "戴尔 UltraSharp 显示器", category: "桌面装备", assetName: "reward-monitor", iconKind: .keyboard),
        RewardItem(id: "2000-7-4", tier: 2000, step: 7, priceCNY: 1400, name: "AirPods Pro", category: "数码耳机", assetName: "reward-airpods", iconKind: .headphones),
        RewardItem(id: "2000-7-5", tier: 2000, step: 7, priceCNY: 1400, name: "保友金豪人体工学椅", category: "桌面装备", assetName: "reward-office-chair", iconKind: .keyboard),
        RewardItem(id: "2000-7-6", tier: 2000, step: 7, priceCNY: 1400, name: "携程周边两日游", category: "旅行体验", assetName: "reward-travel", iconKind: .travel),
        RewardItem(id: "2000-8-1", tier: 2000, step: 8, priceCNY: 1600, name: "希尔顿酒店一晚", category: "酒店度假", assetName: "reward-hotel", iconKind: .hotel),
        RewardItem(id: "2000-8-2", tier: 2000, step: 8, priceCNY: 1600, name: "AirPods Pro", category: "数码耳机", assetName: "reward-airpods", iconKind: .headphones),
        RewardItem(id: "2000-8-3", tier: 2000, step: 8, priceCNY: 1600, name: "海马体城市写真", category: "旅行体验", assetName: "reward-travel", iconKind: .travel),
        RewardItem(id: "2000-8-4", tier: 2000, step: 8, priceCNY: 1600, name: "Sony WH-1000XM 耳机", category: "数码耳机", assetName: "reward-headphones", iconKind: .headphones),
        RewardItem(id: "2000-8-5", tier: 2000, step: 8, priceCNY: 1600, name: "戴森 Supersonic 吹风机", category: "生活电器", assetName: "reward-hair-dryer", iconKind: .laptop),
        RewardItem(id: "2000-8-6", tier: 2000, step: 8, priceCNY: 1600, name: "Keychron Q 系列键盘", category: "桌面装备", assetName: "reward-keyboard", iconKind: .keyboard),
        RewardItem(id: "2000-9-1", tier: 2000, step: 9, priceCNY: 1800, name: "Insta360 GO 相机", category: "影像设备", assetName: "reward-camera", iconKind: .camera),
        RewardItem(id: "2000-9-2", tier: 2000, step: 9, priceCNY: 1800, name: "携程周边两日游", category: "旅行体验", assetName: "reward-travel", iconKind: .travel),
        RewardItem(id: "2000-9-3", tier: 2000, step: 9, priceCNY: 1800, name: "保友金豪人体工学椅", category: "桌面装备", assetName: "reward-office-chair", iconKind: .keyboard),
        RewardItem(id: "2000-9-4", tier: 2000, step: 9, priceCNY: 1800, name: "DJI Osmo Action", category: "影像设备", assetName: "reward-camera", iconKind: .camera),
        RewardItem(id: "2000-9-5", tier: 2000, step: 9, priceCNY: 1800, name: "Marshall 音箱", category: "数码音箱", assetName: "reward-speaker", iconKind: .headphones),
        RewardItem(id: "2000-9-6", tier: 2000, step: 9, priceCNY: 1800, name: "希尔顿酒店周末房", category: "酒店度假", assetName: "reward-hotel", iconKind: .hotel),
        RewardItem(id: "2000-10-1", tier: 2000, step: 10, priceCNY: 2000, name: "Club Med 周末套餐", category: "旅行体验", assetName: "reward-travel", iconKind: .travel),
        RewardItem(id: "2000-10-2", tier: 2000, step: 10, priceCNY: 2000, name: "Coach 通勤包", category: "通勤包袋", assetName: "reward-bag", iconKind: .beauty),
        RewardItem(id: "2000-10-3", tier: 2000, step: 10, priceCNY: 2000, name: "极米家用投影仪", category: "影音设备", assetName: "reward-projector", iconKind: .laptop),
        RewardItem(id: "2000-10-4", tier: 2000, step: 10, priceCNY: 2000, name: "iPad mini", category: "数码装备", assetName: "reward-tablet", iconKind: .laptop),
        RewardItem(id: "2000-10-5", tier: 2000, step: 10, priceCNY: 2000, name: "Sony WH-1000XM 耳机", category: "数码耳机", assetName: "reward-headphones", iconKind: .headphones),
        RewardItem(id: "2000-10-6", tier: 2000, step: 10, priceCNY: 2000, name: "海马体旅拍", category: "旅行体验", assetName: "reward-travel", iconKind: .travel),
        RewardItem(id: "3000-1-1", tier: 3000, step: 1, priceCNY: 300, name: "Blue Frog 晚餐", category: "餐厅正餐", assetName: "reward-restaurant-meal", iconKind: .meal),
        RewardItem(id: "3000-1-2", tier: 3000, step: 1, priceCNY: 300, name: "丝域头疗护理", category: "头发护理", assetName: "reward-haircare", iconKind: .wellness),
        RewardItem(id: "3000-1-3", tier: 3000, step: 1, priceCNY: 300, name: "小米空气炸锅", category: "生活电器", assetName: "reward-air-fryer", iconKind: .laptop),
        RewardItem(id: "3000-1-4", tier: 3000, step: 1, priceCNY: 300, name: "王品牛排午餐", category: "牛排餐厅", assetName: "reward-steak", iconKind: .meal),
        RewardItem(id: "3000-1-5", tier: 3000, step: 1, priceCNY: 300, name: "Shake Shack 双人餐", category: "快餐套餐", assetName: "reward-burger-meal", iconKind: .meal),
        RewardItem(id: "3000-1-6", tier: 3000, step: 1, priceCNY: 300, name: "泰到位肩颈按摩", category: "按摩放松", assetName: "reward-massage", iconKind: .wellness),
        RewardItem(id: "3000-2-1", tier: 3000, step: 2, priceCNY: 600, name: "亚朵酒店一晚", category: "酒店度假", assetName: "reward-hotel", iconKind: .hotel),
        RewardItem(id: "3000-2-2", tier: 3000, step: 2, priceCNY: 600, name: "Nike Pegasus 跑鞋", category: "运动鞋履", assetName: "reward-sneakers", iconKind: .wellness),
        RewardItem(id: "3000-2-3", tier: 3000, step: 2, priceCNY: 600, name: "大董双人简餐", category: "餐厅正餐", assetName: "reward-restaurant-meal", iconKind: .meal),
        RewardItem(id: "3000-2-4", tier: 3000, step: 2, priceCNY: 600, name: "Bose QuietComfort 耳机", category: "数码耳机", assetName: "reward-headphones", iconKind: .headphones),
        RewardItem(id: "3000-2-5", tier: 3000, step: 2, priceCNY: 600, name: "戴尔显示器", category: "桌面装备", assetName: "reward-monitor", iconKind: .keyboard),
        RewardItem(id: "3000-2-6", tier: 3000, step: 2, priceCNY: 600, name: "Coach 小号托特", category: "通勤包袋", assetName: "reward-bag", iconKind: .beauty),
        RewardItem(id: "3000-3-1", tier: 3000, step: 3, priceCNY: 900, name: "希尔顿欢朋一晚", category: "酒店度假", assetName: "reward-hotel", iconKind: .hotel),
        RewardItem(id: "3000-3-2", tier: 3000, step: 3, priceCNY: 900, name: "Sony LinkBuds", category: "数码耳机", assetName: "reward-earbuds", iconKind: .headphones),
        RewardItem(id: "3000-3-3", tier: 3000, step: 3, priceCNY: 900, name: "香格里拉自助餐", category: "自助火锅", assetName: "reward-buffet-hotpot", iconKind: .meal),
        RewardItem(id: "3000-3-4", tier: 3000, step: 3, priceCNY: 900, name: "AirPods Pro", category: "数码耳机", assetName: "reward-airpods", iconKind: .headphones),
        RewardItem(id: "3000-3-5", tier: 3000, step: 3, priceCNY: 900, name: "亚朵周末房", category: "酒店度假", assetName: "reward-hotel", iconKind: .hotel),
        RewardItem(id: "3000-3-6", tier: 3000, step: 3, priceCNY: 900, name: "戴森 Supersonic 吹风机", category: "生活电器", assetName: "reward-hair-dryer", iconKind: .laptop),
        RewardItem(id: "3000-4-1", tier: 3000, step: 4, priceCNY: 1200, name: "Jo Malone 香水", category: "香氛护肤", assetName: "reward-fragrance", iconKind: .beauty),
        RewardItem(id: "3000-4-2", tier: 3000, step: 4, priceCNY: 1200, name: "桔子水晶酒店一晚", category: "酒店度假", assetName: "reward-hotel", iconKind: .hotel),
        RewardItem(id: "3000-4-3", tier: 3000, step: 4, priceCNY: 1200, name: "德龙咖啡机", category: "生活电器", assetName: "reward-coffee-machine", iconKind: .laptop),
        RewardItem(id: "3000-4-4", tier: 3000, step: 4, priceCNY: 1200, name: "戴尔 UltraSharp 显示器", category: "桌面装备", assetName: "reward-monitor", iconKind: .keyboard),
        RewardItem(id: "3000-4-5", tier: 3000, step: 4, priceCNY: 1200, name: "Coach 通勤包", category: "通勤包袋", assetName: "reward-bag", iconKind: .beauty),
        RewardItem(id: "3000-4-6", tier: 3000, step: 4, priceCNY: 1200, name: "希尔顿酒店一晚", category: "酒店度假", assetName: "reward-hotel", iconKind: .hotel),
        RewardItem(id: "3000-5-1", tier: 3000, step: 5, priceCNY: 1500, name: "希尔顿酒店一晚", category: "酒店度假", assetName: "reward-hotel", iconKind: .hotel),
        RewardItem(id: "3000-5-2", tier: 3000, step: 5, priceCNY: 1500, name: "Keychron Q 系列键盘", category: "桌面装备", assetName: "reward-keyboard", iconKind: .keyboard),
        RewardItem(id: "3000-5-3", tier: 3000, step: 5, priceCNY: 1500, name: "泰到位高端 SPA", category: "按摩放松", assetName: "reward-massage", iconKind: .wellness),
        RewardItem(id: "3000-5-4", tier: 3000, step: 5, priceCNY: 1500, name: "Sony WH-1000XM 耳机", category: "数码耳机", assetName: "reward-headphones", iconKind: .headphones),
        RewardItem(id: "3000-5-5", tier: 3000, step: 5, priceCNY: 1500, name: "保友金豪人体工学椅", category: "桌面装备", assetName: "reward-office-chair", iconKind: .keyboard),
        RewardItem(id: "3000-5-6", tier: 3000, step: 5, priceCNY: 1500, name: "海马体城市写真", category: "旅行体验", assetName: "reward-travel", iconKind: .travel),
        RewardItem(id: "3000-6-1", tier: 3000, step: 6, priceCNY: 1800, name: "Insta360 GO 相机", category: "影像设备", assetName: "reward-camera", iconKind: .camera),
        RewardItem(id: "3000-6-2", tier: 3000, step: 6, priceCNY: 1800, name: "携程周边两日游", category: "旅行体验", assetName: "reward-travel", iconKind: .travel),
        RewardItem(id: "3000-6-3", tier: 3000, step: 6, priceCNY: 1800, name: "保友金豪人体工学椅", category: "桌面装备", assetName: "reward-office-chair", iconKind: .keyboard),
        RewardItem(id: "3000-6-4", tier: 3000, step: 6, priceCNY: 1800, name: "DJI Osmo Action", category: "影像设备", assetName: "reward-camera", iconKind: .camera),
        RewardItem(id: "3000-6-5", tier: 3000, step: 6, priceCNY: 1800, name: "Marshall 音箱", category: "数码音箱", assetName: "reward-speaker", iconKind: .headphones),
        RewardItem(id: "3000-6-6", tier: 3000, step: 6, priceCNY: 1800, name: "希尔顿周末房", category: "酒店度假", assetName: "reward-hotel", iconKind: .hotel),
        RewardItem(id: "3000-7-1", tier: 3000, step: 7, priceCNY: 2100, name: "国内往返机票", category: "航空出行", assetName: "reward-flight", iconKind: .ride),
        RewardItem(id: "3000-7-2", tier: 3000, step: 7, priceCNY: 2100, name: "Marshall 音箱", category: "数码音箱", assetName: "reward-speaker", iconKind: .headphones),
        RewardItem(id: "3000-7-3", tier: 3000, step: 7, priceCNY: 2100, name: "安缦周边餐饮体验", category: "旅行体验", assetName: "reward-travel", iconKind: .travel),
        RewardItem(id: "3000-7-4", tier: 3000, step: 7, priceCNY: 2100, name: "Club Med 周末套餐", category: "旅行体验", assetName: "reward-travel", iconKind: .travel),
        RewardItem(id: "3000-7-5", tier: 3000, step: 7, priceCNY: 2100, name: "Coach 通勤包", category: "通勤包袋", assetName: "reward-bag", iconKind: .beauty),
        RewardItem(id: "3000-7-6", tier: 3000, step: 7, priceCNY: 2100, name: "极米家用投影仪", category: "影音设备", assetName: "reward-projector", iconKind: .laptop),
        RewardItem(id: "3000-8-1", tier: 3000, step: 8, priceCNY: 2400, name: "大疆 Osmo Pocket 3", category: "影像设备", assetName: "reward-camera", iconKind: .camera),
        RewardItem(id: "3000-8-2", tier: 3000, step: 8, priceCNY: 2400, name: "米家空气净化器", category: "生活电器", assetName: "reward-air-purifier", iconKind: .laptop),
        RewardItem(id: "3000-8-3", tier: 3000, step: 8, priceCNY: 2400, name: "海马体旅拍", category: "旅行体验", assetName: "reward-travel", iconKind: .travel),
        RewardItem(id: "3000-8-4", tier: 3000, step: 8, priceCNY: 2400, name: "PlayStation 5 Slim", category: "游戏数码", assetName: "reward-game-console", iconKind: .movie),
        RewardItem(id: "3000-8-5", tier: 3000, step: 8, priceCNY: 2400, name: "戴森 Supersonic 吹风机", category: "生活电器", assetName: "reward-hair-dryer", iconKind: .laptop),
        RewardItem(id: "3000-8-6", tier: 3000, step: 8, priceCNY: 2400, name: "希尔顿度假套餐", category: "酒店度假", assetName: "reward-hotel", iconKind: .hotel),
        RewardItem(id: "3000-9-1", tier: 3000, step: 9, priceCNY: 2700, name: "PlayStation 5 Slim", category: "游戏数码", assetName: "reward-game-console", iconKind: .movie),
        RewardItem(id: "3000-9-2", tier: 3000, step: 9, priceCNY: 2700, name: "携程双人周末游", category: "旅行体验", assetName: "reward-travel", iconKind: .travel),
        RewardItem(id: "3000-9-3", tier: 3000, step: 9, priceCNY: 2700, name: "德龙全自动咖啡机", category: "生活电器", assetName: "reward-coffee-machine", iconKind: .laptop),
        RewardItem(id: "3000-9-4", tier: 3000, step: 9, priceCNY: 2700, name: "大疆 Osmo Pocket 3", category: "影像设备", assetName: "reward-camera", iconKind: .camera),
        RewardItem(id: "3000-9-5", tier: 3000, step: 9, priceCNY: 2700, name: "iPad mini", category: "数码装备", assetName: "reward-tablet", iconKind: .laptop),
        RewardItem(id: "3000-9-6", tier: 3000, step: 9, priceCNY: 2700, name: "米家空气净化器", category: "生活电器", assetName: "reward-air-purifier", iconKind: .laptop),
        RewardItem(id: "3000-10-1", tier: 3000, step: 10, priceCNY: 3000, name: "iPad mini", category: "数码装备", assetName: "reward-tablet", iconKind: .laptop),
        RewardItem(id: "3000-10-2", tier: 3000, step: 10, priceCNY: 3000, name: "戴森 Supersonic 吹风机", category: "生活电器", assetName: "reward-hair-dryer", iconKind: .laptop),
        RewardItem(id: "3000-10-3", tier: 3000, step: 10, priceCNY: 3000, name: "希尔顿度假两日游", category: "酒店度假", assetName: "reward-hotel", iconKind: .hotel),
        RewardItem(id: "3000-10-4", tier: 3000, step: 10, priceCNY: 3000, name: "大疆 Osmo Pocket 3", category: "影像设备", assetName: "reward-camera", iconKind: .camera),
        RewardItem(id: "3000-10-5", tier: 3000, step: 10, priceCNY: 3000, name: "PlayStation 5 Slim", category: "游戏数码", assetName: "reward-game-console", iconKind: .movie),
        RewardItem(id: "3000-10-6", tier: 3000, step: 10, priceCNY: 3000, name: "德龙全自动咖啡机", category: "生活电器", assetName: "reward-coffee-machine", iconKind: .laptop)
    ]
}

private struct RewardItem: Sendable {
    var id: String
    var tier: Int
    var step: Int
    var priceCNY: Double
    var name: String
    var category: String
    var assetName: String
    var iconKind: RewardIconKind
}
