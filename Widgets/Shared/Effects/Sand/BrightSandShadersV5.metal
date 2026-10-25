//
//  BrightSandShadersV5.metal
//  Widgets
//

#include <metal_stdlib>
using namespace metal;

struct BrightSandUniformsV5 {
    float4 uBackColor;
    float4 uGlowColor;
    float4 uFrontColor;
    float uRotation;
    float uSpin;
    float uRadius;
    float uStrength;
    float uDecay;
    float uTurbulence;
    float uPointSizeScale;
    float uAspect;
    float uPointScale;
    float uTime;
    float uMorph;
    float uIconScale;
    float uIconDepth;
    float uIconScatter;
    float uIconDrift;
    float uIconTilt;
    float uIconGlow;
    float uIconStagger;
    float uIconSize;
    float uIconAngle;
    float uIconWobble;
    float uTouchStrength;
    float uTouchRadius;
    float uTouchFade;
    float uTouchNoise;
    float uTouchOnIcon;
    int uTouchCount;
};

struct BrightSandVOutV5 {
    float4 position [[position]];
    float pointSize [[point_size]];
    float brightness;
    float depth;
};

constant float kTimeScale = 1.0;

float hash11(uint n) {
  n = (n ^ 61u) ^ (n >> 16);
  n *= 9u;
  n = n ^ (n >> 4);
  n *= 0x27d4eb2du;
  n = n ^ (n >> 15);
  return float(n & 0x00ffffffu) / float(0x01000000u);
}

float h3(float3 p) {
  p = fract(p * float3(0.1031, 0.1030, 0.0973));
  p += dot(p, p.yxz + 33.33);
  return fract((p.x + p.y) * p.z);
}

float vnoise3(float3 x) {
  float3 i = floor(x);
  float3 f = fract(x);
  float3 w = f * f * (3.0 - 2.0 * f);
  float n000 = h3(i + float3(0,0,0));
  float n100 = h3(i + float3(1,0,0));
  float n010 = h3(i + float3(0,1,0));
  float n110 = h3(i + float3(1,1,0));
  float n001 = h3(i + float3(0,0,1));
  float n101 = h3(i + float3(1,0,1));
  float n011 = h3(i + float3(0,1,1));
  float n111 = h3(i + float3(1,1,1));
  float nx00 = mix(n000, n100, w.x);
  float nx10 = mix(n010, n110, w.x);
  float nx01 = mix(n001, n101, w.x);
  float nx11 = mix(n011, n111, w.x);
  float nxy0 = mix(nx00, nx10, w.y);
  float nxy1 = mix(nx01, nx11, w.y);
  return mix(nxy0, nxy1, w.z);
}

float fbm3(float3 p) {
  float a = 0.5;
  float v = 0.0;
  for (int i = 0; i < 4; ++i) {
    v += a * vnoise3(p);
    p *= 2.02;
    a *= 0.5;
  }
  return v;
}

float3 shape(float r1, float r2, float r3, float t, float3 dir) {
  float rr = pow(r3, 0.45);
  float disp = fbm3(dir * 2.5 + float3(0.0, 0.0, t * 0.35) + 7.13);
  rr *= 0.70 + 0.55 * disp;
  return dir * rr;
}

vertex BrightSandVOutV5 brightSandVertexV5(uint vid [[vertex_id]],
                                     device const packed_float3 *aTargets [[buffer(0)]],
                                     constant BrightSandUniformsV5 &uni [[buffer(1)]],
                                     device const float4 *touches [[buffer(2)]]) {
  BrightSandVOutV5 out;
  float3 aTarget = float3(aTargets[vid]);
  float r1 = hash11(vid * 3u + 11u);
  float r2 = hash11(vid * 3u + 23u);
  float r3 = hash11(vid * 3u + 37u);

  float theta = r1 * 6.2831853;
  float cosPhi = 2.0 * r2 - 1.0;
  float sinPhi = sqrt(max(0.0, 1.0 - cosPhi * cosPhi));
  float3 dir = float3(sinPhi * cos(theta), sinPhi * sin(theta), cosPhi);

  float t = uni.uTime * kTimeScale;

  float3 pn = shape(r1, r2, r3, t, dir);
  float3 p = pn * uni.uRadius;

  float3 wavep = pn * 4.0 + float3(t * 0.5, t * 0.4, t * 0.3);
  float3 wave = float3(fbm3(wavep + 1.7),
                   fbm3(wavep + 9.2),
                   fbm3(wavep + 17.4)) - 0.5;

  float r4 = hash11(vid * 7u + 101u);
  float m = clamp(uni.uMorph * (1.0 + uni.uIconStagger) - r4 * uni.uIconStagger, 0.0, 1.0);
  m = m * m * (3.0 - 2.0 * m);

  float3 jit = float3(hash11(vid * 13u + 5u),
                  hash11(vid * 13u + 9u),
                  hash11(vid * 13u + 17u)) - 0.5;
  float3 tgt = float3(aTarget.xy * uni.uIconScale, aTarget.z * uni.uIconDepth);
  tgt.xy += jit.xy * uni.uIconScatter;
  tgt += wave * uni.uIconDrift;
  p = mix(p, tgt, m);
  p += wave * uni.uRadius * 0.18 * uni.uTurbulence * (1.0 - m);

  float density = fbm3(p * (3.0 / max(uni.uRadius, 0.0001))
                       + float3(-t * 0.45, t * 0.25, t * 0.55));
  density = smoothstep(0.15, 0.70, density);

  float distFromCenter = length(p) / max(uni.uRadius, 0.0001);
  float falloff = exp(-uni.uDecay * 0.6 * distFromCenter);

  float pitch = (uni.uIconWobble * m) * sin(t * 0.55);
  float cp = cos(pitch), sp = sin(pitch);
  float py2 = p.y * cp - p.z * sp;
  float pz2 = p.y * sp + p.z * cp;
  p.y = py2;
  p.z = pz2;

  float ang = uni.uRotation + uni.uSpin * t + (uni.uIconTilt + uni.uIconAngle) * m;
  float c = cos(ang);
  float s = sin(ang);
  float rx = p.x * c + p.z * s;
  float rz = -p.x * s + p.z * c;
  p.x = rx;
  p.z = rz;

  float depthRaw = (p.z / max(uni.uRadius, 0.0001)) * 0.5 + 0.5;
  float depth = clamp(depthRaw, 0.0, 1.0);

  float2 pndc = float2(p.x / uni.uAspect, p.y);
  for (int i = 0; i < uni.uTouchCount; ++i) {
    float4 tp = touches[i];
    float2 d = pndc - tp.xy;
    float dist = length(d);
    float bearing = atan2(d.y, d.x);
    float lobe = fbm3(float3(cos(bearing) * 2.3, sin(bearing) * 2.3,
                           uni.uTime * 0.22 + float(i) * 4.1));
    float sigma = max(uni.uTouchRadius, 0.005)
                  * (0.45 + 1.5 * lobe) * (0.72 + 0.62 * r4);
    float ageW = exp(-tp.z * uni.uTouchFade);
    float falloffT = exp(-(dist * dist) / (sigma * sigma));
    float3 noiseSamp = float3(pndc.x * 7.0, pndc.y * 7.0, uni.uTime * 0.4 + float(i));
    float shapeNoise = fbm3(noiseSamp);
    float push = uni.uTouchStrength * mix(1.0, uni.uTouchOnIcon, m)
                 * ageW * falloffT * (0.25 + uni.uTouchNoise * shapeNoise);
    float skew = (fbm3(float3(r4 * 31.0, bearing * 1.7, uni.uTime * 0.3)) - 0.5) * 1.6;
    float cs = cos(skew), sn = sin(skew);
    float2 base = dist > 1e-5 ? d / dist : float2(1.0, 0.0);
    float2 dir2 = float2(base.x * cs - base.y * sn, base.x * sn + base.y * cs);
    pndc += dir2 * push;
  }

  out.position = float4(pndc.x, pndc.y, 0.5, 1.0);
  out.pointSize = max(1.0, uni.uPointScale * uni.uPointSizeScale * (0.65 + 0.55 * depth) * (1.0 + (uni.uIconSize - 1.0) * m));
  out.brightness = falloff * (0.35 + 0.85 * density) * uni.uStrength * 0.7
                * (0.40 + 0.60 * depth) * (1.0 + uni.uIconGlow * m);
  out.depth = depth;
  return out;
}

fragment float4 brightSandFragmentV5(BrightSandVOutV5 in [[stage_in]],
                                  float2 pointCoord [[point_coord]],
                                  constant BrightSandUniformsV5 &uni [[buffer(1)]]) {
  float2 d = pointCoord - float2(0.5);
  float r = length(d) * 2.0;
  if (r > 1.0) discard_fragment();
  float a = (1.0 - r) * in.brightness;
  float depth = in.depth;
  float3 col = mix(uni.uBackColor.rgb, uni.uGlowColor.rgb, clamp(depth * 2.0, 0.0, 1.0));
  col = mix(col, uni.uFrontColor.rgb, clamp((depth - 0.5) * 2.0, 0.0, 1.0));
  return float4(col * a, a);
}
