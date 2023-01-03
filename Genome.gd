extends Node2D
class_name Genome

# Declare member variables here. Examples:
var GENOME_LENGTH = 25#(13+7+8)*3+2
var MUTATION_RATE = 1.0/50.0 #0.005
var sites = [0]
var readHead = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func randomize_genome():
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	sites = []
	for i in range(GENOME_LENGTH):
		sites.append(rng.randi_range(0,255))


func set_genome(newSites):
	sites = newSites


func make_mutated_copy():
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var newSites = [] + sites #shitty way to copy an array
	for i in range(GENOME_LENGTH): #TODO this is terribly inefficient
		if rng.randf() <= MUTATION_RATE:
			var choice = rng.randi_range(0,1)
			if  choice == 0:
				newSites[i] += rng.randi_range(-5,5) #uniform offset mutation
				newSites[i] %= 255
			elif choice == 1:
				newSites[i] = rng.randi_range(0,255)
	return newSites


func get_value(minVal:int, maxVal:int) -> int:
	var valRange = maxVal - minVal
	var result = minVal + sites[readHead] % (valRange+1)
	readHead = (readHead + 1) % GENOME_LENGTH
	return result
	
	 
