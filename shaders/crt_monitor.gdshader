shader_type canvas_item;

// Screen curvature
uniform float curvature_x : hint_range(0.0, 0.5) = 0.1;
uniform float curvature_y : hint_range(0.0, 0.5) = 0.1;

// Scanlines
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.4;
uniform float scanline_frequency : hint_range(100.0, 1000.0) = 400.0;
uniform float scanline_speed : hint_range(0.0, 10.0) = 1.0;

// Vignette
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.3;
uniform float vignette_smoothness : hint_range(0.1, 2.0) = 0.5;

// Chromatic aberration
uniform float aberration_amount : hint_range(0.0, 0.01) = 0.003;

// Phosphor glow
uniform float glow_intensity : hint_range(0.0, 1.0) = 0.1;
uniform vec3 phosphor_color = vec3(1.0, 1.0, 0.95);

// Noise and flicker
uniform float noise_intensity : hint_range(0.0, 0.5) = 0.05;
uniform float flicker_intensity : hint_range(0.0, 0.2) = 0.02;
uniform float flicker_speed : hint_range(0.1, 20.0) = 10.0;

// Screen brightness and contrast
uniform float brightness : hint_range(0.5, 1.5) = 1.0;
uniform float contrast : hint_range(0.5, 2.0) = 1.1;
uniform float saturation : hint_range(0.0, 2.0) = 0.95;

// Pixel grid
uniform float pixel_grid_intensity : hint_range(0.0, 1.0) = 0.1;
uniform vec2 pixel_grid_size = vec2(640.0, 480.0);

// Screen texture
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

// Helper functions
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

vec2 curve_uv(vec2 uv, float curve_x, float curve_y) {
    // Apply barrel distortion (bulges outward) for CRT curvature
    vec2 centered = uv * 2.0 - 1.0;
    vec2 offset = centered.xy * vec2(1.0 + centered.y * centered.y * curve_x,
                                     1.0 + centered.x * centered.x * curve_y);
    return offset * 0.5 + 0.5;
}

vec3 adjust_saturation(vec3 color, float sat) {
    float gray = dot(color, vec3(0.299, 0.587, 0.114));
    return mix(vec3(gray), color, sat);
}

void fragment() {
    vec2 uv = SCREEN_UV;

    // Apply CRT curvature
    vec2 curved_uv = curve_uv(uv, curvature_x, curvature_y);

    // Check if we're outside the curved bounds
    if (curved_uv.x < 0.0 || curved_uv.x > 1.0 || curved_uv.y < 0.0 || curved_uv.y > 1.0) {
        COLOR = vec4(0.0, 0.0, 0.0, 1.0);
    } else {

    // Apply chromatic aberration
    vec3 color;
    color.r = texture(screen_texture, curved_uv + vec2(aberration_amount, 0.0)).r;
    color.g = texture(screen_texture, curved_uv).g;
    color.b = texture(screen_texture, curved_uv - vec2(aberration_amount, 0.0)).b;

    // Apply phosphor glow
    color = mix(color, color * phosphor_color, glow_intensity);

    // Scanlines
    float scanline = sin(curved_uv.y * scanline_frequency + TIME * scanline_speed) * 0.5 + 0.5;
    scanline = mix(1.0, scanline, scanline_intensity);
    color *= scanline;

    // Horizontal scanlines (less pronounced)
    float h_scanline = sin(curved_uv.x * scanline_frequency * 0.5) * 0.5 + 0.5;
    h_scanline = mix(1.0, h_scanline, scanline_intensity * 0.3);
    color *= h_scanline;

    // Pixel grid effect
    vec2 pixel_coord = curved_uv * pixel_grid_size;
    vec2 pixel = fract(pixel_coord);
    float grid = (1.0 - step(0.98, pixel.x)) * (1.0 - step(0.98, pixel.y));
    color = mix(color * 0.9, color, mix(1.0, grid, pixel_grid_intensity));

    // Vignette
    vec2 vignette_coords = uv * (1.0 - uv);
    float vignette = pow(vignette_coords.x * vignette_coords.y * 15.0, vignette_smoothness);
    vignette = mix(1.0 - vignette_intensity, 1.0, vignette);
    color *= vignette;

    // Flicker
    float flicker = 1.0 + sin(TIME * flicker_speed) * flicker_intensity;
    color *= flicker;

    // Noise
    float noise = random(curved_uv + vec2(TIME * 0.1, TIME * 0.2));
    color += vec3(noise) * noise_intensity;

    // Brightness and contrast adjustment
    color = (color - 0.5) * contrast + 0.5;
    color *= brightness;

    // Saturation adjustment
    color = adjust_saturation(color, saturation);

    // Clamp values
    color = clamp(color, 0.0, 1.0);

    COLOR = vec4(color, 1.0);
    }
}