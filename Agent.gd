extends KinematicBody2D
class_name Agent

# Declare member variables here. Examples:
var MAX_SPEED:float = 200
var ROTATION_SPEED:float = 4
var ACCELERATION:float = 400
var motion:Vector2 = Vector2.ZERO


onready var Genome = $Genome
onready var Brain = $Brain
onready var FoodUse = $FoodUseTimer
onready var camera = $Camera2D
onready var debugConePL = $debugVisionCones/PL
onready var debugConePR = $debugVisionCones/PR
onready var debugConeCenter = $debugVisionCones/Center
onready var debugConeTouch_N = $debugVisionCones/Touch_N
onready var debugConeTouch_E = $debugVisionCones/Touch_E
onready var debugConeTouch_S = $debugVisionCones/Touch_S
onready var debugConeTouch_W = $debugVisionCones/Touch_W
onready var debugBrainVisual = $debugBrainVis/Label
onready var dangerSpikeArea:Area2D = $DangerSpike/

#INPUT SIGNAL BUFFER
var touching_N:int = 0
var touching_E:int = 0
var touching_S:int = 0
var touching_W:int = 0
var sees_agent_C:int = 0
var sees_food_red_C:int = 0
var sees_food_blue_C:int = 0
var sees_agent_L:int = 0
var sees_food_red_L:int = 0
var sees_food_blue_L:int = 0
var sees_agent_R:int = 0
var sees_food_red_R:int = 0
var sees_food_blue_R:int = 0
var food_level:int = 25
var food_collision:bool = 0
var spike_collision:bool = 0
var was_attacked:bool = 0
var lastFoodColor:String = "None"
#-------------------
# data tracking vars
var food_eaten_tracker:int = 0
var children_had_tracker:int = 0
var switch_counter:int = 0

# fuzzy logic variables
var intensity:float = -1
var evolvedHungerThreshold:int = -1

#body state variables
var spike_extended:bool = false


# Called when the node enters the scene tree for the first time.
func _ready():
	FoodUse.start()

func myRound(val:float,decLen:int)->float:
	return float(int(val*10*decLen))/(decLen*10)

#TODO: this should probably be a signal that is processed at the text node
func updateDebugText(inputs,outputs,hiddens):
	debugBrainVisual.text = ""
	for i in inputs:
		debugBrainVisual.text += str(myRound(i,1))
	debugBrainVisual.text +="\n"
	for h in hiddens:
		debugBrainVisual.text += str(myRound(h,1))
	debugBrainVisual.text +="\n"
	for o in outputs:
		debugBrainVisual.text += str(myRound(o,1))
	
	
	
#TODO: the data for set_input could be passed as a signal,
#      and the output from the brain could be received as one. (is this good?)
func _physics_process(delta):
	#tank controls version
	Brain.set_input(0,min(touching_N/intensity,1.0))
	Brain.set_input(1,min(touching_E/intensity,1.0))
	Brain.set_input(2,min(touching_S/intensity,1.0))
	Brain.set_input(3,min(touching_W/intensity,1.0))
	Brain.set_input(4,min(sees_agent_L/intensity,1.0))
	Brain.set_input(5,min(sees_agent_C/intensity,1.0))
	Brain.set_input(6,min(sees_agent_R/intensity,1.0))
	Brain.set_input(7,min(sees_food_red_L/intensity,1.0))
	Brain.set_input(8,min(sees_food_red_C/intensity,1.0))
	Brain.set_input(9,min(sees_food_red_R/intensity,1.0))
	Brain.set_input(10,min(sees_food_blue_L/intensity,1.0))
	Brain.set_input(11,min(sees_food_blue_C/intensity,1.0))
	Brain.set_input(12,min(sees_food_blue_R/intensity,1.0))
	Brain.set_input(13,int(food_level>60))#able to repro
	Brain.set_input(14,int(food_level<evolvedHungerThreshold))#close to death
	Brain.set_input(15,food_collision)
	Brain.set_input(16,spike_collision)
	Brain.set_input(17,was_attacked)
	food_collision = 0 #only send input once
	spike_collision = 0
	was_attacked = 0
	
	Brain.update()
	
	var holdinputs:Array = []
	for i in range(Brain.get_size()[0]):
		holdinputs.append(Brain.get_input(i))
	var holdoutputs:Array = []
	for i in range(Brain.get_size()[1]):
		holdoutputs.append(Brain.get_output(i))
	updateDebugText(holdinputs, holdoutputs, Brain.get_newHidden())
	
	#handle movment
	var L:float = Brain.get_output(0)
	var R:float = Brain.get_output(1)
	var axis:Vector2 = Vector2.ZERO
	
	var rotation_dir:float = R-L
	axis.y = abs(rotation_dir)-1
	
	rotation += rotation_dir * ROTATION_SPEED * delta

	if axis == Vector2.ZERO:
		apply_friction(ACCELERATION * delta)
	else:
		apply_movement(axis* ACCELERATION * delta)
	var _trash = move_and_slide(motion.rotated(rotation)) #does not carry over
	
	
	#handle reproduction
	if food_level > 60 and Brain.get_output(2)>=(2.0/3.0):
		GlobalSignals.emit_signal("agent_born", self)
		children_had_tracker += 1
		food_level -= 35 #60 -> 25 + 25 + 10 (each agent is reset, 10 lost to entropy)
		
	if Brain.get_output(3) >= (2.0/3.0):
		spike_extended = true
		dangerSpikeArea.visible = true
	else:
		spike_extended = false
		dangerSpikeArea.visible = false
	
	
	
func get_input_axis(right:float,left:float,down:float,up:float)->Vector2:
	var axis:Vector2 = Vector2.ZERO
	axis.x = right - left
	axis.y = down - up # y+ is down in this coordinate system
	return axis.normalized()
	
	
	
func apply_friction(speed:float):
	if motion.length() > speed:
		motion -= motion.normalized()*speed/3
	else:
		motion = Vector2.ZERO


func apply_movement(acc:Vector2):
	motion += acc
	motion = motion.limit_length(MAX_SPEED)


func get_mutated_genome()->Array:
	var newGenome = Genome.make_mutated_copy()
	return newGenome


func on_birth(newGenome):
	Genome.set_genome(newGenome)
	intensity = Genome.get_value(1,10)
	evolvedHungerThreshold = Genome.get_value(1,59)
	Brain.make_from_genome(Genome)


func on_spawn():
	Genome.randomize_genome()
	intensity = Genome.get_value(1,10)
	evolvedHungerThreshold = Genome.get_value(1,59)
	Brain.make_from_genome(Genome)


#func _unhandled_input(event):
#	if event.is_action_pressed("ui_accept"):
#		#var new_genome = make_mutated_copy()
#		GlobalSignals.emit_signal("agent_born", self)
		

func _on_Vision_body_entered(body):
	if body.is_in_group("Agent"):
		sees_agent_C += 1
		debugConeCenter.color.g = min(sees_agent_C/intensity,1.0)
	if body.is_in_group("Food"):
		if body.foodColor == "Red":
			sees_food_red_C += 1
			debugConeCenter.color.r = min(sees_food_red_C/intensity,1.0)
		if body.foodColor == "Blue":
			sees_food_blue_C += 1
			debugConeCenter.color.b = min(sees_food_blue_C/intensity,1.0)

func _on_Vision_body_exited(body):
	if body.is_in_group("Agent"):
		sees_agent_C -= 1
		debugConeCenter.color.g = min(sees_agent_C/intensity,1.0)
	if body.is_in_group("Food"):
		if body.foodColor == "Red":
			sees_food_red_C -= 1
			debugConeCenter.color.r = min(sees_food_red_C/intensity,1.0)
		if body.foodColor == "Blue":
			sees_food_blue_C -= 1
			debugConeCenter.color.b = min(sees_food_blue_C/intensity,1.0)


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
		debugConePL.color.g = min(sees_agent_L/intensity,1.0)
	if body.is_in_group("Food"):
		if body.foodColor == "Red":
			sees_food_red_L += 1
			debugConePL.color.r = min(sees_food_red_L/intensity,1.0)
		if body.foodColor == "Blue":
			sees_food_blue_L += 1
			debugConePL.color.b = min(sees_food_blue_L/intensity,1.0)


func _on_P_left_body_exited(body):
	if body.is_in_group("Agent"):
		sees_agent_L -= 1
		debugConePL.color.g = min(sees_agent_L/intensity,1.0)
	if body.is_in_group("Food"):
		if body.foodColor == "Red":
			sees_food_red_L -= 1
			debugConePL.color.r = min(sees_food_red_L/intensity,1.0)
		if body.foodColor == "Blue":
			sees_food_blue_L -= 1
			debugConePL.color.b = min(sees_food_blue_L/intensity,1.0)


func _on_P_right_body_entered(body):
	if body.is_in_group("Agent"):
		sees_agent_R += 1
		debugConePR.color.g = min(sees_agent_R/intensity,1.0)
	if body.is_in_group("Food"):
		if body.foodColor == "Red":
			sees_food_red_R += 1
			debugConePR.color.r = min(sees_food_red_R/intensity,1.0)
		if body.foodColor == "Blue":
			sees_food_blue_R += 1
			debugConePR.color.b = min(sees_food_blue_R/intensity,1.0)


func _on_P_right_body_exited(body):
	if body.is_in_group("Agent"):
		sees_agent_R -= 1
		debugConePR.color.g = min(sees_agent_R/intensity,1.0)
	if body.is_in_group("Food"):
		if body.foodColor == "Red":
			sees_food_red_R -= 1
			debugConePR.color.r = min(sees_food_red_R/intensity,1.0)
		if body.foodColor == "Blue":
			sees_food_blue_R -= 1
			debugConePR.color.b = min(sees_food_blue_R/intensity,1.0)




func _on_TextureButton_pressed():
	$Camera2D.make_current()
	#GlobalSignals.emit_signal("changed_view",self)
	


func _on_TextureButton_mouse_entered():
	$Sprite.modulate = Color(1,0,1)



func _on_TextureButton_mouse_exited():
	$Sprite.modulate = Color(1,1,1)




func _on_TouchSensor_N_body_entered(_body):
	touching_N += 1
	debugConeTouch_N.color.b = min(touching_N/intensity,1.0)


func _on_TouchSensor_N_body_exited(_body):
	touching_N -= 1
	debugConeTouch_N.color.b = min(touching_N/intensity,1.0)


func _on_TouchSensor_E_body_entered(_body):
	touching_E += 1
	debugConeTouch_E.color.b = min(touching_E/intensity,1.0)


func _on_TouchSensor_E_body_exited(_body):
	touching_E -= 1
	debugConeTouch_E.color.b = min(touching_E/intensity,1.0)


func _on_TouchSensor_S_body_entered(_body):
	touching_S += 1
	debugConeTouch_S.color.b = min(touching_S/intensity,1.0)


func _on_TouchSensor_S_body_exited(_body):
	touching_S -= 1
	debugConeTouch_S.color.b = min(touching_S/intensity,1.0)


func _on_TouchSensor_W_body_entered(_body):
	touching_W += 1
	debugConeTouch_W.color.b = min(touching_W/intensity,1.0)


func _on_TouchSensor_W_body_exited(_body):
	touching_W -= 1
	debugConeTouch_W.color.b = min(touching_W/intensity,1.0)


func _on_DangerSpike_body_entered(body):
	if spike_extended and body.is_in_group("Agent"):
		spike_collision = true
		body.food_level -= 15
		body.was_attacked = 1 #bool
#		if lastFoodColor != "Agent":
#			food_level -= 15 #switch cost
#			lastFoodColor = "Agent"
#		else:
		food_level += 10 #loss of 5
			
