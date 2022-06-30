extends Node2D

var tab_offset
var curve_length: float
var curve_baked_points: Array
var curr_tab_count: int
var curr_tab_dist: float
var TM: TabManager
var curve: Curve2D
onready var camera = $Camera2D

func _ready():

	create_curve()
	
	tab_offset = 20 * 0.5 / curve_length
	TM = TabManager.new(curve, $TabContainer)
	calc_tab_stats()
		
	$UiContainer/sb_byNumber.value = curr_tab_count
	$UiContainer/cb_byNumber.pressed = true

	curve_baked_points = curve.get_baked_points()

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

func get_tab_offsets_by_number(number_of_tabs):
	var tab_pos = []
	number_of_tabs -= TM.tab_collection.size()
	if number_of_tabs > 0:
		var dist_between = 1 / number_of_tabs
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
	#$UiContainer/sb_byNumber.value = curr_tab_count
	#$UiContainer/sb_byDistance.value = curr_tab_dist
	
func add_no_tab_zone(mouse_point: Vector2):
	var closest_tab = TM.get_closest_tab(mouse_point)
	if closest_tab:
		var offset = closest_tab.offset_unit
		TM.insert_no_tab_zone(offset - tab_offset * 2, offset + tab_offset * 2)
		print(TM.no_tab_collection)
		update()
		var offsets = []
		for tab in TM.tab_collection:
			offsets.append(tab.offset_unit)
		TM.remove_auto_tabs()
		insert_tabs_by_unit_offset(offsets)
	


func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed:
		var mouse_point = $TabContainer.to_local(event.position)
		if event.button_index == BUTTON_LEFT:
			var closest_point = curve.get_closest_point(mouse_point)
			var click_dist = closest_point.distance_to(mouse_point)
			if click_dist < 60: # ensure click is somewhat close to contour
				var closest_offset = curve.get_closest_offset(mouse_point)
				TM.insert_manual(closest_offset / curve_length)
		if event.button_index == BUTTON_RIGHT:
			add_no_tab_zone(mouse_point)
#	if event is InputEventMouseButton and event.button_index == BUTTON_WHEEL_UP:
#		camera.zoom = Vector2(camera.zoom.x - 0.1, camera.zoom.x - 0.1)
#	if event is InputEventMouseButton and event.button_index == BUTTON_WHEEL_DOWN:
#		camera.zoom = Vector2(camera.zoom.x + 0.1, camera.zoom.x + 0.1)		

func _draw():
	draw_set_transform($TabContainer.position, 0, Vector2(1,1))
	if curve_baked_points:
		draw_polyline(curve_baked_points, Color.black, 2, true)
		
	for no_tab_zone in TM.no_tab_collection:
		var no_tab_zones = []
		no_tab_zones.append(curve.interpolate_baked(no_tab_zone[0] * curve_length))
		no_tab_zones.append(curve.interpolate_baked(no_tab_zone[1] * curve_length))
		draw_polyline(no_tab_zones, Color.red, 4, true)
		

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

func _on_btn_clearAll_pressed():
	TM.remove_all_tabs()
	calc_tab_stats()

func _on_btn_clearAllNoTabZones_pressed():
	TM.remove_no_tab_zones()
	update()
