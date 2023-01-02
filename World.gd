extends Node

onready var agent_manager = $AgentManager
onready var food_manager = $FoodManager
onready var view = $view

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	GlobalSignals.connect("agent_born", agent_manager, "handle_agent_birth")
	GlobalSignals.connect("agent_spawned", agent_manager, "handle_agent_spawn")
	GlobalSignals.connect("food_spawned", food_manager, "handle_food_spawn")
	GlobalSignals.connect("food_depleated", food_manager, "handle_food_depleated")
	GlobalSignals.connect("agent_died", agent_manager, "handle_agent_death")
	GlobalSignals.connect("changed_view", view, "handle_change_view")
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

