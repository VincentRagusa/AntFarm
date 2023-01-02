extends Node2D
onready var camera = $Camera2D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var tracking_agent = false
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if tracking_agent == false:
		$Camera2D.position = get_global_mouse_position()
	#else:
		#$Camera2D.position = 
	
func _input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == BUTTON_WHEEL_UP:
				if $Camera2D.zoom > Vector2(.3,.3):
					$Camera2D.zoom = $Camera2D.zoom - Vector2(0.1,0.1)
			if event.button_index == BUTTON_WHEEL_DOWN:
				if $Camera2D.zoom < Vector2(2.5,2.5):
					$Camera2D.zoom = $Camera2D.zoom + Vector2(0.1,0.1)


func handle_change_view():
	camera.make_current()
	

