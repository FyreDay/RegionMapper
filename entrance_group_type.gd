class_name EntranceGroupType
extends HBoxContainer

signal move_up(EntranceGroupType)
signal move_down(EntranceGroupType)
signal delete(EntranceGroupType)

@onready var label: Label = $HBoxContainer/Label

func setup(new_label: String) -> void:
    label.text = new_label


func _on_up_pressed() -> void:
    move_up.emit(self)


func _on_down_pressed() -> void:
    move_down.emit(self)


func _on_delete_pressed() -> void:
    delete.emit(self)
