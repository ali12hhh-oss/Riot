shader_type canvas_item;

uniform vec4 color_top : source_color = vec4(0.043, 0.047, 0.07, 1.0);
uniform vec4 color_bottom : source_color = vec4(0.11, 0.045, 0.03, 1.0);
uniform vec4 glow_color : source_color = vec4(1.0, 0.42, 0.24, 1.0);
uniform float speed = 0.2;

void fragment() {
	float t = TIME * speed;
	vec2 uv = UV;

	float grad = uv.y + 0.04 * sin(uv.x * 6.0 + t * 3.0);
	vec3 col = mix(color_bottom, color_top, clamp(grad, 0.0, 1.0));

	// توهج أفق نابض بالأسفل يعطي إحساس أضواء مدينة ليلية بعيدة
	float glow = smoothstep(0.82, 1.0, uv.y) * 0.35;
	glow *= 0.6 + 0.4 * sin(t * 2.0);
	col += glow_color.rgb * glow;

	// حبيبات خفيفة (Grain) لكسر التسطيح
	float grain = fract(sin(dot(uv * 500.0, vec2(12.9898, 78.233))) * 43758.5453);
	col += (grain - 0.5) * 0.015;

	COLOR = vec4(col, 1.0);
}
