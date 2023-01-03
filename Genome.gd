extends Node2D
class_name Genome

# Declare member variables here. Examples:
var GENOME_LENGTH:int = (15+4+15)*3 + 2
var MUTATION_RATE:float = 0.005
var sites:Array = []
var readHead:int = 0


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


func make_mutated_copy()->Array:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var newSites = [] + sites #shitty way to copy an array
	for i in range(GENOME_LENGTH): #TODO this is terribly inefficient
		if rng.randf() <= MUTATION_RATE:
			var choice = rng.randi_range(0,2)
			if  choice == 0:
				newSites[i] += rng.randi_range(-5,5) #uniform offset mutation
				newSites[i] %= 255
			elif choice == 1:
				newSites[i] = rng.randi_range(0,255)
			elif choice == 2:
				var from:int = rng.randi_range(0,GENOME_LENGTH-1)
				var length:int = rng.randi_range(1,GENOME_LENGTH)
				var to:int = rng.randi_range(0,GENOME_LENGTH-1)
				var holder:Array = []
				for offset in range(from,from+length):
					newSites[(to+offset)%GENOME_LENGTH] = sites[(from+offset)%GENOME_LENGTH]
	return newSites


func get_value(minVal:int, maxVal:int) -> int:
	var valRange = maxVal - minVal
	var result = minVal + sites[readHead] % (valRange+1)
	readHead = (readHead + 1) % GENOME_LENGTH
	return result
	
	 
