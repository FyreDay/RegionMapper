class_name CustomEdit
extends LineEdit

var _web_paste_callback

func _ready() -> void:
    if OS.get_name() == "Web":
        _setup_web_paste_bridge()

func _gui_input(event: InputEvent) -> void:
    if OS.get_name() == "Web" and event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_V and (event.ctrl_pressed or event.meta_pressed):
            print("Ctrl v pressed")
            print(event.as_text())
            get_viewport().set_input_as_handled()  
    
func _setup_web_paste_bridge() -> void:
    _web_paste_callback = JavaScriptBridge.create_callback(_on_web_paste)
    var window = JavaScriptBridge.get_interface("window")
    window.godotPasteCallback = _web_paste_callback
    JavaScriptBridge.eval("""
    (function() {
        window.addEventListener('paste', function(e) {
            console.log('[paste] event fired, target=', e.target);
            var cd = e.clipboardData || window.clipboardData;
            if (!cd) { console.log('[paste] no clipboardData object'); return; }
            var text = cd.getData('text/plain');
            console.log('[paste] captured text:', JSON.stringify(text));
            if (window.godotPasteCallback) {
                window.godotPasteCallback(text);
            } else {
                console.log('[paste] godotPasteCallback missing!');
            }
        });
        console.log('[paste] listener registered');
    })();
    """, true)

func _on_web_paste(args: Array) -> void:
    print("[paste] _on_web_paste called with: ", args)
    if args.is_empty():
        return
    var text := str(args[0])
    var focused := get_viewport().gui_get_focus_owner()
    print("[paste] focused node: ", focused)
    if focused == self:
        DisplayServer.clipboard_set(text)
        menu_option(LineEdit.MENU_PASTE)
        print("[paste] pasted into LineEdit")
