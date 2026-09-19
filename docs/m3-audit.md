# MD3 合规审计报告

- **目标**：Muse Player Flutter UI（`lib/`，49 个 dart 文件 ≈ 4950 行）
- **日期**：2026-09-16
- **依据**：`~/.agents/skills/material-3`（实现层）+ `~/.agents/skills/material-design-3-ui`（设计/评审层）
- **初评总分**：**62 / 100**
- **复评总分**：**88 / 100**（同日，`refactor/ui` 分支修复后，见下方「修复记录」）
- **结论**：初评为「需要改进，未到可发布状态」。五类须修项已全部处理并补了回归测试。
  剩余扣分集中在少数刻意的视觉选择（首页 Hero 渐变仍为硬编码色值）与尚未验证的真机表现。

## 修复记录（2026-09-16 · refactor/ui）

| # | 问题 | 处置 | 证据 |
| --- | --- | --- | --- |
| 1 | 4 个空操作控件 | PlaylistCard 接真实导航（切到 shell 的播放列表分区）；AlbumCard / 歌手行改为非交互；队列按钮与其 `showQueue` 标志整体移除 | `home_cards.dart`、`library_page.dart`、`player_controls.dart` |
| 2 | 当前播放状态只用颜色表达 | 3px 色条换成带 `semanticLabel` 的图标（播放中 `graphic_eq` / 暂停 `pause`） | `song_tile.dart` |
| 3 | 零减少动效适配 | 新建 `AppMotion`，6 处动画全部改走 `AppMotion.of`，`MediaQuery.disableAnimations` 时返回 `Duration.zero` | `core/utils/motion.dart` + 6 个调用点 |
| 4 | `outline` 与 `outlineVariant` 同值 | 拆为两个独立角色，色板新增 `outline` 字段 | `theme_config.dart`、`theme.dart`、`app_config.json` |
| 5 | 5 级 tonal surface 塌成 1 级 | 补出 `surfaceContainerLowest/Low/Container/High/Highest` 完整色阶 | 同上 |
| 6 | 形状魔法数字 | 建立 M3 形状令牌 `shape*`，11 处字面量全部归位；`floatingPlayerBarRadius = 30` 作为有据偏离保留并加注释 | `app_sizes.dart` |
| 7 | 断点不匹配 M3 | 改为 compact `<600` / medium+expanded `600–1199` / large+extra-large `>=1200`；`< 480` 并入 `AppBreakpoints.heroCompactMax` | `breakpoints.dart` |
| 8 | 内容最大宽度 1200 偏宽 | 新增 `pageMaxWidthText = 1040`，搜索与设置页使用 | `app_sizes.dart`、`page_scaffold.dart` |
| 9 | 标题层级只靠字号 | `SectionHeader` 三级同时区分字号 + 字重 + 颜色 | `section_header.dart` |
| 10 | 触达尺寸 44dp（审计漏报） | 移动端主播放按钮 44 → 48dp | `floating_player_bar_layouts.dart` |
| 11 | 死代码 | 删除 `context_extensions.dart`（用窗口宽度判断，与各处的组件 constraints 语义不符，套用会算错）；`ResponsiveLayout` 改由 `MainShell` 实际使用 | `app.dart` |

**回归测试**：`test/accessibility_test.dart` 覆盖减少动效、非颜色状态线索、空操作控件三类问题；
`test/app_config_test.dart` 新增断言，保证 `outline ≠ outlineVariant` 且 tonal 色阶不塌陷。

**仍存在（刻意保留或未处理）**：

- `home_cards.dart` 的 Hero 渐变原本是 6 个硬编码色值（亮暗各 3），**现已迁到
  `theme.heroGradient`**。它不属于 M3 颜色角色体系，所以没有映射成令牌，
  而是作为独立的装饰性配置项存在 —— 这是有意的分类，不是遗漏。
- `cover_artwork.dart` 的 6 组渐变是**生成式占位封面**，属于内容而非 chrome，保持硬编码合理。
- `AppSizes.floatingPlayerBarRadius = 30` 不在 M3 标尺上，作为有据偏离保留（见 `architecture.md`）。
- 真机表现（安全区、`dvh` 行为、触摸拖拽手感）无法在无头测试中验证。

## 运行时验证（2026-09-16）

静态分析全绿不等于渲染正确。实际在 Linux 桌面跑起来、按三个断点截图检查后，发现两个
**静态分析抓不到**的问题：

| # | 问题 | 状态 |
| --- | --- | --- |
| 12 | 桌面导航面板的页脚 `Phase 1 · Mock UI` 被悬浮播放条完全盖住 | **已修**：给面板底部加 `scrollBottomPadding`，与其他可滚动页面一致 |
| 13 | 移动端底部 `NavigationBar` 放了 **6 个**目的地，超出 M3 建议的 3–5 | **已修**：搜索不再是分区，降为 5 个，见下 |

**关于 #12**：Floating Player Bar 用 `Positioned(left: 24, right: 24)` 横跨**整个窗口**，
包括 220px 的导航面板。可滚动页面有 `scrollBottomPadding = 150` 预留，导航面板没有 ——
于是页脚被压在条下面。这是既有问题（默认窗口 1280×800 也落在 desktop 区间），不是本次重构引入的。

> 后续：该页脚（`Phase 1 · Mock UI`）在视觉改版中整体删除，面板末尾改为直接留出
> `scrollBottomPadding`。此处保留当时的处置记录。

**关于 #13**：`AppSection` 原有 6 个分区（首页 / 搜索 / 音乐库 / 收藏 / 播放列表 / 设置），
在 compact 尺寸下全部塞进底部导航栏，超出 M3 建议的 **3–5 个**。

**处置**：搜索降为普通路由。首页头部本来就带搜索框，再占一个导航位是冗余的；
移除后正好 5 个，落在建议区间内。`app.dart` 同时改为遍历 `AppSection.values`
构建页面列表，消除"手写列表必须与枚举同序"这个隐式耦合 —— 现在新增分区会编译报错
直到补上页面。

**已知取舍**：搜索页现在是 push 出来的独立路由（自带 AppBar 与返回），
因此**不显示悬浮播放条**。这符合 M3 的 search view 全屏接管模式，但代价是
搜索时无法控制播放。若这一点不可接受，需要把搜索改回 shell 页面但不出现在导航项里 ——
代价是会出现"没有任何目的地处于选中态"的状态。

**关于 #12 的验证方式**：改 `build/.../flutter_assets/.../app_config.json` 里的
`theme.heroGradient` 为纯绿色并重启，Hero 卡片确实变绿 —— 证明确实读的是配置而非硬编码。

**截图**：`demo/muse-player-shots/` 保存了 tablet(954) / desktop(1400) / mobile(480) /
desktop 修复后 / 浅色主题 五张验证截图。

## 评分明细

| 类别 | 初评 | 复评 | 状态 | 核心问题 |
| --- | --- | --- | --- | --- |
| 颜色令牌 | 6/10 | 8/10 | pass | Hero 渐变仍为硬编码色值；其余角色已拆分到位 |
| 排版 | 7/10 | 9/10 | pass | 层级已由字号 + 字重 + 颜色共同承载 |
| 形状 | 4/10 | 9/10 | pass | 已建立 M3 形状令牌；30 作为有据偏离保留 |
| 高度 | 6/10 | 8/10 | pass | tonal 色阶已补齐；卡片仍统一 `elevation: 0` |
| 组件 | 7/10 | 9/10 | pass | 空操作控件已清除 |
| 布局 | 7/10 | 9/10 | pass | 断点已对齐 M3 window size class |
| 导航 | 8/10 | 9/10 | pass | 目的地顺序跨断点一致 |
| 动效 | 5/10 | 9/10 | pass | 已接入 `MediaQuery.disableAnimations` |
| 无障碍 | 5/10 | 9/10 | pass | 状态不再只靠颜色；触达尺寸已达标 |
| 主题 | 7/10 | 9/10 | pass | 令牌可精细演进 |

## 严重问题（须修）

### 1. 令牌压平：`outline` 与 `outlineVariant` 同值

`lib/app/theme.dart:49-50`

```dart
outline: palette.divider,
outlineVariant: palette.divider,
```

**问题**：M3 里这两个角色语义不同 —— `outline` 用于**重要边界**（输入框描边、聚焦环），
`outlineVariant` 用于**装饰性分隔**（分割线）。设成同一个值后，分割线和输入框描边无法区分，
后续想调整任一方都会连带改动另一方。

**后果**：主题无法精细化演进；输入框边界与列表分割线视觉权重相同，削弱可读性。

**修正**：拆成两个独立色值。分割线用 `outlineVariant`（更浅），输入框/聚焦态用 `outline`。

### 2. 令牌压平：5 级 tonal surface 塌成 1 级

`lib/app/theme.dart:46-47`

```dart
surfaceContainerHighest: palette.surfaceVariant,
surfaceContainerHigh: palette.surfaceVariant,
```

**问题**：M3 用 **tonal surface 而非阴影**表达高度，靠 `surface-container-lowest / low / container / high / highest`
五级递进区分层级。这里 5 级全指向同一个色值。

**后果**：高度信息无处表达 —— 这也是为什么卡片只能一律 `elevation: 0`。悬浮元素（播放条、菜单、对话框）
与背景之间缺少 M3 本应提供的层次线索。

**修正**：色板里补出 5 级 tonal 色阶（可用 `ColorScheme.fromSeed` 生成后覆写），
至少让 `surfaceContainer` / `High` / `Highest` 三者可区分。

### 3. 4 个空操作控件（假可供性）

| 位置 | 控件 |
| --- | --- |
| `lib/pages/home/home_cards.dart:176` | `PlaylistCard` 的 `onTap: () {}` |
| `lib/pages/library/library_page.dart:99` | `AlbumCard(album: ..., onTap: () {})` |
| `lib/pages/library/library_page.dart:119` | 歌手 `ListTile` 的 `onTap: () {}` |
| `lib/widgets/player/player_controls.dart:92` | 队列按钮 `onPressed: () {}` |

**问题**：这些控件有完整的点击反馈（水波纹、hover 态、`tooltip`），但点了没有任何结果。

**后果**：比"没有这个按钮"更糟 —— 用户会反复尝试，然后判定应用坏了。
无障碍层面更严重：读屏软件会把这些播报为可操作按钮。

**修正**：三选一 —— 实现跳转；或 `onTap: null` 使其呈现禁用态；或本阶段直接移除。
**不要保留一个看起来能按的假按钮。**

### 4. 当前播放状态只用颜色表达

`lib/widgets/song/song_tile.dart:45-55`

```dart
tileColor: isCurrentSong
    ? theme.colorScheme.primaryContainer.withValues(alpha: 0.45)
    : Colors.transparent,
// ...以及一个 3px 宽的 primary 色竖条
```

**问题**：两个线索（行底色 + 左侧竖条）**都是颜色**。色觉障碍用户（约 8% 男性）
在浅色主题下无法区分当前播放行 —— `primaryContainer` 45% 透明度叠加在 `surface` 上，
明度差本就很小。

**后果**：违反 WCAG 1.4.1「不得仅用颜色传达信息」；同时这是音乐播放器最核心的状态，代价被放大。

**修正**：加一个**非颜色**线索。最小改动是把左侧竖条换成播放中的图标
（如 `Icons.equalizer_rounded` / `Icons.volume_up`），或给标题加字重差异。

### 5. 完全没有适配"减少动效"

全项目搜索 `disableAnimations` / `reduceMotion` / `accessibleNavigation` → **零结果**。

涉及 6 处动效：

| 位置 | 动效 |
| --- | --- |
| `lib/pages/home/home_cards.dart:113` | `AnimatedScale` 170ms（卡片 hover 缩放） |
| `lib/widgets/album/album_card.dart:36` | `AnimatedScale` 170ms |
| `lib/widgets/player/player_controls.dart:50` | `AnimatedSwitcher` 180ms（播放⇄暂停图标） |
| `lib/widgets/navigation/desktop_navigation.dart:131` | `AnimatedContainer` 180ms |
| `lib/pages/now_playing/now_playing_widgets.dart:196` | 200ms |
| `lib/widgets/player/floating_player_bar_layouts.dart:224` | 180ms |

**问题**：前庭功能障碍用户开启系统级"减少动效"后，应用毫无响应。

**后果**：无障碍合规缺失。**且项目自己的 `demo/web-music-player` 已经处理了
`prefers-reduced-motion`（见其 README 的自检清单）—— Flutter 版落后于自己的 demo。**

**修正**：读 `MediaQuery.disableAnimationsOf(context)`，为真时把时长置零。
建议在 `AppTheme` 或一个 `MotionDurations` helper 里统一收口，而不是逐个 widget 判断。

## 警告（建议修）

### 6. 形状魔法数字

11 处 `BorderRadius.circular(<字面量>)`，而 `AppSizes` 只有 2 个形状常量：

```
theme.dart:68 → 16      home_cards.dart:34  → 24     now_playing_widgets.dart:257 → 20
theme.dart:97 → 24      home_cards.dart:119 → 16     desktop_navigation.dart:130/140 → 18
                        home_cards.dart:177 → 16     player_progress.dart:92 → 2
                                                     song_tile.dart:58 → 2 / :102 → 12
```

M3 形状标尺是 none / 4 / 8 / 12 / 16 / 20 / 28 / 32 / 48 / full。
其中 **18 和 2 不在标尺上**，`floatingPlayerBarRadius = 30` 也落在 28 与 32 之间。

**修正**：在 `AppSizes` 里建立形状令牌（`shapeXs=4 / shapeSm=8 / shapeMd=12 / shapeLg=16 / shapeXl=28 / shapeFull`），
全部改走令牌。30 若是有意的品牌偏离，保留但注明。

### 7. 断点不匹配 M3 window size class

`lib/app/breakpoints.dart:9-11` 用的是 `700 / 1100`。

M3 的定义是：compact `<600`、medium `600–839`、expanded `840–1199`、large `1200–1599`、extra-large `≥1600`。

**后果**：在 840–1100 区间（典型平板横屏、小窗桌面）应用会切到 NavigationRail，
而 M3 认为这个区间已可承载更宽的布局。

**另外**：`lib/pages/home/home_cards.dart:29` 自造了第 4 个断点 `constraints.maxWidth < 480`，
未登记在 `AppBreakpoints` 里 —— 这是全项目唯一一处绕过统一入口的地方。

**修正**：要么对齐 M3 的 600/840，要么在文档里明确声明这是有意的偏离并说明理由。
无论选哪个，`< 480` 都应并入 `AppBreakpoints`。

### 8. 内容最大宽度 1200 偏宽

`lib/core/constants/app_sizes.dart:9` `pageMaxWidth = 1200`。

M3 对 large / extra-large 窗口的建议是约束在 **840–1040dp**。

**后果**：超宽屏下正文行长过长，降低可读性。（音乐应用的网格布局可以更宽，
但文本密集区 —— 搜索页、设置页 —— 值得单独收窄。）

**修正**：文本密集页用 840–1040，网格/封面页可保持 1200。

### 9. 标题层级只靠字号，字重不承载信息

`lib/widgets/common/section_header.dart` 三个层级一律 `FontWeight.w700`。

M3 的 emphasized 字重是 `w500`，常规正文是 `w400`。全站 `w700` 意味着字重维度被浪费。

**修正**：page 级用 `w700`、section 级用 `w500`、subsection 用 `w500` + 颜色降级，
让层级同时由**字号 + 字重 + 颜色**三个维度承载。

## 通过项（做得好，不要动）

- **无 MD2 混用**：全程 Flutter M3 组件，没有混入 M2 规则。
- **组件选型正确**：视图切换用 `SegmentedButton`（不是 Tabs），
  导航用 `NavigationBar` / `NavigationRail` / 自定义 panel，音量用 `Slider`，
  更多操作菜单用 `PopupMenuButton` —— 都是按行为而非外形选的。
- **自适应是真实的**：三种尺寸各有独立外壳，不是把手机版拉宽。
  mobile 用底部导航、tablet 用 rail、desktop 用 220px 面板，**且目的地顺序跨断点一致**。
- **触达尺寸合格**：主播放按钮 `player_controls.dart:45` 显式设为 52×52，其余 `IconButton` 默认 48。
  图标按钮普遍带 `tooltip`，Flutter 会将其暴露为语义标签。
- **高度用色调而非阴影**：卡片一律 `elevation: 0` + `surfaceTintColor: transparent`，
  符合 M3「用 tonal surface 而非阴影表达高度」的方向（虽然 tonal 色阶还没铺开）。
- **玻璃播放条是有据的偏离**：`GlassContainer` + `BackdropFilter` 并非 M3 组件，
  但 ① 仅在单个悬浮播放条使用，未进列表项；② `docs/architecture.md` 已写明理由（避免 GPU 开销）。
  符合"有意偏离 M3 时必须说明"的要求。

## 修复优先级

> 以下为**初评时**的排序，保留作为决策依据的记录。第 1–7 项已于 2026-09-16 全部完成
> （第 7 项中的 Hero 渐变以 `theme.heroGradient` 形式落地），详见开头「修复记录」。

1. **删掉或禁用 4 个空操作控件** —— 改动最小，用户伤害最直接。
2. **给当前播放状态加非颜色线索** —— 核心状态 + 无障碍合规，改动局限在 `song_tile.dart`。
3. **收口减少动效** —— 新建一个动效时长 helper，6 处调用点统一走它。
4. **拆分 `outline` / `outlineVariant`，补出 tonal surface 色阶** —— 动 `theme_config.dart` 与 `app_config.json`，
   是后续所有视觉调整的地基。
5. **建立形状令牌**，消灭 11 处魔法圆角。
6. **断点对齐 M3 window size class**，并把 `home_cards.dart:29` 的 `< 480` 并入 `AppBreakpoints`。
7. 正文最大宽度按页面类型区分；标题层级引入字重差异。

## 备注

- 本报告只做只读分析，未改动任何工程文件。
- 第 1–4 项属于**须修**（对应自评表里的 1 分项），第 6–9 项属于**可选优化**。
- 审计依据的两个 skill 位于 `~/.agents/skills/`，不在 skill 注册表中，需直接读取 SKILL.md 使用。
