# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

## Users

Primary users are general menstruators seeking insight into their own bodies. In a daily, private moment — often quick and low-effort — they want to log their period and understand their cycle, when their next period will come, and where they are in their cycle. The job is "know my body without the overhead." A secondary audience is mapped by the broad language support (en, ar, ur, id, de) serving people who menstruate across those languages, including RTL reading contexts.

## Product Purpose

Floii is an easy-to-grasp menstrual cycle tracking app. It lets users log period dates and symptoms, see predicted periods and fertile window, understand their cycle phases, and get personalized lifestyle recommendations aligned with their cycle. Success means the user can understand and predict their cycle quickly and confidently, without being overwhelmed by a cluttered, feature-heavy app.

## Positioning

Floii differentiates on simplicity and ease of grasp: a deliberately clean, approachable experience versus the dense, feature-heavy cycle apps on the market (Clue, Flo, Natural Cycles). The whole product is built around one glance — today's status, this month's calendar, and the phase timeline — so anyone can understand their body on first use. Privacy is a supporting promise: all data stays on-device (Hive local storage), no cloud, no account, no tracking, and the app works fully offline.

## Operating Context

The app is used on a phone screen in short daily bursts. Core flow: open to the month calendar, tap a date to mark a period, confirm predicted periods the app suggests, and read the current cycle phase. Predictions are computed locally from logged periods (average cycle length, default 28 days). Users can add prior cycles to improve prediction accuracy. Language can be switched from onboarding and in-settings, including RTL for Arabic/Urdu, and light/dark themes are toggleable (dark is the default).

## Capabilities and Constraints

- Cycle & period tracking via a tap-to-mark calendar.
- Ovulation and fertile-window insights; smart predictions that improve as more cycles are logged.
- Phase timeline and cycle analytics (Insights, Trends screens).
- Lifestyle recommendations aligned to the cycle.
- Privacy and offline: all data local via Hive DB, no backend, shared_preferences for completion flags.
- Multi-language: en, ar, ur, id, de with full RTL directionality support.
- Flutter (Material 3), cross-platform: iOS, Android, web, and desktop targets share one design language.
- Tech: Flutter (Dart SDK ^3.6.1), Hive + hive_flutter for local storage, shared_preferences, smooth_page_indicator, intl; Nunito font; dark mode default on.
- Explicitly undecided product facts: exact prediction algorithm details, scope of "lifestyle recommendations," and whether fertility tracking is the dominant use case or a supporting one.

## Brand Commitments

Name "Floii" is binding. The current soft-pink / lavender "claymorphism" aesthetic is the incumbent look but is explicitly non-binding — the visual world may evolve in future design work. Multi-language and offline-privacy commitments are product facts to preserve. No other binding visual or voice constraints were declared.

## Evidence on Hand

- App screenshots: `floii-screenshot.png` (repo root) and `docs/assets` build artifacts.
- App icon assets under `lib/icons/` (icon-512.png referenced by onboarding).
- Full working implementation across `lib/screens` (home, insights, trends, settings, onboarding).
- No real user testimonials, case studies, press, or downloadable app-store presence are on hand; future marketing copy must not fabricate these.

## Product Principles

- One-glance clarity: another feature added is a loss unless it survives the glance test.
- Privacy is a feature the user should feel, not a box checked: no cloud, no account, offline by default.
- Predictions earn trust by being explainable and confirmable, improving as the user logs more.
- Inclusive by language and reading direction: RTL and multi-language are first-class, not bolt-ons.
- The body's own rhythm is the brand: gentle, warm, physiological — never clinical or shaming.

## Accessibility & Inclusion

Inclusive by bilingual/RTL design (ar, ur, id, de supported, with Directionality handling). Dark and light themes both supported. No product-specific accessibility standard beyond Material defaults is established; this is an open area for future work.
