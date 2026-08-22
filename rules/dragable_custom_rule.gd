class_name DragableCustomRule
extends LineEdit

signal popup_opened
signal popup_closed
signal name_change_request(DragableCustomRule, String)
signal delete_me

var dragable_ref = preload("res://rules/dragable_rule_data.tscn")

@onready var edit_menu: PopupPanel = $EditMenu
@onready var name_edit: LineEdit = $EditMenu/VBoxContainer/NameEdit

var mouse_over = false
var click_count = 0
var elapsed_time = 0
var dragging = false
const dragtime = .3
var drag_timer = 0

var drag_start_pos:= Vector2.ZERO
@export var custom_rule_def: CustomRuleDefinition
var custom_rule:CustomRule
@export var drag_layer:Control

func _ready() -> void:
    if custom_rule_def:
        set_rule(custom_rule_def.get_data())

func _process(delta: float) -> void:
    if click_count > 0:
        elapsed_time+=delta
        if click_count >= 2:
            elapsed_time = 0
            click_count = 0
            selecting_enabled = true
            editable = true
        if elapsed_time > .3:
            click_count-=1
            elapsed_time = 0
    if dragging:
        drag_timer += delta
        if drag_timer >= dragtime:
            var drag_ref = dragable_ref.instantiate()
            drag_layer.add_child(drag_ref)
            drag_ref.setup(custom_rule, true)
            drag_timer = 0
            dragging = false
    

func setup(new_custom_rule:CustomRule, new_drag_layer:Control):
    set_rule(new_custom_rule)
    drag_layer = new_drag_layer
    

func set_rule(new_custom_rule:CustomRule):
    if new_custom_rule:
        custom_rule = new_custom_rule
        text = custom_rule.rule_name
    else:
        queue_free()
        
func dispay_error():
    print("error")

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                dragging = true
            elif mouse_over and custom_rule.editable:
                print("click")
                click_count += 1
        if event.button_index == MOUSE_BUTTON_RIGHT:
            if event.pressed and custom_rule and custom_rule.editable:
                open_edit_menu()
                
    if event is InputEventMouseMotion:
        if not(dragging and Input.is_action_pressed("click")):
            dragging = false
            drag_timer = 0


func open_edit_menu():
    popup_opened.emit()
    name_edit.text = custom_rule.rule_name
    edit_menu.position = get_viewport().get_mouse_position()
    edit_menu.reset_size()
    edit_menu.popup()

func _on_name_edit_text_changed(new_text: String) -> void:
    name_change_request.emit(self, new_text)

func set_rule_name(new_name):
    custom_rule.set_name(new_name)
    text = new_name
    queue_redraw()

func _on_mouse_entered() -> void:
    mouse_over = true


func _on_mouse_exited() -> void:
    mouse_over = false
    if dragging:
        var drag_ref = dragable_ref.instantiate()
        drag_layer.add_child(drag_ref)
        drag_ref.setup(custom_rule, true)
        drag_timer = 0
        dragging = false


func _on_focus_exited() -> void:
    selecting_enabled = false
    editable = false

func _on_text_submitted(new_text: String) -> void:
    
    custom_rule.set_combo_name(new_text)
    selecting_enabled = false
    editable = false
    release_focus()

func _on_edit_menu_popup_hide() -> void:
    name_edit.remove_theme_stylebox_override("normal")
    popup_closed.emit()


func _on_delete_button_pressed() -> void:
    custom_rule.invalid.emit()
    delete_me.emit(self)
    
