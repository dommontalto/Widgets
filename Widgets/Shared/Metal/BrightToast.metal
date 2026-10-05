#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// Snaps a blurred layer back to hard edges, so two blurred shapes that
// overlap fuse into one gooey body instead of a soft smudge.
[[ stitchable ]] half4 brightAlphaThreshold(float2 position, SwiftUI::Layer layer, float threshold) {
    half4 color = layer.sample(position);
    if (color.a < threshold) {
        return half4(0.0h);
    }
    return half4(color.rgb / color.a, 1.0h);
}
