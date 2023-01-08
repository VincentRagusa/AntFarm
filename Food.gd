extends KinematicBody2D


# Declare member variables here. Examples:
var food_level:int = 5
var food_onHit:int = 5
var foodColor:String = "None"
var switchCost:int = 8
# Called when the node enters the scene tree for the first time.
#func _ready():
#	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_Area2D_body_entered(body):
	if body.is_in_group("Agent"):
		if not body.spike_extended:
			if body.lastFoodColor == foodColor or body.lastFoodColor == "None":
				body.food_level += food_onHit
				body.food_eaten_tracker += 1
			else:
				body.food_level -= switchCost
				body.switch_counter += 1
			food_level -= food_onHit
			body.food_collision = 1 #bool
			body.lastFoodColor = foodColor
			if food_level <= 0:
				GlobalSignals.emit_signal("food_depleated")
				queue_free()
