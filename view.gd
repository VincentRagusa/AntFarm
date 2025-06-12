extends Node2D
onready var camera = $Camera2D

var mouse_start_pos
var screen_start_position
var dragging = false

#func _ready():
#	pass 

#func _process(delta):
#	pass
const MIN_ZOOM: float = 0.3
const MAX_ZOOM: float = 3.0
const ZOOM_VEL: float = 0.05

func _input(event):
	if event.is_action("zoom_in"):
		if $Camera2D.zoom > Vector2(MIN_ZOOM,MIN_ZOOM):
			$Camera2D.zoom = $Camera2D.zoom - Vector2(ZOOM_VEL,ZOOM_VEL)
	elif event.is_action("zoom_out"):
		if $Camera2D.zoom < Vector2(MAX_ZOOM,MAX_ZOOM):
			$Camera2D.zoom = $Camera2D.zoom + Vector2(ZOOM_VEL,ZOOM_VEL)
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
