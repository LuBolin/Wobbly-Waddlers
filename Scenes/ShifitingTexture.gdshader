shader_type canvas_item;

uniform float speed = 1.0; // Speed of the horizontal movement

void fragment() {
    // Get the current UV coordinates
    vec2 uv = UV;
    
    // Offset the UV coordinates based on time and speed
    uv.x -= TIME * speed;
    
    // Wrap the UV coordinates to ensure they remain in the 0–1 range
    uv.x = fract(uv.x);
    
    // Sample the default texture using the modified UV coordinates
    COLOR = texture(TEXTURE, uv);
}
