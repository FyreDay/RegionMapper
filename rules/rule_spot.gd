class_name RuleSpot
extends PanelContainer

@export var drag_layer:Control

signal is_hovered(RuleSpot)
signal new_root(RuleData)

var hovered := false
var dragable_rule_data:DragableRuleData
#this is for when you can remove a rule from this spot
var parent_rule_data:RuleData
var being_dragged:= false

func _ready() -> void:
    if drag_layer:
        is_hovered.connect(drag_layer.update_rule_spot)
    _update_style()

func _on_mouse_entered() -> void:
    print("Entered" + str(self))
    if being_dragged:
        return
    hovered = true
    _update_style()
    is_hovered.emit(self)

func setup(new_drag_layer:Control, new_parent_rule_data):
    parent_rule_data = new_parent_rule_data
    if not drag_layer:
        drag_layer = new_drag_layer
        is_hovered.connect(drag_layer.update_rule_spot)
        

func _on_mouse_exited() -> void:
    print("Exited" + str(self))
    hovered = false
    _update_style()
    is_hovered.emit(null)

func has_rule():
    return dragable_rule_data != null

func from_rule_data(new_rule_data:RuleData):
    if dragable_rule_data:
        dragable_rule_data.free()
        dragable_rule_data = null

    if new_rule_data:
        var dragable_ref: PackedScene = load(
            "res://rules/dragable_rule_data.tscn"
        )
        dragable_rule_data = dragable_ref.instantiate()
        add_child(dragable_rule_data)
        dragable_rule_data.setup_with_data(new_rule_data, drag_layer)
        
        if is_hovered.is_connected(drag_layer.update_rule_spot):
            is_hovered.disconnect(drag_layer.update_rule_spot)
    else:
        if not is_hovered.is_connected(drag_layer.update_rule_spot):
            is_hovered.connect(drag_layer.update_rule_spot)
    _update_style()
    

func set_rule(new_dragable_rule_data:DragableRuleData):
    print("set Rule")
    if dragable_rule_data:
        dragable_rule_data.free()
        dragable_rule_data = null
    dragable_rule_data = new_dragable_rule_data  
    dragable_rule_data.reparent(self)
    if parent_rule_data:
        parent_rule_data.add_child_data(dragable_rule_data.rule_data)
    else:
        new_root.emit(dragable_rule_data.rule_data)
    is_hovered.emit(null)
    if is_hovered.is_connected(drag_layer.update_rule_spot):
        is_hovered.disconnect(drag_layer.update_rule_spot)
    _update_style()

func _update_style() -> void:
    if dragable_rule_data == null:
        var style := StyleBoxFlat.new()

        style.bg_color = Color(0.12, 0.12, 0.12, 1.0)
        style.border_width_left = 1
        style.border_width_right = 1
        style.border_width_top = 1
        style.border_width_bottom = 1

        style.border_color = Color.WHITE if hovered else Color(0.35, 0.35, 0.35)

        style.corner_radius_top_left = 8
        style.corner_radius_top_right = 8
        style.corner_radius_bottom_left = 8
        style.corner_radius_bottom_right = 8

        add_theme_stylebox_override("panel", style)
    else:
        remove_theme_stylebox_override("panel")
    queue_redraw()
        
func release_dragable_rule():
    var rule = dragable_rule_data
    if parent_rule_data:
        parent_rule_data.remove_child_data(rule.rule_data)
    dragable_rule_data = null
    is_hovered.connect(drag_layer.update_rule_spot)
    rule.reparent(drag_layer)
    
    _update_style()
        
