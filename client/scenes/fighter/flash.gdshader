shader_type canvas_item;
// A fighter's sprite in the street's light: tinted by the area's ambient
// light, a little darker toward the feet (the ground's shade) and a touch
// brighter at the head (lit from above by the street lamps), then tinted
// toward a solid colour for the white "impact flash" on a hit.
uniform vec4 flash_color : source_color = vec4(1.0);
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 ambient : source_color = vec4(1.0);
// How tall the figure stands above its feet (local y 0), in sprite pixels.
uniform float height = 62.0;
// Brightness at the feet and at the head.
uniform float feet_light = 0.82;
uniform float head_light = 1.06;

varying float rise;

void vertex() {
	rise = clamp(-VERTEX.y / max(height, 1.0), 0.0, 1.0);
}

void fragment() {
	vec4 base = texture(TEXTURE, UV) * COLOR;
	float light = mix(feet_light, head_light, smoothstep(0.0, 0.8, rise));
	vec3 lit = base.rgb * ambient.rgb * light;
	COLOR = vec4(mix(lit, flash_color.rgb, flash), base.a);
}
