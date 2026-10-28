//
//  BrightDNAStrandShadersV5.metal
//  Widgets
//
//  Created by Dom Montalto on 21/10/2026.
//

#include <metal_stdlib>
using namespace metal;

namespace brightDNAStrand {

struct Uniforms {
    float4x4 mvp;
    float3 cameraPos;
    float time;
    float height;
    float focusY;        // world-space centre of the lit zone
    float focusWidth;    // half-width of the lit zone along the strand
};

struct Bead {
    packed_float3 center;
    float radius;
    float pairIndex;
};

struct VOut {
    float4 pos [[position]];
    float3 wpos;
    float3 nrm;
    float3 bead;
};

// Aqua palette in linear pre-tone-map values: deep #075974, light #9ED7E7,
// and the #C4EAF4 highlight lifted 40% towards white.
constant float3 DEEP = float3(0.0066, 0.0852, 0.1272);
constant float3 LIGHT = float3(0.2276, 0.6128, 0.9783);
constant float3 HIGHLIGHT = float3(0.5349, 0.7584, 1.0);
constant float3 CYAN = float3(0.455, 0.961, 0.984);
constant float3 BLUE = float3(0.06, 0.38, 1.00);

static inline float hash31(float3 p) {
    p = fract(p * 0.1031);
    p += dot(p, p.yzx + 33.33);
    return fract((p.x + p.y) * p.z);
}

static inline float vnoise(float3 x) {
    float3 i = floor(x), f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    float n000 = hash31(i + float3(0, 0, 0)), n100 = hash31(i + float3(1, 0, 0));
    float n010 = hash31(i + float3(0, 1, 0)), n110 = hash31(i + float3(1, 1, 0));
    float n001 = hash31(i + float3(0, 0, 1)), n101 = hash31(i + float3(1, 0, 1));
    float n011 = hash31(i + float3(0, 1, 1)), n111 = hash31(i + float3(1, 1, 1));
    float nx00 = mix(n000, n100, f.x), nx10 = mix(n010, n110, f.x);
    float nx01 = mix(n001, n101, f.x), nx11 = mix(n011, n111, f.x);
    return mix(mix(nx00, nx10, f.y), mix(nx01, nx11, f.y), f.z);
}

static inline float fbm(float3 p) {
    float s = 0.0, a = 0.5;
    for (int i = 0; i < 3; i++) { s += a * vnoise(p); p *= 2.03; a *= 0.5; }
    return s / 0.875;
}

static inline float3 studioEnv(float3 R) {
    float up = R.y * 0.5 + 0.5;
    float3 env = mix(float3(0.006, 0.009, 0.014), float3(0.30, 0.36, 0.46), smoothstep(0.35, 1.0, up));
    env += float3(0.85, 0.92, 1.0) * smoothstep(0.72, 0.95, dot(R, normalize(float3(-0.55, 0.75, 0.35)))) * 1.3;
    env += float3(0.25, 0.45, 0.65) * smoothstep(0.80, 0.98, dot(R, normalize(float3(0.9, 0.1, -0.3)))) * 0.6;
    return env;
}

} // namespace brightDNAStrand

using namespace brightDNAStrand;

// MARK: - Beads

vertex VOut brightDNAStrandBeadVertex(uint vid [[vertex_id]],
                                      uint iid [[instance_id]],
                                      const device packed_float3 *sphere [[buffer(0)]],
                                      constant Uniforms &u [[buffer(1)]],
                                      const device Bead *beads [[buffer(2)]]) {
    Bead b = beads[iid];
    float3 c = float3(b.center);
    float3 n = float3(sphere[vid]);
    float3 p = c + n * b.radius;

    VOut o;
    o.pos = u.mvp * float4(p, 1.0);
    o.wpos = p;
    o.nrm = n;
    o.bead = c;
    return o;
}

// Faceted aqua gems: deep-blue bodies lit from inside (outer beads brightest),
// razor facet highlights, and a quarter of the beads catching brief glints.
// Both ends of the strand dissolve into vapour.
fragment float4 brightDNAStrandBeadFragment(VOut in [[stage_in]],
                                            constant Uniforms &u [[buffer(0)]]) {
    float endStart = u.height * 0.5 - 1.4;
    float dissolve = saturate((abs(in.wpos.y) - endStart) / 1.4);
    float dn = fbm(in.wpos * 4.5 + float3(0.0, -u.time * 0.35, 0.0));
    if (dissolve > 0.0 && dn < dissolve) discard_fragment();
    float burn = dissolve > 0.0 ? smoothstep(0.12, 0.0, dn - dissolve) : 0.0;

    float3 N = normalize(in.nrm);
    float3 V = normalize(u.cameraPos - in.wpos);
    float3 L = normalize(float3(-0.55, 0.8, 0.45));
    float3 H = normalize(L + V);

    float outward = saturate(length(in.bead.xz) / 0.42);
    float fy = (in.wpos.y - u.focusY) / u.focusWidth;
    float zone = exp(-fy * fy * 0.35);
    float seed = hash31(in.bead * 37.0 + 0.5);
    float rate = hash31(in.bead * 53.0 + 7.1);

    // Facets: snap the normal to a coarse lattice, turned randomly per bead.
    float a = seed * 6.2831853, c = cos(a), sn = sin(a);
    float3 q = float3(c * N.x - sn * N.z, N.y, sn * N.x + c * N.z);
    q = normalize(round(q * 1.4));
    float3 Nf = normalize(float3(c * q.x + sn * q.z, q.y, -sn * q.x + c * q.z));
    float fv = saturate(dot(Nf, V));
    float fh = saturate(dot(Nf, H));
    float Ff = 0.04 + 0.96 * pow(1.0 - fv, 5.0);

    float lambert = saturate(dot(Nf, L)) * 0.7 + 0.3;
    float3 color = DEEP * lambert;
    color += studioEnv(reflect(-V, Nf)) * Ff;
    float outerBoost = 0.3 + 1.7 * outward * outward;
    color += LIGHT * 0.35 * outerBoost * (0.85 + 0.4 * zone);
    color += HIGHLIGHT * pow(fh, 300.0) * 6.0;
    float glint = step(0.75, seed) * pow(0.5 + 0.5 * sin(u.time * (0.8 + rate * 2.0) + rate * 40.0), 6.0);
    color += HIGHLIGHT * glint * (pow(fh, 30.0) * 4.0 + 0.3);

    color *= mix(0.45, 1.0, exp(-pow(fy / 3.5, 2.0)));
    color += mix(BLUE, CYAN, burn) * burn * 1.8;

    float dc = length(u.cameraPos - in.wpos);
    color *= exp(-max(dc - 2.4, 0.0) * 0.4);

    return float4(color, 1.0);
}

// MARK: - Bloom + composite

struct FSOut {
    float4 pos [[position]];
    float2 uv;
};

vertex FSOut brightDNAStrandFullscreenVertex(uint vid [[vertex_id]]) {
    float2 p = float2((vid << 1) & 2, vid & 2);
    FSOut o;
    o.pos = float4(p * 2.0 - 1.0, 0.0, 1.0);
    o.uv = float2(p.x, 1.0 - p.y);
    return o;
}

fragment float4 brightDNAStrandBrightPass(FSOut in [[stage_in]],
                                          texture2d<float> src [[texture(0)]],
                                          constant float &threshold [[buffer(0)]]) {
    constexpr sampler s(filter::linear, address::clamp_to_edge);
    float3 c = src.sample(s, in.uv).rgb;
    float b = max(max(c.r, c.g), c.b);
    float k = max(b - threshold, 0.0) / max(b, 1e-4);
    return float4(c * k, 1.0);
}

struct BlurParams { float2 dir; };

// Alpha is blurred too, so the blurred scene keeps its coverage.
fragment float4 brightDNAStrandBlurPass(FSOut in [[stage_in]],
                                        texture2d<float> src [[texture(0)]],
                                        constant BlurParams &p [[buffer(0)]]) {
    constexpr sampler s(filter::linear, address::clamp_to_edge);
    const float w[5] = { 0.227027, 0.1945946, 0.1216216, 0.054054, 0.016216 };
    float4 c = src.sample(s, in.uv) * w[0];
    for (int i = 1; i < 5; i++) {
        float2 o = p.dir * float(i);
        c += src.sample(s, in.uv + o) * w[i];
        c += src.sample(s, in.uv - o) * w[i];
    }
    return c;
}

struct CompositeParams {
    float bloomIntensity;
    float saturation;
    float2 strandDir;     // the strand's direction on screen, aspect-corrected
    float aspect;
    float frost;          // frosted-grain jitter in the blurred ends
    float glowHold;       // share of the glow held back behind the blur
    float _pad;
    float2 band;          // blur start and full, as distance along the strand from centre
};

static inline float3 aces(float3 x) {
    const float a = 2.51, b = 0.03, c = 2.43, d = 0.59, e = 0.14;
    return saturate((x * (a * x + b)) / (x * (c * x + d) + e));
}

fragment float4 brightDNAStrandComposite(FSOut in [[stage_in]],
                                         texture2d<float> scene [[texture(0)]],
                                         texture2d<float> b2 [[texture(1)]],
                                         texture2d<float> b4 [[texture(2)]],
                                         texture2d<float> b8 [[texture(3)]],
                                         texture2d<float> b16 [[texture(4)]],
                                         texture2d<float> blurredScene [[texture(5)]],
                                         constant CompositeParams &p [[buffer(0)]]) {
    constexpr sampler s(filter::linear, address::clamp_to_edge);
    float2 uv = in.uv;
    float2 dc = uv - 0.5;
    float ab = 0.005;   // chromatic aberration on bloom, grows outward

    float3 bloom = float3(0.0);
    if (p.bloomIntensity > 0.0) {
        float3 l2 = float3(b2.sample(s, uv + dc * ab).r, b2.sample(s, uv).g, b2.sample(s, uv - dc * ab).b);
        float3 l4 = float3(b4.sample(s, uv + dc * ab * 1.6).r, b4.sample(s, uv).g, b4.sample(s, uv - dc * ab * 1.6).b);
        float3 l8 = b8.sample(s, uv).rgb;
        float3 l16 = b16.sample(s, uv).rgb;
        bloom = (l2 * 0.5 + l4 * 0.4 + l8 * 0.4 + l16 * 0.35) * p.bloomIntensity;
    }

    // Both ends of the strand sit behind a soft, lightly frosted blur; the
    // middle stays sharp.
    float along = dot(dc * float2(p.aspect, 1.0), p.strandDir);
    float glass = smoothstep(p.band.x, p.band.y, abs(along));
    float4 sceneS = scene.sample(s, uv);
    if (glass > 0.0) {
        float2 px = uv * float2(scene.get_width(), scene.get_height());
        float2 frost = (float2(hash31(float3(px, 1.0)), hash31(float3(px, 7.0))) - 0.5) * p.frost * glass;
        float4 frosted = blurredScene.sample(s, uv + frost);
        frosted.rgb /= max(frosted.a, 1e-3);   // the blur is premultiplied; coverage is applied below
        sceneS = mix(sceneS, frosted, glass);
    }
    bloom *= 1.0 - p.glowHold * glass;

    float3 c = aces(sceneS.rgb + bloom);
    c *= 1.0 - dot(dc, dc) * 0.85;
    float l = dot(c, float3(0.2126, 0.7152, 0.0722));
    c = mix(float3(l), c, p.saturation);

    // Coverage is the strand plus its glow, so the SwiftUI background shows
    // through the empty void.
    float a = saturate(sceneS.a + max(max(bloom.r, bloom.g), bloom.b));
    return float4(c * a, a);
}
