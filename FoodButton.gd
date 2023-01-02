extends Button

onready var textInput = get_parent().get_node("FoodNum")

# Declare member variables here. Examples:
var rng = RandomNumberGenerator.new()
	


# Called when the node enters the scene tree for the first time.
func _ready():
	rng.randomize()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Button2_pressed():
	var pos = null
	var num = int(textInput.text)
	for i in range(num):
		pos = Vector2(rng.randi_range(16, 3840-16),rng.randi_range(16, 2160-16))
		GlobalSignals.emit_signal("food_spawned", pos )
