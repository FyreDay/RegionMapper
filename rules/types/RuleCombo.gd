class_name RuleCombo
extends RefCounted

signal changed
signal invalid

var combo_name: String
var root: RuleData

func set_combo_name(new_name: String) -> void:
    combo_name = new_name
    changed.emit()

func to_dict() -> Dictionary:
    var root_out = ""
    if root:
        root_out = root.to_dict()

    return {"combo_name": combo_name, "root": root_out}


static func from_dict(data: Dictionary, rule_manager: RuleManager) -> RuleCombo:
    var combo = RuleCombo.new()
    combo.combo_name = data.get("combo_name", "FAILURE")
    combo.root = RuleData.from_dict(data.get("root"), rule_manager)
    return combo
