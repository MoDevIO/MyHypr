#version 330 core

in vec2 TexCoord;
out vec4 FragColor;

uniform sampler2D screenTexture;
uniform float uTime;       // elapsed time in seconds
uniform float uDuration;   // animation duration (reveal phase only)
uniform vec2  uResolution; // screen resolution (pixels), passed dynamically by the overlay

const float HOLD_TIME = 1.2; // seconds to freeze while theme applies behind

void main() {
    vec2 uv = TexCoord;

    // Sample the screenshot texture
    vec4 texColor = texture(screenTexture, uv);

    // Hold phase: show frozen screenshot, no reveal yet
    float revealTime = max(uTime - HOLD_TIME, 0.0);
    float revealDuration = uDuration - HOLD_TIME;
    float progress = clamp(revealTime / revealDuration, 0.0, 1.0);

    // Smooth easing (ease-in-out cubic)
    float t = progress < 0.5
        ? 4.0 * progress * progress * progress
        : 1.0 - pow(-2.0 * progress + 2.0, 3.0) / 2.0;

    // Compute the maximum radius needed to cover the entire screen from center
    float maxRadius = length(uResolution) * 0.5;

    // Current reveal radius
    float radius = t * maxRadius;

    // Distance from this fragment to the screen center (in pixels)
    vec2 fragPos = uv * uResolution;
    vec2 center  = uResolution * 0.5;
    float dist   = length(fragPos - center);

    // Soft edge (anti-aliased border, ~3px feather)
    float edge = smoothstep(radius - 2.0, radius + 2.0, dist);

    // Inside the circle → transparent (reveal desktop), outside → show screenshot
    // edge = 0 inside circle, edge = 1 outside
    if (edge < 0.01) {
        discard; // fully transparent — reveal the desktop beneath
    }

    FragColor = vec4(texColor.rgb, edge);
}
