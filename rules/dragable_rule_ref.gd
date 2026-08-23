extends Control

@onready var name_ref: LineEdit = $NameRef

var dragging:bool
var rule_combo:RuleCombo
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
    if not dragging:
        return
    position = get_parent().get_local_mouse_position()
    queue_redraw()

    if not Input.is_action_pressed("click"):
        var drag_layer = get_parent() as DragLayer
        if drag_layer.hovered_entrance == null:
            queue_free()
            return
        drag_layer.hovered_entrance.set_rule(rule_combo)
        dragging = false
        queue_free()
        

func setup(new_rule_combo:RuleCombo, is_dragging):
    rule_combo = new_rule_combo
    dragging = is_dragging
    name_ref.text = rule_combo.combo_name
