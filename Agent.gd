extends KinematicBody2D
class_name Agent

# Constants
const MAX_SPEED:float = 200.0
const ROTATION_SPEED:float = 4.0
const ACCELERATION:float = 300.0

# Member variables
var motion:Vector2 = Vector2.ZERO

# Node references
onready var Genome = $Genome
onready var Brain = $Brain
onready var FoodUse = $FoodUseTimer
onready var camera = $Camera2D
onready var dangerSpikeArea = $DangerSpike
onready var debug_vision_cones = $debugVisionCones
onready var debug_cones = {
	"PL": debug_vision_cones.get_node("PL"),
	"PR": debug_vision_cones.get_node("PR"),
	"Center": debug_vision_cones.get_node("Center"),
	"Touch_N": debug_vision_cones.get_node("Touch_N"),
	"Touch_E": debug_vision_cones.get_node("Touch_E"),
	"Touch_S": debug_vision_cones.get_node("Touch_S"),
	"Touch_W": debug_vision_cones.get_node("Touch_W")
}
onready var debugBrainVisual = $debugBrainVis/Label

# Input signal buffer - using floats instead of ints for faster math operations
var touching_N:float = 0.0
var touching_E:float = 0.0
var touching_S:float = 0.0
var touching_W:float = 0.0
var sees_agent_C:float = 0.0
var sees_food_red_C:float = 0.0
var sees_food_blue_C:float = 0.0
var sees_agent_L:float = 0.0
var sees_food_red_L:float = 0.0
var sees_food_blue_L:float = 0.0
var sees_agent_R:float = 0.0
var sees_food_red_R:float = 0.0
var sees_food_blue_R:float = 0.0

# Other variables
var food_level:int = 25 
var food_collision:bool = false
var spike_collision:bool = false
var was_attacked:bool = false
var lastFoodColor:String = "None"
var food_eaten_tracker:int = 0
var children_had_tracker:int = 0
var switch_counter:int = 0
var intensity:float = -1.0
var inv_intensity:float = -1.0
var evolvedHungerThreshold:int = -1
var spike_extended:bool = false

# Pre-calculated constants
var ONE_THIRD:float = 1.0/3.0
var TWO_THIRDS:float = 2.0/3.0

func _ready():
	FoodUse.start()

func myRound(val:float, decLen:int) -> float:
	return float(int(val * 10.0 * decLen)) / (decLen * 10.0)

func updateDebugText(inputs, outputs, hiddens):
	var text := ""
	for i in inputs:
		text += str(myRound(i, 1))
	text += "\n"
	for h in hiddens:
		text += str(myRound(h, 1))
	text += "\n"
	for o in outputs:
		text += str(myRound(o, 1))
	debugBrainVisual.text = text

func _physics_process(delta):
	
	# Set brain inputs
	Brain.set_input(0, min(touching_N * inv_intensity, 1.0))
	Brain.set_input(1, min(touching_E * inv_intensity, 1.0))
	Brain.set_input(2, min(touching_S * inv_intensity, 1.0))
	Brain.set_input(3, min(touching_W * inv_intensity, 1.0))
	Brain.set_input(4, min(sees_agent_L * inv_intensity, 1.0))
	Brain.set_input(5, min(sees_agent_C * inv_intensity, 1.0))
	Brain.set_input(6, min(sees_agent_R * inv_intensity, 1.0))
	Brain.set_input(7, min(sees_food_red_L * inv_intensity, 1.0))
	Brain.set_input(8, min(sees_food_red_C * inv_intensity, 1.0))
	Brain.set_input(9, min(sees_food_red_R * inv_intensity, 1.0))
	Brain.set_input(10, min(sees_food_blue_L * inv_intensity, 1.0))
	Brain.set_input(11, min(sees_food_blue_C * inv_intensity, 1.0))
	Brain.set_input(12, min(sees_food_blue_R * inv_intensity, 1.0))
	Brain.set_input(13, float(food_level > 60)) # bool to float
	Brain.set_input(14, float(food_level < evolvedHungerThreshold))
	Brain.set_input(15, float(food_collision))
	Brain.set_input(16, float(spike_collision))
	Brain.set_input(17, float(was_attacked))
	Brain.set_input(18, float(lastFoodColor=="Red"))
	Brain.set_input(19, float(lastFoodColor=="Blue"))
	Brain.set_input(20, float(lastFoodColor=="Agent"))
	
	# Reset one-time signals
	food_collision = false
	spike_collision = false
	was_attacked = false
	
	Brain.update()
	#updateDebugText(Brain.inputBuffer,Brain.outputBuffer,Brain.recurrentBuffer_old)
	
	# Handle movement
	var L:float = Brain.get_output(0)
	var R:float = Brain.get_output(1)
	var rotation_dir:float = R - L
	
	rotation += rotation_dir * ROTATION_SPEED * delta
	
	if rotation_dir == 0.0:
		apply_friction(ACCELERATION * delta)
	else:
		apply_movement(Vector2(0.0, abs(rotation_dir) - 1.0) * ACCELERATION * delta)
	
	move_and_slide(motion.rotated(rotation))
	
	# Handle reproduction and spikes
	if food_level > 60 and Brain.get_output(2) >= TWO_THIRDS:
		GlobalSignals.emit_signal("agent_born", self)
		children_had_tracker += 1
		food_level -= 35
	
	var should_extend_spikes:bool = Brain.get_output(3) >= TWO_THIRDS
	if spike_extended != should_extend_spikes:
		spike_extended = should_extend_spikes
		dangerSpikeArea.visible = spike_extended

func apply_friction(speed:float):
	if motion.length_squared() > speed * speed:
		motion -= motion.normalized() * speed * ONE_THIRD
	else:
		motion = Vector2.ZERO

func apply_movement(acc:Vector2):
	motion += acc
	if motion.length_squared() > MAX_SPEED * MAX_SPEED:
		motion = motion.normalized() * MAX_SPEED


func get_mutated_genome()->Array:
	var newGenome = Genome.make_mutated_copy()
	return newGenome


func on_birth(newGenome):
	Genome.set_genome(newGenome)
	intensity = Genome.get_value(1,10)
	inv_intensity = 1.0 / intensity
	evolvedHungerThreshold = Genome.get_value(1,59)
	Brain.make_from_genome(Genome)


func on_spawn():
	Genome.randomize_genome()
	intensity = Genome.get_value(1,10)
	inv_intensity = 1.0 / intensity
	evolvedHungerThreshold = Genome.get_value(1,59)
	Brain.make_from_genome(Genome)


#func _unhandled_input(event):
#	if event.is_action_pressed("ui_accept"):
#		#var new_genome = make_mutated_copy()
#		GlobalSignals.emit_signal("agent_born", self)
		

func _on_Vision_body_entered(body):
	if body.is_in_group("Agent"):
		sees_agent_C += 1
		debug_cones.Center.color.g = min(sees_agent_C*inv_intensity,1.0)
	if body.is_in_group("Food"):
		if body.foodColor == "Red":
			sees_food_red_C += 1
			debug_cones.Center.color.r = min(sees_food_red_C*inv_intensity,1.0)
		if body.foodColor == "Blue":
			sees_food_blue_C += 1
			debug_cones.Center.color.b = min(sees_food_blue_C*inv_intensity,1.0)

func _on_Vision_body_exited(body):
	if body.is_in_group("Agent"):
		sees_agent_C -= 1
		debug_cones.Center.color.g = min(sees_agent_C*inv_intensity,1.0)
	if body.is_in_group("Food"):
		if body.foodColor == "Red":
			sees_food_red_C -= 1
			debug_cones.Center.color.r = min(sees_food_red_C*inv_intensity,1.0)
		if body.foodColor == "Blue":
			sees_food_blue_C -= 1
			debug_cones.Center.color.b = min(sees_food_blue_C*inv_intensity,1.0)


func _on_FoodUseTimer_timeout():
	food_level -= 1
	if food_level <= 0:
		GlobalSignals.emit_signal("agent_died", self)
		if camera.current:
			GlobalSignals.emit_signal("changed_view")
		queue_free()
	FoodUse.start()


func _on_P_left_body_entered(body):
	if body.is_in_group("Agent"):
		sees_agent_L += 1
		debug_cones.PL.color.g = min(sees_agent_L*inv_intensity,1.0)
	if body.is_in_group("Food"):
		if body.foodColor == "Red":
			sees_food_red_L += 1
			debug_cones.PL.color.r = min(sees_food_red_L*inv_intensity,1.0)
		if body.foodColor == "Blue":
			sees_food_blue_L += 1
			debug_cones.PL.color.b = min(sees_food_blue_L*inv_intensity,1.0)


func _on_P_left_body_exited(body):
	if body.is_in_group("Agent"):
		sees_agent_L -= 1
		debug_cones.PL.color.g = min(sees_agent_L*inv_intensity,1.0)
	if body.is_in_group("Food"):
		if body.foodColor == "Red":
			sees_food_red_L -= 1
			debug_cones.PL.color.r = min(sees_food_red_L*inv_intensity,1.0)
		if body.foodColor == "Blue":
			sees_food_blue_L -= 1
			debug_cones.PL.color.b = min(sees_food_blue_L*inv_intensity,1.0)


func _on_P_right_body_entered(body):
	if body.is_in_group("Agent"):
		sees_agent_R += 1
		debug_cones.PR.color.g = min(sees_agent_R*inv_intensity,1.0)
	if body.is_in_group("Food"):
		if body.foodColor == "Red":
			sees_food_red_R += 1
			debug_cones.PR.color.r = min(sees_food_red_R*inv_intensity,1.0)
		if body.foodColor == "Blue":
			sees_food_blue_R += 1
			debug_cones.PR.color.b = min(sees_food_blue_R*inv_intensity,1.0)


func _on_P_right_body_exited(body):
	if body.is_in_group("Agent"):
		sees_agent_R -= 1
		debug_cones.PR.color.g = min(sees_agent_R*inv_intensity,1.0)
	if body.is_in_group("Food"):
		if body.foodColor == "Red":
			sees_food_red_R -= 1
			debug_cones.PR.color.r = min(sees_food_red_R*inv_intensity,1.0)
		if body.foodColor == "Blue":
			sees_food_blue_R -= 1
			debug_cones.PR.color.b = min(sees_food_blue_R*inv_intensity,1.0)




func _on_TextureButton_pressed():
	$Camera2D.make_current()
	#GlobalSignals.emit_signal("changed_view",self)
	


func _on_TextureButton_mouse_entered():
	$Sprite.modulate = Color(1,0,1)



func _on_TextureButton_mouse_exited():
	$Sprite.modulate = Color(1,1,1)




func _on_TouchSensor_N_body_entered(_body):
	touching_N += 1
	debug_cones.Touch_N.color.b = min(touching_N*inv_intensity,1.0)


func _on_TouchSensor_N_body_exited(_body):
	touching_N -= 1
	debug_cones.Touch_N.color.b = min(touching_N*inv_intensity,1.0)


func _on_TouchSensor_E_body_entered(_body):
	touching_E += 1
	debug_cones.Touch_E.color.b = min(touching_E*inv_intensity,1.0)


func _on_TouchSensor_E_body_exited(_body):
	touching_E -= 1
	debug_cones.Touch_E.color.b = min(touching_E*inv_intensity,1.0)


func _on_TouchSensor_S_body_entered(_body):
	touching_S += 1
	debug_cones.Touch_S.color.b = min(touching_S*inv_intensity,1.0)


func _on_TouchSensor_S_body_exited(_body):
	touching_S -= 1
	debug_cones.Touch_S.color.b = min(touching_S*inv_intensity,1.0)


func _on_TouchSensor_W_body_entered(_body):
	touching_W += 1
	debug_cones.Touch_W.color.b = min(touching_W*inv_intensity,1.0)


func _on_TouchSensor_W_body_exited(_body):
	touching_W -= 1
	debug_cones.Touch_W.color.b = min(touching_W*inv_intensity,1.0)


func _on_DangerSpike_body_entered(body):
	if spike_extended and body.is_in_group("Agent"):
		spike_collision = true
		body.food_level -= 15
		body.was_attacked = 1 #bool
		if lastFoodColor != "Agent":
			food_level -= 5 #switch cost
			lastFoodColor = "Agent"
		else:
			food_level += 10 #loss of 5
			
