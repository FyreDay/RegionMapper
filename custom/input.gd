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
                get_viewport().set_input_as_handled()


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

            window.addEventListener('keydown', function(e) {
                if ((e.ctrlKey || e.metaKey) &&
                    (e.key === 'v' || e.key === 'V')) {

                    console.log('[paste] JS Ctrl+V detected');

                    if (!navigator.clipboard) {
                        console.log('[paste] navigator.clipboard unavailable');
                        return;
                    }

                    navigator.clipboard.readText()
                        .then(function(text) {
                            console.log('[paste] clipboard text:', JSON.stringify(text));

                            if (window.godotPasteCallback) {
                                window.godotPasteCallback(text);
                            } else {
                                console.log('[paste] godotPasteCallback missing!');
                            }
                        })
                        .catch(function(err) {
                            console.error('[paste] clipboard.readText() failed:', err);
                        });
                }
            });

            console.log('[paste] JS keydown listener registered');
        })();
    """, true)


func _on_web_paste(args: Array) -> void:
    print("[paste] Godot callback: ", args)

    if args.is_empty():
        return

    var text := str(args[0])

    var focused := get_viewport().gui_get_focus_owner()
    print("[paste] focused node: ", focused)

    if focused != self:
        print("[paste] LineEdit is not focused")
        return

    # Insert directly rather than trying to invoke LineEdit's native paste.
    insert_text_at_caret(text)

    print("[paste] inserted into LineEdit")
