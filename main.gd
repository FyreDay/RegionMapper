extends Node2D

@onready var map = $Map
@onready var ui:LogicUI = $UI
@onready var node_manager = $NodeManager

var pending_json: String
var pending_meta_json: String
var pending_image: Image
var pending_image_name: String

# Keep references to JS callbacks alive until they fire, or they'll be garbage
# collected and JS's call into them will silently do nothing.
var _web_zip_upload_callback
var _web_png_upload_callback

var undo_redo := UndoRedo.new()

func _ready() -> void:
    ui.region_scale_changed.connect(map._on_region_scale)
    node_manager.setup(undo_redo)
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

    ui.request_web_import.connect(_start_web_zip_upload)
    ui.request_web_map_import.connect(_start_web_png_upload)

func _process(_delta: float) -> void:
    pass

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("redo"):
        undo_redo.redo()
        get_viewport().set_input_as_handled()
        return
    if event.is_action_pressed("undo"):
        undo_redo.undo()
        get_viewport().set_input_as_handled()
    
# ---------------------------------------------------------------------------
# Loading a project zip (shared by desktop FileDialog and web upload)
# ---------------------------------------------------------------------------

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
        map.set_map(image, meta.image_name, meta.get("map_scale", 10))
        ui.set_scale_spinner(meta.get("map_scale", 10))
    ui.load_rule_data(data.get("rules"))
    node_manager.load_data(data.get("nodes"), ui.rule_palette_manager)

    zip.close()

# ---------------------------------------------------------------------------
# Saving a project zip (shared helper, called from both desktop and web paths)
# ---------------------------------------------------------------------------

func _on_save_data():
    var data = {"nodes": node_manager.save_data(), "rules": ui.save_rule_data()}
    pending_json = JSON.stringify(data)
    pending_image = map.image
    pending_meta_json = JSON.stringify({
        "version": "0.0.1",
        "image_name": map.image_name,
        "map_scale": map.map_scale
    })
    pending_image_name = map.image_name

    if OS.get_name() == "Web":
        _download_project_zip()
        return

    ui.save_file_dialog.current_file = "map.zip"
    ui.save_file_dialog.popup_centered()

func _on_save_path(path):
    if not path.to_lower().ends_with(".zip"):
        path += ".zip"

    var err := _write_project_zip(path)
    if err != OK:
        push_error("Failed to create ZIP: " + str(err))
        return

    print("Saved to: ", path)

# Writes data.json + metadata.json + (optional) image into a zip at `path`.
# `path` can be a real OS path (desktop) or a user:// path (web tmp file) —
# ZIPPacker/FileAccess both resolve user:// the same on every platform.
func _write_project_zip(path: String) -> Error:
    var zip := ZIPPacker.new()
    var err := zip.open(path)
    if err != OK:
        return err

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

    zip.close()   # unconditional now — was the bug
    return OK

func _download_project_zip() -> void:
    var tmp_path := "user://_export_tmp.zip"
    var err := _write_project_zip(tmp_path)
    if err != OK:
        push_error("Failed to build project zip: " + str(err))
        return

    var f := FileAccess.open(tmp_path, FileAccess.READ)
    var bytes := f.get_buffer(f.get_length())
    f.close()
    DirAccess.remove_absolute(tmp_path)

    JavaScriptBridge.download_buffer(bytes, "map.zip", "application/zip")

# ---------------------------------------------------------------------------
# Python export — zipped on both platforms; written to disk on desktop,
# downloaded on web (there's no folder picker on web to write loose files to)
# ---------------------------------------------------------------------------

func write_file(path: String, contents: String):
    var file := FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        push_error("Failed to write: " + path)
        return
    file.store_string(contents)
    file.close()

func _on_export_data(dir:String):
    var save_data = node_manager.save_data()
    var regions_py := generate_regions_python(save_data.regions)
    var entrances_py := generate_entrances_python(save_data.entrances)

    if OS.get_name() == "Web":
        var bytes := _zip_files_to_bytes({
            "regions.py": regions_py.to_utf8_buffer(),
            "entrances.py": entrances_py.to_utf8_buffer(),
        })
        JavaScriptBridge.download_buffer(bytes, "python_export.zip", "application/zip")
        return

    write_file(dir.path_join("regions.py"), regions_py)
    write_file(dir.path_join("entrances.py"), entrances_py)

# Zips an arbitrary {filename: PackedByteArray} dict into memory and returns
# the finished zip's bytes. Uses a user:// tmp file since ZIPPacker needs a
# backing path, then reads it back and deletes it.
func _zip_files_to_bytes(files: Dictionary) -> PackedByteArray:
    var tmp_path := "user://_tmp_export.zip"
    var zip := ZIPPacker.new()
    var err := zip.open(tmp_path)
    if err != OK:
        push_error("Failed to build zip: " + str(err))
        return PackedByteArray()

    for filename in files:
        zip.start_file(filename)
        zip.write_file(files[filename])
        zip.close_file()
    zip.close()

    var f := FileAccess.open(tmp_path, FileAccess.READ)
    var bytes := f.get_buffer(f.get_length())
    f.close()
    DirAccess.remove_absolute(tmp_path)
    return bytes

func generate_regions_python(data) -> String:
    var output := ""
    output += "from enum import Enum\n\n"
    output += "class Regions(Enum):\n"
    for region in data:
        output += '    ' + region.id + ' = ' + JSON.stringify(region.name) + '\n'
    return output

const ENTRANCES_HEADER := """\
from enum import Enum

from .regions import Regions
from rule_builder.rules import True_

class EntranceTypeEnum(Enum):
    def __init__(self, value: str, exiting_region: RegionTypeEnum, entering_region: RegionTypeEnum, entrance_group: Number, rule = True_()):
        # self._value_ must be set to the first element to support lookup by value
        self._value_ = value
        self.exiting_screen = exiting_region
        self.entering_screen = entering_region
        self.entrance_group = entrance_group
        self.rule = rule


"""

func generate_entrances_python(data) -> String:
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

# ---------------------------------------------------------------------------
# Web-only: browser file upload via a hidden <input type="file">.
# JS hands binary data back as a JavaScriptObject wrapping an ArrayBuffer —
# js_buffer_to_packed_byte_array() converts it to a real PackedByteArray.
# ---------------------------------------------------------------------------

func _start_web_zip_upload() -> void:
    _web_zip_upload_callback = JavaScriptBridge.create_callback(_on_web_zip_uploaded)
    var window = JavaScriptBridge.get_interface("window")
    window.godotZipUploadCallback = _web_zip_upload_callback
    JavaScriptBridge.eval("""
    (function() {
        var input = document.createElement('input');
        input.type = 'file';
        input.accept = '.zip';
        input.style.display = 'none';
        document.body.appendChild(input);
        input.addEventListener('change', function(e) {
            var file = e.target.files[0];
            document.body.removeChild(input);
            if (!file) { return; }
            var reader = new FileReader();
            reader.onload = function(evt) {
                window.godotZipUploadCallback(evt.target.result);
            };
            reader.readAsArrayBuffer(file);
        });
        input.click();
    })();
    """, true)

func _on_web_zip_uploaded(args: Array) -> void:
    if args.is_empty() or not JavaScriptBridge.is_js_buffer(args[0]):
        push_error("Web upload did not return binary data")
        return

    var bytes: PackedByteArray = JavaScriptBridge.js_buffer_to_packed_byte_array(args[0])
    var tmp_path := "user://_import_tmp.zip"
    var f := FileAccess.open(tmp_path, FileAccess.WRITE)
    f.store_buffer(bytes)
    f.close()

    _on_load_data(tmp_path)
    DirAccess.remove_absolute(tmp_path)

func _start_web_png_upload() -> void:
    _web_png_upload_callback = JavaScriptBridge.create_callback(_on_web_png_uploaded)
    var window = JavaScriptBridge.get_interface("window")
    window.godotPngUploadCallback = _web_png_upload_callback
    JavaScriptBridge.eval("""
    (function() {
        var input = document.createElement('input');
        input.type = 'file';
        input.accept = '.png,image/png';
        input.style.display = 'none';
        document.body.appendChild(input);
        input.addEventListener('change', function(e) {
            var file = e.target.files[0];
            document.body.removeChild(input);
            if (!file) { return; }
            var reader = new FileReader();
            reader.onload = function(evt) {
                window.godotPngUploadCallback(evt.target.result, file.name);
            };
            reader.readAsArrayBuffer(file);
        });
        input.click();
    })();
    """, true)

func _on_web_png_uploaded(args: Array) -> void:
    if args.is_empty() or not JavaScriptBridge.is_js_buffer(args[0]):
        push_error("PNG upload did not return binary data")
        return

    var bytes: PackedByteArray = JavaScriptBridge.js_buffer_to_packed_byte_array(args[0])
    var file_name: String = args[1] if args.size() > 1 else "map.png"

    var image := Image.new()
    var err := image.load_png_from_buffer(bytes)
    if err != OK:
        push_error("Failed to decode uploaded PNG")
        return

    map.set_map(image, file_name, 10)
