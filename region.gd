class_name Region
extends Node2D

signal popup_opened
signal popup_closed
signal delete_region
signal merge_start
signal name_change_request
signal color_change_request
signal drag_started
signal drag_moved(region, old_rect, delta)
signal drag_ended
signal resize_started
signal resize_moved(region, old_rect, new_rect)
signal resize_ended

@onready var edit_menu: PopupPanel = $EditMenu
@onready var name_edit: CustomEdit = $EditMenu/VBoxContainer/NameEdit
@onready var color_changer: ColorPickerButton = $EditMenu/VBoxContainer/ColorChanger
enum Dragables { TOP_BAR, RESIZE_HANDLE, NONE}
const alpha = .3
const TOP_BAR_HEIGHT = 18

var region_color := Color.WHITE
var old_region_color
var node_rect := Rect2(Vector2.ZERO,Vector2(100,100))
var region_name = ""

var current_dragable: Dragables = Dragables.NONE
var drag_start_pos: Vector2
var drag_old_pos: Vector2

var merge_controller
var region_references
var is_merge_controller
var popup_caller:Region = null



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
    pass

func setup(rect: Rect2, new_name):
    node_rect = rect.abs()
    if node_rect.size.x < 40:
        node_rect.size.x = 40
    if node_rect.size.y < 40:
        node_rect.size.y = 40
        
    region_name = new_name
    region_color = Color.from_hsv(randf(), 1.0, 1.0,alpha)
    show_behind_parent = true
    merge_controller = null
    region_references = []
    is_merge_controller = true

func _draw() -> void:
    var font := ThemeDB.fallback_font
    var font_size := 16
    var text_width := font.get_string_size(region_name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
    
    var x := node_rect.position.x + (node_rect.size.x - text_width) / 2.0
    var y := node_rect.position.y + font_size
    var region_rect = node_rect
    region_rect.position.y = region_rect.position.y + TOP_BAR_HEIGHT
    region_rect.size.y = region_rect.size.y - TOP_BAR_HEIGHT
    draw_rect(region_rect, region_color)
    var top_bar_rect = node_rect
    top_bar_rect.size.y = TOP_BAR_HEIGHT
    draw_rect(top_bar_rect, Color(Color.WEB_GRAY, .5))
    draw_string(font,Vector2(x, y),region_name,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size)
    
    var grip_size := 10.0
    var grip_spacing := 4.0
    var grip_width := 1.0

    var corner := node_rect.end

    for i in range(3):
        var offset := i * grip_spacing

        draw_line(
            corner + Vector2(-grip_size + offset, -1),
            corner + Vector2(-1, -grip_size + offset),
            Color.DARK_GRAY,
            grip_width,
            false
        )

func _unhandled_input(event: InputEvent) -> void:
    var mouse_pos := get_global_mouse_position()
   
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                current_dragable = Dragables.NONE
                var dragable := get_clickable(mouse_pos)

                if dragable != Dragables.NONE:
                    current_dragable = dragable

                    drag_start_pos = mouse_pos
                    
                    if dragable == Dragables.RESIZE_HANDLE:
                        drag_old_pos = node_rect.size
                        resize_started.emit(self)
                    elif dragable == Dragables.TOP_BAR:
                        drag_old_pos = node_rect.position
                        drag_started.emit(self)
                    
                    get_viewport().set_input_as_handled()
                    return
            else:
                if current_dragable == Dragables.NONE:
                    return
                var dragable := current_dragable
                current_dragable = Dragables.NONE
                
                if dragable == Dragables.RESIZE_HANDLE:
                    var new_size = node_rect.size
                    resize_ended.emit(
                        self,
                        drag_old_pos,
                        new_size
                    )
                elif dragable == Dragables.TOP_BAR:
                    var new_pos = node_rect.position
                    drag_ended.emit(
                        self,
                        drag_old_pos,
                        new_pos
                    )
                
                get_viewport().set_input_as_handled()
                return
                
    if event is InputEventMouseMotion and Input.is_action_pressed("click"): 
        if current_dragable != Dragables.NONE:
            if current_dragable == Dragables.TOP_BAR:
                var old_pos = node_rect
                node_rect.position = drag_old_pos + mouse_pos - drag_start_pos
                drag_moved.emit(self, old_pos, (mouse_pos - drag_start_pos))
            elif current_dragable == Dragables.RESIZE_HANDLE:
                var old_pos = node_rect
                var new_size = drag_old_pos + mouse_pos - drag_start_pos
                new_size.x = 40 if new_size.x <= 40 else new_size.x
                new_size.y = 40 if new_size.y <= 40 else new_size.y
                node_rect.size = new_size
                resize_moved.emit(self, old_pos, node_rect)
            queue_redraw()
            get_viewport().set_input_as_handled()

func get_clickable(global_mouse_pos) -> Dragables:
    var top_bar_rect = node_rect
    top_bar_rect.size.y = TOP_BAR_HEIGHT
    if global_mouse_pos.distance_to(node_rect.end) <= 12 and is_mouse_over(global_mouse_pos):
        return Dragables.RESIZE_HANDLE
    if top_bar_rect.has_point(to_local(global_mouse_pos)):
        return Dragables.TOP_BAR
    return Dragables.NONE
    
func set_rect_pos(new_position):
    node_rect.position = new_position
    queue_redraw()
    
func set_rect_size(size):
    node_rect.size = size
    queue_redraw()
    
func is_mouse_over(global_mouse_pos: Vector2) -> bool:
    if current_dragable == Dragables.TOP_BAR:
        var old_rect = Rect2(drag_old_pos, node_rect.size)
        return old_rect.has_point(to_local(global_mouse_pos))
    return node_rect.has_point(to_local(global_mouse_pos))

func is_mouse_over_merge(global_mouse_pos: Vector2) -> bool:
    if is_merge_controller:
        if is_mouse_over(global_mouse_pos):
            return true
        for region in region_references:
            if region.is_mouse_over(global_mouse_pos):
                return true
    else:
        return merge_controller.is_mouse_over_merge(global_mouse_pos)
        
    return false

func get_controller():
    return self if is_merge_controller else merge_controller
    

func open_edit_menu(caller, _flags):
    if not is_merge_controller:
        merge_controller.open_edit_menu(self, _flags)
        return
    popup_caller = caller
    if get_viewport() == null:
        return
    popup_opened.emit()
    name_edit.text = region_name
    color_changer.color = Color(region_color, 1.0)
    
    edit_menu.position = get_viewport().get_mouse_position()
    edit_menu.reset_size()
    edit_menu.popup()

func is_merge_valid(new_merge_controller):
    if self == new_merge_controller:
        return false
    if merge_controller != null and new_merge_controller.merge_controller != null:
        if merge_controller == new_merge_controller.merge_controller:
            return false
    if merge_controller == new_merge_controller:
        return false
    if is_merge_controller and new_merge_controller.merge_controller == self:
        return false
    return true
        
        
func get_merge_state():
    return {
        "is_merge_controller": is_merge_controller,
        "merge_controller": merge_controller,
        "region_references": region_references.duplicate(),
        "region_name": region_name,
        "region_color": region_color,
    }
    
func snapshot_regions():
    var snapshot = {}

    for region in region_references:
        snapshot[region] = region.get_merge_state()
    snapshot[self] = self.get_merge_state()
    if merge_controller != null:
        snapshot[merge_controller] = merge_controller.get_merge_state()
    return snapshot
    
func do_merge(new_merge_controller):
    if not is_merge_valid(new_merge_controller):
        return
    if is_merge_controller and region_references.size() > 0:
        var new_parent_region = region_references[0]
        new_parent_region.merge_controller = null
        new_parent_region.is_merge_controller = true
        new_parent_region.region_references = region_references.slice(1)
        for new_child in new_parent_region.region_references:
            new_child.merge_controller = new_parent_region
        region_references = []
    is_merge_controller = false
    if merge_controller != null:
        merge_controller.remove_region_reference(self)
    merge_controller = new_merge_controller
    region_name = merge_controller.region_name
    region_color = merge_controller.region_color
    merge_controller.add_region_reference(self)
    
    queue_redraw()
    
    
func add_region_reference(region):
    region_references.append(region)
    
func remove_region_reference(region):
    region_references.erase(region)
    

func _on_edit_menu_popup_hide() -> void:
    name_edit.remove_theme_stylebox_override("normal")
    popup_closed.emit()


func _on_color_changer_color_changed(color: Color) -> void:
    region_color = Color(color, alpha)
    set_region_color(region_color)



func _on_name_edit_text_changed(new_text: String) -> void:
    name_change_request.emit(self, new_text)
    
func set_region_name(new_name: String) -> void:
    for region in region_references:
        region.set_region_name(new_name)

    region_name = new_name
    queue_redraw()
    
func set_region_color(new_color: Color) -> void:
    if is_merge_controller:
        for region in region_references:
            region.set_region_color(new_color)

    region_color = Color(new_color, alpha)
    queue_redraw()


func _on_delete_button_pressed() -> void:
    edit_menu.hide()
    delete_region.emit(popup_caller)
    
func _on_merge_button_pressed() -> void:
    if is_merge_controller:
        merge_start.emit(self)
    else:
        merge_start.emit(merge_controller)
        
func _on_color_changer_popup_closed() -> void:
    color_change_request.emit(self, region_color, old_region_color)


func _on_color_changer_picker_created() -> void:
    old_region_color = region_color


func _on_copy_name_button_pressed() -> void:
    DisplayServer.clipboard_set(region_name)
    
