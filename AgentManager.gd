extends Node2D

export(PackedScene) var Agent

onready var TextBox = get_parent().get_node("Main_HUD/HUD/right_menu/SystemStats/TextOutput")

var rng = RandomNumberGenerator.new()

var POP_MAX = 500
var popCount = 0
var popLog = {} #format hash:[organisms born with this type, list of children counts, list of food counts]
var logFile = File.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func arr_join(arr, separator = ""):
	var output = "";
	for s in arr:
		output += str(s) + separator
	output = output.left( output.length() - separator.length() )
	return output

func logOrg(sites):
	var key = arr_join(sites).sha256_text()
	if key in popLog:
		popLog[key][0] += 1
		popLog[key][1] += 1
	else:
		popLog[key] = [1,1,[],[]]
		
		
func remOrg(sites,offspring,food):
	var key = arr_join(sites).sha256_text()
	popLog[key][0] -= 1
	popLog[key][2].append(offspring)
	popLog[key][3].append(food)
	#if popLog[key][0] == 0:
		#popLog.erase(key)



func mean(array):
	if len(array) == 0: return null
	var sum = 0.0
	for element in array:
		sum += element
	return sum / len(array)


func compareWithNull(val1, val2):
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

func customComparison(a,b):
	var alife = a[1][0]
	var blife = b[1][0]
	var atot = a[1][1]
	var btot = b[1][1]
	var aoffs = a[1][2]
	var boffs = b[1][2]
	var afoods = a[1][3]
	var bfoods = b[1][3]
	
	if (alife > 0) == (blife > 0): #both alive or both dead (sort groups)
#		var ma = mean(aoffs)
#		var mb = mean(boffs)
		var ma = atot #these replace the mean for alternative sort
		var mb = btot
		
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

func sortedDictionary(dict):
	var items = []
	for key in dict.keys():
		items.append([key,dict[key]])
	items.sort_custom(self, "customComparison")
	return items


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if popCount < 1:
		var pos = Vector2(rng.randi_range(64, 3840-64),rng.randi_range(64, 2160-64))
		handle_agent_spawn(pos)
	var result = "Population Size: " + str(popCount) + "\n\nCount Total  ID            ave_Child  ave_Food\n"
	#for key in popLog.keys():
	#	result += str(popLog[key][0]) + " " + key.substr(0,7) + " " + str(mean(popLog[key][1])) + " "  + str(mean(popLog[key][2])) + "\n"
	var firstBreak = false
	for pair in sortedDictionary(popLog):
		var key = pair[0]
		var value = pair[1]
		if not firstBreak and value[0] == 0:
			result += "\n"
			firstBreak = true
		result += str(value[0]) + "        " + str(value[1]) + "       " + key.substr(0,7) + "  " + str(mean(value[2])).substr(0,6) + "       "  + str(mean(value[3])).substr(0,6) + "\n"
	TextBox.text = result
	#ItemList.add_item(result)
	

func handle_agent_birth(parent: Agent):
	if popCount < POP_MAX:
		popCount += 1
		var child = Agent.instance()
		add_child(child)
		var parentHash = arr_join(parent.Genome.sites).sha256_text()
		child.global_position = parent.global_position
		var newGenomeSites = parent.get_mutated_genome()
		var childHash = arr_join(newGenomeSites).sha256_text()
		child.on_birth(newGenomeSites)
		#print(popCount, " \tBABY ", newGenomeSites)
		
		logOrg(newGenomeSites)
		if logFile.file_exists("./antfarm.dat"):
			logFile.open("./antfarm.dat",File.READ_WRITE)
		else:
			logFile.open("./antfarm.dat",File.WRITE_READ)
		logFile.seek_end()
		logFile.store_line(parentHash+","+childHash)
		logFile.close()
	
func handle_agent_death(agent: Agent):
	popCount -= 1
	remOrg(agent.Genome.sites,agent.children_had_tracker,agent.food_eaten_tracker)


func handle_agent_spawn(pos: Vector2):
	if popCount < POP_MAX:
		popCount += 1
		var agent_instance = Agent.instance()
		add_child(agent_instance)
		agent_instance.global_position = pos
		agent_instance.on_spawn()
		var childHash = arr_join(agent_instance.Genome.sites).sha256_text()
		
		logOrg(agent_instance.Genome.sites)
		if logFile.file_exists("./antfarm.dat"):
			logFile.open("./antfarm.dat",File.READ_WRITE)
		else:
			logFile.open("./antfarm.dat",File.WRITE_READ)
		logFile.seek_end()
		logFile.store_line("null,"+childHash)
		logFile.close()
	
