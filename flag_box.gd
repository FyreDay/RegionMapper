class_name FlagToggle
extends HBoxContainer

signal checked(int,bool)

@onready var box: CheckBox = $CheckBox

var flag_index

func setup(index:int, flag_name:String, checked:bool):
    box.text = flag_name
    box.button_pressed = checked
    flag_index = index

func _on_check_box_toggled(toggled_on: bool) -> void:
    checked.emit(flag_index, toggled_on)
