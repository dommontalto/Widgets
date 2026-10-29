//
//  BrightLiquidGlassLogoShadersV5.metal
//  Widgets
//
//  Created by Dom Montalto on 23/10/2026.
//
//  Adapted from ReactDrops Liquid Glass Logo, see THIRD_PARTY_LICENSES.md.
//

#include <metal_stdlib>
using namespace metal;

namespace brightLiquidGlassLogo {

struct RenderUniforms {
    float4 tile;
    float2 resolution;
    float2 logoBox;
    float dpr;
    float unit;
    float time;
    float settle;
    float artScale;
    float tileEnabled;
    float pageLight;
    float depth;
    float dispersion;
    float relief;
    float caustics;
    float highlights;
    float echoTint;
    float innerWallFocus;
    float dropStrength;
};

struct CompositeUniforms {
    float2 resolution;
    float dpr;
    float unit;
    float settle;
    float bloom;
    float time;
    float finish;
    float pageLight;
    float4 page;
};

struct FSOut {
    float4 position [[position]];
};

constant float PI = 3.14159265359;
constant int BANDS = 32;

constexpr sampler imageSampler(filter::linear, mip_filter::linear, address::clamp_to_edge);

static inline float sq(float x) { return x * x; }
static inline float bell(float x, float width) { return exp(-sq(x / max(width, 0.001))); }
static inline float ease(float a, float b, float x) { return smoothstep(a, b, x); }

static inline float3 spectrum(float s) {
    float wavelength = 400.0 + 300.0 * s;
    float3 rgb = float3(0.0);
    if (wavelength < 440.0) rgb = float3((440.0 - wavelength) / 120.0, 0.0, 1.0);
    else if (wavelength < 490.0) rgb = float3(0.0, (wavelength - 440.0) / 50.0, 1.0);
    else if (wavelength < 510.0) rgb = float3(0.0, 1.0, (510.0 - wavelength) / 20.0);
    else if (wavelength < 580.0) rgb = float3((wavelength - 510.0) / 70.0, 1.0, 0.0);
    else if (wavelength < 645.0) rgb = float3(1.0, (645.0 - wavelength) / 65.0, 0.0);
    else rgb = float3(1.0, 0.0, 0.0);
    return rgb * mix(0.2, 1.0, ease(400.0, 430.0, wavelength)) * mix(1.0, 0.65, ease(650.0, 700.0, wavelength));
}

static inline float glassIor(float s, float spread) {
    float wavelength = 0.4 + 0.3 * s;
    return 1.38 + (0.04 / (wavelength * wavelength) - 0.12) * spread;
}

// p is y-up while Metal textures are y-down, so v is flipped.
static inline float4 imageAt(texture2d<float> image, float2 p, float2 box, constant RenderUniforms &u) {
    float2 uv = 0.5 + p / box;
    float2 footprint = float2(image.get_width(), image.get_height()) / max(box * u.dpr, float2(1.0));
    float lod = max(0.0, log2(max(footprint.x, footprint.y)));
    lod += (1.0 - ease(0.20, 0.36, u.time)) * 2.2;
    float4 ink = image.sample(imageSampler, float2(uv.x, 1.0 - uv.y), level(lod));
    return ink * step(0.0, uv.x) * step(0.0, uv.y) * step(uv.x, 1.0) * step(uv.y, 1.0);
}

static inline float superRadius(float2 p, float n) {
    float2 a = max(abs(p), float2(0.00001));
    return pow(pow(a.x, n) + pow(a.y, n), 1.0 / n);
}

static inline float2 superNormal(float2 p, float n) {
    return normalize(sign(p) * pow(max(abs(p), float2(0.00001)), float2(n - 1.0)) + float2(0.000001));
}

// Precise sin keeps the hash stable at the large arguments it is fed.
static inline float hash1(float n) { return fract(precise::sin(n * 127.1 + 311.7) * 43758.5453); }

static inline float contourNoise(float u) {
    float i = floor(u);
    float f = fract(u);
    f = f * f * (3.0 - 2.0 * f);
    return mix(hash1(i), hash1(i + 1.0), f);
}

static inline float specks(float u, float d, float size, float seed) {
    float spacing = size * 22.0;
    float cell = floor(u / spacing);
    float on = step(0.7, hash1(cell + seed));
    float center = (cell + 0.2 + 0.6 * hash1(cell + seed + 17.0)) * spacing;
    float offset = (hash1(cell + seed + 31.0) - 0.5) * size * 0.6;
    float dash = size * (2.5 + 4.0 * hash1(cell + seed + 53.0));
    return on * bell(u - center, dash) * bell(d - offset, size * 0.35);
}

static inline float driftingSpecks(float u, float d, float size, float seed, float t) {
    float spacing = size * 22.0;
    float cell = floor(u / spacing);
    float glints = 0.0;
    for (int j = -1; j <= 1; j++) {
        float id = cell + float(j);
        float on = step(0.7, hash1(id + seed));
        float rate = 2.5 + 3.0 * hash1(id + seed + 71.0);
        float phase = 6.2832 * hash1(id + seed + 89.0);
        float center = (id + 0.2 + 0.6 * hash1(id + seed + 17.0)) * spacing + sin(t * rate * 0.5 + phase) * spacing * 0.05;
        float offset = (hash1(id + seed + 31.0) - 0.5) * size * 0.6 + sin(t * rate + phase) * size * 1.6;
        float dash = size * (2.5 + 4.0 * hash1(id + seed + 53.0));
        glints += on * bell(u - center, dash) * bell(d - offset, size * 0.35);
    }
    return min(glints, 1.0);
}

static inline float edgeWarp(float arc, float seed, float unit) {
    float broad = contourNoise(arc / (unit * 0.037) + seed) - 0.5;
    float fine = contourNoise(arc / (unit * 0.008) + seed + 29.0) - 0.5;
    return unit * (broad * 0.0017 + fine * 0.0008);
}

static inline float2 glassPores(float arc, float d, float seed, constant RenderUniforms &u) {
    if (abs(d) > u.unit * 0.011) return float2(0.0);
    float pitch = u.unit * 0.022;
    float cell = floor(arc / pitch);
    float2 pores = float2(0.0);
    for (int j = -1; j <= 1; j++) {
        float id = cell + float(j) + seed;
        float visible = step(0.63, hash1(id));
        float center = (cell + float(j) + 0.15 + 0.7 * hash1(id + 17.0)) * pitch;
        float across = (hash1(id + 31.0) - 0.5) * u.unit * 0.009;
        float span = u.unit * (0.0022 + 0.0035 * hash1(id + 53.0));
        float height = max(0.35 / u.dpr, u.unit * (0.0007 + 0.0012 * hash1(id + 71.0)));
        float2 q = float2((arc - center) / span, (d - across) / height);
        q.x += q.y * (hash1(id + 89.0) - 0.5) * 0.55;
        float radius = length(q);
        float aa = max(0.18, 0.4 / (u.dpr * height));
        float cavity = bell(radius, 0.65);
        float lip = bell(radius - 1.0, aa);
        float glint = 0.25 + 0.75 * max(dot(q / max(radius, 0.001), normalize(float2(-0.4, 0.8))), 0.0);
        pores += float2(cavity, lip * glint) * visible;
    }
    return min(pores, float2(1.0));
}

static inline float3 exteriorColor(float3 light, float coverage, constant RenderUniforms &u) {
    float3 shade = mix(float3(0.40, 0.46, 0.56), u.tile.rgb * 0.86, u.echoTint);
    return mix(light, shade * coverage, u.pageLight);
}

static float4 refractedLogo(float2 p, float2 normalXY, float lensScale, float glass, float chromaticScale,
                            float surfaceDistance, texture2d<float> logo, constant RenderUniforms &u,
                            thread float3 &refractedCoverage) {
    float3 normal = normalize(float3(normalXY, 1.0));
    float3 color = float3(0.0);
    float3 weights = float3(0.0);
    float alpha = 0.0;
    float minCoverage = 1.0;
    float maxCoverage = 0.0;
    refractedCoverage = float3(0.0);
    float spread = u.dispersion * chromaticScale * mix(0.85, mix(2.2, 1.5, ease(0.28, 0.9, u.time)), ease(0.25, 0.33, u.time));
    float3 neutralRay = refract(float3(0.0, 0.0, -1.0), normal, 1.0 / glassIor(0.5, spread));
    float2 neutralOffset = neutralRay.xy / max(-neutralRay.z, 0.25) * u.unit * u.depth * 0.80 * lensScale;
    float sphereRadius = u.unit * lensScale * 0.5;
    float sphereFocus = 1.0 - ease(0.225, 0.335, u.time);
    float bubbleQ = min(length(p) / max(sphereRadius, 1.0), 1.0);
    float openingFocus = 1.0 - ease(0.19, 0.265, u.time);
    float focusProfile = mix(0.7 + 0.6 * sq(bubbleQ), 1.0 - 0.9 * sq(bubbleQ), openingFocus);
    for (int i = 0; i < BANDS; i++) {
        float s = float(i) / float(BANDS - 1);
        float ior = glassIor(s, spread);
        float3 ray = refract(float3(0.0, 0.0, -1.0), normal, 1.0 / ior);
        float2 offset = ray.xy / max(-ray.z, 0.25) * u.unit * u.depth * 0.80 * lensScale;
        float2 bubbleSample = p * focusProfile + offset * mix(0.35, 0.12, openingFocus);
        bubbleSample += float2(0.025, 0.10) * u.unit * openingFocus;
        bubbleSample += (offset - neutralOffset) * openingFocus * 1.6;
        float2 sourcePoint = mix(p + offset, bubbleSample, sphereFocus);
        float4 ink = imageAt(logo, sourcePoint, u.logoBox * u.artScale, u);
        ink *= mix(1.0, 1.0 - ease(0.72, 0.86, bubbleQ), openingFocus);
        float edgeShift = (s - 0.5) * u.unit * lensScale * 0.018 * u.dispersion * chromaticScale;
        ink *= 1.0 - smoothstep(-0.8 / u.dpr, 0.8 / u.dpr, surfaceDistance - edgeShift);
        minCoverage = min(minCoverage, ink.a);
        maxCoverage = max(maxCoverage, ink.a);
        float3 w = spectrum(s);
        color += ink.rgb * w;
        alpha += ink.a * (w.r + w.g + w.b);
        refractedCoverage += ink.a * w;
        weights += w;
    }
    color /= weights;
    refractedCoverage /= weights;
    float coating = ease(-u.unit * lensScale * 0.022, 0.0, surfaceDistance);
    color.g *= 1.0 - 0.65 * coating * (maxCoverage - minCoverage);
    float youngFilm = (maxCoverage - minCoverage) * (1.0 - ease(0.19, 0.30, u.time));
    youngFilm *= 1.0 - ease(-u.unit * lensScale * 0.08, -u.unit * lensScale * 0.025, surfaceDistance);
    color.r += color.b * youngFilm * 0.80;
    color.b += color.r * youngFilm * 0.60;
    color.g *= 1.0 - youngFilm * 0.55;
    alpha /= weights.r + weights.g + weights.b;
    float diffuse = max(dot(normal, normalize(float3(-0.4, 0.6, 1.0))), 0.0);
    float3 earlyWhite = mix(float3(0.90, 0.93, 0.95), float3(0.84, 0.86, 0.89), ease(0.21, 0.40, u.time));
    float3 whiteBalance = mix(earlyWhite, float3(0.87, 0.88, 0.885), ease(0.75, 1.22, u.time));
    color *= whiteBalance * ((0.90 + 0.10 * diffuse + glass * u.caustics * 0.04) * ((0.975 + 0.025 * sin(p.y / u.unit * PI)) * (1.0 + 0.09 * ease(0.75, 1.22, u.time) + 0.03 * (1.0 - ease(0.2, 0.5, u.time)))));
    return float4(color, alpha);
}

static float4 iconLens(float2 p, texture2d<float> logo, constant RenderUniforms &u) {
    float t = u.time;
    float unit = u.unit;
    float settle = ease(0.0, 1.0, u.settle);
    float enter = ease(0.025, 0.16, t);
    float4 source = imageAt(logo, p, u.logoBox * u.artScale, u);
    if (t > 1.58) return source * settle;
    if (enter < 0.001) return float4(0.0);
    float shape = 2.0 + 3.0 * ease(0.29, 0.36, t);
    float expand = enter * (0.64 + 0.41 * (1.0 - exp(-max(t - 0.16, 0.0) * 5.8)));
    float collapse = 1.0 - ease(1.33, 1.52, t);
    float lensScale = max(0.001, mix(expand * mix(0.48, 1.0, collapse), 1.0, settle));
    float halfSize = unit * 0.5 * lensScale;
    float radius = superRadius(p / halfSize, shape);
    float sd = (radius - 1.0) * halfSize;
    float aa = max(fwidth(sd), 0.65);
    float mask = (1.0 - smoothstep(-aa, aa, sd));
    float glass = (1.0 - ease(1.05, 1.4, t)) * collapse * (1.0 - settle);
    float shown = ease(0.12, 0.165, t) * (1.0 - ease(1.39, 1.53, t));
    if (sd > unit * 0.10) return float4(0.0);
    float2 outward = superNormal(p / halfSize, shape);
    float2 radial = normalize(p + float2(0.001));
    float diagonal = max(0.0, 2.0 * radial.x * radial.y);
    float shoulderStart = 0.6 + 0.18 * ease(0.66, 1.15, t) * (1.0 - diagonal) + 0.16 * ease(1.0, 1.22, t) * diagonal;
    float shoulder = ease(shoulderStart, 1.0, radius);
    float slope = (0.04 * radius + (0.85 + 0.2 * (1.0 - ease(0.28, 0.75, t))) * shoulder * shoulder) * glass * u.dropStrength;
    slope += (1.0 - ease(0.18, 0.42, t)) * radius * 0.32 * u.dropStrength;
    float2 opticalDirection = normalize(mix(outward, normalize(p + float2(0.001)), 0.95));
    float astigmatism = 0.8 + 0.4 * radial.x * radial.y;
    float2 n = opticalDirection * slope * astigmatism * (1.0 - settle);
    float3 refractedCoverage = float3(0.0);
    float4 ink = refractedLogo(p, n, lensScale, glass, 1.0, sd, logo, u, refractedCoverage);
    float illumination = 0.5 + 0.5 * dot(outward, normalize(float2(-0.5, 0.9)));
    float3 inkCoverage = refractedCoverage;
    float plateLight = ease(0.3, 0.8, dot(u.tile.rgb, float3(0.299, 0.587, 0.114)));
    float3 body = u.tile.rgb * (mix(0.55, 0.96, plateLight) + mix(0.45, 0.04, plateLight) * (1.0 - min(radius, 1.0)));
    body += float3(0.004, 0.007, 0.01) * bell(radius - 0.75, 0.5);
    float3 color = ink.rgb + body * (1.0 - inkCoverage) * glass * u.tileEnabled;
    float plateFade = mix((1.0 - ease(1.08, 1.36, t)) * (1.0 - settle), glass, u.pageLight);
    float alpha = max(ink.a, plateFade * u.tileEnabled);
    float2 spherePoint = p / halfSize;
    float3 sphereNormal = normalize(float3(spherePoint, sqrt(max(0.001, 1.0 - dot(spherePoint, spherePoint)))));
    float3 sphereRay = reflect(float3(0.0, 0.0, -1.0), sphereNormal);
    float lightTravel = mix(-0.12, 0.20, ease(0.13, 0.30, t));
    float softbox = bell(sphereRay.x - lightTravel, 1.05) * bell(sphereRay.y - 0.56, 0.52);
    float sphericalLight = softbox * (1.0 - ease(0.245, 0.36, t)) * glass * u.highlights * 0.70;
    color += float3(0.50, 0.61, 0.72) * sphericalLight * (1.0 - ink.a * 0.85);
    alpha = max(alpha, sphericalLight);

    float arc = atan2(p.y, p.x) * unit * 0.5;
    float grainScale = unit * 0.03;
    float developed = ease(0.23, 0.48, t);
    float cornerExposure = ease(0.12, 0.8, -2.0 * radial.x * radial.y);
    float reliefScale = lensScale * developed * (0.2 + 0.8 * cornerExposure);
    float sharedWarp = edgeWarp(arc, 0.0, unit) * reliefScale;
    float rimSd = sd + sharedWarp;
    float innerSd = sd + sharedWarp * 0.7 + edgeWarp(arc, 41.0, unit) * reliefScale * 0.4;
    float inner2Sd = sd + sharedWarp * 0.45 + edgeWarp(arc, 83.0, unit) * reliefScale * 0.6;
    float thickness = 0.75 + 0.5 * contourNoise(arc / (unit * 0.013) + 13.0);
    float around = arc / (unit * 0.5);
    float rimBob = unit * 0.0025 * developed * (0.6 * sin(7.0 * around + 0.4) * sin(t * 6.3 + 1.0) + 0.4 * sin(3.0 * around + 2.0) * sin(t * 4.1));
    float rimLineSd = rimSd + rimBob;
    float shimmer = mix(contourNoise(arc / grainScale), contourNoise(arc / grainScale + 211.0), 0.5 + 0.5 * sin(t * 5.0 + 6.2832 * contourNoise(arc / (grainScale * 3.0) + 7.0)));
    float rim = bell(rimLineSd + unit * 0.002, unit * 0.0018 * thickness + aa * 0.3) * (0.6 + 0.8 * shimmer);
    float centerFade = 1.0 - ease(0.62, 0.92, t);
    float inner = centerFade * bell(innerSd + unit * 0.012, unit * 0.0025 / thickness + aa * 0.2) * (0.55 + 0.9 * contourNoise(arc / grainScale + 41.0));
    float inner2 = centerFade * bell(inner2Sd + unit * 0.022, unit * 0.0018 * thickness + aa * 0.1) * (0.5 + contourNoise(arc / grainScale + 83.0));
    float key = pow(illumination, 5.0);
    float rimVisibility = 1.0 - 0.55 * ease(0.75, 1.22, t);
    float lowerRight = pow(0.5 + 0.5 * dot(outward, normalize(float2(0.8, -0.6))), 5.0);
    lowerRight *= ease(-0.25, -0.05, p.x / unit) * (1.0 - ease(-0.22, -0.02, p.y / unit));
    float2 insetPoint = p - float2(0.002, -0.002) * unit * lensScale;
    float wallGap = (0.055 - 0.023 * ease(0.18, 0.34, t)) + 0.050 * ease(0.14, 0.50, t) * (1.0 - 0.5 * ease(0.80, 1.22, t));
    float insetHalf = halfSize - wallGap * unit * lensScale;
    float insetShape = max(2.0, 2.0 + (shape - 2.0) * ease(0.20, 0.55, t) - 0.45);
    float insetRadius = superRadius(insetPoint / insetHalf, insetShape);
    float insetSd = (insetRadius - 1.0) * insetHalf + sharedWarp * 0.4 + edgeWarp(arc, 151.0, unit) * reliefScale * 0.7;
    float channel = ease(-unit * 0.008, unit * 0.025, insetSd) * mask;
    float echoMask = channel * lowerRight * glass * (1.0 - settle);
    float3 backFace = float3(0.0);
    float logoLight = 0.0;
    if (echoMask * u.relief > 0.002) {
        float2 backNormal = normalize(mix(superNormal(insetPoint / insetHalf, insetShape), radial, 0.6));
        float backSlope = ease(0.90, 1.10, insetRadius) * 1.55 * glass * u.dropStrength;
        float2 inward = -normalize(insetPoint + float2(0.001));
        float3 backRay = refract(float3(0.0, 0.0, -1.0), normalize(float3(backNormal * backSlope, 1.0)), 1.0 / 1.38);
        float2 landing = insetPoint + backRay.xy / max(-backRay.z, 0.25) * unit * u.depth * 0.80 * lensScale;
        float reach = 0.0;
        for (int i = 0; i < 20; i++) {
            reach = float(i) * unit * lensScale * 0.03;
            if (imageAt(logo, landing + inward * reach, u.logoBox * u.artScale, u).a > 0.2) break;
        }
        float3 backCoverage = float3(0.0);
        float4 backImage = refractedLogo(insetPoint + inward * reach, backNormal * backSlope, lensScale, glass, 1.6, sd, logo, u, backCoverage);
        backFace = backImage.rgb * float3(0.03, 0.65, 1.0) * echoMask * 0.48 * u.relief * (1.0 - 0.70 * ease(0.75, 1.12, t));
        logoLight = ease(0.05, 0.6, backImage.a);
    }
    lowerRight *= logoLight;
    float wallRim = centerFade * bell(insetSd, unit * 0.0028 + aa * 0.25);
    float wallShadow = centerFade * bell(insetSd + unit * 0.008, unit * 0.005);
    float2 pores = float2(0.0);
    if (developed * cornerExposure > 0.001) {
        pores = glassPores(arc, (rimSd + unit * 0.003) / lensScale, 313.0, u);
        pores += glassPores(arc, insetSd / lensScale, 617.0, u) * 0.6 * centerFade;
        pores += glassPores(arc, (inner2Sd + unit * 0.027) / lensScale, 919.0, u) * 0.8 * centerFade;
        pores *= developed * cornerExposure;
    }
    float angle = atan2(p.y, p.x);
    float upperSliver = 0.12 + 1.15 * bell(angle - 2.18, 0.32);
    float lowerSliver = 0.12 + 1.10 * bell(angle + 0.85, 0.30);
    float tlOffset = angle - 0.75 * PI;
    float brOffset = angle + 0.25 * PI;
    float tlReach = tlOffset < 0.0 ? 0.65 : 0.42;
    float brReach = brOffset < 0.0 ? 0.65 : 0.42;
    float wallCorner = max(
        1.0 - ease(0.6 * tlReach, tlReach, abs(tlOffset)),
        1.0 - ease(0.6 * brReach, brReach, abs(brOffset))
    );
    float3 insetLight = float3(0.60, 0.78, 0.91) * wallRim * (key * key * 0.8 * upperSliver + lowerRight * lowerRight * 0.75 * lowerSliver + 0.005 + 0.35 * wallCorner * u.innerWallFocus);
    float drift = 0.7 + 0.6 * contourNoise(arc / (unit * 0.09) + 7.0);
    float filaments = (bell(innerSd + unit * 0.021, unit * 0.0035 * thickness) * 0.9 + bell(inner2Sd + unit * 0.028, unit * 0.004 / thickness) * 0.7) * centerFade + bell(rimSd + unit * 0.035, unit * 0.003 * thickness) * 0.5;
    float3 lowerRelief = (
        float3(0.03, 0.32, 1.0) * bell(sd + unit * 0.038, unit * 0.022 + aa * 0.2) * 0.55 +
        float3(0.22, 0.62, 1.0) * bell(sd + unit * 0.027, unit * 0.012 + aa * 0.1) * 0.7 +
        float3(0.75, 0.97, 1.0) * filaments * 1.35
    ) * drift * lowerRight * glass * u.highlights * u.relief * (1.0 - 0.85 * ease(0.6, 1.0, t)) * (1.0 - settle);
    lowerRelief *= 1.0 - pores.x * 0.22;
    lowerRelief += float3(0.45, 0.85, 1.0) * pores.y * 0.10 * lowerRight * glass * u.highlights * u.relief * (1.0 - settle);
    float wallLit = clamp(key * key * 0.8 * upperSliver + lowerRight * lowerRight * 0.75 * lowerSliver, 0.0, 1.0);
    float wallGate = mix(1.0, max(ease(0.2, 0.7, wallLit), wallCorner), u.pageLight * u.innerWallFocus);
    color *= 1.0 - wallShadow * wallGate * u.relief * 0.12 * (1.0 - ink.a);
    color += backFace + lowerRelief + insetLight * wallGate * glass * u.highlights * u.relief * (1.0 - ink.a) * mix(rimVisibility, 0.9, key);
    alpha = max(alpha, max(lowerRelief.r, max(lowerRelief.g, lowerRelief.b)));
    float rimLight = rim * (0.07 + key * 0.55) + inner * (0.025 + key * 0.16) + inner2 * 0.025;
    float speckSize = max(unit * 0.0042, 0.8 / u.dpr);
    float bubbles = driftingSpecks(arc, rimLineSd + unit * 0.002, speckSize, 0.0, t) * 0.9;
    bubbles += specks(arc, innerSd + unit * 0.012, speckSize * 0.8, 97.0) * 0.6 * centerFade;
    bubbles += specks(arc, insetSd, speckSize * 0.9, 191.0) * 0.5 * centerFade;
    rimLight += bubbles * (0.04 + key * 0.5 + lowerRight * 0.45);
    rimLight = rimLight * (1.0 - pores.x * 0.35) + pores.y * (key * 0.16 + lowerRight * 0.12);
    float3 spectralRim = float3(0.0);
    float3 spectralWeights = float3(0.0);
    for (int i = 0; i < BANDS; i++) {
        float s = float(i) / float(BANDS - 1);
        float3 w = spectrum(s);
        spectralRim += w * bell(rimSd + (s - 0.5) * unit * 0.011 * u.dispersion + unit * 0.003, unit * 0.002 * thickness);
        spectralWeights += w;
    }
    spectralRim /= spectralWeights;
    float3 reflection = (float3(0.6, 0.76, 0.9) * rimLight * 1.15 + spectralRim * (0.02 + ink.a * 0.32)) * u.highlights * glass * mix(rimVisibility, 1.2, key);
    float sphericalRim = (
        bell(sd + unit * lensScale * 0.008, unit * lensScale * 0.009) * 0.60 +
        bell(insetSd, unit * lensScale * 0.008) * 0.40
    ) * (0.25 + 0.75 * abs(outward.y)) * (1.0 - ease(0.235, 0.34, t));
    reflection += float3(0.65, 0.80, 0.90) * sphericalRim * 1.4 * u.highlights * glass;
    float cyanKey = pow(max(0.0, -outward.x), 8.0) * (1.0 - ease(0.235, 0.34, t));
    float cyanLip = bell(sd + unit * lensScale * 0.020, unit * lensScale * 0.009);
    cyanLip += bell(insetSd, unit * lensScale * 0.005) * 0.35;
    reflection += float3(0.015, 0.68, 1.0) * cyanLip * cyanKey * glass * u.highlights * 0.85;
    float youth = 1.0 - ease(0.25, 0.37, t);
    reflection += float3(0.78, 0.84, 0.9) * youth * 0.07 * (0.5 + 0.5 * radius) * (1.0 - ink.a) * glass;
    float3 film = mix(float3(0.32, 0.0, 0.20), float3(0.32, 0.08, 0.02), ease(0.75, 1.12, t)) * bell(sd + unit * 0.001, unit * 0.002) * ink.a * glass * u.highlights;
    color += reflection + film;
    alpha = max(alpha, max(reflection.r, max(reflection.g, reflection.b)));
    float4 result = float4(color * mask, alpha * mask);

    float outer = bell(rimSd - unit * 0.012, unit * 0.0028 * thickness) * (0.04 + key * 0.2) * (0.5 + contourNoise(arc / grainScale + 131.0));
    outer += specks(arc, rimSd - unit * 0.012, speckSize, 277.0) * (0.03 + key * 0.3 + lowerRight * 0.25);
    float waveAge = ease(0.36, 1.1, t);
    float wave = bell(sd - unit * (0.014 + 0.03 * waveAge), unit * 0.004 + aa * 0.3) * 0.05 * ease(0.34, 0.42, t) * (1.0 - waveAge);
    float3 echoTint = mix(float3(0.43, 0.62, 0.79), u.tile.rgb + (1.0 - u.tile.rgb) * 0.4, 0.5 * u.echoTint);
    float echoLevel = mix(1.0, mix(0.6, 1.0, u.pageLight), u.echoTint);
    float waveSides = mix(1.0, 0.10, ease(0.25, 0.80, abs(outward.x)));
    float3 ghost = (echoTint + ink.rgb * 0.6) * (outer + wave * waveSides) * glass * u.highlights * rimVisibility * echoLevel;
    float exterior = max(ghost.r, max(ghost.g, ghost.b)) * 1.8;
    result.rgb += exteriorColor(ghost * 1.8, exterior, u);
    result.a = max(result.a, exterior);
    return mix(result * shown, source, settle);
}

static inline float4 softenedWaves(texture2d<float> scene, float2 uv, float lod, constant CompositeUniforms &u) {
    float2 d = float2(u.dpr * 0.90) / u.resolution;
    float4 blurred = scene.sample(imageSampler, uv, level(lod)) * 0.25;
    blurred += scene.sample(imageSampler, uv + float2(d.x, 0.0), level(lod)) * 0.125;
    blurred += scene.sample(imageSampler, uv - float2(d.x, 0.0), level(lod)) * 0.125;
    blurred += scene.sample(imageSampler, uv + float2(0.0, d.y), level(lod)) * 0.125;
    blurred += scene.sample(imageSampler, uv - float2(0.0, d.y), level(lod)) * 0.125;
    blurred += scene.sample(imageSampler, uv + d, level(lod)) * 0.0625;
    blurred += scene.sample(imageSampler, uv - d, level(lod)) * 0.0625;
    blurred += scene.sample(imageSampler, uv + float2(d.x, -d.y), level(lod)) * 0.0625;
    blurred += scene.sample(imageSampler, uv + float2(-d.x, d.y), level(lod)) * 0.0625;
    return blurred;
}

} // namespace brightLiquidGlassLogo

using namespace brightLiquidGlassLogo;

vertex FSOut brightLiquidGlassLogoVertex(uint vid [[vertex_id]]) {
    float2 p = float2((vid << 1) & 2, vid & 2);
    FSOut o;
    o.position = float4(p * 2.0 - 1.0, 0.0, 1.0);
    return o;
}

fragment float4 brightLiquidGlassLogoRender(FSOut in [[stage_in]],
                                            texture2d<float> logo [[texture(0)]],
                                            constant RenderUniforms &u [[buffer(0)]]) {
    float2 fragCoord = float2(in.position.x, u.resolution.y - in.position.y);
    float2 p = (fragCoord - u.resolution * 0.5) / u.dpr;
    float4 result = iconLens(p, logo, u);
    result.a = clamp(max(result.a, max(result.r, max(result.g, result.b))), 0.0, 1.0);
    float dither = (fract(precise::sin(dot(fragCoord, float2(12.9898, 78.233))) * 43758.5453) - 0.5) / 255.0;
    return float4(clamp(result.rgb + dither * result.a, float3(0.0), float3(result.a)), result.a);
}

// The scene and the drawable share Metal's y-down origin, so the scene is sampled unflipped.
fragment float4 brightLiquidGlassLogoComposite(FSOut in [[stage_in]],
                                               texture2d<float> scene [[texture(0)]],
                                               constant CompositeUniforms &u [[buffer(0)]]) {
    float2 fragCoord = float2(in.position.x, u.resolution.y - in.position.y);
    float2 uv = in.position.xy / u.resolution;
    float4 base = scene.sample(imageSampler, uv, level(0.0));
    float offset = log2(max(u.dpr, 0.5));
    float wavePhase = smoothstep(0.29, 0.41, u.time) * (1.0 - smoothstep(1.25, 1.50, u.time));
    float waveMask = 0.0;
    if (wavePhase > 0.001) {
        float enter = smoothstep(0.025, 0.16, u.time);
        float expand = enter * (0.64 + 0.41 * (1.0 - exp(-max(u.time - 0.16, 0.0) * 5.8)));
        float collapse = 1.0 - smoothstep(1.33, 1.52, u.time);
        float lensScale = mix(expand * mix(0.48, 1.0, collapse), 1.0, smoothstep(0.0, 1.0, u.settle));
        float halfSize = max(0.001, u.unit * lensScale * 0.5);
        float shape = 2.0 + 3.0 * smoothstep(0.29, 0.36, u.time);
        float2 p = abs((fragCoord - u.resolution * 0.5) / u.dpr) / halfSize;
        float radius = pow(pow(p.x, shape) + pow(p.y, shape), 1.0 / shape);
        float distance = (radius - 1.0) * halfSize;
        waveMask = smoothstep(0.0, max(0.75, u.unit * 0.004), distance) * wavePhase;
        if (waveMask > 0.001) {
            base = mix(base, softenedWaves(scene, uv, max(0.0, offset + 0.15), u), waveMask * 0.94);
        }
    }
    float3 diffused = scene.sample(imageSampler, uv, level(offset + 2.5)).rgb * 0.50;
    diffused += scene.sample(imageSampler, uv, level(offset + 4.1)).rgb * 0.32;
    diffused += scene.sample(imageSampler, uv, level(offset + 5.4)).rgb * 0.18;
    float light = max(base.r, max(base.g, base.b));
    float effect = 1.0 - smoothstep(0.0, 1.0, u.finish);
    float3 glow = diffused * u.bloom * 0.20 * (1.0 - min(1.0, light * 1.2)) * effect * (1.0 - u.pageLight);
    float alpha = clamp(max(base.a, max(glow.r, max(glow.g, glow.b))), 0.0, 1.0);
    float grain = fract(precise::sin(dot(fragCoord + floor(u.time * 24.0), float2(12.9898, 78.233))) * 43758.5453) - 0.5;
    float3 color = base.rgb + glow + grain * 0.009 * base.a * clamp(light * 3.0 + 0.05, 0.05, 1.0) * effect * (1.0 - waveMask * 0.85);
    // Premultiplied, so laid over the page colour where the glass and logo don't cover it.
    float3 premultiplied = clamp(color, float3(0.0), float3(alpha));
    return float4(premultiplied + u.page.rgb * (1.0 - alpha), 1.0);
}
