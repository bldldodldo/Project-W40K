shader_type canvas_item;

uniform vec4 Color_Head;
uniform vec4 Color_Torso;
uniform vec4 Shoulder_L;
uniform vec4 Shoulder_R;
uniform vec4 Arm_L;
uniform vec4 Arm_R;
uniform vec4 Leg_L;
uniform vec4 Leg_R;
uniform vec4 Weapon_L_main;
uniform vec4 Weapon_R;
uniform float tolerance;
uniform int spread_radius = 1; // Number of pixels the effect should spread

bool color_match(vec3 color, vec3 target, float tol) {
    return distance(color, target) < tol;
}

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    vec3 color = tex_color.rgb;
    vec4 mapped_color = tex_color; // Default to original
    bool should_recolor = false;

    // Loop through a square area to check if any neighboring pixels need recoloring
    vec2 pixel_step = vec2(0.0001); // Fixed pixel offset per step

    for (int x = -spread_radius; x <= spread_radius; x++) {
        for (int y = -spread_radius; y <= spread_radius; y++) {
            vec2 offset = vec2(float(x), float(y)) * pixel_step;
            vec4 neighbor = texture(TEXTURE, UV + offset);

            // Check if any neighbor is a key color
            if (color_match(neighbor.rgb, vec3(0.0, 0.0, 1.0), tolerance)) {
                mapped_color.rgb = Color_Head.rgb;
                should_recolor = true;
            } else if (color_match(neighbor.rgb, vec3(0.0, 1.0, 0.0), tolerance)) {
                mapped_color.rgb = Color_Torso.rgb;
                should_recolor = true;
            } else if (color_match(neighbor.rgb, vec3(1.0, 0.392, 0.392), tolerance)) {
                mapped_color.rgb = Shoulder_L.rgb;
                should_recolor = true;
            } else if (color_match(neighbor.rgb, vec3(1.0, 0.0, 0.0), tolerance)) {
                mapped_color.rgb = Shoulder_R.rgb;
                should_recolor = true;
            } else if (color_match(neighbor.rgb, vec3(1.0, 1.0, 0.0), tolerance)) {
                mapped_color.rgb = Arm_L.rgb;
                should_recolor = true;
            } else if (color_match(neighbor.rgb, vec3(1.0, 0.0, 1.0), tolerance)) {
                mapped_color.rgb = Arm_R.rgb;
                should_recolor = true;
            } else if (color_match(neighbor.rgb, vec3(0.392, 1.0, 0.392), tolerance)) {
                mapped_color.rgb = Leg_L.rgb;
                should_recolor = true;
            } else if (color_match(neighbor.rgb, vec3(0, 1.0, 1.0), tolerance)) {
                mapped_color.rgb = Leg_R.rgb;
                should_recolor = true;
            } else if (color_match(neighbor.rgb, vec3(0.392, 0.392, 1.0), tolerance)) {
                mapped_color.rgb = Weapon_L_main.rgb;
                should_recolor = true;
            }
        }
    }

    // Apply new color if any nearby pixel matched
    if (should_recolor) {
        COLOR = mapped_color;
    } else {
        COLOR = tex_color; // Keep original if no match
    }
}
