#include <metal_stdlib>
using namespace metal;

// The voice-reactive orb from Ricky Bharti's component vault
// (https://vault.rickybharti.com). A single fragment pass ray-casts a
// unit sphere per pixel, refracts a second ray out of its back face, and
// paints both with a procedural galaxy (band, dust lanes, three star scales, a
// pulsar), then layers an aurora, a meteor, moving lights, the semantic state
// tint and, for the layered profile, a chromatic lens along the rim.
//
// `archetype`: 0 spiral, 1 nebula, 2 core, 3 deep-field. `state`: 0 idle,
// 1 listening, 2 thinking, 3 speaking, 4 success, 5 error. `glass` > 0 selects
// the layered profile (back-face sample + rim lens); 0 is the compact one.

static float scalarHash(float value) {
    return fract(sin(value * 127.1) * 43758.5453);
}

struct BrightSolvingStarsSky {
    float resolution;
    float seed;
    float archetype;
    float detail;
    float audioPulse;
    float3 accentPrimary;
    float3 accentSecondary;
    float3 accentHighlight;
};

static float4 sampleSky(float3 direction, float time, thread const BrightSolvingStarsSky &u) {
    float longitude = atan2(direction.z, direction.x);
    float latitude = asin(clamp(direction.y, -1.0, 1.0));
    float varianceA = fract(u.seed * 7.13);
    float varianceB = fract(u.seed * 3.71);
    float varianceC = fract(u.seed * 5.37);

    float type = u.archetype >= 0.0 ? u.archetype : floor(fract(u.seed * 9.73) * 4.0);
    float nebulaType = step(0.5, type) * (1.0 - step(1.5, type));
    float coreType = step(1.5, type) * (1.0 - step(2.5, type));
    float deepType = step(2.5, type);

    float planeOffset = latitude
        + (0.15 + 0.4 * varianceA) * sin(longitude * (1.0 + floor(varianceB * 2.0)) + 1.3)
        + 0.12 * sin(longitude * 3.0 + time * 0.1);
    float band = exp(-planeOffset * planeOffset * (5.0 + 10.0 * varianceC));
    band = mix(band, max(band, 0.8), nebulaType);
    band *= 1.0 - 0.85 * deepType;

    float waveA = sin(longitude * 2.0 + sin(latitude * 3.0 + time * 0.25) * 1.6 + time * 0.15);
    float waveB = sin(longitude * 5.0 - sin(latitude * 4.0 - time * 0.2) * 1.2 - time * 0.22 + 2.4);
    float cloud = pow(0.5 + 0.5 * waveA, 2.0) * (0.45 + 0.55 * pow(0.5 + 0.5 * waveB, 2.0));
    float dustLane = pow(0.5 + 0.5 * sin(longitude * 4.0 + latitude * 7.0 + sin(longitude * 2.0) * 2.0), 3.0);
    float galaxy = clamp(band * cloud * (1.0 - dustLane * (0.55 + 0.35 * varianceB)), 0.0, 1.0);

    float3 paletteHue = mix(
        mix(u.accentPrimary, u.accentSecondary, varianceA),
        mix(u.accentSecondary, u.accentHighlight, varianceC),
        0.5 + 0.5 * sin(longitude + latitude * 2.0 - time * 0.2)
    );
    float3 greyHue = float3(dot(paletteHue, float3(0.299, 0.587, 0.114)));
    paletteHue = clamp(greyHue + (paletteHue - greyHue) * 1.45, float3(0.0), float3(1.0));
    float3 dustColor = mix(float3(0.72, 0.78, 0.92), paletteHue, 0.45 + 0.3 * varianceA + 0.45 * nebulaType);
    float3 color = dustColor * galaxy * (0.6 + 0.9 * nebulaType);

    float shear = sin(longitude * 13.0 + latitude * 4.0 - time * 0.35)
        * sin(longitude * 5.0 + time * 0.2);
    color += dustColor * band * cloud * max(shear, 0.0) * 0.14;

    float secondPlane = latitude - (0.35 + 0.25 * varianceB) * sin(longitude * 2.0 - 1.1) + 0.4;
    float secondArm = exp(-secondPlane * secondPlane * 7.0) * cloud;
    color += mix(dustColor, u.accentSecondary, 0.35) * secondArm * 0.2;

    float3 ambientColor = mix(
        float3(0.04, 0.03, 0.1),
        mix(u.accentPrimary, mix(u.accentSecondary, u.accentHighlight, varianceC), varianceA) * 0.22,
        0.75
    );
    color += ambientColor * (0.5 + 0.22 * sin(time * 0.4 + longitude)) * (0.4 + 0.6 * band);
    color += float3(1.0, 0.88, 0.68) * pow(band, 4.0) * pow(cloud, 2.0) * 0.4;

    float coreAngle = varianceB * 6.28318;
    float3 coreDirection = normalize(float3(cos(coreAngle) * 0.85, 0.6 * (varianceC - 0.5), sin(coreAngle) * 0.85));
    float bulge = max(dot(direction, coreDirection), 0.0);
    color += mix(float3(1.0, 0.85, 0.6), u.accentHighlight, 0.25)
        * (pow(bulge, 14.0) * 1.6 + pow(bulge, 4.0) * 0.5) * coreType;

    float pocketA = pow(cloud, 5.0) * band * (0.7 + 0.3 * sin(time * 0.6 + longitude * 3.0));
    color += mix(u.accentHighlight, u.accentPrimary, fract(varianceA + 0.5 * sin(longitude * 2.0) + 0.5))
        * pocketA * (0.5 + 0.4 * varianceB + 0.8 * nebulaType);
    float pocketB = pow(0.5 + 0.5 * sin(longitude * 3.0 + latitude * 4.0 - time * 0.18 + 2.0), 6.0) * band;
    color += mix(u.accentSecondary, u.accentHighlight, varianceC) * pocketB * (0.25 + 0.3 * varianceA + 0.5 * nebulaType);

    float detail = smoothstep(90.0, 200.0, u.resolution) * u.detail;
    float2 grainGrid = float2(longitude, latitude) * 34.0;
    float2 grainCell = floor(grainGrid);
    float2 grainLocal = fract(grainGrid);
    float grainHash = scalarHash(grainCell.x * 3.7 + grainCell.y * 11.3);
    float2 grainPoint = float2(
        0.2 + 0.6 * scalarHash(grainHash * 91.0),
        0.2 + 0.6 * scalarHash(grainHash * 47.0)
    );
    float grainDistance = length((grainLocal - grainPoint) * float2(cos(latitude), 1.0));
    float resolutionFactor = clamp(u.resolution / 420.0, 0.22, 1.0);
    float grain = exp(-grainDistance * grainDistance * 700.0 * resolutionFactor)
        * step(0.3, grainHash) * (0.15 + 0.85 * band);
    color += float3(0.88, 0.9, 1.0) * grain * 0.4 * detail;
    float coverage = clamp(galaxy * 0.7 + pow(band, 4.0) * 0.25, 0.0, 1.0);

    for (int scaleIndex = 0; scaleIndex < 3; scaleIndex++) {
        float scale = scaleIndex == 0 ? 6.0 : (scaleIndex == 1 ? 11.0 : 19.0);
        float2 grid = float2(longitude, latitude) * scale;
        float2 cell = floor(grid);
        float2 local = fract(grid);
        float hashX = scalarHash(cell.x * 13.7 + cell.y * 7.3 + float(scaleIndex) * 91.0);
        float hashY = scalarHash(cell.x * 5.1 + cell.y * 17.9 + float(scaleIndex) * 37.0);
        float2 starPoint = float2(0.15 + 0.7 * hashX, 0.15 + 0.7 * hashY);
        float distanceToStar = length((local - starPoint) * float2(cos(latitude), 1.0));
        float census = (varianceB - 0.5) * 0.2 + 0.35 * nebulaType - 0.2 * coreType + 0.3 * deepType;
        float threshold = scaleIndex == 2 ? 0.3 : 0.55;
        float keep = step(threshold + census, scalarHash(hashX * 89.0 + hashY * 31.0) + band * 0.25);
        float twinkle = mix(
            0.92,
            0.6 + 0.4 * sin(time * (1.5 + 3.0 * hashX) + hashX * 40.0),
            resolutionFactor
        );
        float sizeHash = scalarHash(hashX * 53.0 + hashY * 71.0 + cell.x);
        float magnitude = 0.35 + 1.8 * sizeHash * sizeHash;
        float sharpness = (scaleIndex == 0 ? 260.0 : (scaleIndex == 1 ? 700.0 : 1600.0))
            / magnitude * resolutionFactor;
        float star = exp(-distanceToStar * distanceToStar * sharpness) * keep * twinkle;
        float3 temperature = hashX < 0.33
            ? float3(0.85, 0.9, 1.0)
            : (hashX < 0.66 ? float3(1.0, 0.95, 0.85) : mix(float3(1.0), u.accentSecondary, 0.3));
        float3 tint = mix(float3(1.0), temperature, 0.6);
        float brightness = (scaleIndex == 0 ? 1.7 : (scaleIndex == 1 ? 0.9 : 0.5))
            * (0.55 + 0.7 * magnitude);
        float scaleFade = mix(scaleIndex == 2 ? 0.14 : 0.45, 1.0, detail);
        color += tint * star * brightness * scaleFade;

        if (scaleIndex == 0) {
            float largeStar = smoothstep(1.2, 2.0, magnitude);
            color += tint * exp(-distanceToStar * distanceToStar * 60.0) * 0.18 * largeStar * twinkle * scaleFade;
            float2 offset = (local - starPoint) * float2(cos(latitude), 1.0);
            float spike = exp(-offset.x * offset.x * 1200.0) * exp(-offset.y * offset.y * 26.0)
                + exp(-offset.y * offset.y * 1200.0) * exp(-offset.x * offset.x * 26.0);
            color += tint * spike * 0.3 * largeStar * twinkle * scaleFade;
            coverage = max(coverage, spike * 0.3 * largeStar * scaleFade);
        }
        coverage = max(coverage, star * min(brightness, 1.5) * scaleFade);
    }

    float pulsarAngle = varianceA * 6.28318;
    float3 pulsarDirection = normalize(float3(
        sin(pulsarAngle) * 0.9,
        1.4 * (varianceB - 0.5),
        cos(pulsarAngle) * 0.9
    ));
    float pulsarAlignment = max(dot(direction, pulsarDirection), 0.0);
    float pulse = pow(0.5 + 0.5 * sin(time * (1.2 + varianceC + 1.5 * u.audioPulse) + varianceC * 6.28), 8.0);
    pulse = min(1.0, pulse + 0.6 * u.audioPulse);
    float pulsarFade = mix(0.45, 1.0, detail);
    color += float3(0.9, 0.95, 1.0)
        * (pow(pulsarAlignment, 900.0) * (0.6 + 1.2 * pulse) + pow(pulsarAlignment, 110.0) * 0.5 * pulse)
        * pulsarFade;
    coverage = max(coverage, pow(pulsarAlignment, 900.0) * (0.5 + 0.5 * pulse) * pulsarFade);

    return float4(min(color, float3(1.0)), min(coverage, 1.0));
}

static float4 sampleRotatedSphere(float3 direction, float spin, float time, thread const BrightSolvingStarsSky &u) {
    float roll = time * 0.13;
    float rollCos = cos(roll);
    float rollSin = sin(roll);
    direction = float3(
        rollCos * direction.x - rollSin * direction.y,
        rollSin * direction.x + rollCos * direction.y,
        direction.z
    );
    float tilt = 0.45 + 0.35 * sin(time * 0.24);
    float tiltCos = cos(tilt);
    float tiltSin = sin(tilt);
    direction = float3(
        direction.x,
        tiltCos * direction.y - tiltSin * direction.z,
        tiltSin * direction.y + tiltCos * direction.z
    );
    float spinCos = cos(spin);
    float spinSin = sin(spin);
    direction = float3(
        spinCos * direction.x + spinSin * direction.z,
        direction.y,
        -spinSin * direction.x + spinCos * direction.z
    );
    return sampleSky(direction, time, u);
}

struct BrightSolvingStarsOrb {
    BrightSolvingStarsSky sky;
    float time;
    float spin;
    float audioBrightness;
    float glass;
    float intensity;
    float glow;
    float state;
    float stateBlend;
    float3 interiorColor;
    float3 baseColor;
};

static float3 shadeOrb(float2 point, thread const BrightSolvingStarsOrb &o) {
    thread const BrightSolvingStarsSky &u = o.sky;
    bool compact = o.glass <= 0.0;

    float radius = length(point);
    float clampedRadius = min(radius, 0.9995);
    float depth = sqrt(1.0 - clampedRadius * clampedRadius);
    float3 normal = float3(point.x, point.y, depth);
    float rim = pow(1.0 - depth, 2.4);

    float3 refracted = refract(float3(0.0, 0.0, -1.0), normal, 0.75);
    float backDistance = -2.0 * dot(normal, refracted);
    float3 backDirection = normalize(normal + refracted * backDistance);

    float time = o.time * 0.8 + u.seed;
    float varianceA = fract(u.seed * 6.31);
    float varianceB = fract(u.seed * 2.17);
    float warpedTime = time
        + (0.9 + 1.3 * varianceA) * sin(time * (0.09 + 0.07 * varianceB))
        + (0.5 + 0.8 * varianceB) * sin(time * (0.21 + 0.09 * varianceA) + 2.6);

    float4 front = sampleRotatedSphere(normal, o.spin, warpedTime, u);
    float4 back = compact
        ? float4(0.0)
        : sampleRotatedSphere(backDirection, o.spin, warpedTime * 0.8 + 2.7, u);

    float3 voidColor = mix(o.baseColor * 0.04, o.baseColor * 0.35, rim);
    float3 color = mix(o.interiorColor, voidColor, 0.97 - 0.04 * rim);
    float frontAlpha = clamp(front.a, 0.0, 1.0);
    float backAlpha = clamp(back.a, 0.0, 1.0);
    color = mix(color, back.rgb, backAlpha * 0.16);
    color = mix(color, front.rgb, frontAlpha * 0.85);

    float auroraLongitude = atan2(normal.x, normal.z);
    float speechWave = pow(
        0.5 + 0.5 * sin(auroraLongitude * 3.0 + sin(auroraLongitude * 7.0 + time * 1.1) * 0.7 + time * 0.5),
        3.0
    ) * (0.55 + 0.45 * sin(auroraLongitude * 5.0 - time * 0.65 + 1.7));
    float visibleSky = -normal.y;
    float hangingMask = smoothstep(-0.15, 0.5, visibleSky);
    float rayPattern = 0.7 + 0.3 * sin(
        auroraLongitude * 24.0 + sin(auroraLongitude * 9.0 - time * 0.8) * 2.0 + time * 1.6
    );
    float aurora = clamp(speechWave, 0.0, 1.0) * hangingMask * rayPattern * (1.0 + 2.2 * u.audioPulse);
    float auroraVariance = fract(u.seed * 2.93);
    float3 auroraColor = mix(
        float3(0.12, 0.95, 0.55),
        float3(0.45, 0.35, 1.0),
        smoothstep(0.0, 0.95, visibleSky + 0.35 * speechWave)
    );
    auroraColor = mix(auroraColor, mix(u.accentPrimary, u.accentHighlight, auroraVariance), 0.15 + 0.4 * auroraVariance);
    color += auroraColor * aurora * 0.8;

    float meteorPeriod = 4.5 + 3.5 * fract(u.seed * 4.91);
    float meteorEpoch = floor(time / meteorPeriod);
    float meteorPhase = fract(time / meteorPeriod);
    float2 meteorStart = float2(
        -1.1 + 2.2 * scalarHash(meteorEpoch * 1.3),
        0.85 - 1.4 * scalarHash(meteorEpoch * 2.9)
    );
    float2 meteorDirection = normalize(float2(
        0.7 + 0.5 * scalarHash(meteorEpoch * 4.1),
        -0.35 - 0.4 * scalarHash(meteorEpoch * 5.3)
    ));
    float2 meteorHead = meteorStart + meteorDirection * meteorPhase * 2.8;
    float2 meteorRelative = point - meteorHead;
    float meteorAlong = dot(meteorRelative, meteorDirection);
    float meteorPerpendicular = dot(meteorRelative, float2(-meteorDirection.y, meteorDirection.x));
    float meteorVisible = smoothstep(0.0, 0.06, meteorPhase) * smoothstep(0.5, 0.32, meteorPhase);
    float meteorTail = exp(-meteorPerpendicular * meteorPerpendicular * 1600.0)
        * exp(meteorAlong * 9.0) * step(meteorAlong, 0.0) * smoothstep(-0.5, -0.02, meteorAlong);
    float meteorGlow = exp(-dot(meteorRelative, meteorRelative) * 900.0);
    color += (float3(1.0) * meteorGlow * 1.2 + mix(float3(1.0), u.accentSecondary, 0.3) * meteorTail * 0.85)
        * meteorVisible;

    float3 movingLight = normalize(float3(
        0.85 * sin(time * 0.42),
        0.45 * sin(time * 0.26 + 1.2),
        0.5
    ));
    float diffuse = (0.62 + 0.65 * max(dot(normal, movingLight), 0.0)) * (1.0 + 0.35 * o.audioBrightness);
    color *= diffuse;
    float3 voiceColor = mix(u.accentSecondary, float3(1.0, 0.97, 0.9), 0.45);
    color += voiceColor * pow(1.0 - clampedRadius, 1.8) * o.audioBrightness * 0.5;
    color += (u.accentSecondary * 0.7 + float3(0.12)) * rim * o.audioBrightness * 0.65 * o.glow;
    color += color * o.audioBrightness * 0.18 * sin(time * 14.0 + clampedRadius * 40.0 + u.seed * 7.0);
    float counterLight = max(dot(normal.xy, -movingLight.xy), 0.0) * rim;
    color += mix(u.accentPrimary, float3(0.5, 0.6, 0.9), 0.5) * counterLight * 0.18 * o.glow;

    float3 keyDirection = normalize(float3(
        -0.45 + 0.3 * sin(time * 0.34),
        0.62 + 0.2 * sin(time * 0.27 + 1.7),
        0.64
    ));
    float keyStrength = 0.5 * (0.78 + 0.22 * sin(time * 0.45 + 2.2));
    color += float3(1.0) * pow(max(dot(normal, keyDirection), 0.0), 150.0) * keyStrength * o.glow;
    float3 sheenDirection = normalize(float3(sin(time * 0.07) * 0.9, 0.35 + 0.3 * cos(time * 0.05), 0.7));
    color += float3(1.0) * pow(max(dot(normal, sheenDirection), 0.0), 7.0) * 0.05 * o.glow;
    float3 glintDirection = normalize(float3(0.52, -0.5 + 0.12 * sin(time * 0.09), 0.69));
    color += float3(1.0) * pow(max(dot(normal, glintDirection), 0.0), 140.0) * 0.25 * o.glow;
    color = mix(color, front.rgb, frontAlpha * rim * 0.3);

    float listeningState = step(0.5, o.state) * (1.0 - step(1.5, o.state));
    float thinkingState = step(1.5, o.state) * (1.0 - step(2.5, o.state));
    float successState = step(3.5, o.state) * (1.0 - step(4.5, o.state));
    float errorState = step(4.5, o.state);
    float statePulse = 0.5 + 0.5 * sin(time * (1.1 + thinkingState * 0.7));
    float stateStrength = o.stateBlend * (
        listeningState * 0.12
        + thinkingState * (0.08 + 0.1 * statePulse)
        + successState * 0.22
        + errorState * 0.18
    );
    float3 stateColor = mix(u.accentPrimary, u.accentSecondary, thinkingState * statePulse);
    stateColor = mix(stateColor, u.accentHighlight, successState);
    stateColor = mix(stateColor, float3(1.0, 0.08, 0.05), errorState);
    color += stateColor * (0.15 + 0.85 * rim) * stateStrength * o.glow;

    color *= o.intensity;
    float limb = smoothstep(0.94, 1.0, clampedRadius);
    return mix(color, color * 0.85, limb * 0.4);
}

// The web canvas is clipped by a CSS circle mask with a half-pixel soft edge;
// the same coverage is folded into the premultiplied output here.
[[ stitchable ]] half4 brightSolvingStars(
    float2 position,
    half4 inColor,
    float2 size,
    float resolution,
    float time,
    float seed,
    float archetype,
    float glass,
    float intensity,
    float detail,
    float glow,
    float spin,
    float audioBrightness,
    float audioPulse,
    float state,
    float stateBlend,
    float3 interiorColor,
    float3 baseColor,
    float3 accentPrimary,
    float3 accentSecondary,
    float3 accentHighlight
) {
    // GL's texture space runs bottom-up; flipping y keeps the sky's
    // orientation identical to the web render.
    float2 uv = position / size;
    float2 point = float2(uv.x * 2.0 - 1.0, 1.0 - uv.y * 2.0);
    float radius = length(point);
    float edge = 1.0 / max(size.y * 0.5, 1.0);
    float coverage = 1.0 - smoothstep(1.0 - edge, 1.0, radius);
    if (coverage <= 0.0) return half4(0.0);

    BrightSolvingStarsOrb o;
    o.sky.resolution = resolution;
    o.sky.seed = seed;
    o.sky.archetype = archetype;
    o.sky.detail = detail;
    o.sky.audioPulse = audioPulse;
    o.sky.accentPrimary = accentPrimary;
    o.sky.accentSecondary = accentSecondary;
    o.sky.accentHighlight = accentHighlight;
    o.time = time;
    o.spin = spin;
    o.audioBrightness = audioBrightness;
    o.glass = glass;
    o.intensity = intensity;
    o.glow = glow;
    o.state = state;
    o.stateBlend = stateBlend;
    o.interiorColor = interiorColor;
    o.baseColor = baseColor;

    float3 color;
    bool lensed = false;
    if (glass > 0.0) {
        float exponential = exp(2.0 * 1.7724539 * (radius - 0.9) / 0.1414214);
        float edgeFalloff = 0.5 + 0.5 * (exponential - 1.0) / (exponential + 1.0);
        if (edgeFalloff > 0.004) {
            float lensPulse = 1.0 + 0.16 * (
                0.6 * sin(time * 0.9 + seed)
                + 0.4 * sin(time * 1.7 + seed * 1.3)
            );
            float displacement = glass * edgeFalloff * lensPulse;
            float redShift = 1.4 * (1.0 + 0.06 * sin(time * 1.3 + seed));
            float greenShift = 1.2 * (1.0 + 0.06 * sin(time * 1.3 + seed + 2.1));
            float blueShift = 1.0 * (1.0 + 0.06 * sin(time * 1.3 + seed + 4.2));
            color = float3(
                shadeOrb(point * (1.0 - displacement * redShift), o).r,
                shadeOrb(point * (1.0 - displacement * greenShift), o).g,
                shadeOrb(point * (1.0 - displacement * blueShift), o).b
            );
            float2 absolutePoint = min(abs(point), float2(1.0));
            float lobe = max(
                abs(absolutePoint.x * 0.766 + absolutePoint.y * 0.643),
                abs(absolutePoint.x * 0.766 - absolutePoint.y * 0.643)
            );
            float lensGlow = 0.65 * pow(clamp((lobe - 0.0707) / 1.3435, 0.0, 1.0), 2.4) * edgeFalloff;
            lensGlow += 1.02 * clamp(1.0 + (radius - 1.0) / 0.15, 0.0, 1.0)
                * step(radius, 1.0) * pow(lobe, 2.0);
            color += float3(0.25) * min(lensGlow, 1.0) * glow;
            lensed = true;
        }
    }
    if (!lensed) {
        color = shadeOrb(point, o);
    }

    return half4(half3(clamp(color, float3(0.0), float3(1.0)) * coverage), half(coverage));
}
