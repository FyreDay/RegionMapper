extends Node

func _ready() -> void:
    if OS.has_feature("web"):
        _setup_web_paste_bridge()


func _setup_web_paste_bridge() -> void:
    JavaScriptBridge.eval("""
		window.godotPaste = async function() {
			try {
				const text = await navigator.clipboard.readText();
				window.godotWebPasteBuffer = text;
			} catch (e) {
				console.error("Clipboard read failed:", e);
				window.godotWebPasteBuffer = "";
			}
		};

		window.godotWebPasteBuffer = "";
    """)


func _unhandled_key_input(event: InputEvent) -> void:
    if not OS.has_feature("web"):
        return

    if event is InputEventKey \
            and event.pressed \
            and not event.echo \
            and event.keycode == KEY_V \
            and (event.ctrl_pressed or event.meta_pressed):

        print("Godot Ctrl+V pressed")

        JavaScriptBridge.eval("window.godotPaste();")

        get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
    if OS.has_feature("web"):
        _poll_web_paste()


func _poll_web_paste() -> void:
    var text = JavaScriptBridge.eval("window.godotWebPasteBuffer")

    if text != null and text != "":
        JavaScriptBridge.eval("window.godotWebPasteBuffer = '';")

        print("Pasted: ", text)

        _inject_text_into_focused_node(text)


func _inject_text_into_focused_node(text: String) -> void:
    var focused_node = get_viewport().gui_get_focus_owner()

    if focused_node is LineEdit:
        focused_node.insert_text_at_caret(text)
    elif focused_node is TextEdit:
        focused_node.insert_text_at_caret(text)
