class_name TabManager

var tab_collection: Array
var no_tab_collection: Array

var curve: Curve2D = null
var ui_container = null

var curve_length = 0

func _init(p_curve:Curve2D = null, p_ui_container:Node = null):
	if p_curve:
		curve = p_curve
		curve_length = curve.get_baked_length()
	if p_ui_container:
		ui_container = p_ui_container

func insert_no_tab_zone(unit_offset_start, unit_offset_end):
	var p1 = unit_offset_start
	var p2 = unit_offset_end
	if unit_offset_end < unit_offset_start:
		p1 = unit_offset_end
		p2 = unit_offset_start
		
	no_tab_collection.append([p1, p2])
	
func insert_manual(p_offset_unit: float) -> void:
	var tab = Tab.new(Tab.TAB_TYPE.MANUAL, curve, p_offset_unit)
	_finalize_tab(tab)
	
func insert_auto(p_offset_unit: float) -> void:
	var tab = Tab.new(Tab.TAB_TYPE.AUTO, curve, p_offset_unit)
	_finalize_tab(tab)

func _finalize_tab(tab: Tab) -> void:
	ui_container.add_child(tab.sprite)
	tab_collection.append(tab)
	sort_tabs_by_offset()
		
func remove_all_tabs() -> void:
	remove_manual_tabs()
	remove_auto_tabs()
	
func remove_no_tab_zones() -> void:
	no_tab_collection.clear()
	
func remove_manual_tabs() -> void:
	var remove = []
	for tab in tab_collection:
		if tab.type == Tab.TAB_TYPE.MANUAL:
			remove.append(tab)
	remove_tabs(remove)
	
func remove_auto_tabs() -> void:
	var remove = []
	for tab in tab_collection:
		if tab.type == Tab.TAB_TYPE.AUTO:
			remove.append(tab)
	remove_tabs(remove)	

func remove_tabs(tabs: Array):
	for tab in tabs:
		tab.sprite.queue_free()
		tab_collection.erase(tab)
				
func remove_tab_at_index(index: int) -> void:
	if index >= 0 && index < tab_collection.size():
		var tab = tab_collection[index]
		tab.sprite.queue_free()
		tab_collection.remove(index)
		
func get_closest_tab(point: Vector2, type = null):
	var close_enough_dist = 30
	var closest_dist = 99999
	var closest_tab = null
	for tab in tab_collection:
		if type == null || tab.type == type:
			var dist = point.distance_to(curve.interpolate_baked(tab.offset_actual))
			if dist < closest_dist && dist <= close_enough_dist:
				closest_tab = tab
				closest_dist = dist
	return closest_tab
		

func sort_tabs_by_offset() -> void:
	tab_collection.sort_custom(TabSorter, "sort_by_offset")
	
class TabSorter:	
	
	static func sort_by_offset(a:Tab, b:Tab) -> bool:
		if a.offset_unit < b.offset_unit:
			return true
		return false
