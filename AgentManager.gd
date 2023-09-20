extends Node2D

export(PackedScene) var Agent

onready var TextBox = get_parent().get_node("Main_HUD/HUD/right_menu/SystemStats/TextOutput")

var rng = RandomNumberGenerator.new()

var dataFile:String = "./DATA.dat"
var POP_MAX:int = 256
var popCount:int = 0
var popLog:Dictionary = {} #format hash:[organisms born with this type, list of children counts, list of food counts]
var logFile:File = File.new()
var birthQueue = []


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func arr_join(arr:Array, separator:String = "")->String:
	var output:String = "";
	for s in arr:
		output += str(s) + separator
	output = output.left( output.length() - separator.length() )
	return output

func logOrg(sites:Array):
	var key:String = arr_join(sites).sha256_text()
	if key in popLog:
		popLog[key][0] += 1
		popLog[key][1] += 1
	else:
		popLog[key] = [1,1,[],[]]
		
		
func remOrg(sites:Array,offspring:int,food:int):
	var key:String = arr_join(sites).sha256_text()
	popLog[key][0] -= 1
	popLog[key][2].append(offspring)
	popLog[key][3].append(food)
	#if popLog[key][0] == 0:
		#popLog.erase(key)



func mean(array:Array)->float:
	if len(array) == 0: return float('inf')
	var sum:float = 0.0
	for element in array:
		sum += element
	return sum / len(array)


func compareWithNull(val1:float, val2:float):
	if val1 != null and val2 != null:
		if val1 != val2:
			return val1 > val2
		else:
			#signals a tie
			return null
	elif val1 == null and val2 != null:
		return false
	elif val1 != null and val2 == null:
		return true
	else:
		return false

func customComparison(a:Array,b:Array)->bool:
	var alife:int = a[1][0]
	var blife:int = b[1][0]
	var atot:int = a[1][1]
	var btot:int = b[1][1]
	var aoffs:Array = a[1][2]
	var boffs:Array = b[1][2]
	var afoods:Array = a[1][3]
	var bfoods:Array = b[1][3]
	
	if (alife > 0) == (blife > 0): #both alive or both dead (sort groups)
		
		#this helper function lets you handle ties with ifs
		var comp = compareWithNull(alife,blife)
		if comp == null:
			comp = compareWithNull(atot,btot)
		if comp == null:
			comp = compareWithNull(mean(afoods),mean(bfoods))
		if comp == null:
			comp = compareWithNull(mean(aoffs),mean(boffs))
		return comp
	else:
		#one alive one dead, prefer alive
		return alife > blife

func sortedDictionary(dict:Dictionary)->Array:
	var items:Array = []
	for key in dict.keys():
		items.append([key,dict[key]])
	items.sort_custom(self, "customComparison")
	return items


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	#auto spawn to speed up initial search
	if popCount < 1:
		for _i in range(100):
			var pos:Vector2 = Vector2(rng.randi_range(64, 3840-64),rng.randi_range(64, 2160-64))
			handle_agent_spawn(pos)
			
	#birth Queue
	if popCount < POP_MAX and len(birthQueue)>0:
		popCount += 1
		var parent = birthQueue.pop_front()
		var parentHash:String = parent[0]
		var newGenomeSites:Array = parent[1]
		var pos:Vector2 = parent[2]
		var child:Agent = Agent.instance()
		add_child(child)
		child.global_position = pos
		var childHash:String = arr_join(newGenomeSites).sha256_text()
		child.on_birth(newGenomeSites)
		logOrg(newGenomeSites)
		fileWrite(parentHash+","+childHash)
			
	#text print out
	var result:String = "Population Size: " + str(popCount) + "\n\nCount Total  ID            ave_Child  ave_Food\n"
	var firstBreak:bool = false
	for pair in sortedDictionary(popLog):
		var key:String = pair[0]
		var value:Array = pair[1]
		if not firstBreak and value[0] == 0:
			result += "\n"
			firstBreak = true
		result += str(value[0]) + "        " + str(value[1]) + "       " + key.substr(0,7) + "  " + str(mean(value[2])).substr(0,6) + "       "  + str(mean(value[3])).substr(0,6) + "\n"
	TextBox.text = result
	


func handle_agent_birth(parent: Agent):
	var parentHash:String = arr_join(parent.Genome.sites).sha256_text()
	var newGenomeSites:Array = parent.get_mutated_genome()
	var spawnAt:Vector2 = parent.global_position
	birthQueue.append([parentHash,newGenomeSites,spawnAt])
	
	
func handle_agent_death(agent: Agent):
	popCount -= 1
	remOrg(agent.Genome.sites,agent.children_had_tracker,agent.food_eaten_tracker)


func handle_agent_spawn(pos: Vector2):
	if popCount < POP_MAX:
		popCount += 1
		var agent_instance:Agent = Agent.instance()
		add_child(agent_instance)
		agent_instance.global_position = pos
		agent_instance.on_spawn()
		var childHash:String = arr_join(agent_instance.Genome.sites).sha256_text()
		
		logOrg(agent_instance.Genome.sites)
		fileWrite("null,"+childHash)
	
func fileWrite(line:String):
	if logFile.file_exists(dataFile):
		var _trash = logFile.open(dataFile,File.READ_WRITE)
	else:
		var _trash = logFile.open(dataFile,File.WRITE_READ)
	logFile.seek_end()
	logFile.store_line(line)
	logFile.close()
