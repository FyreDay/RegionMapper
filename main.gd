extends Node2D

@onready var map = $Map
@onready var ui:LogicUI = $UI
@onready var node_manager = $NodeManager

var pending_json: String
var pending_meta_json: String
var pending_image: Image
var pending_image_name: String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    ui.map_selected.connect(map.set_map_path)
    ui.save_data.connect(_on_save_data)
    ui.save_path.connect(_on_save_path)
    ui.load_data.connect(_on_load_data)
    ui.export_path.connect(_on_export_data)
    ui.popup_opened.connect(map.camera.disable_input)
    ui.popup_closed.connect(map.camera.enable_input)
    node_manager.popup_opened.connect(map.camera.disable_input)
    node_manager.popup_closed.connect(map.camera.enable_input)
    node_manager.hovered_entrance_update.connect(ui.update_entrance)
    


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
    pass

func _on_load_data(path):
    var zip := ZIPReader.new()
    var err := zip.open(path)
    if err != OK:
        push_error("Failed to open ZIP: " + path)
        zip.close()
        return
    if not zip.file_exists("metadata.json"):
        push_error("Invalid project: metadata.json is missing")
        zip.close()
        return
    if not zip.file_exists("data.json"):
        push_error("Invalid project: nodes.json is missing")
        zip.close()
        return
        
    var meta_bytes := zip.read_file("metadata.json")
    var meta_text := meta_bytes.get_string_from_utf8()
    
    var meta = JSON.parse_string(meta_text)
    
    if not meta.has("version"):
        push_error("Invalid project: missing version")
        zip.close()
        return

    if meta.version != "0.0.1":
        push_error("Unsupported project version: " + str(meta.version))
        zip.close()
        return
        
    if not meta.has("image_name"):
        push_error("Invalid project: missing image name")
        zip.close()
        return
        
    var image := Image.new()
    
    if meta.image_name != "":
        if not zip.file_exists(meta.image_name):
            push_error("Invalid project: " + meta.image_name + " is missing")
            zip.close()
            return
        var image_bytes := zip.read_file(meta.image_name)
        err = image.load_png_from_buffer(image_bytes)
        if err != OK:
            push_error("Failed to load image")
            zip.close()
            return

    print("Metadata valid")
    
    var data_bytes := zip.read_file("data.json")
    var data_text := data_bytes.get_string_from_utf8()

    var data = JSON.parse_string(data_text)

    if data == null or not data is Dictionary or not data.has("nodes") or not data.has("rules"):
        push_error("Invalid project: data.json is not valid JSON")
        zip.close()
        return
    if meta.image_name != "":
        map.set_map(image, meta.image_name)
    ui.load_rule_data(data.get("rules"))
    node_manager.load_data(data.get("nodes"), ui.rule_palette_manager)
    
    zip.close()

func _on_save_data():
    print("save data")
    var data = {"nodes": node_manager.save_data(), "rules": ui.save_rule_data()}
    pending_json = JSON.stringify(data)
    pending_image = map.image
    pending_meta_json = JSON.stringify({
        "version": "0.0.1",
        "image_name": map.image_name
    })
    pending_image_name = map.image_name
    print("open data prompt")
    ui.save_file_dialog.current_file = "map.zip"
    ui.save_file_dialog.popup_centered()
    
func _on_save_path(path):
    if not path.to_lower().ends_with(".zip"):
        path += ".zip"

    var zip := ZIPPacker.new()
    var err := zip.open(path)
    if err != OK:
        push_error("Failed to create ZIP: " + str(err))
        return
    
    zip.start_file("data.json")
    zip.write_file(pending_json.to_utf8_buffer())
    zip.close_file()

    zip.start_file("metadata.json")
    zip.write_file(pending_meta_json.to_utf8_buffer())
    zip.close_file()

    if pending_image != null:
        var image_buffer := pending_image.save_png_to_buffer()

        zip.start_file(pending_image_name)
        zip.write_file(image_buffer)
        zip.close_file()

        zip.close()

    print("Saved to: ", path)

func write_file(path: String, contents: String):
    var file := FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        push_error("Failed to write: " + path)
        return

    file.store_string(contents)
    file.close()

func _on_export_data(dir:String):
    var save_data = node_manager.save_data()
    write_file(
        dir.path_join("regions.py"),
        generate_regions_python(save_data.regions)
    )

    write_file(
        dir.path_join("entrances.py"),
        generate_entrances_python(save_data.entrances)
    )

func generate_regions_python(data):
    var output := ""
    output += "from enum import Enum\n\n"
    output += "class Regions(Enum):\n"
    for region in data:
        output += '    ' + region.id + ' = ' + JSON.stringify(region.name) + '\n'
    return output
    
const ENTRANCES_HEADER := """\
from enum import Enum

from .regions import Regions
from rule_builder.rules import Has, True_

class EntranceTypeEnum(Enum):
    def __init__(self, value: str, exiting_region: RegionTypeEnum, entering_region: RegionTypeEnum, entrance_group: Number, rule = True_()):
        # self._value_ must be set to the first element to support lookup by value
        self._value_ = value
        self.exiting_screen = exiting_region
        self.entering_screen = entering_region
        self.entrance_group = entrance_group
        self.rule = rule


"""

func generate_entrances_python(data):
    var output := ENTRANCES_HEADER
    output += "class Entrances(EntranceTypeEnum):\n"
    for entrance in data:
        #TODO:attach entrance group
        output += ('    ' + entrance.id + ' = (' + JSON.stringify(entrance.name) + 
        ', Regions.' + entrance.from_region + ', Regions.' + entrance.to_region + 
        ', ' + '0' + get_rule_dict(entrance.rule_name) + ')\n')
        if entrance.dual_directional:
            output += ('    ' + entrance.id + '_BACK = (' + JSON.stringify(entrance.name + ' Backwards') + 
        ', Regions.' + entrance.to_region + ', Regions.' + entrance.from_region + 
        ', ' + '0' +  get_rule_dict(entrance.rule_name) + ')\n')
    return output
    
    
func get_rule_dict(rule_name: String):
    if rule_name == null or rule_name == "":
        return ""
    var combo = ui.get_rule_combo(rule_name)
    if not combo.root:
        return ""
    return (', ' +  JSON.stringify(combo.root.to_dict()))
   
    
    
    
