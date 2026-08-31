class_name RuleArg
extends HBoxContainer

@onready var label: Label = $Label
@onready var text_value: LineEdit = $StringValue
@onready var int_value: SpinBox = $IntValue
@onready var number_value: SpinBox = $FloatValue
@onready var bool_value: CheckBox = $BoolValue
@onready var string_list: HBoxContainer = $StringListValue
@onready var add_string_list: Button = $StringListValue/Add

var string_input = preload("res://custom/input.tscn")

var arg_name
var rule_data: RuleData

func setup(new_arg_name: String, definition: ArgType, value, new_rule_data:RuleData) -> void:
    arg_name = new_arg_name
    label.text = new_arg_name
    rule_data = new_rule_data
    text_value.hide()
    int_value.hide()
    number_value.hide()
    bool_value.hide()
    string_list.hide()
    rule_data.set_arg(arg_name, value)

    match definition.arg_type:
        CustomRuleArgumentDefinition.RuleArgType.STRING:
            text_value.show()
            text_value.text = str(value)

        CustomRuleArgumentDefinition.RuleArgType.INT:
            int_value.show()
            int_value.value = int(value)
        CustomRuleArgumentDefinition.RuleArgType.FLOAT:
            number_value.show()
            number_value.value = float(value)

        CustomRuleArgumentDefinition.RuleArgType.BOOL:
            bool_value.show()
            bool_value.button_pressed = bool(value)
        
        CustomRuleArgumentDefinition.RuleArgType.STRING_LIST:
            string_list.show()
            for str_value in value:
                var str_input = string_input.instantiate()
                string_list.add_child(str_input)
                str_input.text = str_value
                str_input.text_changed.connect(_on_string_list_value_changed)
                string_list.move_child(add_string_list, string_list.get_child_count() - 1)
                
    
        
func _on_string_value_text_changed(new_text: String) -> void:
    rule_data.set_arg(arg_name, new_text)


func _on_int_value_value_changed(value: float) -> void:
    rule_data.set_arg(arg_name, value)


func _on_bool_value_toggled(toggled_on: bool) -> void:
    rule_data.set_arg(arg_name, toggled_on)

func _on_string_list_value_changed(_value: String) -> void:
    var a:= []
    for c in string_list.get_children():
        if c is LineEdit:
            a.append(c.text)
        
    rule_data.set_arg(arg_name, a)

func _on_string_list_add_pressed() -> void:
    var str_input = string_input.instantiate()
    string_list.add_child(str_input)
    str_input.text_changed.connect(_on_string_list_value_changed)
    string_list.move_child(add_string_list, string_list.get_child_count() - 1)
