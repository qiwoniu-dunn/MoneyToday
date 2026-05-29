# Reward Asset Taxonomy

This document keeps the image-asset layer separate from the reward copy layer.

Reward names can mention concrete brands and products, but image generation should stay reusable. For example, Jo Malone, Maison Margiela, Diptyque, and Tom Ford can all use one fragrance-style pixel asset instead of one image per brand.

Current source table: the latest expanded reward table in product discussion, organized as 5 daily-income tiers x 10 steps x 6 reward options. That is 300 displayed reward options in the current draft. The product target can be expanded to 600 displayed options later; append new product names to these asset keys unless a genuinely new visual family appears.

## Summary

- Product-copy options fully enumerated in current draft: 300
- Product-copy expansion target: 600
- Generic pixel assets to create: 47
- Target style: crisp pixel-art reward icon with visible blocky detail, stored as a clear 512 x 512 PNG for app display.
- Mapping rule: show concrete brand/product names in text, but select the corresponding generic asset key for the image.

## Asset List

| # | Asset key | Generic image to draw | Mapped reward names |
|---:|---|---|---|
| 1 | `reward-coffee` | Branded-looking hot coffee cup, no logo | 星巴克拿铁, Peet's 咖啡甜点, Manner 咖啡双杯, 星巴克臻选咖啡 |
| 2 | `reward-tea` | Modern milk tea / fruit tea cup | 喜茶多肉葡萄, 喜茶轻食套餐, 奈雪霸气芝士草莓, 奈雪欧包茶饮 |
| 3 | `reward-burger-meal` | Burger, fries, and drink combo | 麦当劳板烧鸡腿堡套餐, 肯德基香辣鸡腿堡套餐, 汉堡王皇堡套餐, 汉堡王双人套餐, Shake Shack 单人餐, Shake Shack 双人餐, 麦当劳双人小食 |
| 4 | `reward-noodle-bento` | Bowl meal / lunch box | 和府捞面招牌面, 日式便当, 盒马鲜生寿司拼盘 |
| 5 | `reward-salad` | Fresh salad bowl | Wagas 轻食沙拉, Wagas 商务午餐, 茶饮轻食餐 |
| 6 | `reward-brunch` | Brunch plate with bread and coffee | M Stand 周末早午餐, Baker & Spice 双人早午餐 |
| 7 | `reward-restaurant-meal` | Polished restaurant dinner plate | 西贝单人正餐, Blue Frog 晚餐, Blue Frog 双人晚餐, 大董单人餐, 大董双人简餐, 炉鱼双人餐, 精致双人餐 |
| 8 | `reward-steak` | Steakhouse plate | 王品牛排午餐, Wolfgang's Steakhouse 单人餐, Ruth's Chris 双人晚餐 |
| 9 | `reward-buffet-hotpot` | Hotpot or buffet spread | 盒马鲜生海鲜小火锅, 大渔铁板烧单人餐, 大渔铁板烧双人餐, 香格里拉自助餐 |
| 10 | `reward-movie` | Cinema ticket and popcorn | 万达影城电影票, 万达双人电影票, 万达双人电影夜, 万达 IMAX 电影票, CGV 巨幕电影票, CGV 双人电影夜, IMAX 电影票 |
| 11 | `reward-live-show` | Stage ticket with spotlight | UCCA 展览门票, MAO Livehouse 门票, MAO Livehouse 预售票, 笑果脱口秀门票, 保利剧院门票 |
| 12 | `reward-massage` | Massage table / relaxed shoulder icon | 良子肩颈放松, 泰到位足疗, 良子足疗按摩, 泰到位肩颈按摩, 良子城市按摩, 曼谷屋泰式按摩, 泰到位深度 SPA, 泰到位高端 SPA |
| 13 | `reward-haircare` | Salon chair with hair-care sparkle | 东田造型理发, 东田造型男士理发, 东田染发护理, 丝域头皮护理, 丝域头疗护理 |
| 14 | `reward-fitness-class` | Gym / yoga mat class icon | 超级猩猩单次课, 超级猩猩单次体验, Lululemon 瑜伽体验, Lululemon 瑜伽课, PURE 瑜伽体验课, PURE 单次瑜伽课 |
| 15 | `reward-sportswear` | Folded athletic shirt or shorts | Nike Dri-FIT 运动 T 恤, Nike 运动短裤 |
| 16 | `reward-sneakers` | Sneakers side view | Converse 帆布鞋, Nike Pegasus 跑鞋, Adidas Ultraboost, Adidas 运动鞋 |
| 17 | `reward-sports-accessory` | Sport bag / training accessory | Nike 运动腰包, Nike 通勤双肩包, Keep 瑜伽垫 |
| 18 | `reward-health-scale` | Smart body scale | 小米体脂秤, Keep 智能体脂秤 |
| 19 | `reward-earbuds` | Compact true-wireless earbuds | 小米 Redmi Buds, Beats Studio Buds, Sony LinkBuds |
| 20 | `reward-headphones` | Premium over-ear / noise-canceling headphones | Bose QuietComfort 耳机, Sony WH-1000XM 耳机 |
| 21 | `reward-airpods` | White stem earbuds in charging case | AirPods Pro |
| 22 | `reward-speaker` | Small premium speaker | Marshall 音箱, Bose 便携音箱 |
| 23 | `reward-keycaps` | Colorful keycap set | 洛斐键帽, Keychron 键帽, 设计师键帽 |
| 24 | `reward-keyboard` | Compact mechanical keyboard | Keychron 机械键盘, Keychron Q 系列键盘 |
| 25 | `reward-mouse` | Premium ergonomic mouse | 罗技 MX Master 鼠标, 罗技 MX Master 3S |
| 26 | `reward-desk-setup` | Desk accessory cluster | MUJI 桌面收纳, 宜家电脑支架, Ergotron 显示器支架, Humanscale 脚踏, 宜家桌面灯, 电脑支架, 显示器支架 |
| 27 | `reward-monitor` | Desktop monitor | 小米 4K 显示器, 戴尔显示器, 戴尔 UltraSharp 显示器 |
| 28 | `reward-office-chair` | Ergonomic office chair | 西昊人体工学椅, 保友金豪人体工学椅 |
| 29 | `reward-storage-drive` | Portable SSD | 闪迪移动固态硬盘 |
| 30 | `reward-air-fryer` | Compact air fryer | 小米空气炸锅 |
| 31 | `reward-toothbrush` | Electric toothbrush | 飞利浦电动牙刷 |
| 32 | `reward-home-appliance` | Small home appliance / fan | MUJI 空气循环扇 |
| 33 | `reward-coffee-machine` | Countertop coffee machine | 德龙咖啡机, 德龙全自动咖啡机 |
| 34 | `reward-air-purifier` | Tall air purifier | 米家空气净化器 |
| 35 | `reward-hair-dryer` | Premium hair dryer | 戴森 Supersonic 吹风机 |
| 36 | `reward-fragrance` | Perfume bottle and candle | Diptyque 香氛蜡烛, Diptyque 小蜡烛, Marshall 香薰蜡烛, MUJI 香薰精油, MUJI 香薰机, Jo Malone 旅行香氛, Jo Malone 香水, Maison Margiela 香水, 轻奢香水 |
| 37 | `reward-skincare` | Skincare bottles / gift box | 欧莱雅护肤礼盒, 资生堂护肤套装 |
| 38 | `reward-city-ride` | Taxi / metro commute icon | 滴滴快车短途, 滴滴快车跨区, 上海地铁月度通勤 |
| 39 | `reward-train` | High-speed train ticket / train nose | 高铁城际往返票, 上海杭州高铁往返 |
| 40 | `reward-flight` | Airplane ticket and plane | 上海北京机票, 国内往返机票 |
| 41 | `reward-hotel` | Hotel bed / skyline window | 亚朵酒店一晚, 亚朵周末房, 亚朵酒店钟点房, 桔子水晶酒店一晚, 希尔顿欢朋一晚, 希尔顿酒店一晚, 希尔顿酒店周末房, 希尔顿周末房, 希尔顿度假套餐, 希尔顿度假两日游 |
| 42 | `reward-travel` | Weekend suitcase / route map | 携程周边一日游, 携程周边两日游, 携程双人周末游, Club Med 周末套餐, 安缦周边餐饮体验, 海马体城市写真, 海马体旅拍, 城市旅拍 |
| 43 | `reward-camera` | Compact action / pocket camera | Insta360 GO 相机, DJI Osmo Action, 大疆 Osmo Pocket 3 |
| 44 | `reward-game-console` | Slim white game console and controller | PlayStation 5 Slim |
| 45 | `reward-tablet` | Small tablet | iPad mini |
| 46 | `reward-projector` | Home projector | 极米家用投影仪 |
| 47 | `reward-bag` | Premium commuter tote / backpack | Coach 小号托特, Coach 通勤包 |

## Consolidation Notes

- Keep brand names only in reward copy. Pixel art should avoid logos and readable marks.
- If a new reward is just another brand inside an existing family, reuse the existing asset key.
- Add a new asset key only when the object silhouette would clearly be different at small in-app icon size.
- For app implementation, each reward item should store both `displayName` and `assetKey`.
- Some product names appear across multiple daily-income tiers by design. The mapping above lists unique visual families, not every table cell.
