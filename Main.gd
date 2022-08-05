extends Node2D

# UNAWARE, Auto is unaware of Manual tabs
# AWARE1, Auto aware of manual but cals spacing using reduced tab count (auto tabs only)
# AWARE2, Auto aware of manual but calcs spacing using full tab count (auto and manual)
enum INSERTION_MODES {UNAWARE, AWARE1, AWARE2}
var insertion_mode = INSERTION_MODES.UNAWARE
var tab_offset
var curve_length: float
var curve_baked_points: Array
var curr_tab_count: int
var curr_tab_dist: float
var TM: TabManager
var curve: Curve2D
var render_no_tab_zones = false

var shift_pressed = false
var p1 = null
var p2 = null
var min_mouse_dist = 60

onready var camera = $Camera2D
var coins = 10

func _ready():
	var btnGroup = ButtonGroup.new()
	$UiContainer/VBoxContainer2/cb_tabInsertMode1.group = btnGroup
	$UiContainer/VBoxContainer2/cb_tabInsertMode2.group = btnGroup
	$UiContainer/VBoxContainer2/cb_tabInsertMode3.group = btnGroup
	$UiContainer/VBoxContainer2/cb_tabInsertMode1.pressed = true

	create_curve()

	tab_offset = 20 * 0.5 / curve_length
	TM = TabManager.new(curve, $TabContainer)
	calc_tab_stats()

	$UiContainer/sb_byNumber.value = curr_tab_count
	$UiContainer/cb_byNumber.pressed = true

func create_curve():
	curve = Curve2D.new()
	curve.bake_interval = 1
	var points = [
		[0,0], [0, 300], [100, 300], [100, 200], [150, 200], [150, 300],
		[800, 300], [700, 0]]
	var first_point = points[0]
	for point in points:
		curve.add_point(Vector2(point[0], point[1]))

	# close the curve by adding the first point again...
	curve.add_point(Vector2(first_point[0], first_point[1]))

	curve_length = curve.get_baked_length()
	curve_baked_points = curve.get_baked_points()

func get_tab_offsets_by_number(number_of_tabs):
	var tab_pos = []
	if insertion_mode == INSERTION_MODES.AWARE1:
		number_of_tabs -= TM.tab_collection.size()
	if number_of_tabs > 0:
		var dist_between = 1 / number_of_tabs
		if insertion_mode == INSERTION_MODES.AWARE2:
			number_of_tabs -= TM.tab_collection.size()
		for i in range(number_of_tabs):
			tab_pos.append(i * dist_between + tab_offset)
	return tab_pos

func get_tab_offsets_by_distance(distance_between_tabs):
	var tab_pos = []
	if distance_between_tabs > 0 && distance_between_tabs < curve_length:
		var number_of_tabs = int(curve_length / distance_between_tabs)
		number_of_tabs -= TM.tab_collection.size()
		if number_of_tabs > 0:
			var delta_as_unit = curve_length / number_of_tabs / curve_length
			for i in range(number_of_tabs):
				tab_pos.append(i * delta_as_unit + tab_offset)
	return tab_pos

func insert_tabs_by_number(number_of_tabs):
	TM.remove_auto_tabs()
	var offsets = get_tab_offsets_by_number(number_of_tabs)
	insert_tabs_by_unit_offset(offsets)

func insert_tabs_by_distance(distance):
	TM.remove_auto_tabs()
	var offsets = get_tab_offsets_by_distance(distance)
	insert_tabs_by_unit_offset(offsets)

func insert_tabs_by_unit_offset(offsets):
	for offset in offsets:
		var skip = false
		for no_tab_zone in TM.no_tab_collection:
			if offset >= no_tab_zone[0] && offset <= no_tab_zone[1]:
				skip = true
				break
		if !skip:
			TM.insert_auto(offset)

	calc_tab_stats()

func calc_tab_stats():
	curr_tab_count = TM.tab_collection.size()
	curr_tab_dist = curve_length
	if curr_tab_count <= 0: return
	curr_tab_dist = int(curve_length / curr_tab_count)

func add_no_tab_zone(mouse_point: Vector2):
	var closest_tab = TM.get_closest_tab(mouse_point, Tab.TAB_TYPE.AUTO)
	if closest_tab:
		var offset = closest_tab.offset_unit
		TM.insert_no_tab_zone(offset - tab_offset * 2, offset + tab_offset * 2)
		#TM.remove_tabs([closest_tab])
		insert_tabs_by_number($UiContainer/sb_byNumber.value)
		update()
	get_last_no_tab_zone()

func add_two_point_no_tab_zone(pt1: Vector2, pt2: Vector2):
	var pt1_new = curve.get_closest_offset(pt1) / curve_length
	var pt2_new = curve.get_closest_offset(pt2) / curve_length
	print("%s, %s" % [pt1_new, pt2_new])
	TM.insert_no_tab_zone(pt1_new, pt2_new)
	insert_tabs_by_number($UiContainer/sb_byNumber.value)
	update()
	get_last_no_tab_zone()

func get_path_points_in_unit_range(s, e):
	var pts = []
	pts.append(curve.interpolate_baked(s * curve_length))
	for pt in curve_baked_points:
		var offset = curve.get_closest_offset(pt) / curve_length
		if offset > s && offset < e:
			pts.append(pt)
	pts.append(curve.interpolate_baked(e * curve_length))
	return pts

func _unhandled_input(event):
	# Shift key handling
	if event is InputEventKey:
		if event.scancode == KEY_SHIFT:
			shift_pressed = event.pressed

		if event.scancode == KEY_RIGHT:
			curr_no_tab_zone[0] += 0.005
			curr_no_tab_zone[1] += 0.005
			update()

		if event.scancode == KEY_LEFT:
			curr_no_tab_zone[0] -= 0.005
			curr_no_tab_zone[1] -= 0.005
			update()

	# Mouse handling
	if event is InputEventMouseButton and event.pressed:
		var mouse_point = $TabContainer.to_local(event.position)
		var closest_point = curve.get_closest_point(mouse_point)
		var click_dist = closest_point.distance_to(mouse_point)
		if event.button_index == BUTTON_LEFT:
			if click_dist < min_mouse_dist: # ensure click is somewhat close to path
				var closest_offset = curve.get_closest_offset(mouse_point)
				TM.insert_manual(closest_offset / curve_length)
		if event.button_index == BUTTON_RIGHT:
			if shift_pressed && click_dist < min_mouse_dist:
				if !p1:
					p1 = closest_point
				else:
					p2 = closest_point
					add_two_point_no_tab_zone(p1, p2)
					p1 = null
					p2 = null
			else:
				add_no_tab_zone(mouse_point)

# Zoom
#	if event is InputEventMouseButton and event.button_index == BUTTON_WHEEL_UP:
#		camera.zoom = Vector2(camera.zoom.x - 0.1, camera.zoom.x - 0.1)
#	if event is InputEventMouseButton and event.button_index == BUTTON_WHEEL_DOWN:
#		camera.zoom = Vector2(camera.zoom.x + 0.1, camera.zoom.x + 0.1)

func _draw():
	draw_set_transform($TabContainer.position, 0, Vector2(1,1))
	if curve_baked_points:
		draw_polyline(curve_baked_points, Color.black, 2, true)

	if render_no_tab_zones:
		for no_tab_zone in TM.no_tab_collection:
			#var coords = []
			#coords.append(curve.interpolate_baked(no_tab_zone[0] * curve_length))
			#coords.append(curve.interpolate_baked(no_tab_zone[1] * curve_length))
			var pts = get_path_points_in_unit_range(no_tab_zone[0], no_tab_zone[1])
			draw_polyline(pts, Color.red, 2, true)


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

func _on_btn_clearManual_pressed():
	TM.remove_manual_tabs()
	calc_tab_stats()

func _on_btn_clearAuto_pressed():
	TM.remove_auto_tabs()
	calc_tab_stats()

func _on_btn_clearAllTabs_pressed():
	TM.remove_all_tabs()
	calc_tab_stats()

func _on_btn_clearAllNoTabZones_pressed():
	TM.remove_no_tab_zones()
	update()

func _on_btn_clearEverything_pressed():
	TM.remove_all_tabs()
	TM.remove_no_tab_zones()
	update()
	calc_tab_stats()


func _on_cb_tabInsertMode1_pressed():
	insertion_mode = INSERTION_MODES.UNAWARE

func _on_cb_tabInsertMode2_pressed():
	insertion_mode = INSERTION_MODES.AWARE1

func _on_cb_tabInsertMode3_pressed():
	insertion_mode = INSERTION_MODES.AWARE2

func _on_cb_renderNoTabZones_toggled(button_pressed):
	render_no_tab_zones = button_pressed
	update()

var curr_no_tab_zone = null
var org_left_val = -1
var org_right_val = -1

func _on_HSliderLeft_value_changed(value):
	if !curr_no_tab_zone:
		get_last_no_tab_zone()
	if curr_no_tab_zone:
		curr_no_tab_zone[0] = org_left_val + value
		update()


func _on_HSliderRight_value_changed(value):
	if !curr_no_tab_zone:
		get_last_no_tab_zone()
	if curr_no_tab_zone:
		curr_no_tab_zone[1] = org_right_val + value
		update()

func get_last_no_tab_zone():
		if TM.no_tab_collection.size():
			curr_no_tab_zone = TM.no_tab_collection[-1]
			org_left_val = curr_no_tab_zone[0]
			org_right_val = curr_no_tab_zone[1]
