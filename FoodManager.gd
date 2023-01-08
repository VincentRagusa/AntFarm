extends Node2D


export(PackedScene) var Food
export(float) var spawnDelay #units: second

var MIN_FOOD:int = 1000
var foodInstanceCounter:int = 0
var offset:int = 64
var deltaSum:float = 0

var rng = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	rng.randomize()

func _process(delta):
	deltaSum += delta
	while deltaSum >= spawnDelay and foodInstanceCounter < MIN_FOOD:
		deltaSum -= spawnDelay
		#print("only", foodInstanceCounter, "food left, spawning more")
		var pos = Vector2(rng.randi_range(offset, 3840-offset),rng.randi_range(offset, 2160-offset))
#		GlobalSignals.emit_signal("food_spawned", pos ) #signaling here may be inefficient
		handle_food_spawn(pos) 

func handle_food_spawn(pos: Vector2):
	foodInstanceCounter += 1
	#print("Food Created",foodInstanceCounter)
	var food_instance = Food.instance()
	if rng.randf() < 0.5:
		#red
		food_instance.foodColor = "Red"
	else:
		#blue
		food_instance.foodColor = "Blue"
		food_instance.get_node("Sprite").modulate = Color(0,0,1)
	add_child(food_instance)
	food_instance.global_position = pos

func handle_food_depleated():
	foodInstanceCounter -= 1
	#print("Food depleated", foodInstanceCounter)
	
