extends Node2D

@onready var map_sprite: Sprite2D = $map_sprite
@onready var camera: Camera2D = $Camera2D

var image: Image = null
var image_name = ""
var map_scale = 10
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
    pass

func set_map(new_image, new_name, new_scale):
    image = new_image
    image_name = new_name
    var texture := ImageTexture.create_from_image(new_image)
    map_sprite.texture = texture
    _on_region_scale(new_scale)

func set_map_path(path: String) -> void:
    image = Image.load_from_file(path)
    
    if image == null:
        print("Failed to load image: ", path)
        image_name = ""
        return
    image_name = path.get_file()
    var texture := ImageTexture.create_from_image(image)
    map_sprite.texture = texture

func _on_region_scale(new_scale:float):
    map_scale = new_scale
    camera.set_map_scale(new_scale)
    self.scale = Vector2(new_scale/10.0, new_scale/10.0)
    
