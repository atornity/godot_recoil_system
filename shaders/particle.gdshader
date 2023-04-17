shader_type spatial;

uniform vec3 color : source_color = vec3(1., 1., 1.);
uniform float light_affect = 0.1;

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(vec4(normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz)), 0.0), vec4(0.0, 1.0, 0.0, 0.0), vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0), MODEL_MATRIX[3]);
}


void light() {
	DIFFUSE_LIGHT = vec3(ATTENUATION * ATTENUATION) * LIGHT_COLOR * light_affect;
}

void fragment() {
	ALBEDO = color;
}
