#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

static float3 brightRipple_mod289v3(float3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
static float2 brightRipple_mod289v2(float2 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
static float3 brightRipple_permute(float3 x)  { return brightRipple_mod289v3(((x * 34.0) + 1.0) * x); }

static float brightRipple_snoise(float2 v) {
    const float4 C = float4(0.211324865405187,
                             0.366025403784439,
                            -0.577350269189626,
                             0.024390243902439);
    float2 i  = floor(v + dot(v, C.yy));
    float2 x0 = v -   i + dot(i, C.xx);

    float2 i1 = (x0.x > x0.y) ? float2(1.0, 0.0) : float2(0.0, 1.0);
    float4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;

    i = brightRipple_mod289v2(i);
    float3 p = brightRipple_permute(brightRipple_permute(i.y + float3(0.0, i1.y, 1.0))
                                     + i.x + float3(0.0, i1.x, 1.0));

    float3 m = max(0.5 - float3(dot(x0, x0),
                                 dot(x12.xy, x12.xy),
                                 dot(x12.zw, x12.zw)), 0.0);
    m = m * m;
    m = m * m;

    float3 x  = 2.0 * fract(p * C.www) - 1.0;
    float3 h  = abs(x) - 0.5;
    float3 ox = floor(x + 0.5);
    float3 a0 = x - ox;
    m *= 1.79284291400159 - 0.85373472095314 * (a0 * a0 + h * h);

    float3 g;
    g.x  = a0.x  * x0.x  + h.x  * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}

static float2x2 brightRipple_rot2(float r) {
    float c = cos(r), s = sin(r);
    return float2x2(c, s, -s, c);
}

static float brightRipple_uvFrame(float2 uv) {
    float aax = 2.0 * fwidth(uv.x);
    float aay = 2.0 * fwidth(uv.y);
    float left   = smoothstep(0.0, aax, uv.x);
    float right  = 1.0 - smoothstep(1.0 - aax, 1.0, uv.x);
    float bottom = smoothstep(0.0, aay, uv.y);
    float top    = 1.0 - smoothstep(1.0 - aay, 1.0, uv.y);
    return left * right * bottom * top;
}

static float brightRipple_caustic(float2 uv, float t, float scale) {
    float2 n = float2(0.1);
    float2 N = float2(0.1);
    float2x2 m = brightRipple_rot2(0.5);
    for (int j = 0; j < 6; j++) {
        uv = m * uv;
        n  = m * n;
        float fj = float(j);
        float2 q = uv * scale + fj + n + (0.5 + 0.5 * fj) * (fmod(fj, 2.0) - 1.0) * t;
        n += sin(q);
        N += cos(q) / scale;
        scale *= 1.1;
    }
    return (N.x + N.y + 1.0);
}

[[ stitchable ]] half4 brightRipple(float2 position,
                               SwiftUI::Layer layer,
                               float4 boundingRect,
                               float  time,
                               float  speed,
                               float  size,
                               float  caustic,
                               float  waves,
                               float  layering,
                               float  edges,
                               float  highlights,
                               half4  colorBack,
                               half4  colorHighlight) {
    float2 sz = boundingRect.zw;
    float aspect = sz.x / max(sz.y, 1.0);

    float2 imageUV = position / max(sz, float2(1.0));
    float2 patternUV = (imageUV - 0.5) * float2(aspect, 1.0);
    patternUV /= max(0.01 + 0.09 * size, 1e-4);

    float t = time * speed;

    float wavesNoise = brightRipple_snoise((0.3 + 0.1 * sin(t)) * 0.1 * patternUV
                                  + float2(0.0, 0.4 * t));

    float causticN = brightRipple_caustic(patternUV + waves * float2(1.0, -1.0) * wavesNoise,
                                 2.0 * t, 1.5);
    causticN += saturate(layering) * brightRipple_caustic(patternUV + 2.0 * waves * float2(1.0, -1.0) * wavesNoise,
                                                 1.5 * t, 2.0);
    causticN = causticN * causticN;

    float edgeMask = smoothstep(0.0, 0.1, imageUV.x);
    edgeMask *= smoothstep(0.0, 0.1, imageUV.y);
    edgeMask *= (smoothstep(1.0, 1.1, imageUV.x) + (1.0 - smoothstep(0.8, 0.95, imageUV.x)));
    edgeMask *= (1.0 - smoothstep(0.9, 1.0, imageUV.y));
    edgeMask = mix(edgeMask, 1.0, saturate(edges));

    float causticDistort = 0.02 * causticN * edgeMask;
    float wavesDistort   = 0.1 * saturate(waves) * wavesNoise;

    imageUV += float2(wavesDistort, -wavesDistort);
    imageUV += saturate(caustic) * causticDistort;

    float frame = brightRipple_uvFrame(imageUV);

    half4 image = layer.sample(imageUV * sz);

    float3 backRGB = float3(colorBack.rgb) * float(colorBack.a);
    float3 col = mix(backRGB, float3(image.rgb), float(image.a) * frame);

    causticN = max(-0.2, causticN);
    float hi = 0.05 * saturate(highlights) * causticN;
    col = mix(col, float3(colorHighlight.rgb), hi);
    float sparkle = 0.025 * saturate(highlights) * causticN * float(colorHighlight.a)
                     * (0.5 + 0.5 * wavesNoise);
    col += float3(colorHighlight.rgb) * sparkle;

    return half4(half3(col), 1.0);
}
