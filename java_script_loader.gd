extends Node

func _ready() -> void:
    # Only execute this logic if the application is running in a web export
    if OS.has_feature("web"):
        print("Setup javascript copy/paste bridge")
        _setup_web_paste_listener()

func _setup_web_paste_listener() -> void:
    # 1. Create a global window variable to store data safely
    JavaScriptBridge.eval("window.godotWebPasteBuffer = '';")
    
    # 2. Inject a raw window-level listener for the browser 'paste' event
    var js_listener = """
	window.addEventListener('paste', (event) => {
		// Securely extract plain text straight from the browser event
		let clipboardData = event.clipboardData || window.clipboardData;
		let pastedText = clipboardData.getData('text');
		console.log("Listen to event")
		// Buffer the content into our accessible window variable
		window.godotWebPasteBuffer = pastedText;
	});
	"""
    JavaScriptBridge.eval(js_listener)

func _process(_delta: float) -> void:
    if OS.has_feature("web"):
        _poll_web_paste()

func _poll_web_paste() -> void:
    # Fetch the buffer value to see if a native browser paste occurred
    var current_buffer = JavaScriptBridge.eval("window.godotWebPasteBuffer")
    
    if current_buffer != null and current_buffer != "":
        # Clear out the buffer immediately so it doesn't loop infinitely
        JavaScriptBridge.eval("window.godotWebPasteBuffer = '';")
        print(current_buffer)
        # Send the text to your active input nodes
        _inject_text_into_focused_node(current_buffer)

func _inject_text_into_focused_node(text_to_paste: String) -> void:
    var focused_node = get_viewport().gui_get_focus_owner()
    
    # Detect if the target is a valid text container and modify it directly
    if focused_node is LineEdit:
        focused_node.insert_text_at_caret(text_to_paste)
    elif focused_node is TextEdit:
        focused_node.insert_text_at_caret(text_to_paste)
