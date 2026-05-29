# Reward Catalog V2 Draft

This is the working draft for the next reward catalog. It keeps concrete brand/product copy separate from reusable image assets.

## Design Rules

- Daily-income tiers: 300, 500, 1000, 2000, 3000 CNY.
- Each tier has 10 steps, evenly split by daily income.
- Each step currently has 6 concrete reward options, so the current draft contains 300 concrete options.
- Expansion target is 600 concrete options. Unless new products create a new small-icon silhouette family, they should reuse the existing asset keys in `reward-asset-taxonomy.md`.
- Avoid weak copy such as entry-level, low-price, budget, accessory-only, discount, fund, or subsidy.
- Display concrete brands/products in copy, but draw generic logo-free pixel icons.

## Candidate Table

Each reward is written as `displayName` -> `assetKey`.

| 日薪档 | 阶梯 | 金额 | 候选 1 | 候选 2 | 候选 3 | 候选 4 | 候选 5 | 候选 6 |
|---:|---:|---:|---|---|---|---|---|---|
| 300 | 1 | 30 | 星巴克拿铁 -> `reward-coffee` | 滴滴快车短途 -> `reward-city-ride` | 麦当劳板烧鸡腿堡套餐 -> `reward-burger-meal` | 喜茶多肉葡萄 -> `reward-tea` | 瑞幸丝绒拿铁 -> `reward-coffee` | 肯德基香辣鸡腿堡套餐 -> `reward-burger-meal` |
| 300 | 2 | 60 | 万达影城电影票 -> `reward-movie` | 和府捞面招牌面 -> `reward-noodle-bento` | Peet's 咖啡甜点 -> `reward-coffee` | Manner 咖啡双杯 -> `reward-coffee` | 汉堡王皇堡套餐 -> `reward-burger-meal` | 奈雪霸气芝士草莓 -> `reward-tea` |
| 300 | 3 | 90 | Wagas 轻食沙拉 -> `reward-salad` | 良子肩颈放松 -> `reward-massage` | Nike Dri-FIT 运动 T 恤 -> `reward-sportswear` | 盒马鲜生寿司拼盘 -> `reward-noodle-bento` | 超级猩猩单次体验 -> `reward-fitness-class` | MUJI 香薰精油 -> `reward-fragrance` |
| 300 | 4 | 120 | M Stand 周末早午餐 -> `reward-brunch` | 超级猩猩单次课 -> `reward-fitness-class` | 小米 Redmi Buds -> `reward-earbuds` | 西贝单人正餐 -> `reward-restaurant-meal` | UCCA 展览门票 -> `reward-live-show` | Keep 瑜伽垫 -> `reward-sports-accessory` |
| 300 | 5 | 150 | 西贝单人正餐 -> `reward-restaurant-meal` | 东田造型理发 -> `reward-haircare` | MUJI 桌面收纳 -> `reward-desk-setup` | Keychron 手托 -> `reward-desk-setup` | Diptyque 小蜡烛 -> `reward-fragrance` | 万达双人电影票 -> `reward-movie` |
| 300 | 6 | 180 | 泰到位足疗 -> `reward-massage` | Diptyque 香氛蜡烛 -> `reward-fragrance` | 上海地铁月度通勤 -> `reward-city-ride` | 良子足疗按摩 -> `reward-massage` | Marshall 香薰蜡烛 -> `reward-fragrance` | Nike 运动短裤 -> `reward-sportswear` |
| 300 | 7 | 210 | 盒马鲜生海鲜小火锅 -> `reward-buffet-hotpot` | 洛斐键帽 -> `reward-keycaps` | UCCA 展览门票 -> `reward-live-show` | Keychron 键帽 -> `reward-keycaps` | MAO Livehouse 预售票 -> `reward-live-show` | 飞利浦电动牙刷 -> `reward-toothbrush` |
| 300 | 8 | 240 | Lululemon 瑜伽体验 -> `reward-fitness-class` | 欧莱雅护肤礼盒 -> `reward-skincare` | Anker 快充套装 -> `reward-desk-setup` | PURE 单次瑜伽课 -> `reward-fitness-class` | 资生堂护肤套装 -> `reward-skincare` | 小米体脂秤 -> `reward-health-scale` |
| 300 | 9 | 270 | 万达双人电影夜 -> `reward-movie` | Boxing Cat 精酿 -> `reward-restaurant-meal` | Converse 帆布鞋 -> `reward-sneakers` | CGV 双人电影夜 -> `reward-movie` | Nike 运动腰包 -> `reward-sports-accessory` | Baker & Spice 双人早午餐 -> `reward-brunch` |
| 300 | 10 | 300 | Blue Frog 晚餐 -> `reward-restaurant-meal` | 丝域头皮护理 -> `reward-haircare` | 小米空气炸锅 -> `reward-air-fryer` | Shake Shack 双人餐 -> `reward-burger-meal` | 泰到位肩颈按摩 -> `reward-massage` | 宜家桌面灯 -> `reward-desk-setup` |
| 500 | 1 | 50 | CGV 巨幕电影票 -> `reward-movie` | 滴滴快车跨区 -> `reward-city-ride` | 喜茶轻食套餐 -> `reward-tea` | 星巴克臻选咖啡 -> `reward-coffee` | 麦当劳双人小食 -> `reward-burger-meal` | 奈雪欧包茶饮 -> `reward-tea` |
| 500 | 2 | 100 | Shake Shack 单人餐 -> `reward-burger-meal` | 泰到位肩颈按摩 -> `reward-massage` | Nike 运动腰包 -> `reward-sports-accessory` | Wagas 商务午餐 -> `reward-salad` | 万达 IMAX 电影票 -> `reward-movie` | MUJI 香薰机 -> `reward-fragrance` |
| 500 | 3 | 150 | 东田造型男士理发 -> `reward-haircare` | 汉堡王双人套餐 -> `reward-burger-meal` | 宜家电脑支架 -> `reward-desk-setup` | 西贝单人正餐 -> `reward-restaurant-meal` | 飞利浦电动牙刷 -> `reward-toothbrush` | UCCA 展览门票 -> `reward-live-show` |
| 500 | 4 | 200 | 良子城市按摩 -> `reward-massage` | Jo Malone 旅行香氛 -> `reward-fragrance` | Keychron 键帽 -> `reward-keycaps` | 曼谷屋泰式按摩 -> `reward-massage` | 洛斐键帽 -> `reward-keycaps` | 保利剧院门票 -> `reward-live-show` |
| 500 | 5 | 250 | Baker & Spice 双人早午餐 -> `reward-brunch` | PURE 瑜伽体验课 -> `reward-fitness-class` | 飞利浦电动牙刷 -> `reward-toothbrush` | Lululemon 瑜伽课 -> `reward-fitness-class` | Anker 充电套装 -> `reward-desk-setup` | CGV 双人电影夜 -> `reward-movie` |
| 500 | 6 | 300 | 王品牛排午餐 -> `reward-steak` | 丝域头疗护理 -> `reward-haircare` | 小米空气炸锅 -> `reward-air-fryer` | Blue Frog 晚餐 -> `reward-restaurant-meal` | Keep 智能体脂秤 -> `reward-health-scale` | Boxing Cat 精酿 -> `reward-restaurant-meal` |
| 500 | 7 | 350 | MAO Livehouse 门票 -> `reward-live-show` | Nike 通勤双肩包 -> `reward-sports-accessory` | 闪迪移动固态硬盘 -> `reward-storage-drive` | Adidas 运动鞋 -> `reward-sneakers` | Keychron 机械键盘 -> `reward-keyboard` | 大渔铁板烧单人餐 -> `reward-buffet-hotpot` |
| 500 | 8 | 400 | 罗技 MX Master 鼠标 -> `reward-mouse` | 大渔铁板烧双人餐 -> `reward-buffet-hotpot` | 亚朵酒店钟点房 -> `reward-hotel` | 华为 Watch Fit -> `reward-health-scale` | 东田染发护理 -> `reward-haircare` | 小米 4K 显示器 -> `reward-monitor` |
| 500 | 9 | 450 | Maison Margiela 香水 -> `reward-fragrance` | 泰到位深度 SPA -> `reward-massage` | Adidas Ultraboost -> `reward-sneakers` | Jo Malone 香水 -> `reward-fragrance` | Bose 便携音箱 -> `reward-speaker` | 香格里拉自助餐 -> `reward-buffet-hotpot` |
| 500 | 10 | 500 | Wolfgang's Steakhouse 单人餐 -> `reward-steak` | Ergotron 显示器支架 -> `reward-desk-setup` | 高铁城际往返票 -> `reward-train` | Sony LinkBuds -> `reward-earbuds` | 大董单人餐 -> `reward-restaurant-meal` | 亚朵酒店一晚 -> `reward-hotel` |
| 1000 | 1 | 100 | 泰到位肩颈按摩 -> `reward-massage` | Wagas 商务午餐 -> `reward-salad` | IMAX 电影票 -> `reward-movie` | Shake Shack 单人餐 -> `reward-burger-meal` | Nike 运动腰包 -> `reward-sports-accessory` | 星巴克臻选咖啡 -> `reward-coffee` |
| 1000 | 2 | 200 | 曼谷屋泰式按摩 -> `reward-massage` | Keychron 机械键盘 -> `reward-keyboard` | 笑果脱口秀门票 -> `reward-live-show` | 良子城市按摩 -> `reward-massage` | Jo Malone 旅行香氛 -> `reward-fragrance` | 保利剧院门票 -> `reward-live-show` |
| 1000 | 3 | 300 | Blue Frog 晚餐 -> `reward-restaurant-meal` | 丝域头疗护理 -> `reward-haircare` | 小米空气炸锅 -> `reward-air-fryer` | 王品牛排午餐 -> `reward-steak` | Keep 智能体脂秤 -> `reward-health-scale` | MUJI 空气循环扇 -> `reward-home-appliance` |
| 1000 | 4 | 400 | 罗技 MX Master 3S -> `reward-mouse` | 炉鱼双人餐 -> `reward-restaurant-meal` | 华为 Watch Fit -> `reward-health-scale` | 大渔铁板烧双人餐 -> `reward-buffet-hotpot` | 东田染发护理 -> `reward-haircare` | 小米 4K 显示器 -> `reward-monitor` |
| 1000 | 5 | 500 | 上海杭州高铁往返 -> `reward-train` | Jo Malone 香水 -> `reward-fragrance` | Humanscale 脚踏 -> `reward-desk-setup` | Sony LinkBuds -> `reward-earbuds` | 大董单人餐 -> `reward-restaurant-meal` | 亚朵酒店一晚 -> `reward-hotel` |
| 1000 | 6 | 600 | 亚朵酒店一晚 -> `reward-hotel` | Nike Pegasus 跑鞋 -> `reward-sneakers` | 大董双人简餐 -> `reward-restaurant-meal` | 戴尔显示器 -> `reward-monitor` | Bose QuietComfort 耳机 -> `reward-headphones` | Coach 小号托特 -> `reward-bag` |
| 1000 | 7 | 700 | 桔子水晶酒店一晚 -> `reward-hotel` | Beats Studio Buds -> `reward-earbuds` | 东田染发护理 -> `reward-haircare` | Adidas Ultraboost -> `reward-sneakers` | 德龙咖啡机 -> `reward-coffee-machine` | 希尔顿欢朋一晚 -> `reward-hotel` |
| 1000 | 8 | 800 | 泰到位高端 SPA -> `reward-massage` | 携程周边一日游 -> `reward-travel` | 小米 4K 显示器 -> `reward-monitor` | AirPods Pro -> `reward-airpods` | 保友金豪人体工学椅 -> `reward-office-chair` | 香格里拉自助餐 -> `reward-buffet-hotpot` |
| 1000 | 9 | 900 | 希尔顿欢朋一晚 -> `reward-hotel` | Sony LinkBuds -> `reward-earbuds` | 香格里拉自助餐 -> `reward-buffet-hotpot` | Bose QuietComfort 耳机 -> `reward-headphones` | 亚朵周末房 -> `reward-hotel` | 戴森 Supersonic 吹风机 -> `reward-hair-dryer` |
| 1000 | 10 | 1000 | Bose QuietComfort 耳机 -> `reward-headphones` | 西昊人体工学椅 -> `reward-office-chair` | 亚朵周末房 -> `reward-hotel` | AirPods Pro -> `reward-airpods` | 德龙咖啡机 -> `reward-coffee-machine` | 携程周边两日游 -> `reward-travel` |
| 2000 | 1 | 200 | Keychron 机械键盘 -> `reward-keyboard` | 良子城市按摩 -> `reward-massage` | 保利剧院门票 -> `reward-live-show` | Jo Malone 旅行香氛 -> `reward-fragrance` | 洛斐键帽 -> `reward-keycaps` | 曼谷屋泰式按摩 -> `reward-massage` |
| 2000 | 2 | 400 | 罗技 MX Master 3S -> `reward-mouse` | Blue Frog 双人晚餐 -> `reward-restaurant-meal` | 华为 Watch Fit -> `reward-health-scale` | 小米 4K 显示器 -> `reward-monitor` | 大渔铁板烧双人餐 -> `reward-buffet-hotpot` | 东田染发护理 -> `reward-haircare` |
| 2000 | 3 | 600 | 亚朵酒店一晚 -> `reward-hotel` | Nike Pegasus 跑鞋 -> `reward-sneakers` | 大董双人简餐 -> `reward-restaurant-meal` | Bose QuietComfort 耳机 -> `reward-headphones` | Coach 小号托特 -> `reward-bag` | 戴尔显示器 -> `reward-monitor` |
| 2000 | 4 | 800 | 泰到位高端 SPA -> `reward-massage` | 携程周边一日游 -> `reward-travel` | 小米 4K 显示器 -> `reward-monitor` | AirPods Pro -> `reward-airpods` | 香格里拉自助餐 -> `reward-buffet-hotpot` | 保友金豪人体工学椅 -> `reward-office-chair` |
| 2000 | 5 | 1000 | Bose QuietComfort 耳机 -> `reward-headphones` | 西昊人体工学椅 -> `reward-office-chair` | 希尔顿欢朋一晚 -> `reward-hotel` | 德龙咖啡机 -> `reward-coffee-machine` | AirPods Pro -> `reward-airpods` | 亚朵周末房 -> `reward-hotel` |
| 2000 | 6 | 1200 | Jo Malone 香水 -> `reward-fragrance` | 桔子水晶酒店一晚 -> `reward-hotel` | 德龙咖啡机 -> `reward-coffee-machine` | 戴尔 UltraSharp 显示器 -> `reward-monitor` | Coach 通勤包 -> `reward-bag` | 希尔顿酒店一晚 -> `reward-hotel` |
| 2000 | 7 | 1400 | Ruth's Chris 双人晚餐 -> `reward-steak` | 上海北京机票 -> `reward-flight` | 戴尔 UltraSharp 显示器 -> `reward-monitor` | AirPods Pro -> `reward-airpods` | 保友金豪人体工学椅 -> `reward-office-chair` | 携程周边两日游 -> `reward-travel` |
| 2000 | 8 | 1600 | 希尔顿酒店一晚 -> `reward-hotel` | AirPods Pro -> `reward-airpods` | 海马体城市写真 -> `reward-travel` | Sony WH-1000XM 耳机 -> `reward-headphones` | 戴森 Supersonic 吹风机 -> `reward-hair-dryer` | Keychron Q 系列键盘 -> `reward-keyboard` |
| 2000 | 9 | 1800 | Insta360 GO 相机 -> `reward-camera` | 携程周边两日游 -> `reward-travel` | 保友金豪人体工学椅 -> `reward-office-chair` | DJI Osmo Action -> `reward-camera` | Marshall 音箱 -> `reward-speaker` | 希尔顿酒店周末房 -> `reward-hotel` |
| 2000 | 10 | 2000 | Club Med 周末套餐 -> `reward-travel` | Coach 通勤包 -> `reward-bag` | 极米家用投影仪 -> `reward-projector` | iPad mini -> `reward-tablet` | Sony WH-1000XM 耳机 -> `reward-headphones` | 海马体旅拍 -> `reward-travel` |
| 3000 | 1 | 300 | Blue Frog 晚餐 -> `reward-restaurant-meal` | 丝域头疗护理 -> `reward-haircare` | 小米空气炸锅 -> `reward-air-fryer` | 王品牛排午餐 -> `reward-steak` | Shake Shack 双人餐 -> `reward-burger-meal` | 泰到位肩颈按摩 -> `reward-massage` |
| 3000 | 2 | 600 | 亚朵酒店一晚 -> `reward-hotel` | Nike Pegasus 跑鞋 -> `reward-sneakers` | 大董双人简餐 -> `reward-restaurant-meal` | Bose QuietComfort 耳机 -> `reward-headphones` | 戴尔显示器 -> `reward-monitor` | Coach 小号托特 -> `reward-bag` |
| 3000 | 3 | 900 | 希尔顿欢朋一晚 -> `reward-hotel` | Sony LinkBuds -> `reward-earbuds` | 香格里拉自助餐 -> `reward-buffet-hotpot` | AirPods Pro -> `reward-airpods` | 亚朵周末房 -> `reward-hotel` | 戴森 Supersonic 吹风机 -> `reward-hair-dryer` |
| 3000 | 4 | 1200 | Jo Malone 香水 -> `reward-fragrance` | 桔子水晶酒店一晚 -> `reward-hotel` | 德龙咖啡机 -> `reward-coffee-machine` | 戴尔 UltraSharp 显示器 -> `reward-monitor` | Coach 通勤包 -> `reward-bag` | 希尔顿酒店一晚 -> `reward-hotel` |
| 3000 | 5 | 1500 | 希尔顿酒店一晚 -> `reward-hotel` | Keychron Q 系列键盘 -> `reward-keyboard` | 泰到位高端 SPA -> `reward-massage` | Sony WH-1000XM 耳机 -> `reward-headphones` | 保友金豪人体工学椅 -> `reward-office-chair` | 海马体城市写真 -> `reward-travel` |
| 3000 | 6 | 1800 | Insta360 GO 相机 -> `reward-camera` | 携程周边两日游 -> `reward-travel` | 保友金豪人体工学椅 -> `reward-office-chair` | DJI Osmo Action -> `reward-camera` | Marshall 音箱 -> `reward-speaker` | 希尔顿周末房 -> `reward-hotel` |
| 3000 | 7 | 2100 | 国内往返机票 -> `reward-flight` | Marshall 音箱 -> `reward-speaker` | 安缦周边餐饮体验 -> `reward-travel` | Club Med 周末套餐 -> `reward-travel` | Coach 通勤包 -> `reward-bag` | 极米家用投影仪 -> `reward-projector` |
| 3000 | 8 | 2400 | 大疆 Osmo Pocket 3 -> `reward-camera` | 米家空气净化器 -> `reward-air-purifier` | 海马体旅拍 -> `reward-travel` | PlayStation 5 Slim -> `reward-game-console` | 戴森 Supersonic 吹风机 -> `reward-hair-dryer` | 希尔顿度假套餐 -> `reward-hotel` |
| 3000 | 9 | 2700 | PlayStation 5 Slim -> `reward-game-console` | 携程双人周末游 -> `reward-travel` | 德龙全自动咖啡机 -> `reward-coffee-machine` | 大疆 Osmo Pocket 3 -> `reward-camera` | iPad mini -> `reward-tablet` | 米家空气净化器 -> `reward-air-purifier` |
| 3000 | 10 | 3000 | iPad mini -> `reward-tablet` | 戴森 Supersonic 吹风机 -> `reward-hair-dryer` | 希尔顿度假两日游 -> `reward-hotel` | 大疆 Osmo Pocket 3 -> `reward-camera` | PlayStation 5 Slim -> `reward-game-console` | 德龙全自动咖啡机 -> `reward-coffee-machine` |

## Implementation Notes

- A future Swift implementation should model each candidate with `displayName`, `priceCNY`, `unit`, `assetKey`, `dailyIncomeTier`, and `step`.
- The image folder for this batch is `Sources/MoneyTodayApp/Resources/RewardsV2`.
- The expected file name for each image is `<assetKey>.png`, for example `reward-game-console.png`.
- The current 47 images can support both the current 300-option draft and a later 600-option draft if the added rewards stay in these product families.
