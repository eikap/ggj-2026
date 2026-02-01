shader_type canvas_item;

uniform float distortion_strength : hint_range(0.0, 0.05) = 0.01;
uniform float speed : hint_range(0.0, 5.0) = 0.6;
uniform float frequency = 3.0;

void fragment() {
    vec2 uv = UV;

    // Slow, dreamy vertical wave
    float wave = sin(uv.y * frequency + TIME * speed) * distortion_strength;

    // Apply distortion horizontally
    uv.x += wave;

    // Sample the texture with the distorted UV
    COLOR = texture(TEXTURE, uv) * COLOR;
}