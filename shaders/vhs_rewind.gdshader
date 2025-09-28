shader_type canvas_item;

uniform float strength : hint_range(0.0, 1.0) = 0.5;
uniform float time_scale : hint_range(0.1, 10.0) = 3.0;
uniform float distortion_amount : hint_range(0.0, 0.5) = 0.1;
uniform float noise_amount : hint_range(0.0, 1.0) = 0.3;
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.4;
uniform float chromatic_aberration : hint_range(0.0, 0.05) = 0.02;
uniform float tracking_offset : hint_range(-0.5, 0.5) = 0.0;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

// Noise function
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

// Value noise
float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

void fragment() {
    vec2 uv = SCREEN_UV;
    float time = TIME * time_scale;

    // VHS tracking distortion (horizontal shift)
    float tracking_noise = noise(vec2(0.0, uv.y * 3.0 + time * 2.0));
    uv.x += tracking_offset * tracking_noise * strength;

    // Horizontal distortion bands (rewind effect)
    float distort_band = sin(uv.y * 20.0 + time * 10.0);
    float distort_amount = distortion_amount * strength;
    uv.x += distort_band * distort_amount * (0.5 + 0.5 * sin(time * 7.0));

    // Wave distortion - higher frequency, lower amplitude
    float wave = sin(uv.y * 80.0 - time * 40.0) * 0.001 * strength;
    uv.x += wave;

    // Vertical hold issues
    float vertical_hold = sin(time * 4.0) * 0.01 * strength;
    uv.y += vertical_hold;

    // Chromatic aberration (RGB split)
    float aberration = chromatic_aberration * strength;
    vec3 color;
    color.r = texture(screen_texture, uv + vec2(aberration, 0.0)).r;
    color.g = texture(screen_texture, uv).g;
    color.b = texture(screen_texture, uv - vec2(aberration, 0.0)).b;

    // Add noise
    float noise_val = random(uv + vec2(time * 0.1, time * 0.2));
    color += vec3(noise_val) * noise_amount * strength * 0.5;

    // Scanlines
    float scanline = sin(uv.y * 800.0) * 0.5 + 0.5;
    scanline = mix(1.0, scanline, scanline_intensity * strength);
    color *= scanline;

    // Random horizontal lines (tracking errors)
    float line_noise = step(0.98, random(vec2(uv.y * 10.0, time * 3.0)));
    color = mix(color, vec3(random(vec2(uv.y, time))), line_noise * strength);

    // Color degradation
    color = mix(color, vec3(dot(color, vec3(0.299, 0.587, 0.114))), 0.3 * strength);

    // Output
    COLOR = vec4(color, 1.0);
}