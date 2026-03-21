# MBTI Feature Plan

## Product Goals

- Add a lightweight MBTI onboarding feature for a gay social app.
- Use MBTI as a soft matching signal, not a hard gate.
- Improve profile completeness, matching confidence, and conversation starters.

## Entry Points

- Home recommendation page:
  - `发现你的隐藏人格`
  - `完善人格，提升匹配成功率 +30%`
- Profile page:
  - Personality card with current MBTI or CTA to test
  - Support `重新测试`
- Nearby filter:
  - Filter users by MBTI type

## Test Flow

- Lightweight flow: 12 questions, binary choice
- Each question maps to one of four dimensions:
  - `E / I`
  - `N / S`
  - `T / F`
  - `J / P`
- Interaction style:
  - One question per screen
  - Strong transition feedback
  - Large touch targets
  - Progress bar

## Result Page

- Show:
  - MBTI type
  - Personality title
  - One-line hook
  - Summary
  - Three keywords
- Save result back into profile
- Allow retest

## Data Model

Backend `users` table:

- `mbti_type TEXT`
- `height_cm INTEGER`
- `weight_kg INTEGER`

Frontend `AppUser`:

- `mbtiType`
- `heightCm`
- `weightKg`

## Matching Usage

- Stage 1:
  - Use MBTI only for display and nearby filtering
- Stage 2:
  - Use MBTI as a ranking feature in recommendation scoring
  - Example:
    - same type small boost
    - complementary dimensions small boost
    - missing MBTI no penalty, only lower confidence

## Qwen API Suggestion

Do not place vendor secrets directly in Flutter code.

Recommended architecture:

- Keep Qwen credentials on backend only
- Read from environment variables:
  - `QWEN_API_KEY`
  - or cloud credential env vars
- Use Qwen for optional enhancements only:
  - personalized summary copy rewrite
  - richer profile tag copy
  - generating illustration prompt for MBTI avatar

Core MBTI result logic should remain local and deterministic.

## MBTI Avatar Direction

Current implementation uses a generated badge placeholder.

Recommended design direction:

- Stylized “小老头人格徽章”
- Cute but tasteful, not childish
- Different accessories by archetype:
  - thinker: glasses
  - romantic: star/moon
  - leader: badge/crown
  - helper: warm scarf
- Use purple-primary palette with soft blue/pink accents

## Figma Prompt

Use this prompt in Figma AI or with a designer:

```text
为一款面向 gay 用户的社交 App 设计一个 MBTI 功能模块。

目标：
- 风格清爽、明亮、紫色为主，蓝色和粉色为辅助
- 不要传统心理测试网站风格
- 要像高质量社交产品，不要学术感，不要压抑

请设计 4 个界面：

1. 首页 MBTI 入口卡片
- 文案：发现你的隐藏人格
- 副标题：完善人格，提升匹配成功率 +30%
- 卡片应具有吸引力，适合推荐页上方展示

2. MBTI 测试流程页
- 12 题轻量测试，单题单屏
- 每题只有 2 个选项
- 大按钮、强反馈、适合移动端滑动切换
- 显示进度条
- 视觉需要有“被引导探索自己”的感觉

3. MBTI 结果页
- 显示 MBTI 类型，例如 INFP
- 显示人格名称，例如 调停者
- 一句话总结
- 三个关键词标签
- 一枚生动的“小老头人格徽章”

4. 个人中心人格档案区
- 已测试状态：展示人格徽章、MBTI、人格说明、重新测试按钮
- 未测试状态：展示引导 CTA

视觉要求：
- 紫色主调，清爽通透的玻璃感
- 不要沉闷黑底
- 用渐变、柔光、轻颗粒提升质感
- 人格徽章统一为 Q 版“小老头”角色体系
- 不同 MBTI 可通过帽子、眼镜、表情、配饰区分

输出要求：
- iPhone 竖屏界面
- 组件化设计，便于复用
- 标注主要状态：未测试、测试中、已完成
```
