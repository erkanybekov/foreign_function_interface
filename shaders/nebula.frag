#include <flutter/runtime_effect.glsl>

// Canvas dimensions in pixels
uniform vec2 uSize;
// Animation time (ticker / 60.0)
uniform float uTime;
// Galaxy scale = min(width, height) * 0.46
uniform float uScale;

out vec4 fragColor;

// --- Noise helpers ---

float hash(vec2 p) {
    p = fract(p * vec2(127.1, 311.7));
    p += dot(p, p + 74.33);
    return fract(p.x * p.y);
}

float valueNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(hash(i),               hash(i + vec2(1.0, 0.0)), f.x),
        mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x),
        f.y
    );
}

// 4-octave fractal Brownian motion
float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    vec2  shift = vec2(1.7, 9.2);
    for (int i = 0; i < 4; i++) {
        v += a * valueNoise(p);
        p  = p * 2.1 + shift;
        a *= 0.5;
    }
    return v;
}

void main() {
    vec2 fc = FlutterFragCoord().xy;
    vec2 uv = fc / uSize;

    // --- Animated cloud centers (exact match of the Dart computation) ---
    vec2 c1 = uSize * vec2(
        0.30 + sin(uTime * 0.18) * 0.04,
        0.42 + cos(uTime * 0.14) * 0.04
    );
    vec2 c2 = uSize * vec2(
        0.72 + cos(uTime * 0.11) * 0.03,
        0.62 + sin(uTime * 0.16) * 0.03
    );

    // --- Two independent FBM layers for organic shapes ---
    vec2 q = uv * 3.5;
    float n1 = fbm(q + vec2(uTime * 0.04,  uTime * 0.03));
    float n2 = fbm(q + vec2(3.7, 1.3) + vec2(-uTime * 0.03, uTime * 0.02));

    // --- Cloud 1 : blue/cyan → green  (#64D2FF → #B6F08A) ---
    float r1 = length(fc - c1) / uScale;
    // Slightly wider noise swing + edge emphasis vs Canvas radial falloff.
    float mask1 = (1.0 - smoothstep(0.0, 1.0, r1)) * (0.38 + n1 * 0.62 + 0.08 * (1.0 - r1) * n1);
    float alpha1 = mask1 * 0.21;
    vec3  col1 = mix(
        vec3(0.392, 0.824, 1.000),  // #64D2FF
        vec3(0.714, 0.941, 0.541),  // #B6F08A
        clamp(r1 / 0.34, 0.0, 1.0)
    ) * alpha1;

    // --- Cloud 2 : amber → purple  (#FFD37A → #7C8CFF) ---
    float r2 = length(fc - c2) / uScale;
    float mask2 = (1.0 - smoothstep(0.0, 1.0, r2)) * (0.32 + n2 * 0.68 + 0.06 * (1.0 - r2) * n2);
    float alpha2 = mask2 * 0.12;
    vec3  col2 = mix(
        vec3(1.000, 0.827, 0.478),  // #FFD37A
        vec3(0.486, 0.549, 1.000),  // #7C8CFF
        clamp(r2 / 0.38, 0.0, 1.0)
    ) * alpha2;

    // Premultiplied-alpha output (RGB already scaled by alpha)
    vec3  col   = col1 + col2;
    float alpha = clamp(alpha1 + alpha2, 0.0, 1.0);
    fragColor = vec4(col, alpha);
}
