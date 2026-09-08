//
//  LighthouseEnvironment.swift
//  Widgets
//
//  Created by Dom Montalto on 4/9/2026.
//

import SwiftUI

extension EnvironmentValues {
    // When true, `RollingNumberText` ramps its value up from zero (a true
    // count-up) instead of the digit-morph transition.
    @Entry var lighthouseRampNumbersFromZero = false

    // When true, widget charts animate their reveal as they appear: the heart
    // line draws left-to-right and the activity bars grow up from the baseline.
    @Entry var lighthouseAnimateChartReveal = false

    // Gates WHEN the ramp/chart-reveal actually fires. While false the widget
    // holds at its zero state; flipping it true runs the load-in once. Defaults
    // true so views outside Lighthouse load in immediately.
    @Entry var lighthouseLoadIn = true

    // Marks the sleep widget as being shown in a Lighthouse reply. While active
    // the stage bars start fully dimmed; `lighthouseSleepREMFocus` then lights
    // the REM bars back up on load.
    @Entry var lighthouseSleepActive = false

    // When true, the sleep chart keeps only the REM bars at full opacity.
    @Entry var lighthouseSleepREMFocus = false
}
