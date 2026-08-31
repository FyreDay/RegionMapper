class_name RuleArgType
extends HBoxContainer
@onready var arg_type: OptionButton = $ArgType
@onready var arg_name: LineEdit = $ArgName
@onready var text_value: LineEdit = $StringValue
@onready var int_value: SpinBox = $IntValue
@onready var number_value: SpinBox = $FloatValue
@onready var bool_value: CheckBox = $BoolValue
@onready var string_list: HBoxContainer = $StringListValue
@onready var add_string_list: Button = $StringListValue/Add
var string_input = preload("res://custom/input.tscn")

var old_arg_type:ArgType
var old_name:=""
var custom_rule:CustomRule

func _ready() -> void:
    arg_type.add_item("STRING", CustomRuleArgumentDefinition.RuleArgType.STRING)
    arg_type.add_item("INT", CustomRuleArgumentDefinition.RuleArgType.INT)
    arg_type.add_item("FLOAT", CustomRuleArgumentDefinition.RuleArgType.FLOAT)
    arg_type.add_item("BOOL", CustomRuleArgumentDefinition.RuleArgType.BOOL)
    arg_type.add_item("STRING_LIST", CustomRuleArgumentDefinition.RuleArgType.STRING_LIST)

func setup(new_custom_rule:CustomRule):
    
    custom_rule = new_custom_rule
    print("ARG TYPE SETUP: ", custom_rule.get_instance_id())

    old_arg_type = ArgType.new()
    text_value.hide()
    number_value.hide()
    int_value.hide()
    bool_value.hide()
    string_list.hide()
    _on_arg_type_item_selected(0)

func remove_arg():
    pass

func _on_arg_type_item_selected(index: int) -> void:
    text_value.hide()
    number_value.hide()
    int_value.hide()
    bool_value.hide()
    string_list.hide()
    old_arg_type.arg_type = index as CustomRuleArgumentDefinition.RuleArgType
    match index:
        CustomRuleArgumentDefinition.RuleArgType.STRING:
            text_value.show()
            text_value.text = ""
            old_arg_type.default_value = ""

        CustomRuleArgumentDefinition.RuleArgType.INT:
            int_value.show()
            int_value.value = 0
            old_arg_type.default_value = 0
        CustomRuleArgumentDefinition.RuleArgType.FLOAT:
            number_value.show()
            number_value.value = 0
            old_arg_type.default_value = 0

        CustomRuleArgumentDefinition.RuleArgType.BOOL:
            bool_value.show()
            bool_value.button_pressed = false
            old_arg_type.default_value = false
        
        CustomRuleArgumentDefinition.RuleArgType.STRING_LIST:
            string_list.show()
            for c in string_list.get_children():
                if not c is Button:
                    string_list.remove_child(c)
            old_arg_type.default_value = []


func _on_string_value_text_changed(new_text: String) -> void:
    old_arg_type.default_value = new_text
    custom_rule.arg_definitions[old_name] = old_arg_type
    print(str(custom_rule.to_dict()))


func _on_int_value_value_changed(value: float) -> void:
    old_arg_type.default_value = value
    custom_rule.arg_definitions[old_name] = old_arg_type
    print(str(custom_rule.to_dict()))


func _on_bool_value_toggled(toggled_on: bool) -> void:
    old_arg_type.default_value = toggled_on
    custom_rule.arg_definitions[old_name] = old_arg_type

func _on_string_list_value_changed(_value: String) -> void:
    var a:= []
    for c in string_list.get_children():
        if c is LineEdit:
            a.append(c.text)
    old_arg_type.default_value = a
    custom_rule.arg_definitions[old_name] = old_arg_type

func _on_string_list_add_pressed() -> void:
    var str_input = string_input.instantiate()
    string_list.add_child(str_input)
    str_input.text_changed.connect(_on_string_list_value_changed)
    string_list.move_child(add_string_list, string_list.get_child_count() - 1)

func _on_float_value_value_changed(value: float) -> void:
    old_arg_type.default_value = value
    custom_rule.arg_definitions[old_name] = old_arg_type


func _on_arg_name_text_changed(new_text: String) -> void:
    print("ARG TYPE NAME CHANGE: ", custom_rule.get_instance_id())

    if not custom_rule.arg_definitions.has(new_text):
        custom_rule.arg_definitions.erase(old_name)
        custom_rule.arg_definitions[new_text] = old_arg_type
        arg_name.remove_theme_stylebox_override("normal")
        old_name = new_text
    else:
        var style = arg_name.get_theme_stylebox("normal").duplicate()
        style.border_color = Color.RED
        style.set_border_width_all(2)

        arg_name.add_theme_stylebox_override("normal", style)
        
