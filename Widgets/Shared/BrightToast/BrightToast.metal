#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// Snaps a blurred layer back to hard edges, so two blurred shapes that
// overlap fuse into one gooey body instead of a soft smudge. Pixels within
// `borderWidth` of that edge take `borderColor`, outlining the fused shape —
// a stroke drawn before the blur would be thresholded away.
[[ stitchable ]] half4 brightAlphaThreshold(
    float2 position,
    SwiftUI::Layer layer,
    float threshold,
    half4 borderColor,
    float borderWidth
) {
    half4 color = layer.sample(position);
    if (color.a < threshold) {
        return half4(0.0h);
    }

    half3 fill = color.rgb / color.a;

    bool isEdge = false;
    for (int i = 0; i < 8; i++) {
        float angle = float(i) * M_PI_F / 4.0;
        float2 probe = position + float2(cos(angle), sin(angle)) * borderWidth;
        if (layer.sample(probe).a < threshold) {
            isEdge = true;
            break;
        }
    }

    if (isEdge) {
        fill = fill * (1.0h - borderColor.a) + borderColor.rgb;
    }
    return half4(fill, 1.0h);
}
