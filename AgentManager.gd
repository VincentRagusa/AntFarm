extends Node2D

export(PackedScene) var Agent

onready var TextBox = get_parent().get_node("Main_HUD/HUD/right_menu/SystemStats/TextOutput")

var rng = RandomNumberGenerator.new()

const POP_MAX:int = 256
const INITIAL_SPAWN_COUNT:int = 100
const WORLD_BOUNDS := Rect2(64, 64, 3840-128, 2160-128)  # x, y, width, height

var dataFile:String = "./DATA.dat"
var popCount:int = 0
var popLog:Dictionary = {} # format: hash:[current_count, total_count, children_array, food_array]
var logFile:File = File.new()
var birthQueue:Array = []
var _last_update_time = 0.0
var _update_interval = 1.0 # Update stats every 0.2 seconds

func _ready():
	rng.randomize()

func arr_join(arr:Array, separator:String = "") -> String:
	var output := PoolStringArray()
	for s in arr:
		output.append(str(s))
	return output.join(separator)

func logOrg(sites:Array):
	var key:String = arr_join(sites).sha256_text()
	if key in popLog:
		popLog[key][0] += 1
		popLog[key][1] += 1
	else:
		popLog[key] = [1, 1, [], []]
		
func remOrg(sites:Array, offspring:int, food:int):
	var key:String = arr_join(sites).sha256_text()
	var record:Array = popLog[key]
	record[0] -= 1
	record[2].append(offspring)
	record[3].append(food)

func mean(array:Array) -> float:
	if array.empty():
		return INF
	var sum:float = 0.0
	for element in array:
		sum += element
	return sum / array.size()

func compareWithNull(val1:float, val2:float):
	if val1 != null and val2 != null:
		return val1 > val2 if val1 != val2 else null
	elif val1 == null:
		return false
	else:
		return true

func customComparison(a:Array, b:Array) -> bool:
	var a_data:Array = a[1]
	var b_data:Array = b[1]
	
	var a_alive:bool = a_data[0] > 0
	var b_alive:bool = b_data[0] > 0
	
	if a_alive == b_alive:
		var comp = compareWithNull(a_data[0], b_data[0])
		if comp == null:
			comp = compareWithNull(a_data[1], b_data[1])
		if comp == null:
			comp = compareWithNull(mean(a_data[3]), mean(b_data[3]))
		if comp == null:
			comp = compareWithNull(mean(a_data[2]), mean(b_data[2]))
		return comp
	else:
		return a_alive

func sortedDictionary(dict:Dictionary) -> Array:
	var items := []
	items.resize(dict.size())
	var i := 0
	for key in dict:
		items[i] = [key, dict[key]]
		i += 1
	items.sort_custom(self, "customComparison")
	return items

func _process(_delta):
	# Auto spawn initial population
	if popCount < 1:
		for _i in range(INITIAL_SPAWN_COUNT):
			var pos := Vector2(
				rng.randi_range(WORLD_BOUNDS.position.x, WORLD_BOUNDS.end.x),
				rng.randi_range(WORLD_BOUNDS.position.y, WORLD_BOUNDS.end.y)
			)
			handle_agent_spawn(pos)
			
	# Process birth queue
	if popCount < POP_MAX and not birthQueue.empty():
		popCount += 1
		var parent_data = birthQueue.pop_front()
		var parentHash:String = parent_data[0]
		var newGenomeSites:Array = parent_data[1]
		var pos:Vector2 = parent_data[2]
		
		var child:Agent = Agent.instance()
		add_child(child)
		child.global_position = pos
		child.on_birth(newGenomeSites)
		
		var childHash:String = arr_join(newGenomeSites).sha256_text()
		logOrg(newGenomeSites)
		fileWrite(parentHash + "," + childHash)
			
	# Update text display
	_last_update_time += _delta
	if _last_update_time >= _update_interval:
		_last_update_time = 0.0
		_update_stats_display()
		
		
func _update_stats_display():
	var result := PoolStringArray()
	result.append("Population Size: %d\n\nCount Total  ID            ave_Child  ave_Food\n" % popCount)
	
	var firstBreak := false
	for pair in sortedDictionary(popLog):
		var key:String = pair[0]
		var value:Array = pair[1]
		
		if not firstBreak and value[0] == 0:
			result.append("\n")
			firstBreak = true
			
		result.append("%-8d%-8d%-12s%-10s%-10s\n" % [
			value[0],
			value[1],
			key.substr(0, 7),
			str(mean(value[2])).substr(0, 6),
			str(mean(value[3])).substr(0, 6)
		])
	
	TextBox.text = result.join("")

func handle_agent_birth(parent: Agent):
	birthQueue.append([
		arr_join(parent.Genome.sites).sha256_text(),
		parent.get_mutated_genome(),
		parent.global_position
	])
	
func handle_agent_death(agent: Agent):
	popCount -= 1
	remOrg(agent.Genome.sites, agent.children_had_tracker, agent.food_eaten_tracker)

func handle_agent_spawn(pos: Vector2):
	if popCount >= POP_MAX:
		return
		
	popCount += 1
	var agent_instance:Agent = Agent.instance()
	add_child(agent_instance)
	agent_instance.global_position = pos
	agent_instance.on_spawn()
	
	logOrg(agent_instance.Genome.sites)
	fileWrite("null," + arr_join(agent_instance.Genome.sites).sha256_text())
	
func fileWrite(line:String):
	var mode = File.READ_WRITE if logFile.file_exists(dataFile) else File.WRITE_READ
	if logFile.open(dataFile, mode) == OK:
		logFile.seek_end()
		logFile.store_line(line)
		logFile.close()
