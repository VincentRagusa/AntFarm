extends Node2D
onready var camera = $Camera2D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var mouse_start_pos
var screen_start_position
var dragging = false

var tracking_agent = false
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	#if tracking_agent == false:
		#$Camera2D.position = get_global_mouse_position()
	#else:
		#$Camera2D.position = 
	
func _input(event):

	if event.is_action("zoom_up"):
		if $Camera2D.zoom > Vector2(.3,.3):
			$Camera2D.zoom = $Camera2D.zoom - Vector2(0.1,0.1)
	elif event.is_action("zoom_out"):
		if $Camera2D.zoom < Vector2(2.5,2.5):
			$Camera2D.zoom = $Camera2D.zoom + Vector2(0.1,0.1)
	elif event.is_action("drag"):
		if event.is_pressed():
			mouse_start_pos = event.position
			screen_start_position = position
			dragging = true
		else:
			dragging = false
	elif event is InputEventMouseMotion and dragging:
		position = (mouse_start_pos - event.position) + screen_start_position



func handle_change_view():
	camera.make_current()
	

