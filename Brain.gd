extends Node2D
class_name Brain

var INPUT_SIZE = 13
var OUTPUT_SIZE = 3 #7 for veto controls, 3 for tank
var RECURRENT_SIZE = 8

var inputBuffer = []
var outputBuffer = []
var recurrentBuffer_old = []
var recurrentBuffer_new = []

var gates = []
#var gateLogic = [
#	[[0,0],[0,0]],
#	[[0,0],[0,1]],
#	[[0,0],[1,0]], # x > y
#	[[0,0],[1,1]],
#	[[0,1],[0,0]],
#	[[0,1],[0,1]],
#	[[0,1],[1,0]],
#	[[0,1],[1,1]],
#	[[1,0],[0,0]],
#	[[1,0],[0,1]],
#	[[1,0],[1,0]],
#	[[1,0],[1,1]],
#	[[1,1],[0,0]],
#	[[1,1],[0,1]],
#	[[1,1],[1,0]],
#	[[1,1],[1,1]] ]
	
func gateLogic(l:int,x:float,y:float) -> float:
	if l== 0:
		return 0.0
	elif l== 1:
		return (1-x)*(1-y)
	elif l== 2:
		return (1-x)*y
	elif l== 3:
		return 1-x
	elif l== 4:
		return x*(1-y)
	elif l== 5:
		return 1-y
	elif l== 6:
		return 1-(1-x*(1-y))*(1-(1-x)*y)
	elif l== 7:
		return 1-x*y
	elif l== 8:
		return x*y
	elif l== 9:
		return (1-x*(1-y))*(1-(1-x)*y)
	elif l== 10:
		return y
	elif l== 11:
		return 1- x*(1-y)
	elif l== 12:
		return x
	elif l== 13:
		return 1-(1-x)*y
	elif l== 14:
		return 1-(1-x)*(1-y)
	elif l== 15:
		return 1.0
	#begin non-boolean gates
	elif l== 16:
		# x > y fuzzy
		if x > y:
			return x-y
		else:
			return 0.0
	else:
		print("Error in MarkovBrain.gateLogic()")
		return -1.0

		

func get_size():
	return [INPUT_SIZE, OUTPUT_SIZE, RECURRENT_SIZE]

func get_newHidden():
	return recurrentBuffer_new

# Called when the node enters the scene tree for the first time.
func _ready():
	for i in range(INPUT_SIZE):
		inputBuffer.append(0)
	for i in range(OUTPUT_SIZE):
		outputBuffer.append(0)
	for i in range(RECURRENT_SIZE):
		recurrentBuffer_old.append(0)
		recurrentBuffer_new.append(0)


func make_from_genome(genome: Genome):
	for g in range(OUTPUT_SIZE + RECURRENT_SIZE):
		var newGate = []
		#add input wires
		newGate.append(genome.get_value(INPUT_SIZE + RECURRENT_SIZE))
		newGate.append(genome.get_value(INPUT_SIZE + RECURRENT_SIZE))
		#add logic table
		newGate.append(genome.get_value(16+1))
		gates.append(newGate)
		
func update():
	for i in range(OUTPUT_SIZE + RECURRENT_SIZE):
		var gate = gates[i]
		var input1 = inputBuffer[gate[0]] if gate[0] < INPUT_SIZE else recurrentBuffer_old[gate[0]-INPUT_SIZE]
		var input2 = inputBuffer[gate[1]] if gate[1] < INPUT_SIZE else recurrentBuffer_old[gate[1]-INPUT_SIZE]
		if i < OUTPUT_SIZE:
#			outputBuffer[i] = gateLogic[gate[2]][input1][input2]
			outputBuffer[i] = gateLogic(gate[2],input1,input2)
		else:
#			recurrentBuffer_new[i-OUTPUT_SIZE] = gateLogic[gate[2]][input1][input2]
			recurrentBuffer_new[i-OUTPUT_SIZE] = gateLogic(gate[2],input1,input2)
	transfer_recurrent()

func set_input(pos:int,val:float):
	inputBuffer[pos] = val

func get_input(pos:int)->float:
	return inputBuffer[pos]

func clear_input():
	for i in range(INPUT_SIZE):
		inputBuffer[i] = 0
		
func get_output(pos:int):
	return outputBuffer[pos]
	
func clear_output():
	for o in range(OUTPUT_SIZE):
		outputBuffer[o] = 0
		
func transfer_recurrent():
	recurrentBuffer_old = [] + recurrentBuffer_new #shitty vector copy
	
func clear_recurrent():
	for r in range(RECURRENT_SIZE):
		recurrentBuffer_old[r] = 0
		recurrentBuffer_new[r] = 0
		
func reset_brain():
	clear_input()
	clear_output()
	clear_recurrent()
