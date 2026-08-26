extends PopupPanel


func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
            get_viewport().set_input_as_handled()
