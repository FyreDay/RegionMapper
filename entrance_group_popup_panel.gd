extends PopupPanel

func _ready() -> void:
    # This stops Enter or clicking outside from auto-closing the popup
    exclusive = true 

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
            get_viewport().set_input_as_handled()
