//
//  BrightEdgeBlur.metal
//  Widgets
//
//  Created by Dom Montalto on 25/9/2026.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

[[ stitchable ]] half4 brightEdgeBlur(float2 position,
                                      SwiftUI::Layer layer,
                                      float start,
                                      float end,
                                      float maxRadius) {
    float progress = smoothstep(0.0, 1.0, saturate((position.x - start) / max(end - start, 1.0)));
    float radius = maxRadius * progress;
    if (radius < 0.5) {
        return layer.sample(position);
    }

    const int taps = 5;
    float sigma = radius * 0.5;
    half4 sum = half4(0.0);
    float total = 0.0;
    for (int x = -taps; x <= taps; x++) {
        for (int y = -taps; y <= taps; y++) {
            float2 offset = float2(x, y) * (radius / float(taps));
            float weight = exp(-dot(offset, offset) / (2.0 * sigma * sigma));
            sum += layer.sample(position + offset) * half(weight);
            total += weight;
        }
    }
    return sum / half(total);
}
