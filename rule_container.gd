class_name RuleManager
extends VBoxContainer

@onready var ui :LogicUI = $"../../../../.."

var dragable_custom_rule = preload("res://rules/dragable_custom_rule.tscn")

func add_custom_dragable(dcr:DragableCustomRule):
    dcr.popup_opened.connect(ui.popup_opened.emit)
    dcr.popup_closed.connect(ui.popup_closed.emit)
    dcr.name_change_request.connect(request_name_change)
    dcr.delete_me.connect(delete_custom_rule)
    add_child(dcr)

func save_data() -> Array:
    var list := []
    for c in get_children():
        if c is DragableCustomRule:
            if not c.custom_rule.editable:
                continue
            list.append(c.custom_rule.to_dict())
    return list
    
func load_data(data: Dictionary, drag_layer):
    var custom_rules = data.get("custom_rules", [])
    for rule in custom_rules:
        var new_dcr = dragable_custom_rule.instantiate()
        add_child(new_dcr)
        new_dcr.setup(CustomRule.from_dict(rule), drag_layer)
        
func get_custom_rule(rule_name:String) -> CustomRule:
    for c in get_children():
        if c is DragableCustomRule:
            if c.custom_rule.rule_name == rule_name:
                return c.custom_rule
    return null
    
func request_name_change(dcr:DragableCustomRule, new_name):
    for c in get_children():
        if c is DragableCustomRule:
            if c.custom_rule.rule_name == new_name:
                dcr.dispay_error()
                return
    dcr.set_rule_name(new_name)

func delete_custom_rule(dcr:DragableCustomRule):
    remove_child(dcr)
    dcr.queue_free()
        
    
