extends KinematicBody2D
class_name Agent

# Declare member variables here. Examples:
var MAX_SPEED = 250
var ROTATION_SPEED = 5
var ACCELERATION = 500
var motion = Vector2.ZERO


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

#INPUT SIGNAL BUFFER
var touching_N = 0
var touching_E = 0
var touching_S = 0
var touching_W = 0
var sees_agent = 0
var sees_food = 0
var sees_agent_PL = 0
var sees_food_PL = 0
var sees_agent_PR = 0
var sees_food_PR = 0
var food_level = 25
var food_collected = 0 #bool
#-------------------
# data tracking vars
var food_eaten_tracker = 0
var children_had_tracker = 0

# fuzzy logic variables
var intensity = null
var evolvedHungerThreshold = null


# Called when the node enters the scene tree for the first time.
func _ready():
	FoodUse.start()

func myRound(val:float,decLen:int)->float:
	return float(int(val*10*decLen))/(decLen*10)

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
	
	
	
	
func _physics_process(delta):
	#tank controls version
	Brain.set_input(0,min(touching_N/intensity,1.0))
	Brain.set_input(1,min(touching_E/intensity,1.0))
	Brain.set_input(2,min(touching_S/intensity,1.0))
	Brain.set_input(3,min(touching_W/intensity,1.0))
	Brain.set_input(4,min(sees_agent_PL/intensity,1.0))
	Brain.set_input(5,min(sees_agent/intensity,1.0))
	Brain.set_input(6,min(sees_agent_PR/intensity,1.0))
	Brain.set_input(7,min(sees_food_PL/intensity,1.0))
	Brain.set_input(8,min(sees_food/intensity,1.0))
	Brain.set_input(9,min(sees_food_PR/intensity,1.0))
	Brain.set_input(10,int(food_level>60))#able to repro
	Brain.set_input(11,int(food_level<evolvedHungerThreshold))#close to death
	Brain.set_input(12,food_collected)
	food_collected = 0 #only send input once
	Brain.update()
	
	var holdinputs = []
	for i in range(Brain.get_size()[0]):
		holdinputs.append(Brain.get_input(i))
	var holdoutputs = []
	for i in range(Brain.get_size()[1]):
		holdoutputs.append(Brain.get_output(i))
	updateDebugText(holdinputs, holdoutputs, Brain.get_newHidden())
	
	#handle movment
	var L = Brain.get_output(0)
	var R = Brain.get_output(1)
	var axis = Vector2.ZERO
	
	var rotation_dir = R-L
	axis.y = abs(rotation_dir)-1
	
	rotation += rotation_dir * ROTATION_SPEED * delta

	if axis == Vector2.ZERO:
		apply_friction(ACCELERATION * delta)
	else:
		apply_movement(axis* ACCELERATION * delta)
	move_and_slide(motion.rotated(rotation)) #does not carry over
	
	
	#handle reproduction
	if food_level > 60 and Brain.get_output(2)>=(2/3):
		GlobalSignals.emit_signal("agent_born", self)
		children_had_tracker += 1
		food_level -= 35 #60 -> 25 + 25 + 10 (each agent is reset, 10 lost to entropy)
	
func get_input_axis(right,left,down,up):
	var axis = Vector2.ZERO
	axis.x = right - left
	axis.y = down - up # y+ is down in this coordinate system
	return axis.normalized()
	
	
	
func apply_friction(amount):
	if motion.length() > amount:
		motion -= motion.normalized()*amount
	else:
		motion = Vector2.ZERO


func apply_movement(acc):
	motion += acc
	motion = motion.clamped(MAX_SPEED)


func get_mutated_genome():
	var newGenome = Genome.make_mutated_copy()
	return newGenome


func on_birth(newGenome):
	Genome.set_genome(newGenome)
	intensity = Genome.get_value(9)+1 #minimum 1
	evolvedHungerThreshold = Genome.get_value(120)
	Brain.make_from_genome(Genome)


func on_spawn():
	Genome.randomize_genome()
	intensity = Genome.get_value(9)+1 #minimum 1
	evolvedHungerThreshold = Genome.get_value(120)
	Brain.make_from_genome(Genome)


#func _unhandled_input(event):
#	if event.is_action_pressed("ui_accept"):
#		#var new_genome = make_mutated_copy()
#		GlobalSignals.emit_signal("agent_born", self)
		

func _on_Vision_body_entered(body):
	if body.is_in_group("Agent"):
		sees_agent += 1
		debugConeCenter.color.g = min(sees_agent/intensity,1.0)
	if body.is_in_group("Food"):
		sees_food += 1
		debugConeCenter.color.r = min(sees_food/intensity,1.0)

func _on_Vision_body_exited(body):
	if body.is_in_group("Agent"):
		sees_agent -= 1
		debugConeCenter.color.g = min(sees_agent/intensity,1.0)
	if body.is_in_group("Food"):
		sees_food -= 1
		debugConeCenter.color.r = min(sees_food/intensity,1.0)


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
		sees_agent_PL += 1
		debugConePL.color.g = min(sees_agent_PL/intensity,1.0)
	if body.is_in_group("Food"):
		sees_food_PL += 1
		debugConePL.color.r = min(sees_food_PL/intensity,1.0)


func _on_P_left_body_exited(body):
	if body.is_in_group("Agent"):
		sees_agent_PL -= 1
		debugConePL.color.g = min(sees_agent_PL/intensity,1.0)
	if body.is_in_group("Food"):
		sees_food_PL -= 1
		debugConePL.color.r = min(sees_food_PL/intensity,1.0)


func _on_P_right_body_entered(body):
	if body.is_in_group("Agent"):
		sees_agent_PR += 1
		debugConePR.color.g = min(sees_agent_PR/intensity,1.0)
	if body.is_in_group("Food"):
		sees_food_PR += 1
		debugConePR.color.r = min(sees_food_PR/intensity,1.0)


func _on_P_right_body_exited(body):
	if body.is_in_group("Agent"):
		sees_agent_PR -= 1
		debugConePR.color.g = min(sees_agent_PR/intensity,1.0)
	if body.is_in_group("Food"):
		sees_food_PR -= 1
		debugConePR.color.r = min(sees_food_PR/intensity,1.0)




func _on_TextureButton_pressed():
	$Camera2D.make_current()
	#GlobalSignals.emit_signal("changed_view",self)
	


func _on_TextureButton_mouse_entered():
	$Sprite.modulate = Color(1,0,1)



func _on_TextureButton_mouse_exited():
	$Sprite.modulate = Color(1,1,1)




func _on_TouchSensor_N_body_entered(body):
	touching_N += 1
	debugConeTouch_N.color.b = min(touching_N/intensity,1.0)


func _on_TouchSensor_N_body_exited(body):
	touching_N -= 1
	debugConeTouch_N.color.b = min(touching_N/intensity,1.0)


func _on_TouchSensor_E_body_entered(body):
	touching_E += 1
	debugConeTouch_E.color.b = min(touching_E/intensity,1.0)


func _on_TouchSensor_E_body_exited(body):
	touching_E -= 1
	debugConeTouch_E.color.b = min(touching_E/intensity,1.0)


func _on_TouchSensor_S_body_entered(body):
	touching_S += 1
	debugConeTouch_S.color.b = min(touching_S/intensity,1.0)


func _on_TouchSensor_S_body_exited(body):
	touching_S -= 1
	debugConeTouch_S.color.b = min(touching_S/intensity,1.0)


func _on_TouchSensor_W_body_entered(body):
	touching_W += 1
	debugConeTouch_W.color.b = min(touching_W/intensity,1.0)


func _on_TouchSensor_W_body_exited(body):
	touching_W -= 1
	debugConeTouch_W.color.b = min(touching_W/intensity,1.0)

#complex movenment backup
#func _physics_process(delta):
#	Brain.set_input(0,int(touching_N>0))
#	Brain.set_input(1,int(touching_E>0))
#	Brain.set_input(2,int(touching_S>0))
#	Brain.set_input(3,int(touching_W>0))
#	Brain.set_input(4,int(sees_agent>0))
#	Brain.set_input(5,int(sees_food>0))
#	Brain.set_input(6,int(sees_agent_PR>0))
#	Brain.set_input(7,int(sees_food_PR>0))
#	Brain.set_input(8,int(sees_agent_PL>0))
#	Brain.set_input(9,int(sees_food_PL>0))
#	Brain.set_input(10,int(food_level>60))#able to repro
#	Brain.set_input(11,int(food_level<10))#close to death
#	Brain.set_input(12,food_collected)
#	food_collected = 0 #only send input once
#	Brain.update()
#	var holdoutputs = []
#	for i in range(7):
#		holdoutputs.append(Brain.get_output(i))
#	updateDebugText(holdoutputs, Brain.get_newHidden())
#	#handle movment
#	var rotation_dir = Brain.get_output(4)-Brain.get_output(5)
#	rotation += rotation_dir * ROTATION_SPEED * delta
#
#	var axis = get_input_axis(Brain.get_output(0),Brain.get_output(1),Brain.get_output(2),Brain.get_output(3))
#	if axis == Vector2.ZERO:
#		apply_friction(ACCELERATION * delta)
#	else:
#		apply_movement(axis* ACCELERATION * delta)
#	#motion = move_and_slide(motion.rotated(rotation))
#	move_and_slide(motion.rotated(rotation))
#
#
#	#handle reproduction
#	if food_level > 60 and bool(Brain.get_output(6)):
#		GlobalSignals.emit_signal("agent_born", self)
#		children_had_tracker += 1
#		food_level -= 35 #60 -> 25 + 25 + 10 (each agent is reset, 10 lost to entropy)
#
#func get_input_axis(right,left,down,up):
#	var axis = Vector2.ZERO
#	axis.x = right - left
#	axis.y = down - up # y+ is down in this coordinate system
#	return axis.normalized()


# binary logic backup
#func _physics_process(delta):
#	#tank controls version
#	Brain.set_input(0,int(touching_N>0))
#	Brain.set_input(1,int(touching_E>0))
#	Brain.set_input(2,int(touching_S>0))
#	Brain.set_input(3,int(touching_W>0))
#	Brain.set_input(4,int(sees_agent>0))
#	Brain.set_input(5,int(sees_food>0))
#	Brain.set_input(6,int(sees_agent_PR>0))
#	Brain.set_input(7,int(sees_food_PR>0))
#	Brain.set_input(8,int(sees_agent_PL>0))
#	Brain.set_input(9,int(sees_food_PL>0))
#	Brain.set_input(10,int(food_level>60))#able to repro
#	Brain.set_input(11,int(food_level<10))#close to death
#	Brain.set_input(12,food_collected)
#	food_collected = 0 #only send input once
#	Brain.update()
#
#	var holdoutputs = []
#	for i in range(Brain.get_size()[1]):
#		holdoutputs.append(Brain.get_output(i))
#	updateDebugText(holdoutputs, Brain.get_newHidden())
#
#	#handle movment
#	var L = Brain.get_output(0)
#	var R = Brain.get_output(1)
#	var axis = Vector2.ZERO
#	var rotation_dir = 0
#	if L+R == 2:
#		axis.y = -1
#	else:
#		rotation_dir = R-L
#
#	rotation += rotation_dir * ROTATION_SPEED * delta
#
#	if axis == Vector2.ZERO:
#		apply_friction(ACCELERATION * delta)
#	else:
#		apply_movement(axis* ACCELERATION * delta)
#	move_and_slide(motion.rotated(rotation)) #does not carry over
#
#
#	#handle reproduction
#	if food_level > 60 and bool(Brain.get_output(2)):
#		GlobalSignals.emit_signal("agent_born", self)
#		children_had_tracker += 1
#		food_level -= 35 #60 -> 25 + 25 + 10 (each agent is reset, 10 lost to entropy)
