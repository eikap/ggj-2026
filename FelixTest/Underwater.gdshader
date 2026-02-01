shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform sampler2D noise_tex;
uniform float distortion_strength = 0.02;
uniform float wave_speed = 0.5;
uniform float wave_scale = 3.0;

uniform vec3 water_color : source_color = vec3(0.0, 0.4, 0.6);
uniform float absorption_strength = 0.6;

void fragment() {
    vec2 uv = SCREEN_UV;

    // Wave distortion
    float t = TIME * wave_speed;
vec2 uv1 = fract(uv * wave_scale + vec2(t * 0.5, t * 0.2));
vec2 uv2 = fract(uv * (wave_scale * 0.7) + vec2(-t * 0.3, t * 0.4));

vec2 n1 = texture(noise_tex, uv1).rg;
vec2 n2 = texture(noise_tex, uv2).rg;

vec2 noise = (n1 + n2) * 0.5;
//uv += (noise - 0.5) * distortion_strength;

    // Sample screen
    vec4 col = texture(SCREEN_TEXTURE, uv);

    // Color absorption / tint
    col.rgb = mix(col.rgb, water_color, absorption_strength);

    COLOR = col;
}