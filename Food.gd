extends KinematicBody2D


# Declare member variables here. Examples:
var food_level = 5

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Area2D_body_entered(body):
	if body.is_in_group("Agent"):
		body.food_level += 5 # probably should do thsi with a signal?
		body.food_collected = 1
		body.food_eaten_tracker += 1
		food_level -= 5
		if food_level <= 0:
			#disabled = true
			GlobalSignals.emit_signal("food_depleated")
			queue_free()
