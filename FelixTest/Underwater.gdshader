shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// ADD THIS:
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;

uniform sampler2D noise_tex;
uniform float distortion_strength = 0.02;
uniform float wave_speed = 0.5;
uniform float wave_scale = 3.0;

uniform vec3 water_color : source_color = vec3(0.0, 0.4, 0.6);
uniform float absorption_strength = 0.6;

uniform vec3 top_color : source_color = vec3(0.0, 0.45, 0.65);
uniform vec3 bottom_color : source_color = vec3(0.0, 0.18, 0.28);
uniform float gradient_strength : hint_range(0.0, 1.0) = 0.6;

uniform float depth_strength : hint_range(0.0, 2.0) = 1.0;
uniform float depth_offset = 0.0;