class_name CustomEdit
extends LineEdit

static var focused_edit: CustomEdit
var _web_paste_callback


func _ready() -> void:
    focus_entered.connect(_on_focus_entered)

    if OS.get_name() == "Web":
        _setup_web_paste_bridge()

func _exit_tree() -> void:
    if focused_edit == self:
        focused_edit = null


func _on_focus_entered() -> void:
    focused_edit = self

func _gui_input(event: InputEvent) -> void:
    if OS.get_name() == "Web" and event is InputEventKey:
        if event.pressed and not event.echo:
            if event.keycode == KEY_V and (event.ctrl_pressed or event.meta_pressed):
                print("Godot Ctrl+V pressed")

                # Don't mark this as handled.
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

        document.addEventListener('paste', function(e) {
            console.log('[paste] browser paste detected');

            var text = e.clipboardData.getData('text/plain');
            console.log('[paste] clipboard text:', JSON.stringify(text));

            if (window.godotPasteCallback) {
                e.preventDefault();
                window.godotPasteCallback(text);
            }
        }, true); // <-- capture phase

        console.log('[paste] capture listener registered');
    })();
    """, true)

func _on_web_paste(args: Array) -> void:
    print("[paste] Godot callback: ", args)
    if args.is_empty():
        return

    if get_viewport().gui_get_focus_owner() != self:
        return

    var pasted_text := str(args[0])
    insert_text_at_caret(pasted_text)
    print("[paste] inserted into LineEdit")

    
