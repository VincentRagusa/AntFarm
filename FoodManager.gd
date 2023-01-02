extends Node2D


export(PackedScene) var Food

onready var spawnTimer = $spawnTimer

var MIN_FOOD = 600
var foodInstanceCounter = 0
var offset = 64

# Called when the node enters the scene tree for the first time.
func _ready():
	spawnTimer.start()

func _process(delta):
	if spawnTimer.is_stopped() and foodInstanceCounter < MIN_FOOD:
		#print("only", foodInstanceCounter, "food left, spawning more")
		var rng = RandomNumberGenerator.new()
		rng.randomize()
		var pos = Vector2(rng.randi_range(offset, 3840-offset),rng.randi_range(offset, 2160-offset))
		GlobalSignals.emit_signal("food_spawned", pos )
		spawnTimer.start()

func handle_food_spawn(pos: Vector2):
	foodInstanceCounter += 1
	#print("Food Created",foodInstanceCounter)
	var food_instance = Food.instance()
	add_child(food_instance)
	food_instance.global_position = pos

func handle_food_depleated():
	foodInstanceCounter -= 1
	#print("Food depleated", foodInstanceCounter)
	
