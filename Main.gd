extends Node2D

var tab_scene = preload("res://Path2D.tscn")
var tab_offset
var curve_length
var curve_baked_points

var curr_tab_count = 0
var curr_tab_dist

var tab_collection = []

var curve = Curve2D.new()

func _ready():

	create_curve()
	set_tab_offset()

	#var t = Tab.new(.001, "auto")

	$UiContainer/sb_byNumber.value = curr_tab_count
	$UiContainer/cb_byNumber.pressed = true

	curve_baked_points = curve.get_baked_points()

func create_curve():
	curve.bake_interval = 0.5
	var points = [
		[0,0], [0, 300], [100, 300], [100, 200], [150, 200], [150, 300],
		[800, 300], [700, 0]]
	var first_point = points[0]
	for point in points:
		curve.add_point(Vector2(point[0], point[1]))

	# close the curve by adding the first point again...
	curve.add_point(Vector2(first_point[0], first_point[1]))

	curve_length = curve.get_baked_length()

func set_tab_offset():
	var s = tab_scene.instance()
	var tab = s.get_node("PathFollow2D/Sprite")
	tab_offset = tab.texture.get_width() / 2.0 / curve_length
	clear_rendered_tabs()

func clear_rendered_tabs():
	for child in $TabContainer.get_children():
		child.queue_free()

func add_new_tab():
	var tab = tab_scene.instance()
	$TabContainer.add_child(tab)
	tab.curve = curve
	return tab

func calc_tabs_by_number(number_of_tabs):
	var tabs = []
	if number_of_tabs > 0:
		var dist_between = 1 / number_of_tabs
		for i in range(number_of_tabs):
			tabs.append(i * dist_between + tab_offset)
	return tabs

func calc_tabs_by_dist(distance_between_tabs):
	var tabs = []
	if distance_between_tabs > 0 && distance_between_tabs < curve_length:
		var number_of_tabs = int(curve_length / distance_between_tabs)
		var delta_as_unit = curve_length / number_of_tabs / curve_length
		for i in range(number_of_tabs):
			tabs.append(i * delta_as_unit + tab_offset)
	return tabs

func add_tab_at_offset(offset):
	var unit_offset = offset / curve_length
	tab_collection.append(unit_offset)
	clear_rendered_tabs()
	draw_tabs()

func draw_tabs():
	for tab_loc in tab_collection:
		var tab = add_new_tab()
		var pf = tab.get_node("PathFollow2D")
		pf.unit_offset = tab_loc

func insert_tabs_by_number(number_of_tabs):
	tab_collection = calc_tabs_by_number(number_of_tabs)
	clear_rendered_tabs()
	if number_of_tabs <= 0: return
	draw_tabs()

	curr_tab_count = number_of_tabs
	curr_tab_dist = int(curve_length / number_of_tabs)

func insert_tabs_by_distance(distance):
	tab_collection = calc_tabs_by_dist(distance)
	clear_rendered_tabs()
	if distance <= 0: return
	draw_tabs()

	curr_tab_dist = distance
	curr_tab_count = int(curve_length / distance)

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == BUTTON_LEFT:
			var local_coord = $TabContainer.to_local(event.position)
			add_tab_at_offset(curve.get_closest_offset(local_coord))

func _draw():
	draw_set_transform($TabContainer.position, 0, Vector2(1,1))
	if curve_baked_points:
		draw_polyline(curve_baked_points, Color.black, 2, true)

func _on_sb_byNumber_value_changed(value):
	insert_tabs_by_number(value)

func _on_sb_byDistance_value_changed(value):
	insert_tabs_by_distance(value)

func _on_cb_byNumber_toggled(button_pressed):
	$UiContainer/sb_byNumber.editable = button_pressed
	$UiContainer/cb_byDistance.pressed = !button_pressed
	if button_pressed:
		$UiContainer/sb_byNumber.value = curr_tab_count

func _on_cb_byDistance_toggled(button_pressed):
	$UiContainer/sb_byDistance.editable = button_pressed
	$UiContainer/cb_byNumber.pressed = !button_pressed
	if button_pressed:
		$UiContainer/sb_byDistance.value = curr_tab_dist
