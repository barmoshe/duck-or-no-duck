class_name NightLayer
extends CanvasLayer
## Night: everything outside a circle around you goes dark (Crab's night), with a
## Bayer-dithered edge so it stays pixel art. Night Vision and More Eyes widen the circle.

const SHADER := "shader_type canvas_item;
uniform vec2 view_size = vec2(480.0, 270.0);
uniform vec2 center = vec2(240.0, 135.0);
uniform float radius = 80.0;
uniform float dark = 0.0;
float bayer4(vec2 p) {
	int x = int(mod(p.x, 4.0));
	int y = int(mod(p.y, 4.0));
	int m[16] = int[16](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);
	return float(m[y * 4 + x]) / 16.0;
}
void fragment() {
	vec2 p = floor(UV * view_size);
	float d = length(p - center);
	float edge = clamp((d - radius) / 34.0, 0.0, 1.0);
	float a = edge > bayer4(p) ? 0.9 : 0.25 * edge;
	COLOR = vec4(0.04, 0.03, 0.1, a * dark);
}"

var world: World
var rect: ColorRect
var mat: ShaderMaterial


func _ready() -> void:
	layer = 3
	rect = ColorRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	var sh := Shader.new()
	sh.code = SHADER
	mat = ShaderMaterial.new()
	mat.shader = sh
	rect.material = mat
	add_child(rect)


func _process(_dt: float) -> void:
	if world == null or world.run == null or world.player == null or not world.running:
		rect.visible = false
		return
	var dark := world.run.darkness()
	rect.visible = dark > 0.01
	if not rect.visible:
		return
	rect.position = Vector2.ZERO
	rect.size = world.get_viewport_rect().size
	var vs := rect.size
	var sp := world.get_viewport().canvas_transform * (world.player.position + Vector2(0, -world.player.r))
	mat.set_shader_parameter("view_size", vs)
	mat.set_shader_parameter("center", sp.floor())
	mat.set_shader_parameter("radius", world.run.vision())
	mat.set_shader_parameter("dark", dark)
