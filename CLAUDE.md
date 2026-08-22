# Widgets — Project Conventions

**Never create a branch. Commit straight to `main`.**

**Never commit or push unless explicitly told to, and only one commit at a time.**

iOS 26.5+, SwiftUI only. All design tokens come from `Shared/Styling/`. Always use the tokens below — never use raw hex values, magic numbers, or system fonts.

**Never build (xcodebuild or otherwise) unless explicitly asked.**

This repo (`/Users/dommontalto/mac_documents/projects/Widgets`) is the current prototype app: designs are built and iterated here first. The Bright iOS app — the main front end they sync to and from — lives at `/Users/dommontalto/ios`. Shared components (`BrightPillButton`, `BrightCarousel`, etc.) are kept identical between the two repos, but **never edit the iOS app unless explicitly asked to** — by default changes land in this repo only.

---

## Comments

Do not add pointless comments. Never write a comment that merely restates what the code or a symbol name already says (e.g. `// Returns the sorted clinics` above `func sorted(...)`). Only comment when it explains *why* — non-obvious intent, a workaround, or a constraint the code can't express on its own.

**Always `//`, never `///`.** Doc comments are not used in this codebase — if a comment is necessary, write it as `//`.

Never write comments stating that code was ported from, synced with, or originates in the iOS app (or any other repo) — provenance lives in git, not comments.

---

## File Structure

```
Widgets/
├── ContentView.swift                  — root scroll view, 3 sections
├── Shared/Styling/
│   ├── Color/
│   │   ├── Color+StylingExtensions.swift   — all named colours + hex init + dark mode
│   │   └── ThemeColor.swift                — semantic aliases (macros, sleep, etc.)
│   ├── Extensions/
│   │   ├── CGFloat+StylingExtensions.swift — spacing, kerning, corner radius
│   │   └── Double+StylingExtensions.swift  — opacity constants
│   ├── Font/
│   │   ├── Font+StylingExtensions.swift    — Font.standard() / Font.standardSFPro()
│   │   ├── FontSizes.swift                 — FontSizes enum
│   │   ├── FontKerning.swift               — FontKerning enum
│   │   └── LineSpacing.swift               — LineSpacing enum
│   └── ViewModifier/
│       └── CardModifier.swift              — standard card chrome
└── Widgets/
    ├── Genome/
    │   └── GenomeSummaryPercentileWidget.swift
    ├── Exercise/
    │   ├── ExerciseConsistencyWidget.swift  — Strength & Cardio heatmap card
    │   ├── ExerciseTrainingLoadWidget.swift — Split % bar + weekly load rows
    │   ├── ExerciseSessionHistoryWidget.swift — Logs list, past 14 days
    │   ├── ExerciseUpcomingWidget.swift     — No sessions + Quick workout glass pill
    │   ├── ExerciseWeeklyPlanWidget.swift   — green banner + hero image with Start CTA
    │   ├── ExerciseProgramPhaseWidget.swift — mesocycle week + macro/meso/micro bars
    │   ├── ExerciseBodymapWidget.swift      — working sets per muscle group + body image
    │   ├── ExerciseScoresWidget.swift       — recovery/fatigue/readiness gradient tiles
    │   └── ExerciseDemo.swift               — ExerciseDayType + ExerciseDemoData
    └── Vault/
        ├── VaultDatapointsWidget.swift      — GridCell + SpeechBubble defined here
        └── VaultDemo.swift                  — VaultDemoData
```

---

## Colours

Defined in `Color+StylingExtensions.swift` as `static` properties on `Color`.

```swift
// Adaptive (light/dark)
Color.textColor            // primary text
Color.bG                   // screen background
Color.cards                // standard card fill
Color.homeCards            // darker card fill (near-black in dark mode)
Color.lightTextColor       // 60% opacity text
Color.semiLightTextColor   // 80% opacity text

// Never write .textColor.opacity(...) for dimmed black/white text:
// 80% is .semiLightTextColor, 60% is .lightTextColor.

// Fixed accent colours
Color.defaultSkyBlue       // #3DAEFF — highlighted heatmap cells
Color.defaultLighthouseBlue // #CFEBFF — muted heatmap cells
Color.defaultCyan          // adaptive cyan
Color.defaultBrightViolet  // #B872FF — icon accent
Color.defaultWarningRed    // #FF3939 — high-risk / warning
Color.defaultOrange        // #FF512D
Color.defaultBrightGreen   // #2FB360
```

**Never branch on `@Environment(\.colorScheme)` to pick a colour in a view.** A colour that differs between light and dark mode is an adaptive token: define it once in `Color+StylingExtensions.swift` with `Color(light:dark:)` (e.g. `exerciseRowTint`) and use that.

Use `.opacity(Double.<token>)` — never a raw float — when dimming colours:

```swift
Color.textColor.opacity(.semiLowOpacity)   // 0.4
Color.textColor.opacity(.lowOpacity)        // 0.6
Color.defaultWarningRed.opacity(.veryLowOpacity) // 0.3
```

---

## Opacity

Defined in `Double+StylingExtensions.swift` as `static` properties on `Double`.

| Token | Value |
|---|---|
| `.opaque` | 1.0 |
| `.veryHighOpacity` | 0.9 |
| `.mediumOpacity` | 0.8 |
| `.lowOpacity` | 0.6 |
| `.semiLowOpacity` | 0.4 |
| `.veryLowOpacity` | 0.3 |
| `.minimalOpacity` | 0.2 |
| `.veryMinimalOpacity` | 0.15 |
| `.ultraLowOpacity` | 0.1 |
| `.finalBossLowOpacity` | 0.05 |
| `.finalBossUltraLowOpacity` | 0.02 |

---

## Fonts

Use `Font.standard(size:weight:)` (SFCompactRounded) for all body/UI text.
Use `Font.standardSFPro(size:weight:)` only when explicitly matching SF Pro designs.

**`BrightText` defaults to `weight: .light`** (and `color: .textColor`) — never pass `weight: .light` or `color: .textColor` explicitly; only pass them when different.

Available weights via `Font.standard`: `.regular`, `.light`, `.medium`.

```swift
.font(.standard(size: .body1, weight: .regular))   // 16pt — labels, captions
.font(.standard(size: .body2, weight: .regular))   // 15pt
.font(.standard(size: .body4, weight: .regular))   // 13pt — subtitles
.font(.standard(size: .body5, weight: .regular))   // 12pt — axis labels
.font(.standard(size: .subheading, weight: .medium)) // 18pt
.font(.standard(size: .heading, weight: .regular))  // 20pt
.font(.standard(size: .standout3, weight: .medium)) // 22pt — card headers
.font(.standard(size: .standout1, weight: .medium)) // 30pt — section titles
.font(.standard(size: .giant, weight: .light))      // 50pt — large stats
.font(.standard(size: .enormous, weight: .light))   // 65pt — hero numbers
```

**Numbers that change get `.monospacedDigit()`.** A digit that updates in place
jitters as the glyph widths shift — every counter, timer, live stat, picker value,
enumerated label (`Block 1`, `Week 3`) and animated total needs it. Put it on the
view, directly after the `BrightText`:

```swift
BrightText("\(weeks)", size: .enormous)
    .monospacedDigit()

BrightText(session.duration, size: .body1, color: .lightTextColor)
    .monospacedDigit()
```

Pair it with `.contentTransition(.numericText())` when the value animates.
Numbers baked into static copy don't need it.

---

## Spacing

Defined in `CGFloat+StylingExtensions.swift` as `static` properties on `CGFloat`.
Base unit = 6pt.

| Token | Value | Common use |
|---|---|---|
| `.spacing0x` | 0pt | No spacing — never write `spacing: 0` in a stack |
| `.spacing05x` | 3pt | Tight gaps between text |
| `.spacing1x` | 6pt | Cell gaps, small padding |
| `.spacing105x` | 9pt | Icon-to-label gap in headers |
| `.spacing2x` | 12pt | Inner element gaps |
| `.spacing3x` | 18pt | Screen horizontal margins, card padding |
| `.spacing4x` | 24pt | Section spacing, between-group gaps |
| `.spacing5x` | 30pt | Between sections |
| `.spacing6x` | 36pt | Large padding |
| `.spacing8x` | 48pt | Bubble gap from fingertip |
| `.spacing12x` | 72pt | Large offsets |

**Screen layout rule (match Bright iOS app):**
- Horizontal screen margins: `.spacing3x` (18pt)
- Between widgets: `.spacing3x`
- Inside card padding: `.spacing3x` (vertical) — let content fill horizontally
- Section title → widget gap: `.spacing2x`

---

## Corner Radius

Defined in `CGFloat+StylingExtensions.swift`.

| Token | Value | Common use |
|---|---|---|
| `.cornerRadius8` | 8pt | Small chips |
| `.cornerRadius12` | 12pt | Progress bars |
| `.cornerRadius20` | 20pt | Speech bubbles |
| `.cardCornerRadius` | 30pt | Cards (default in CardModifier) and modal sheets |
| `.largePillCornerRadius` | 27pt | CTA buttons |
| `.smallPillCornerRadius` | 32pt | Small pills |

---

## Dates

User-facing dates are year-aware: this year shows no year (`4 Aug, 8:05 PM`), only
previous years carry one (`4 Aug 2025`), and standalone values say `Today` /
`Yesterday`. Apple's stock presets — `.formatted()`,
`formatted(date: .abbreviated, time: .shortened)`, ad-hoc `.dateTime` chains — always
print the year, so never use them for display text, even as prototype filler: they get
ported to the main app verbatim and ship the wrong format. Use the styles in
`Shared/BrightDateFormatting.swift` (`.brightTimestamp`, `.brightDate`, `.brightTime`,
`brightTimeRange`); if a design needs a shape the file can't produce yet, hard-code the
correctly-shaped string (e.g. `"4 Aug, 8:05 PM"`) rather than reaching for a stock
preset. The main app's `Date+FormatStyle.swift` is the source of truth for every shape.

---

## Haptics & wiggle

Never call `UIImpactFeedbackGenerator` or `sensoryFeedback` directly — use
`BrightHaptic` (`Shared/BrightHaptic.swift`):

```swift
.brightHaptic(.light, trigger: selection)          // .light / .medium / .success
.brightHaptic(trigger: isDone) { _, done in         // pick per value
    done ? .success : .light
}
```

To draw attention to whatever is blocking an action, shake it with
`brightWiggle` (`Shared/BrightWiggle.swift`) — it plays the haptic itself:

```swift
TextField("Session name", text: $name)
    .brightWiggle(trigger: nameNudge)   // increment the Int to fire it
```

---

## Tap targets

Never hand-roll a circular icon button — use `BrightRoundButton`, which already
carries the glass, the `.contentShape(Circle())` and (at `.extraLarge`) a light
haptic:

```swift
// Clear glass, tinted glyph
BrightRoundButton(systemImage: "stop.fill", size: .extraLarge,
                  imageColor: .defaultRed, haptic: .medium, onTapCallback: onStop)

// Filled circle, black glyph
BrightRoundButton(systemImage: "play.fill", size: .extraLarge, color: .defaultGreen) { start() }

// Menu label — the Menu takes the tap
Menu { … } label: {
    BrightRoundButton(systemImage: "ellipsis", size: .extraLarge)
        .allowsHitTesting(false)
}
```

`.extraLarge` is 48pt — the primary control on live/session screens — and is the
only size that plays a haptic by default (`.light`); pass `haptic:` to override.

When you must build a custom label, remember an icon-only `Button` is tappable
only where the glyph draws: `.frame(width:height:)` does **not** make the empty
space hittable, and glass applied outside the `Button` is decoration, not target.
Declare `.contentShape(Circle())` — or `Rectangle()` for square/pill labels.
Same for full-width rows and `Menu` labels: put `.contentShape(Rectangle())` on
the row's `HStack` so the gaps between text and trailing accessory still tap.

---

## Destructive red needs an explicit tint

The iOS app tints its whole TabView, which outranks the red that `role: .destructive` gives menu items, context-menu items, and swipe actions. This repo has no global tint, so destructive items look red here and silently lose it when ported. Always add `.tint(.defaultRed)` to every destructive `Button` — in menus, context menus, and swipe actions — even though it looks redundant in this repo.

---

## Last-row trailing chrome

When rows in a stack carry their own trailing chrome — a divider after each row, or bottom padding between rows — the last row must drop it, or it stacks with the container's own padding. Pass `isLast` into the row builder and branch on it (see `ExerciseHistoryWidget.sessionRow` here, and the iOS app's `ExerciseCompletePerformanceGraphWidget`).

---

## CardModifier

Defined in `Shared/Styling/ViewModifier/CardModifier.swift`.

Applies a rounded card with a subtle stroke border that adapts for light/dark mode.

```swift
// Default — always use this, no parameters
.modifier(CardModifier())

// Custom corner radius only if explicitly needed
.modifier(CardModifier(cornerRadius: .cornerRadius20))

// Don't clip content (border still shows)
.modifier(CardModifier(clipContent: false))
```

**NEVER pass `color:` to CardModifier.** Always use `.modifier(CardModifier())` with no arguments.

**Card padding pattern:**
```swift
VStack(alignment: .leading, spacing: .spacing3x) {
    // content
}
.padding(.vertical, .spacing3x)          // top/bottom only
// OR full padding when content doesn't need edge-to-edge:
.padding(.spacing3x)
.modifier(CardModifier())
```

When grid/chart content should go edge-to-edge within the card, pad only
the text/header section horizontally and let the visual content fill the card width.

---

## Page Containers

Defined in `Shared/BrightPageSheetView.swift`.

Never hand-roll page scaffolding. If a screen sets its own `.frame(maxWidth:maxHeight:)`
+ `.background(...ignoresSafeArea())` + `.scrollDismissesKeyboard` + `.navigationTitle`
+ `.navigationBarTitleDisplayMode(.inline)`, use `BrightPageSheetView` instead — it
supplies all of that plus the close/back button.

```swift
BrightPageSheetView(
    title: "Add Sessions",
    horizontalPadding: .spacing0x,     // content does its own padding
    trailing: {
        ToolbarItem(placement: .topBarTrailing) { saveButton }
    },
    content: { scrollContent }
)
```

Rules:
- **Never wrap it in a `NavigationStack`** — it makes one internally. Pass `path:`
  to drive its navigation instead.
- It applies `horizontalPadding` itself (default `.spacing3x`) — pass `.spacing0x`
  rather than fighting it with inner padding.
- It dismisses the keyboard on background tap — drop any local
  `.contentShape(Rectangle())` + `.onTapGesture`.
- Toolbar items go in the `trailing:` builder, not a separate `.toolbar`.
- `showBackButton: true` replaces the close button for pushed-style sheets.

Deliberate exceptions: full-bleed chrome-less sheets (own `presentationBackground`,
no nav bar) stay hand-rolled.

`BrightPageView` — the pushed-destination equivalent with no `NavigationStack` of its
own — exists in the Bright iOS app but has **not** been ported here yet.

---

## Widget Pattern

Each widget is a self-contained SwiftUI View. Supporting types (shapes, demo data)
live in the same file or in a `*Demo.swift` file in the same folder.

```swift
struct ExampleWidget: View {
    var body: some View {
        VStack(alignment: .leading, spacing: .spacing3x) {
            // header with .padding(.horizontal, .spacing3x)
            // content fills card width edge-to-edge
        }
        .padding(.vertical, .spacing3x)
        .modifier(CardModifier())
    }
}
```

**ContentView** shows each widget under a named section. The Vault widget uses
`.padding(.horizontal, -.spacing3x)` to go full-width (edge-to-edge screen).
