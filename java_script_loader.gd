extends Node

func _ready() -> void:
    if OS.has_feature("web"):
        print("setup listener")
        _setup_web_paste_listener()


func _setup_web_paste_listener() -> void:
    print("Setting up web paste listener")

    var js = """
		window.godotWebPasteBuffer = null;

		window.addEventListener("paste", function(event) {
			console.log("Browser paste event fired");

			const clipboardData = event.clipboardData;
			if (!clipboardData) {
				console.log("No clipboardData");
				return;
			}

			const text = clipboardData.getData("text/plain");

			console.log("Browser clipboard:", text);

			window.godotWebPasteBuffer = text;

			event.preventDefault();
		}, true);
	"""

    JavaScriptBridge.eval(js)


func _process(_delta: float) -> void:
    if OS.has_feature("web"):
        _poll_web_paste()


func _poll_web_paste() -> void:
    var text = JavaScriptBridge.eval("""
		(function() {
			if (window.godotWebPasteBuffer === null) {
				return null;
			}
            
			const value = window.godotWebPasteBuffer;
            console.log(value)
			window.godotWebPasteBuffer = null;
			return value;
		})()
    """)

    if text != null:
        print("Received browser clipboard: ", text)
        _inject_text_into_focused_node(text)


func _inject_text_into_focused_node(text: String) -> void:
    var focused_node = get_viewport().gui_get_focus_owner()
    print("Paste: " + text)
    if focused_node is LineEdit:
        focused_node.insert_text_at_caret(text)
    elif focused_node is TextEdit:
        focused_node.insert_text_at_caret(text)
