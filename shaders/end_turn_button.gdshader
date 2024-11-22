shader_type canvas_item;

// Determines the blending factor between the texture and the target color.
uniform float color_factor : hint_range(0.0, 1.0, 0.01);

// Specifies the target color to blend towards.
uniform vec4 target_color : source_color = vec4(0.0, 1.0, 0.0, 1.0); // Default to green

void fragment() {
    // Sample the texture
    vec4 sample = texture(TEXTURE, UV);
    
    // Blend between the texture color and the target color
    vec3 blended_color = mix(sample.rgb, target_color.rgb, color_factor);
    
    // Maintain the original texture's alpha
    COLOR = vec4(blended_color, sample.a);
}
