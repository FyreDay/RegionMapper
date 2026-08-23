extends Camera2D
var zoomTarget :Vector2
var zoomMult: float
var dragStartMousePos = Vector2.ZERO
var dragStartCameraPos = Vector2.ZERO
var isDragging = false
var input_enabled = true
var map_scale = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    zoomTarget = zoom
    zoomMult=1
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    Zoom(delta)
    SimplePan(delta)
    ClickAndDrag()

func Zoom(delta):
    if not input_enabled:
        return
    if Input.is_action_just_pressed("camera_zoom_in"):
        zoomTarget *= 1.1
        zoomMult /= 1.1
    if Input.is_action_just_pressed("camera_zoom_out"):
        zoomTarget /= 1.1
        zoomMult *= 1.1
    zoom = zoom.slerp(zoomTarget, 10 * delta)
    
func SimplePan(delta):
    if not input_enabled:
        return
    var moveAmount = Vector2.ZERO
    if Input.is_action_pressed("camera_move_right"):
        moveAmount.x += 1
    if Input.is_action_pressed("camera_move_left"):
        moveAmount.x -= 1
    if Input.is_action_pressed("camera_move_up"):
        moveAmount.y -= 1
    if Input.is_action_pressed("camera_move_down"):
        moveAmount.y += 1
    
    moveAmount = moveAmount.normalized()
    position += moveAmount * delta * 1000 * zoomMult * (1.0/map_scale)
    
func ClickAndDrag():
    if not input_enabled:
        return
    if !isDragging and Input.is_action_just_pressed("camera_pan"):
        dragStartMousePos = get_viewport().get_mouse_position()
        dragStartCameraPos = position
        isDragging = true
        
    if isDragging and Input.is_action_just_released("camera_pan"):
        isDragging = false
        
    if isDragging:
        var moveVector = get_viewport().get_mouse_position() - dragStartMousePos
        position = dragStartCameraPos - moveVector * 1/(zoom.x * map_scale)
        
func disable_input() -> void:
    input_enabled = false
    isDragging = false

func enable_input() -> void:
    input_enabled = true

func set_map_scale(new_scale:float):
    map_scale = new_scale/10
