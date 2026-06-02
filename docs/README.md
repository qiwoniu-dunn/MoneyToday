# MoneyToday 项目文档

这个目录用于沉淀 MoneyToday 的产品背景、建设过程、版本发布和后续规划。它不是面向普通用户的安装说明，而是面向项目维护、复盘和项目管理系统同步的资料库。

## 文档索引

- [项目上下文摘要](./vcdash-context.md)：给 VCdash 或其他项目管理系统读取的高密度摘要。
- [建设过程记录](./project-log.md)：从想法到 1.0 发布的完整过程记录。
- [1.0 发布记录](./release-1.0.0.md)：版本内容、产物、验证和已知限制。
- [1.1 发布记录](./release-1.1.0.md)：情绪价值增强版的功能、产物、验证和限制。
- [1.2 需求记录](./requirements-1.2.0.md)：奖励文案从价格换算转向模糊价值感和心理安慰的需求约束。
- [1.2 发布记录](./release-1.2.0.md)：UI 还原、文案口径和芝麻奖励互动的实现记录。
- [奖励候选池 V2](./reward-catalog-v2.md)：五档日薪、十个阶梯、具体品牌奖励和 `assetKey` 映射。
- [奖励图像资产映射](./reward-asset-taxonomy.md)：把具体品牌奖励收敛为可复用的像素图资产。
- [产品思考沉淀](./product-thinking.md)：MoneyToday 的设计原则、情绪价值逻辑和后续方向。

## 当前状态

- 项目名称：MoneyToday
- 当前版本：1.2.0
- 当前阶段：1.2 已发布；2026-06-02 完成同版本奖励区修正，准备覆盖 GitHub Release
- GitHub 仓库：https://github.com/qiwoniu-dunn/MoneyToday
- 本地项目路径：`/Users/zhengchaoduan/Desktop/AI/VibeCoding/Moneytoday`
- 主要平台：macOS
- 技术栈：Swift Package Manager + AppKit + SwiftUI

## 维护约定

后续每次重要迭代建议至少更新：

1. `vcdash-context.md`：同步当前状态、最新版本、下一步计划。
2. `project-log.md`：追加当天关键过程和决策。
3. 对应版本的 `release-x.y.z.md`：记录发布产物、功能、验证结果和已知问题。
