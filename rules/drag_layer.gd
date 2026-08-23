class_name DragLayer
extends Control

@onready var confirm_dialog: ConfirmationDialog = $ConfirmationDialog

var hovered_entrance: Entrance
var hovered_rule_spot: RuleSpot

var on_confirm
var on_cancel
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
    pass
    
func update_entrance(entrance:Entrance):
    hovered_entrance = entrance

func update_rule_spot(rule_spot:RuleSpot):
    if rule_spot != null:
        print("Hovered new")
    else:
        print("Hovered NULL")
    hovered_rule_spot = rule_spot


func trigger_dangerous_action(new_on_confirm, new_on_cancel) -> void:
    on_confirm = new_on_confirm
    on_cancel = new_on_cancel
    confirm_dialog.popup_centered()    

func _on_confirmation_dialog_canceled() -> void:
    if on_cancel:
        on_cancel.call()
    on_cancel = null
    on_confirm = null
    


func _on_confirmation_dialog_confirmed() -> void:
    if on_confirm:
        on_confirm.call()
    on_cancel = null
    on_confirm = null
    
