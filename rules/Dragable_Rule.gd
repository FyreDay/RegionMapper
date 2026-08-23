class_name DragableRuleNameEdit
extends LineEdit

signal selected(DragableRuleNameEdit)
signal popup_opened
signal popup_closed
signal name_change_request(DragableCustomRule, String)
signal delete_me

@onready var edit_menu: PopupPanel = $EditMenu
@onready var name_edit: LineEdit = $EditMenu/VBoxContainer/NameEdit

var dragable_ref = preload("res://rules/dragable_rule_ref.tscn")
var mouse_over = false
var click_count = 0
var elapsed_time = 0
var dragging = false
const dragtime = .3
var drag_timer = 0

var drag_start_pos:= Vector2.ZERO
var rule_combo:RuleCombo
var drag_layer:Control
var rule_mode := false

func _process(delta: float) -> void:
    #if Input.is_action_just_pressed("Exit") and has_focus():
        #
        
    #if click_count > 0:
        #elapsed_time+=delta
        #if click_count >= 2:
            #elapsed_time = 0
            #click_count = 0
            #selecting_enabled = true
            #editable = true
        #if elapsed_time > .3:
            #click_count-=1
            #elapsed_time = 0
    if dragging:
        drag_timer += delta
        if drag_timer >= dragtime:
            var drag_ref = dragable_ref.instantiate()
            drag_layer.add_child(drag_ref)
            drag_ref.setup(rule_combo, true)
            drag_timer = 0
            dragging = false
    

func setup(new_rule_combo:RuleCombo, new_drag_layer:Control):
    rule_combo = new_rule_combo
    drag_layer = new_drag_layer
    text = rule_combo.combo_name


func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        print("input")
        print(rule_mode)
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                if rule_mode:
                    selected.emit(self)
                dragging = true
            #elif mouse_over:
                #click_count += 1
        if event.button_index == MOUSE_BUTTON_RIGHT:
            print("right")
            if event.pressed:
                open_edit_menu()
                
                
    if event is InputEventMouseMotion:
        if not(dragging and Input.is_action_pressed("click")):
            dragging = false
            drag_timer = 0
            
        
func open_edit_menu():
    print("open edit menu")
    popup_opened.emit()
    name_edit.text = rule_combo.combo_name
    edit_menu.position = get_viewport().get_mouse_position()
    edit_menu.reset_size()
    edit_menu.popup()

func dispay_error():
    print("error")

func _on_name_edit_text_changed(new_text: String) -> void:
    name_change_request.emit(self, new_text)

func set_combo_name(new_name):
    rule_combo.set_combo_name(new_name)
    text = new_name
    queue_redraw()

func _on_mouse_entered() -> void:
    mouse_over = true


func _on_mouse_exited() -> void:
    mouse_over = false
    if dragging:
        var drag_ref = dragable_ref.instantiate()
        drag_layer.add_child(drag_ref)
        drag_ref.setup(rule_combo, true)
        drag_timer = 0
        dragging = false


func _on_focus_exited() -> void:
    selecting_enabled = false
    editable = false

func _on_text_submitted(new_text: String) -> void:
    
    rule_combo.set_combo_name(new_text)
    selecting_enabled = false
    editable = false
    release_focus()

func update_rule_combo(new_rule_combo:RuleCombo):
    rule_combo = new_rule_combo

func update_rule_data(new_rule_data:RuleData):
    rule_combo.root = new_rule_data
    
func on_rule_builder_state(open:bool):
    rule_mode = open

func _on_edit_menu_popup_hide() -> void:
    name_edit.remove_theme_stylebox_override("normal")
    popup_closed.emit()

func _on_delete_button_pressed() -> void:
    rule_combo.invalid.emit()
    delete_me.emit(self)
