class_name LogicUI
extends Control

signal popup_opened
signal popup_closed
signal map_selected(path: String)
signal load_data
signal save_data
signal save_path(path: String)
signal export_path(dir: String)
signal rule_builder_toggled(bool)
signal request_web_import
signal request_web_map_import
signal flags_updated

signal region_scale_changed(float)

@onready var file_dialog: FileDialog = $FilePngDialog
@onready var save_file_load_dialog: FileDialog = $FileLoadDialog
@onready var save_file_dialog: FileDialog = $SaveFileDialog
@onready var export_dialog: FileDialog = $ExportDirDialog

@onready var tool_panel: Panel = $CanvasLayer/Panel
@onready var rule_palette_panel: Panel = $CanvasLayer/PalettePanel
@onready var rule_builder_toggle: Button = $CanvasLayer/PalettePanel/Title/RuleBuilderToggle
#@onready var rule_part_panel: Panel = 
@onready var rule_editor_panel: Panel = $CanvasLayer/RuleEditor
@onready var drag_layer: DragLayer = $CanvasLayer/DragLayer
@onready var new_rule_combo_button: Button = $CanvasLayer/PalettePanel/ScrollContainer/RulePaletteManager/New
@onready var root_rule_spot: RuleSpot = $CanvasLayer/RuleEditor/RuleBuilderPanel/ScrollContainer/HBoxContainer/RuleSpot
@onready var root_rule_label: Label = $CanvasLayer/RuleEditor/RuleBuilderPanel/ScrollContainer/HBoxContainer/RootRuleLabel

@onready var rule_manager: RuleManager = $CanvasLayer/RuleEditor/RulePartPanel/ScrollContainer/RuleManager
@onready var rule_palette_manager: RulePaletteManager = $CanvasLayer/PalettePanel/ScrollContainer/RulePaletteManager
@onready var entrance_group_panel: PopupPanel = $EntranceGroupPopupPanel

@onready var custom_rule_creator: CustomRuleCreator = $CustomRuleCreator

@onready var hint_panel: PopupPanel = $ControlHintPanel
@onready var scale_spinner: SpinBox = $CanvasLayer/Panel/HBoxContainer/ScaleSpinBox

@onready var group_editor: GroupEditor = $EntranceGroupPopupPanel/EntranceGroupEditor

var dragable = preload("res://rules/Dragable_Rule.tscn")

var palette_open = false
var rule_builder_open = false
var selected_dragable_rule_combo:DragableRuleNameEdit

func _ready() -> void:
    root_rule_spot.hide()
    root_rule_label.text = "Select a rule from the palette"
    group_editor.changed.connect(flags_updated.emit)

func _process(delta: float) -> void:
    slide_panel(delta)

func slide_panel(delta):
    var new_pos = Vector2(0,tool_panel.size.y)
    if not palette_open:
        new_pos.x = -rule_palette_panel.size.x
    
    rule_palette_panel.position = rule_palette_panel.position.lerp(new_pos, 10 * delta)
    
    var new_editor_pos = Vector2(tool_panel.size.x,tool_panel.size.y)
    if rule_builder_open:
        new_editor_pos.x = tool_panel.size.x-rule_editor_panel.size.x
    
    rule_editor_panel.position = rule_editor_panel.position.lerp(new_editor_pos, 10 * delta)  


func _on_file_dialog_file_selected(path: String) -> void:
    map_selected.emit(path)

func _on_button_pressed() -> void:
    if OS.get_name() == "Web":
        request_web_map_import.emit() 
    else:
        file_dialog.popup_file_dialog()

func _on_save_button_pressed() -> void:
    save_data.emit()


func _on_load_button_pressed() -> void:
    if OS.get_name() == "Web":
        request_web_import.emit()
    else:
        save_file_load_dialog.popup_file_dialog()


func _on_file_load_dialog_file_selected(path: String) -> void:
    load_data.emit(path)


func _on_save_file_dialog_file_selected(path: String) -> void:
    save_path.emit(path)


func _on_export_button_pressed() -> void:
    if OS.get_name() == "Web":
        export_path.emit("")   # dir is ignored on web, see main.gd
    else:
        export_dialog.popup_file_dialog()

func _on_export_dir_dialog_dir_selected(dir: String) -> void:
    export_path.emit(dir)


func _on_slide_toggle_toggled(toggled_on: bool) -> void:
    palette_open = toggled_on
    if not palette_open:
        rule_builder_toggle.button_pressed = false
        queue_redraw()
        
func update_entrance(entrance:Entrance):
    drag_layer.update_entrance(entrance)

func _on_rule_builder_toggled(toggled_on: bool) -> void:
    print("toggles")
    rule_builder_open = toggled_on
    rule_builder_toggled.emit(toggled_on)
    if not toggled_on:
        selected_dragable_rule_combo = null
        root_rule_spot.hide()
        root_rule_label.text = "Select a rule from the palette"
        queue_redraw()

    
func _on_rule_combo_selected(selected_rule_combo:DragableRuleNameEdit):
    if selected_dragable_rule_combo and root_rule_spot.new_root.is_connected(selected_dragable_rule_combo.update_rule_data):
        root_rule_spot.new_root.disconnect(selected_dragable_rule_combo.update_rule_data)
    if selected_rule_combo:
        root_rule_spot.show()
        root_rule_label.text = "Root Rule"
    print("Selected " + selected_rule_combo.rule_combo.combo_name)
    selected_dragable_rule_combo = selected_rule_combo
    root_rule_spot.from_rule_data(selected_dragable_rule_combo.rule_combo.root)
    root_rule_spot.new_root.connect(selected_dragable_rule_combo.update_rule_data)
    queue_redraw()
    
func save_rule_data():
    return {"custom_rules": rule_manager.save_data(), "rule_combos": rule_palette_manager.save_data()}
    
func load_rule_data(data:Dictionary):
    rule_manager.load_data(data, drag_layer)
    rule_palette_manager.load_data(data, rule_manager, drag_layer)

func get_rule_combo(new_name: String) -> RuleCombo:
    return rule_palette_manager.get_rule_combo(new_name)

func _on_open_creator_pressed() -> void:
    custom_rule_creator.popup(CustomRule.new(), rule_manager, drag_layer)


func _on_spin_box_value_changed(value: float) -> void:
    region_scale_changed.emit(value)

func set_scale_spinner(value: float):
    scale_spinner.value = value

func _on_control_hint_pressed() -> void:
    hint_panel.popup()

func _on_open_flags_button_pressed() -> void:
    entrance_group_panel.popup()


func _on_entrance_group_popup_panel_popup_hide() -> void:
    pass
    
func _on_flags_updated(arr:Array):
    group_editor.load_array(arr)
