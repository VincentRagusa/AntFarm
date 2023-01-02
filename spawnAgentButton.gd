extends Button


# Declare member variables here. Examples:
var rng = RandomNumberGenerator.new()
	


# Called when the node enters the scene tree for the first time.
func _ready():
	rng.randomize()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Button_pressed():
	var pos = Vector2(rng.randi_range(64, 3840-64),rng.randi_range(64, 2160-64))
	GlobalSignals.emit_signal("agent_spawned", pos)
