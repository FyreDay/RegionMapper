class_name CustomRule
extends RefCounted

signal changed
signal invalid

var editable = true
var is_combinator = false
var rule_name: String
var arg_definitions: Dictionary[String, ArgType] = {}

func trigger_update(custom_rule:CustomRule) -> void:
    rule_name = custom_rule.rule_name
    arg_definitions = custom_rule.arg_definitions
    changed.emit()
    
func set_name(new_name: String):
    rule_name = new_name
    changed.emit()

func to_dict() -> Dictionary:
    var d := {"rule_name": rule_name}
    var defs = []
    for key in arg_definitions:
        defs.append({"name": key, "arg_type": arg_definitions[key].to_dict()})
    d["arg_definitions"] = defs
    return d

static func from_dict(data: Dictionary) -> CustomRule:
    var custom_rule := CustomRule.new()
    custom_rule.rule_name = data.get("rule_name", "")
    
    var defs: Array = data.get("arg_definitions", {})
    for json in defs:
        if json.has("name"):
            custom_rule.arg_definitions[json.get("name")] = ArgType.from_dict(json.get("arg_type"))
    
    return custom_rule
