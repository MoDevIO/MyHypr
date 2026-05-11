#version 330 core

in vec2 TexCoord;
out vec4 FragColor;

uniform sampler2D screenTexture;
uniform float uTime;
uniform float uDuration;
uniform vec2 uResolution;

// First part closes the circle, last part holds fully black.
const float CLOSE_PHASE = 0.8;

void main() {
    vec2 uv = TexCoord;
    vec4 texColor = texture(screenTexture, uv);

    float closeDuration = max(uDuration * CLOSE_PHASE, 0.001);
    float progress = clamp(uTime / closeDuration, 0.0, 1.0);
    float t = progress < 0.5
        ? 4.0 * progress * progress * progress
        : 1.0 - pow(-2.0 * progress + 2.0, 3.0) / 2.0;

    float maxRadius = length(uResolution) * 0.5;
    float radius = t * maxRadius;

    vec2 fragPos = uv * uResolution;
    vec2 center = uResolution * 0.5;
    float dist = length(fragPos - center);

    // 0 inside circle, 1 outside. As radius grows, more pixels become black.
    float edge = smoothstep(radius - 2.0, radius + 2.0, dist);
    vec3 rgb = mix(vec3(0.0), texColor.rgb, edge);

    FragColor = vec4(rgb, 1.0);
}
