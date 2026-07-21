# Widgets — Project Conventions

iOS 26.5+, SwiftUI only. All design tokens come from `Shared/Styling/`. Always use the tokens below — never use raw hex values, magic numbers, or system fonts.

**Never build (xcodebuild or otherwise) unless explicitly asked.**

---

## Comments

Do not add pointless comments. Never write a comment that merely restates what the code or a symbol name already says (e.g. `/// Returns the sorted clinics` above `func sorted(...)`). Only comment when it explains *why* — non-obvious intent, a workaround, or a constraint the code can't express on its own.

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

---

## Spacing

Defined in `CGFloat+StylingExtensions.swift` as `static` properties on `CGFloat`.
Base unit = 6pt.

| Token | Value | Common use |
|---|---|---|
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
| `.cardCornerRadius` | 30pt | Cards (default in CardModifier) |
| `.modalCornerRadius` | 30pt | Modal sheets |
| `.largePillCornerRadius` | 27pt | CTA buttons |
| `.smallPillCornerRadius` | 32pt | Small pills |

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
