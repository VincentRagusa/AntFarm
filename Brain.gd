extends Node2D
class_name Brain

# Constants
const INPUT_SIZE:int = 21
const OUTPUT_SIZE:int = 4  # 8 for veto controls, 4 for tank
const RECURRENT_SIZE:int = 15

# Buffers
var inputBuffer:Array = []
var outputBuffer:Array = []
var recurrentBuffer_old:Array = []
var recurrentBuffer_new:Array = []

# Gates
var gates:Array = []

# Pre-calculated gate logic constants
const GATE_LOGIC_COUNT:int = 17

func _ready():
	# Initialize buffers with default values
	inputBuffer.resize(INPUT_SIZE)
	outputBuffer.resize(OUTPUT_SIZE)
	recurrentBuffer_old.resize(RECURRENT_SIZE)
	recurrentBuffer_new.resize(RECURRENT_SIZE)
	
	for i in range(INPUT_SIZE):
		inputBuffer[i] = 0.5
	for i in range(OUTPUT_SIZE):
		outputBuffer[i] = 0.5
	for i in range(RECURRENT_SIZE):
		recurrentBuffer_old[i] = 0.5
		recurrentBuffer_new[i] = 0.5

# Optimized gate logic using direct calculations instead of conditionals where possible
func gateLogic(l:int, x:float, y:float) -> float:
	match l:
		0: return 0.0
		1: return (1.0 - x) * (1.0 - y)
		2: return (1.0 - x) * y
		3: return 1.0 - x
		4: return x * (1.0 - y)
		5: return 1.0 - y
		6: return 1.0 - (1.0 - x * (1.0 - y)) * (1.0 - (1.0 - x) * y)
		7: return 1.0 - x * y
		8: return x * y
		9: return (1.0 - x * (1.0 - y)) * (1.0 - (1.0 - x) * y)
		10: return y
		11: return 1.0 - x * (1.0 - y)
		12: return x
		13: return 1.0 - (1.0 - x) * y
		14: return 1.0 - (1.0 - x) * (1.0 - y)
		15: return 1.0
		16: return max(x - y, 0.0)  # x > y fuzzy
		_:
			printerr("Error in MarkovBrain.gateLogic()! Logic ", l, " is not defined.")
			return -1.0

func get_size() -> Array:
	return [INPUT_SIZE, OUTPUT_SIZE, RECURRENT_SIZE]

func get_newHidden() -> Array:
	return recurrentBuffer_new.duplicate()

func make_from_genome(genome: Genome):
	gates.resize(OUTPUT_SIZE + RECURRENT_SIZE)
	for i in range(OUTPUT_SIZE + RECURRENT_SIZE):
		gates[i] = [
			genome.get_value(0, INPUT_SIZE + RECURRENT_SIZE - 1),
			genome.get_value(0, INPUT_SIZE + RECURRENT_SIZE - 1),
			genome.get_value(0, GATE_LOGIC_COUNT - 1)
		]

func update():
	var total_gates = OUTPUT_SIZE + RECURRENT_SIZE
	var input_size = INPUT_SIZE
	
	for i in range(total_gates):
		var gate = gates[i]
		var input1_index = gate[0]
		var input2_index = gate[1]
		
		var input1 = inputBuffer[input1_index] if input1_index < input_size else recurrentBuffer_old[input1_index - input_size]
		var input2 = inputBuffer[input2_index] if input2_index < input_size else recurrentBuffer_old[input2_index - input_size]
		
		var result = gateLogic(gate[2], input1, input2)
		
		if i < OUTPUT_SIZE:
			outputBuffer[i] = result
		else:
			recurrentBuffer_new[i - OUTPUT_SIZE] = result
	
	transfer_recurrent()

func set_input(pos: int, val: float):
	inputBuffer[pos] = val

func get_input(pos: int) -> float:
	return inputBuffer[pos]

func clear_input():
	for i in range(INPUT_SIZE):
		inputBuffer[i] = 0.0

func get_output(pos: int) -> float:
	return outputBuffer[pos]

func clear_output():
	for i in range(OUTPUT_SIZE):
		outputBuffer[i] = 0.0

func transfer_recurrent():
	# Faster array copy
	recurrentBuffer_old = recurrentBuffer_new.duplicate()

func clear_recurrent():
	for i in range(RECURRENT_SIZE):
		recurrentBuffer_old[i] = 0.0
		recurrentBuffer_new[i] = 0.0

func reset_brain():
	clear_input()
	clear_output()
	clear_recurrent()
