extends Node2D
onready var camera = $Camera2D

var mouse_start_pos
var screen_start_position
var dragging = false

func _ready():
	pass 

func _process(delta):
	pass

func _input(event):
	if event.is_action("zoom_in"):
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
