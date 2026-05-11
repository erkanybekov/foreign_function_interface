#include <flutter/runtime_effect.glsl>

// Canvas dimensions in pixels
uniform vec2 uSize;
// Animation time (ticker / 60.0)
uniform float uTime;

out vec4 fragColor;

void main() {
    vec2 fc = FlutterFragCoord().xy;

    // Normalised x across the full canvas width [0..1]
    float tx = fc.x / uSize.x;

    // --- Ribbon y-positions ---
    // Original Dart logic builds a polyline with 25 vertices (step 0..24),
    // where x = width * (step / 24)  →  step = tx * 24.
    // That means  step * 0.72  becomes  tx * 17.28
    //             step * 0.31  becomes  tx *  7.44
    float base0 = uSize.y * 0.28;
    float base1 = uSize.y * 0.41;
    float base2 = uSize.y * 0.54;
    // Slow curtain drift — no equivalent on the Canvas polyline path.
    float drift = sin(uTime * 0.38) * 5.0;

    float shim = sin(tx * 52.0 + uTime * 1.05) * 3.5;
    float y0 = base0 + drift * 0.35 + shim + sin(tx * 17.28 + uTime * 0.45) * 28.0
                     + cos(tx *  7.44 + uTime * 0.30) * 16.0;
    float y1 = base1 + drift * 0.55 - shim * 0.6 + sin(tx * 17.28 + uTime * 0.57) * 28.0
                     + cos(tx *  7.44 + uTime * 0.30) * 16.0;
    float y2 = base2 + drift * 0.75 + shim * 0.45 + sin(tx * 17.28 + uTime * 0.69) * 28.0
                     + cos(tx *  7.44 + uTime * 0.30) * 16.0;

    // --- Smooth ribbon falloff (slightly wider than Canvas strokes for GLSL pop) ---
    float d0 = abs(fc.y - y0);
    float d1 = abs(fc.y - y1);
    float d2 = abs(fc.y - y2);

    float r0 = max(0.0, 1.0 - d0 / 11.2);
    float r1 = max(0.0, 1.0 - d1 /  9.4);
    float r2 = max(0.0, 1.0 - d2 /  7.8);

    // Quadratic softening (matches the round-cap feel of the original)
    r0 = r0 * r0;
    r1 = r1 * r1;
    r2 = r2 * r2;

    // Scale to match the original ribbon alpha of 0.11
    r0 *= 0.11;
    r1 *= 0.11;
    r2 *= 0.11;

    // --- Colors (#6EF2B8, #69D3FF, #B692FF) ---
    vec3 col0 = vec3(0.431, 0.949, 0.722);  // #6EF2B8
    vec3 col1v = vec3(0.412, 0.827, 1.000); // #69D3FF
    vec3 col2 = vec3(0.714, 0.573, 1.000);  // #B692FF

    // Premultiplied-alpha output (RGB already scaled by per-ribbon alpha)
    vec3  col   = col0 * r0 + col1v * r1 + col2 * r2;
    float alpha = clamp(r0 + r1 + r2, 0.0, 1.0);
    fragColor = vec4(col, alpha);
}
