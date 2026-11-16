# Floii Design System — the "Bold & Vivid" visual world

This documents the design language, tokens, and component contract for the
Floii redesign. It is the single source of truth for how the UI looks and how
the analytics layer feeds the interface.

## 1. Philosophy

Floii is for general menstruators who want **ease and insight**, not
clinical overwhelm. The redesign keeps every existing capability (calendar,
phase timeline, confirmable predictions, onboarding, offline Hive storage,
5 languages, RTL, dark mode) while making the surfaces bolder, warmer, and
data-richer.

Three pillars:
- **Vivid, not pastel** — saturated phase/role colors with real contrast.
- **Warm, not sterile** — a peachy-neutral ground replaces pure white/grey.
- **Insightful, not noisy** — every new metric answers "what does this tell
  me about my body?"

## 2. Color tokens

All tokens live in `lib/utils/constants/colors.dart` (`AppColors`) and are
wired into Material 3 `ColorScheme`s in `lib/theme/app_theme.dart`.

### Roles
| Token | Light | Dark |
| --- | --- | --- |
| Primary (Velvet Rose) | `#B3264B` | `#F2B8C5` |
| Secondary (Violet) | `#6B3FA0` | `#D3BCF0` |
| Tertiary (Amber) | `#9A5700` | `#FFB968` |
| Ground (warm paper) | `#FCF8F7` | `#201417` |
| Card / surface | `#FFFFFF` | `#2A1B20` |

### Cycle phase tokens (used across calendar, status, timeline, charts)
- **Period** `#C62828`
- **Follicular** `#2E7D32`
- **Ovulation** `#EF6C00`
- **Luteal** `#7B1FA2`
- **Predicted** `#8E24AA`
- **Today** `#1976D2`
- **Fertile** `#D81B60`
- **Success / high-confidence** `#1B7A3D`

### Semantic helpers
- `CyclePhaseVisual` enum maps `CyclePhase → name/color/icon` so every surface
  renders a phase identically (`phaseRole(phase)`).
- Phase colors are stored as opaque constants; alpha is applied at usage via
  `.withValues(alpha: …)` (never `withOpacity`).

## 3. Type scale

Defined on the M3 `textTheme` in `app_theme.dart`. The app leans on a strong
`titleLarge`/`headlineMedium` with weight `700–800` for KPIs and section
heads; body text uses `onSurfaceVariant` at 60–80% for secondary info.

## 4. Components (`lib/widgets/common/`)

- **ClayCard** — soft elevated surface with InkWell ripple for press feedback.
- **MetricCard / StatCard / InfoCard** — KPI tiles; StatCard takes an icon +
  accent color for rich-stat grids.
- **ClayButton** — press-scale button (down when pressed), used for dialogs,
  app-bar icons, and settings rows.
- **SectionHeader** — icon + title + optional caption; gives each analytics
  block a clear intro.
- **ProgressIndicator** (circular, animated, round caps), **FertilityIndicator**,
  **PhaseChip**, **StatusDot** (pulse), **CycleProgressBar** (4-phase segmented).
- **Sparkline** — no-dependency line chart with gradient fill; feeds the
  regularity/insight UI.
- **HBarChart** — no-dependency horizontal ranking bars; feeds distribution
  analysis.

## 5. Analytics contract (`lib/services/cycle/cycle_analytics_service.dart`)

All metrics derive from the period data the app already stores — no fabricated
inputs, no new persistence. Canonical period shape: `List<List<DateTime>>`
(same as `stats['periods']`).

Key API:
- `median`, `stdDev` — robust location/spread.
- `cycleLengths(periods)`, `periodLengths(periods)` — series builders.
- `groupPeriodsFromData(allData)` — converts `DailyData` list into period
  date-lists via `CycleCalculationService.groupPeriods`.
- `computeAnalyticsFromPeriods(periods)` → map with `averageCycle`,
  `medianCycle`, `minCycle`, `maxCycle`, `averagePeriod`, `medianPeriod`,
  `minPeriod`, `maxPeriod`, `cycleStdDev`, `consistency` (0–100 regularity).
- `predictionConfidence(allData, stats)` → `({label, color})` for the next
  window (High ≥85 / Moderate ≥60 / Low).
- `buildTrends(allData)` → chronological series (cycle length over time).

Prediction length keeps using the **median** (robust to outlier cycles).

## 6. Surfaces

- **Home** — cycle status card, interactive calendar (tap to log / long-press
  to edit, tap prediction to confirm), phase timeline.
- **Insights** (rebuilt) — rich statistics grid (avg/median/min/max for cycle &
  period) + consistency card with sparklines + confidence badge; phase breakdown;
  fertility forecast.
- **Trends** (new) — cycle-length drift over time, regularity, distribution
  via HBarChart, pattern findings.
- **Onboarding / Settings** — rethemed for consistency (bold accents, warm
  ground, same card language).

## 7. Localization

Every new user-facing string is added to the single map in
`lib/services/localization/app_localizations.dart` across all 5 languages
(en/ar/ur/id/de), accessed via `context.tr('key')` / `context.trArgs(...)`.
RTL is applied automatically via `Directionality` in `app.dart`.
