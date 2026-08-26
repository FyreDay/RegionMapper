class_name GroupEditor
extends Control

signal changed(Array)

@onready var container: VBoxContainer = $ScrollContainer/EntranceGroupContainer
@onready var enter: HBoxContainer = $ScrollContainer/EntranceGroupContainer/HBoxContainer
@onready var name_edit: LineEdit = $ScrollContainer/EntranceGroupContainer/HBoxContainer/LineEdit

var entrance_group = preload("res://entrance_group_type.tscn")

func _on_line_edit_text_submitted(new_text: String) -> void:
    create_new_flag(new_text)
    create_new_Array()

func create_new_flag(new_text: String):
    var group = entrance_group.instantiate()
    container.add_child(group)
    container.move_child(enter, 0)
    group.setup(new_text)
    group.move_up.connect(_on_move_up)
    group.move_down.connect(_on_move_down)
    group.delete.connect(_on_delete)

func _on_move_up(group:EntranceGroupType):
    container.move_child(group, group.get_index()-1 if group.get_index() > 1 else 1)
    create_new_Array()
    
func _on_move_down(group:EntranceGroupType):
    container.move_child(group, group.get_index()+1 if group.get_index() < container.get_child_count() - 1 else group.get_index())
    create_new_Array()
    
func _on_delete(group:EntranceGroupType):
    container.remove_child(group)
    create_new_Array()

func create_new_Array():
    var arr:=[]
    for child in container.get_children():
        if child is EntranceGroupType:
            arr.append(child.label.text)
    changed.emit(arr)
    
func load_array(flags:Array):
    clear()
    for index in flags.size():
        create_new_flag(flags[index])
        
func clear():
    for child in container.get_children():
        if child is EntranceGroupType:
            container.remove_child(child)
    


func _on_line_edit_gui_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed:
        print("enter")
        if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
            get_viewport().set_input_as_handled()
            _on_line_edit_text_submitted(name_edit.text)
            name_edit.text = ""
