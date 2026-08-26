class_name CustomRuleCreator
extends Control

var arg_type = preload("res://rules/menus/rule_arg_type.tscn")
var rule_data = preload("res://rules/dragable_custom_rule.tscn")

@onready var edit_menu: PopupPanel = $PopupPanel
@onready var arg_container: VBoxContainer = $PopupPanel/PanelContainer/VBoxParent/ArgContainer
@onready var rule_name: LineEdit = $PopupPanel/PanelContainer/VBoxParent/NameBanner/RuleName

var custom_rule:CustomRule
var rule_manager: RuleManager
var drag_layer:DragLayer

func _on_button_pressed() -> void:
    var new_arg_type = arg_type.instantiate()
    arg_container.add_child(new_arg_type)
    new_arg_type.setup(custom_rule)
    queue_redraw()

func _on_delete_arg_pressed() -> void:
    if arg_container.get_child_count() > 0:
        var bottom_child = arg_container.get_child(arg_container.get_child_count() - 1)
        bottom_child.remove_arg()
        arg_container.remove_child(bottom_child)


func _on_save_pressed() -> void:
    var dcr = rule_data.instantiate()
    rule_manager.add_custom_dragable(dcr)
    dcr.setup(custom_rule, drag_layer)
    print(str(custom_rule.to_dict()))

func _on_rule_name_text_changed(new_text: String) -> void:
    custom_rule.rule_name = new_text
    
func popup(editable_custom_rule, manager: RuleManager, dl:DragLayer):
    for c in arg_container.get_children():
        arg_container.remove_child(c) 
    custom_rule = editable_custom_rule
    rule_manager = manager
    drag_layer = dl
    rule_name.text = custom_rule.rule_name
    edit_menu.popup()
    
    


func _on_rule_name_gui_input(event: InputEvent) -> void:
     if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
        get_viewport().set_input_as_handled()
