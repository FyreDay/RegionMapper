class_name CustomEdit
extends LineEdit

var _web_paste_callback: JavaScriptObject


func _ready() -> void:
    if OS.get_name() == "Web":
        _setup_web_paste_bridge()


func _gui_input(event: InputEvent) -> void:
    if OS.get_name() == "Web" and event is InputEventKey:
        if event.pressed and not event.echo:
            if event.keycode == KEY_V and (event.ctrl_pressed or event.meta_pressed):
                print("Godot Ctrl+V pressed")

                # Don't mark this as handled.
                # Let the browser perform its normal paste operation.


func _setup_web_paste_bridge() -> void:
    _web_paste_callback = JavaScriptBridge.create_callback(_on_web_paste)

    var window := JavaScriptBridge.get_interface("window")
    window.godotPasteCallback = _web_paste_callback

    JavaScriptBridge.eval("""
        (function() {
            if (window.godotPasteListenerInstalled) {
                return;
            }

            window.godotPasteListenerInstalled = true;

            // Capture the actual browser paste event.
            window.addEventListener('paste', function(e) {
                console.log('[paste] browser paste event fired');

                var text = e.clipboardData.getData('text/plain');

                console.log('[paste] paste event text:', JSON.stringify(text));

                if (window.godotPasteCallback) {
                    window.godotPasteCallback(text);
                    e.preventDefault();
                }
            }, true); // Capture phase is important.

            console.log('[paste] JS paste listener registered');
        })();
    """, true)


func _on_web_paste(args: Array) -> void:
    print("[paste] Godot callback: ", args)

    if args.is_empty():
        return

    var text := str(args[0])

    if not has_focus():
        return

    insert_text_at_caret(text)
    print("[paste] inserted into LineEdit")
