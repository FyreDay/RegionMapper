extends Node2D

signal popup_opened
signal popup_closed
signal hovered_region_update
signal hovered_entrance_update
signal save_data_ready

var region_scene = preload("res://region.tscn")
var entrance_scene = preload("res://entrance.tscn")
var isDrawingRegion = false
var isDrawingEntrance = false
var dragStartMousePos: Vector2
var dragSizeVector: Vector2
var isMerging = false
var mergingRegion = null
var hovered_region = null
var entrance_from_region = null
var index = 0

var undo_redo := UndoRedo.new()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    draw_region(delta)
    draw_entrance(delta)
    get_hovered_object()

func get_hovered_object():
    var mouse_pos := get_global_mouse_position()
    var result = null
    var highest_z := -INF

    for child in get_children():
        if child.has_method("is_mouse_over") and child.is_mouse_over(mouse_pos):
            if child.z_index >= highest_z:
                highest_z = child.z_index
                result = child
    if result != null and result.has_method("get_controller"):
        hovered_region = result.get_controller()
        hovered_region_update.emit(result, hovered_region)
        hovered_entrance_update.emit(null)
    elif result != null and result is Entrance:
        hovered_entrance_update.emit(result)
    else:
        hovered_region = null
        hovered_entrance_update.emit(null)
        hovered_region_update.emit(null, null)
    return result

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("open_object_menu"):
        if Input.is_key_pressed(KEY_SHIFT):
            return
        var object = get_hovered_object()
        if object:
            object.open_edit_menu()
    if event.is_action_pressed("click"):
        var object = get_hovered_object()
        if isMerging and object is Region:
            if object.is_merge_valid(mergingRegion):
                undo_redo.create_action("Merge Region")
                undo_redo.add_do_method(do_region_merge.bind(object, mergingRegion))
                undo_redo.add_undo_method(undo_region_merge.bind(object.snapshot_regions(), mergingRegion.snapshot_regions()))
                undo_redo.commit_action()
            isMerging = false
    if event.is_action_pressed("redo"):
        undo_redo.redo()
        return
    if event.is_action_pressed("undo"):
        undo_redo.undo()
   
    
    

func _draw() -> void:
    if isDrawingRegion:
        draw_rect(Rect2(dragStartMousePos, dragSizeVector), Color(1,1,1,.5))
    if isDrawingEntrance:
        var duel_directonal = Input.is_key_pressed(KEY_CTRL)
        var arrow_length := 15.0
        var arrow_width := 8.0
        
        var start := dragStartMousePos
        var end := dragStartMousePos + dragSizeVector
        
        # Direction and perpendicular
        var direction := (end - start).normalized()
        var perpendicular := Vector2(-direction.y, direction.x)
        end = end - direction * arrow_length
        if duel_directonal:
            start = start + direction * arrow_length
        draw_line(start, end, Color.BLACK, 8, true)
        
        

        if duel_directonal:
            draw_colored_polygon(
                PackedVector2Array([
                    start + 2 * direction - direction * arrow_length, 
                    start + 2 * direction + perpendicular * arrow_width, 
                    start + 2 * direction - perpendicular * arrow_width
                ]),
                Color.BLACK
            )
        draw_colored_polygon(
            PackedVector2Array([
                end - 2 * direction + direction * arrow_length,
                end - 2 * direction + perpendicular * arrow_width, 
                end - 2 * direction - perpendicular * arrow_width
                ]),
            Color.BLACK
        )

        draw_line(start - direction * 2, end + direction * 2, Color.WHITE, 6, true)
        var inner_length := 12.0
        var inner_width := 6.0
        if duel_directonal:
            draw_colored_polygon(
                PackedVector2Array([
                    start + direction * 1 - direction * inner_length, 
                    start + direction * 1 + perpendicular * inner_width, 
                    start + direction * 1 - perpendicular * inner_width
                ]),
                Color.WHITE
            )

        draw_colored_polygon(
            PackedVector2Array([
                end - direction * 1 + direction * inner_length, 
                end - direction * 1 + perpendicular * inner_width, 
                end - direction * 1 - perpendicular * inner_width
                ]),
            Color.WHITE
        )
    

func draw_region(_delta):
    if isDrawingEntrance:
        return
        
    if !isDrawingRegion and Input.is_action_just_pressed("draw_region"):
        if not Input.is_key_pressed(KEY_SHIFT):
            return
        dragStartMousePos = get_global_mouse_position()
        isDrawingRegion = true
        isMerging = false
        
    if isDrawingRegion and Input.is_action_just_released("draw_region"):
        isDrawingRegion = false
        if abs(dragSizeVector.x) < 20:
            dragSizeVector.x = 20 * sign(dragSizeVector.x)
        if abs(dragSizeVector.y) < 20:
            dragSizeVector.y = 20 * sign(dragSizeVector.y)
            
        create_region(Rect2(dragStartMousePos, dragSizeVector))
        queue_redraw()
        
    if isDrawingRegion:
        dragSizeVector = get_global_mouse_position() - dragStartMousePos
        queue_redraw()
        
func create_region(rect: Rect2):
    var region = region_scene.instantiate()
    
    var name_base = 'Region'
    var new_name = name_base
    while not is_valid_region_name(new_name):
        index += 1
        new_name = name_base + ' ' + str(index)
    
    region.setup(rect, new_name)
    connect_region_signals(region)
    undo_redo.create_action("Create Region")
    undo_redo.add_do_method(add_child.bind(region))
    undo_redo.add_undo_method(remove_child.bind(region))
    undo_redo.commit_action()

func connect_region_signals(region):
    region.popup_opened.connect(_on_popup_opened)
    region.popup_closed.connect(_on_popup_closed)
    region.delete_region.connect(_on_delete_region)
    region.merge_start.connect(_on_merge_start)
    region.name_change_request.connect(_on_region_name_change_requested)
    region.color_change_request.connect(_on_region_color_change_requested)
    region.drag_ended.connect(_on_region_drag_ended)
    region.resize_ended.connect(_on_region_resize_ended)
    region.drag_moved.connect(_on_drag_moved)
    #region.resize_moved.connect(_on_resize_moved)

func draw_entrance(_delta):
    if isDrawingRegion:
        return
    if !isDrawingEntrance and Input.is_action_just_pressed("draw_entrance"):
        if not Input.is_key_pressed(KEY_SHIFT) or hovered_region == null:
            return
        dragStartMousePos = get_global_mouse_position()
        entrance_from_region = hovered_region
        isDrawingEntrance = true
        isMerging = false
        
    if isDrawingEntrance and Input.is_action_just_released("draw_entrance"):
        isDrawingEntrance = false
        if hovered_region == null or hovered_region == entrance_from_region:
            queue_redraw()
            return
        var duel_directonal = Input.is_key_pressed(KEY_CTRL)
        var start := dragStartMousePos
        var end := dragStartMousePos + dragSizeVector
        create_entrance(entrance_from_region, hovered_region, start, end, duel_directonal)
        queue_redraw()
        
    if isDrawingEntrance:
        dragSizeVector = get_global_mouse_position() - dragStartMousePos
        queue_redraw()
        
func create_entrance(from_region, to_region, from_pos, to_pos, dual_directional):
    var entrance = entrance_scene.instantiate()
    var name_base = from_region.region_name + " To " + to_region.region_name
    var new_name = name_base
    while not is_valid_entrance_name(new_name):
        index += 1
        new_name = name_base + ' (' + str(index) + ')'
    entrance.setup(from_region, to_region, from_pos, to_pos, dual_directional, new_name)
    connect_entrance_signals(entrance)
    undo_redo.create_action("Create Entrance")
    undo_redo.add_do_method(add_child.bind(entrance))
    undo_redo.add_undo_method(remove_child.bind(entrance))
    undo_redo.commit_action()

func connect_entrance_signals(entrance):
    entrance.popup_opened.connect(_on_popup_opened)
    entrance.popup_closed.connect(_on_popup_closed)
    entrance.delete_entrance.connect(_on_delete_entrance)
    entrance.name_change_request.connect(_on_entrance_name_change_requested)
    entrance.endpoint_drag_ended.connect(on_endpoint_drag_end)
    hovered_region_update.connect(entrance._on_hovered_region)

func do_region_merge(region, new_parent_region):
    region.do_merge(new_parent_region)

func restore_regions(snapshot):
    for region in snapshot:
        var state = snapshot[region]

        region.is_merge_controller = state.is_merge_controller
        region.merge_controller = state.merge_controller
        region.region_references = state.region_references.duplicate()
        region.region_name = state.region_name
        region.region_color = state.region_color
        region.queue_redraw()
        
func undo_region_merge(region_state1, region_state2):
    restore_regions(region_state1)
    restore_regions(region_state2)


func _on_popup_opened() -> void:
    popup_opened.emit()


func _on_popup_closed() -> void:
    popup_closed.emit()

func _on_delete_region(region) -> void:
    undo_redo.create_action("Delete Region")
    undo_redo.add_do_method(delete_region_and_reference.bind(region))
    undo_redo.add_undo_method(redo_region_and_reference.bind(region))
    undo_redo.commit_action()

func delete_region_and_reference(region):
    if not region.is_merge_controller:
        region.merge_controller.remove_region_reference(region) 
    remove_child.call_deferred(region)
    
func redo_region_and_reference(region):
    if not region.is_merge_controller:
        region.merge_controller.add_region_reference(region) 
    add_child(region)

func _on_merge_start(region):
    isMerging = true
    mergingRegion = region
    

func is_valid_region_name(new_name):
    if new_name.contains('"') or new_name.contains('/') or new_name.contains('\\'):
        return false
    for child in get_children():
        if child is Region:
            if child.region_name == new_name:
                return false
    return true
    
func _on_region_name_change_requested(region, new_name):
    var old_name = region.region_name
    if not is_valid_region_name(new_name):
        var style = region.name_edit.get_theme_stylebox("normal").duplicate()
        style.border_color = Color.RED
        style.set_border_width_all(2)

        region.name_edit.add_theme_stylebox_override("normal", style)
        return
    else:
        region.name_edit.remove_theme_stylebox_override("normal")
    undo_redo.create_action("Change Region Name")

    undo_redo.add_do_method(region.set_region_name.bind(new_name))
    undo_redo.add_undo_method(region.set_region_name.bind(old_name))

    undo_redo.commit_action()
    
func _on_region_color_change_requested(region, new_color, old_color):

    undo_redo.create_action("Change Region Color")

    undo_redo.add_do_method(region.set_region_color.bind(new_color))
    undo_redo.add_undo_method(region.set_region_color.bind(old_color))

    undo_redo.commit_action()
    
func _on_region_drag_ended(region, old_pos, new_pos):
    undo_redo.create_action("Drag Region")
    undo_redo.add_do_method(region.set_rect_pos.bind(new_pos))
    undo_redo.add_undo_method(region.set_rect_pos.bind(old_pos))
    undo_redo.commit_action()
    
func _on_region_resize_ended(region, old_size, new_size):
    undo_redo.create_action("Resize Region")
    undo_redo.add_do_method(region.set_rect_size.bind(new_size))
    undo_redo.add_undo_method(region.set_rect_size.bind(old_size))
    undo_redo.commit_action()
    
func _on_drag_moved(region, old_pos, offset):
    for child in get_children():
        if child is Entrance:
            if child.to_region == region:
                if old_pos.has_point(to_local(child.to_pos)):
                    child.set_offset(Entrance.endpoints.TO_ENDPOINT, offset)
            if child.from_region == region:
                if old_pos.has_point(to_local(child.from_pos)):
                    child.set_offset(Entrance.endpoints.FROM_ENDPOINT, offset)
            
func _on_delete_entrance(entrance):
    
    undo_redo.create_action("Delete Entrance")
    undo_redo.add_do_method(remove_child.bind(entrance))
    undo_redo.add_undo_method(add_child.bind(entrance))
    undo_redo.commit_action()
    
func on_endpoint_drag_end(entrance, endpoint, old_pos, new_pos):
    undo_redo.create_action("Move Endpoint")
    undo_redo.add_do_method(entrance.set_endpoint.bind(endpoint, new_pos))
    undo_redo.add_undo_method(entrance.set_endpoint.bind(endpoint, old_pos))
    undo_redo.commit_action()

func is_valid_entrance_name(new_name):
    if new_name.contains('"') or new_name.contains('/') or new_name.contains('\\'):
        return false
    for child in get_children():
        if child is Entrance:
            if child.entrance_name == new_name:
                return false
    return true
    
func _on_entrance_name_change_requested(entrance, new_name):
    var old_name = entrance.entrance_name
    if not is_valid_entrance_name(new_name):
        var style = entrance.name_edit.get_theme_stylebox("normal").duplicate()
        style.border_color = Color.RED
        style.set_border_width_all(2)

        entrance.name_edit.add_theme_stylebox_override("normal", style)
        return
    else:
        entrance.name_edit.remove_theme_stylebox_override("normal")
    undo_redo.create_action("Change Entrance Name")

    undo_redo.add_do_method(entrance.set_entrance_name.bind(new_name))
    undo_redo.add_undo_method(entrance.set_entrance_name.bind(old_name))

    undo_redo.commit_action()
    
func string_to_id(text: String) -> String:
    # Replace spaces and hyphens with underscores
    var sanitized = text.strip_edges().replace(" ", "_").replace("-", "_").replace("'", "")
    # Convert the entire string to uppercase
    return sanitized.to_upper()
    
func save_data():
    var data = {
        "regions": [],
        "entrances": []
    }  
    var region_ids := {}

    for child in get_children():
        if child is Region:
            region_ids[child] = string_to_id(child.region_name)
            
    for child in get_children():
        if child is Region:
            var merge_id = null

            if not child.is_merge_controller:
                merge_id = region_ids[child.merge_controller]

            data.regions.append({
                "id": region_ids[child],
                "position": [
                    child.node_rect.position.x,
                    child.node_rect.position.y
                ],
                "size": [
                    child.node_rect.size.x,
                    child.node_rect.size.y
                ],
                "name": child.region_name,
                "color": [
                    child.region_color.r,
                    child.region_color.g,
                    child.region_color.b,
                    child.region_color.a
                ],
                "merge_controller": merge_id
            })
    for child in get_children():
        if child is Entrance:
            var rule_name = ""
            if child.rule_combo:
                rule_name = child.rule_combo.combo_name
            data.entrances.append({
                "from_region": region_ids[child.from_region],
                "to_region": region_ids[child.to_region],
                "from_pos": [
                    child.from_pos.x,
                    child.from_pos.y
                ],
                "to_pos": [
                    child.to_pos.x,
                    child.to_pos.y
                ],
                "id" : string_to_id(child.entrance_name),
                "name": child.entrance_name,
                "rule_name": rule_name,
                "dual_directional": child.duel_directonal
            })
    save_data_ready.emit(data)
    return data

func load_data(data: Dictionary, rule_combo_manager:RulePaletteManager):
    var region_lookup := {}
    var regions = []
    var entrances = []
    #setup regions
    for region_data in data.get("regions", []):
        var region = region_scene.instantiate()

        var rect := Rect2(
            Vector2(
                region_data.position[0],
                region_data.position[1]
            ), 
            Vector2(
                region_data.size[0],
                region_data.size[1]
            )
        )

        region.setup(rect, region_data.name)
        region.region_color = Color(
            region_data.color[0],
            region_data.color[1],
            region_data.color[2],
            region_data.color[3]
        )
        
        connect_region_signals(region)
        region_lookup[region_data.id] = region
        
        regions.append(region)
        add_child(region)
        region.queue_redraw()
    #setup controllers
    for region_data in data.get("regions", []):
        var region = region_lookup[region_data.id]

        var controller_id = region_data.merge_controller

        if controller_id != null:
            var controller = region_lookup[controller_id]

            region.merge_controller = controller
            region.is_merge_controller = false
            region.region_name = controller.region_name
            region.region_color = controller.region_color

            if not controller.region_references.has(region):
                controller.region_references.append(region)
        else:
            region.is_merge_controller = true
        region.queue_redraw()
        
    #setup entrances
    for entrance_data in data.get("entrances", []):
        var from_region = region_lookup[entrance_data.from_region]
        var to_region = region_lookup[entrance_data.to_region]

        var from_pos := Vector2(
            entrance_data.from_pos[0],
            entrance_data.from_pos[1]
        )

        var to_pos := Vector2(
            entrance_data.to_pos[0],
            entrance_data.to_pos[1]
        )

        var entrance = entrance_scene.instantiate()

        entrance.setup(
            from_region,
            to_region,
            from_pos,
            to_pos,
            entrance_data.dual_directional,
            entrance_data.name
        )
        

        connect_entrance_signals(entrance)

        add_child(entrance)
        entrances.append(entrance)
        var rule_name = entrance_data.get("rule_name")
        if rule_name != "":
            entrance.set_rule(rule_combo_manager.get_rule_combo(rule_name))
    undo_load(regions, entrances)
        
func undo_load(regions, entrances):
    undo_redo.create_action("Undo Load")
    undo_redo.add_do_method(print.bind("Save Done"))
    undo_redo.add_undo_method(remove_select_children.bind(regions, entrances))
    undo_redo.commit_action()
    
func remove_select_children(regions, entrances):
    for region in regions:
        delete_region_and_reference(region)
    for entrance in entrances:
        remove_child(entrance)
