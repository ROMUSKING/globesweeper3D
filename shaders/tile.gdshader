shader_type spatial;

// Material Properties
uniform float roughness : hint_range(0.0, 1.0) = 0.5;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float rim_strength : hint_range(0.0, 1.0) = 0.5;

// Colors
uniform vec3 u_base_color : source_color = vec3(0.3, 0.3, 0.35); // Unrevealed
uniform vec3 u_revealed_color : source_color = vec3(0.8, 0.8, 0.8); // Revealed (dynamic)
uniform vec3 u_flag_color : source_color = vec3(1.0, 0.2, 0.2); // Flagged
uniform vec3 u_mine_color : source_color = vec3(0.8, 0.1, 0.1); // Mine

// State
// 0.0 = Hidden
// 1.0 = Revealed
// 2.0 = Flagged
// 3.0 = Mine (Revealed)
uniform float u_state = 0.0;

void fragment() {
    vec3 final_albedo = u_base_color;
    float final_roughness = roughness;
    float final_metallic = metallic;

    if (abs(u_state - 1.0) < 0.1) {
        // Revealed
        final_albedo = u_revealed_color;
        final_roughness = 0.8;
        final_metallic = 0.0;
    } else if (abs(u_state - 2.0) < 0.1) {
        // Flagged
        final_albedo = u_flag_color;
        final_roughness = 0.5;
        final_metallic = 0.1;
    } else if (abs(u_state - 3.0) < 0.1) {
        // Mine
        final_albedo = u_mine_color;
        final_roughness = 0.4;
        final_metallic = 0.5;
    }

    // Rim Light (Fresnel)
    float fresnel = pow(1.0 - dot(NORMAL, VIEW), 3.0);
    vec3 rim_color = vec3(0.5, 0.8, 1.0); // Light blue rim
    
    // Mix rim lighting based on state (stronger on unrevealed/techy looking tiles)
    if (abs(u_state - 0.0) < 0.1) {
         final_albedo += rim_color * fresnel * rim_strength;
    }

    ALBEDO = final_albedo;
    ROUGHNESS = final_roughness;
    METALLIC = final_metallic;
}