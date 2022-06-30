class_name Tab

enum TAB_TYPE {MANUAL, AUTO}
var offset_unit: float = 0
var offset_actual: float = 0
var ang_in_rad: float = 0.0
var sprite: Sprite = null
var type: int

var tab_texture = preload("res://tab.png")

func _init(p_type: int, p_curve: Curve2D, p_offset_unit: float):
	var curve_len = p_curve.get_baked_length()
	offset_unit = p_offset_unit
	offset_actual = offset_unit * curve_len
	type = p_type
	
	sprite = Sprite.new()
	sprite.texture = tab_texture
	var tab_width = sprite.texture.get_width()
	
	var p1 = p_curve.interpolate_baked(offset_actual - (tab_width * 0.05))
	var p2 = p_curve.interpolate_baked(offset_actual + (tab_width * 0.05))
	ang_in_rad = p1.angle_to_point(p2)
	
	sprite.position = p_curve.interpolate_baked(offset_actual)
	sprite.rotation = ang_in_rad
	
	if p_type == TAB_TYPE.MANUAL:
		sprite.modulate = Color(0, 0.9, 0, 1)
