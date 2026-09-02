#extends Node
#
#func _ready() -> void:
    #if OS.has_feature("web"):
        #print("setup listener")
        #_setup_web_paste_bridge()
#
#
#func _setup_web_paste_bridge() -> void:
    #JavaScriptBridge.eval("""
        #window.godotWebPasteBuffer = null;
#
        #window.addEventListener("keydown", function(event) {
            #if ((event.ctrlKey || event.metaKey) &&
                #event.key.toLowerCase() === "v") {
#
                #console.log("Browser Ctrl+V");
                #event.stopImmediatePropagation()
                #const input = document.createElement("textarea");
#
                #input.style.position = "fixed";
                #input.style.left = "-10000px";
                #input.style.top = "0";
                #input.style.opacity = "0";
#
                #document.body.appendChild(input);
                #input.focus();
#
                #input.addEventListener("paste", function(pasteEvent) {
                    #console.log("Browser paste received");
#
                    #window.godotWebPasteBuffer =
                        #pasteEvent.clipboardData.getData("text/plain");
#
                    #input.remove();
                #});
            #}
        #}, true);
    #""")
#
#
#func _process(_delta: float) -> void:
    #if not OS.has_feature("web"):
        #return
#
    #var text = JavaScriptBridge.eval("window.godotWebPasteBuffer")
    #print(text)
    #if text != null:
        #JavaScriptBridge.eval("window.godotWebPasteBuffer = null;")
        #_inject_text_into_focused_node(text)
#
#
#func _inject_text_into_focused_node(text: String) -> void:
    #var focused_node = get_viewport().gui_get_focus_owner()
    #print("Paste: " + text)
    #if focused_node is LineEdit:
        #focused_node.insert_text_at_caret(text)
    #elif focused_node is TextEdit:
        #focused_node.insert_text_at_caret(text)
