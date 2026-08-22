class_name Entrance
extends Node2D

signal popup_opened
signal popup_closed
signal delete_entrance
signal name_change_request
signal endpoint_drag_started(entrance, endpoint)
signal endpoint_drag_ended(entrance, endpoint, old_pos, new_pos)

@onready var edit_menu: PopupPanel = $EditMenu
@onready var name_edit: LineEdit = $EditMenu/VBoxContainer/NameEdit
@onready var rule_name: LineEdit = $EditMenu/VBoxContainer/RuleContainer/LineEdit
@onready var rule_plate: LineEdit = $RulePlate

enum endpoints { FROM_ENDPOINT, TO_ENDPOINT, NONE}
const ENDPOINT_RADIUS := 20.0

var dragging_endpoint := endpoints.NONE
var drag_start_pos: Vector2
var drag_old_pos: Vector2

var from_pos: Vector2
var to_pos: Vector2
var duel_directonal = false
var from_region
var to_region
var entrance_name
var updating_rule_edit: = false
var auto_update_name:= false
var name_box:Rect2
var hovered_region
var to_endpoint_offset := Vector2.ZERO
var from_endpoint_offset := Vector2.ZERO
var rule_combo:RuleCombo

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    z_index = 10
    rule_plate.hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
    pass

func setup(new_from_region, new_to_region, new_from_pos, new_to_pos, new_duel_directonal, new_name):
    self.from_region = new_from_region
    self.to_region = new_to_region
    self.from_pos = new_from_pos
    self.to_pos = new_to_pos
    self.duel_directonal = new_duel_directonal
    self.entrance_name = new_name
    show_behind_parent = true
    var midpoint: Vector2 = (from_pos + to_pos) / 2.0
    self.name_box = Rect2(midpoint - Vector2(30,20) / 2.0, Vector2(30,20))
        

func is_mouse_over(global_mouse_pos: Vector2) -> bool:
    var mouse_pos := to_local(global_mouse_pos)

    if name_box.has_point(mouse_pos):
        return true
    #endpoint detection maybe
    return false
    
func _input(event: InputEvent) -> void:
    var mouse_pos := get_global_mouse_position()
   
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                dragging_endpoint = endpoints.NONE
                var endpoint := get_endpoint_at_position(mouse_pos)

                if endpoint != endpoints.NONE:
                    dragging_endpoint = endpoint

                    drag_start_pos = mouse_pos

                    if endpoint == endpoints.FROM_ENDPOINT:
                        drag_old_pos = from_pos
                    else:
                        drag_old_pos = to_pos

                    endpoint_drag_started.emit(self, endpoint)
                    get_viewport().set_input_as_handled()
                    return
            else:
                if dragging_endpoint == endpoints.NONE:
                    return
                var endpoint := dragging_endpoint
                dragging_endpoint = endpoints.NONE

                var new_pos := from_pos if endpoint == endpoints.FROM_ENDPOINT else to_pos

                endpoint_drag_ended.emit(
                    self,
                    endpoint,
                    drag_old_pos,
                    new_pos
                )

                get_viewport().set_input_as_handled()
                return
                
    if event is InputEventMouseMotion and Input.is_action_pressed("click"): 
        if dragging_endpoint != endpoints.NONE:
            if dragging_endpoint == endpoints.FROM_ENDPOINT:
                if from_region.is_mouse_over_merge(mouse_pos):
                    from_pos = mouse_pos
            else:
                if to_region.is_mouse_over_merge(mouse_pos):
                    to_pos = mouse_pos
            queue_redraw()
            get_viewport().set_input_as_handled()

      
func get_endpoint_at_position(mouse_pos: Vector2) -> endpoints:
    if mouse_pos.distance_to(from_pos) <= ENDPOINT_RADIUS:
        return endpoints.FROM_ENDPOINT

    if mouse_pos.distance_to(to_pos) <= ENDPOINT_RADIUS:
        return endpoints.TO_ENDPOINT

    return endpoints.NONE
            
func open_edit_menu():
    popup_opened.emit()
    name_edit.text = entrance_name
    updating_rule_edit = true
    updating_rule_edit = false
    edit_menu.position = get_viewport().get_mouse_position()
    edit_menu.reset_size()
    edit_menu.popup()


func _draw() -> void:
    
    draw_arrow(to_pos + to_endpoint_offset, from_pos + from_endpoint_offset)
    draw_nameplate(to_pos + to_endpoint_offset, from_pos + from_endpoint_offset)
    update_rule_plate()

func update_rule_plate():
    rule_plate.position = Vector2(name_box.position.x + (name_box.size.x/2) - rule_plate.size.x/2, name_box.position.y + name_box.size.y)
    
func draw_nameplate(to_pos_draw: Vector2, from_pos_draw: Vector2):
    var font := ThemeDB.fallback_font
    var font_size := 16
    var padding := 6.0

    var midpoint := (from_pos_draw + to_pos_draw) / 2.0

    var text_size := font.get_string_size(
        entrance_name,
        HORIZONTAL_ALIGNMENT_LEFT,
        -1,
        font_size
    )

    var box_size := text_size + Vector2(padding * 2, padding * 2)
    name_box = Rect2(midpoint - box_size / 2.0, box_size)

    draw_rect(name_box, Color.WHITE)
    draw_rect(name_box, Color.BLACK, false, 2.0)

    var text_position := Vector2(
        name_box.position.x + padding,
        name_box.position.y + padding + font_size
    )

    draw_string(
        font,
        text_position,
        entrance_name,
        HORIZONTAL_ALIGNMENT_LEFT,
        -1,
        font_size,
        Color.BLACK
    )

func draw_arrow(to_pos_draw: Vector2, from_pos_draw: Vector2):
    var arrow_length := 15.0
    var arrow_width := 8.0
    
    var start := from_pos_draw
    var end := to_pos_draw
    
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
                start + 1 * direction - direction * inner_length, 
                start + 1 * direction + perpendicular * inner_width, 
                start + 1 * direction - perpendicular * inner_width
            ]),
            Color.WHITE
        )

    draw_colored_polygon(
        PackedVector2Array([
            end - 1 * direction + direction * inner_length, 
            end - 1 * direction + perpendicular * inner_width, 
            end - 1 * direction - perpendicular * inner_width
            ]),
        Color.WHITE
    )

func set_entrance_name(new_name):
    self.entrance_name = new_name
    queue_redraw()

func set_rule(new_rule_combo:RuleCombo):
    
    if new_rule_combo:
        if rule_combo and rule_combo.invalid.is_connected(_on_rule_combo_invalid):
            rule_combo.invalid.disconnect(_on_rule_combo_invalid)
        
        if rule_combo and rule_combo.changed.is_connected(_on_rule_combo_changed):
            rule_combo.changed.disconnect(_on_rule_combo_changed)
        rule_combo = new_rule_combo
        rule_name.text = rule_combo.combo_name
        rule_plate.text = rule_combo.combo_name
        rule_plate.show()
        rule_combo.invalid.connect(_on_rule_combo_invalid)
        rule_combo.changed.connect(_on_rule_combo_changed)  
    else:
        _on_rule_combo_invalid()
    queue_redraw()

func _on_rule_combo_changed():
    rule_name.text = rule_combo.combo_name
    rule_plate.text = rule_combo.combo_name
    queue_redraw()
    
func _on_rule_combo_invalid():
    rule_combo = null
    rule_name.text = ""
    rule_plate.text = ""
    rule_plate.hide()
    
func get_endpoint_pos(endpoint):
    if endpoint == endpoints.FROM_ENDPOINT:
        return from_pos
    else:
        return to_pos

func set_endpoint(endpoint, new_pos):
    if endpoint == endpoints.FROM_ENDPOINT:
        from_pos = new_pos
        from_endpoint_offset = Vector2.ZERO
    else:
        to_pos = new_pos
        to_endpoint_offset = Vector2.ZERO
    queue_redraw()

func set_offset(endpoint: endpoints, offset: Vector2):
    if endpoint == endpoints.TO_ENDPOINT:
        to_endpoint_offset = offset
    elif endpoint == endpoints.FROM_ENDPOINT:
        from_endpoint_offset = offset
    queue_redraw()
    
func get_offset(endpoint: endpoints):
    if endpoint == endpoints.TO_ENDPOINT:
        return to_endpoint_offset
    elif endpoint == endpoints.FROM_ENDPOINT:
        return from_endpoint_offset

func _on_edit_menu_popup_hide() -> void:
    name_edit.remove_theme_stylebox_override("normal")
    popup_closed.emit()


func _on_name_edit_text_changed(new_text: String) -> void:
    name_change_request.emit(self, new_text)


func _on_delete_button_pressed() -> void:
    delete_entrance.emit(self)
        
func _on_hovered_region(_region, merge_controller):
    hovered_region = merge_controller

func _on_delete_rule_pressed() -> void:
    set_rule(null)
