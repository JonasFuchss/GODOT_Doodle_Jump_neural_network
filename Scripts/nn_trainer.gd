extends Node

var generation_count: int = 0
var pop_count: int = 150
var current_pops: int = 0
var spawn_coord: Array = []

var current_record_height: float = 1
var this_gen_record_height: float = 1
var current_record_genome: Array

# Trackt die Zahl der Mutationen generationsübergreifend.
var innovation_counter: int = 0
# Trackt Mutationen für jede Generation einzeln. Mutationen, welche innerhalb
# einer Generation identisch sind (zB 02 -> 04 splittet in 02 -> 05 -> 04) wird
# dieser die selbe innovations-Nummer zugeordnet.
var mutation_tracker: Array = []
# Anfängliche Genom-Struktur, in der ersten Generation bei allen gleich.
# Bei Erstellung der ersten Generation passieren erste Mutationen
var init_nodes: Dictionary = {
	"input": [],
	"hidden": [],
	"output": []
}
var init_connections: Array[Genome_Connection] = []

var highscore_label: Label
var Doodle = preload("res://Scenes/doodle.tscn")


signal create_doodle(doodle, x, y, nodes, connections)
signal need_new_level(generation)


func _ready() -> void:
	highscore_label = get_node("/root/root/Camera2D/Header/Highscore")
	
	## Anfänglicher Aufbau der grundlegenden Genom-Struktur
	init_nodes["input"].append(Genome_Node.new(0, 0.0))
	init_nodes["input"].append(Genome_Node.new(1, 0.0))
	init_nodes["output"].append(Genome_Node.new(2, 0.0))
	init_connections.append(Genome_Connection.new(0, 0, 2, randf()))
	init_connections.append(Genome_Connection.new(1, 1, 2, randf()))


func create_generation() -> void:
	# Zurücksetzen des generations-spezifischen mutations-trackers
	mutation_tracker.clear()
	
	for pop in pop_count:
		var nodes: Array
		var connections: Array
		
		# Errechne die Nodes & Connections leicht abweichend der vorherigen, besten Generation
		## TODO
		
		current_pops += 1
		create_doodle.emit(Doodle, spawn_coord[0], spawn_coord[1], nodes, connections)


func _on_root_level_built(x_coord: float, y_coord: float) -> void:
	spawn_coord = [x_coord, y_coord]
	create_generation()


func _on_doodle_death_by_falling(weights_in: Array, biases_in: Array, weights_out: Array, biases_out: float, score: float) -> void:
	current_pops -= 1
	
	# runde den Score auf einen Integer. Verhindert Rundungsfehler.
	var rounded_score = roundf(score)
	
	if rounded_score < this_gen_record_height:
		this_gen_record_height = rounded_score
	
	# Hat der doodle einen neuen Highscore aufgestellt? Wenn ja, speichere seinen genome und den Rekord!
	if this_gen_record_height < current_record_height:
		print("-----------\nnew record: ", round(this_gen_record_height), "\n-----------")
		current_record_genome = [weights_in, biases_in, weights_out, biases_out]
		current_record_height = this_gen_record_height
		
	
	# Generation gestorben. Alle runtergefallen.
	if current_pops == 0:
		generation_count += 1
		# setze Rekord zurück
		this_gen_record_height = 1
		
		need_new_level.emit(generation_count)








#########################
#########################
######   Helfer-  #######
######   Klassen  #######
#########################
#########################


class Genome:
	# Dictionary mit den Keys "input", "hidden" und "output": Die Values
	# von denen sind Arrays mit den einzelnen Genome_Node-Klassen
	var nodes: Dictionary
	var connections: Array
	# Anfänglich hat diese Struktur immer drei Nodes. Index 0, 1 und 2
	var node_number: int = 0
	var connection_number: int = 0
	
	func _init(_nodes, _connections):
		nodes		= _nodes
		connections	= _connections
	
	func add_node(type: String, bias: float) -> void:
		var node = Genome_Node.new(node_number, bias)
		nodes[type].append(node)
		node_number += 1
	
	func add_connection(origin_node_id: int, target_node_id: int, weight: float) -> void:
		"""Erstellt eine neue Verbindung mit einer fortlaufenden, neuen ID"""
		var connection = Genome_Connection.new(origin_node_id, target_node_id, weight)
		connections.append(connection)
		connection_number += 1
	
	func get_connections_from_node(node_id: int) -> Array:
		var list_of_connections = []
		for con: Genome_Connection in connections:
			var orig: int = con.get_origin()
			var targ: int = con.get_target()
			if orig == node_id or targ == node_id:
				list_of_connections.append(con.get_id())
	
	func remove_node(node_id) -> void:
		"""Loope durch alle existierenden Nodes und lösche die Node mit der entsprechenden ID"""
		for key in nodes:
			var node_list: Array = nodes[key]
			for i in range(node_list.size()):
				var node: Genome_Node = node_list[i]
				var id = node.get_number()
				if id == node_id:
					node_list.pop_at(i)
					
					## Wenn eine Node gelöscht wird, müssen auch alle damit
					## Connections gelöscht werden, damit sie nicht ins nichts führen.
					
					
					return
	
	func remove_connection(connection_id: int) -> void:
		
	
	func get_node_ids(type: String = "hidden", all: bool = false) -> Array:
		"""gibt ein Array mit allen Node-IDs des gegebenen Typs zurück.
		Falls all = True ist, gibt es die IDs aller Typen zurück"""
		var id_array = []
		if all:
			for key in nodes:
				var node_list: Array = nodes[key]
				for node in node_list:
					var id = node.get_number()
					id_array.append(id)
			return id_array
		else:
			var node_list: Array = nodes[type]
			for node in node_list:
				var id = node.get_number()
				id_array.append(id)
			return id_array
	
	func get_nodes():
		return nodes
	
	func get_connections():
		return connections
	
	func mutate():
		# Base-Chance, dass etwas mutiert:
		var mutation_chance: float = 0.5
		
		# Mutation A: Veränderung des Gewichtes einer Verbindung (+/- 0.3)
		if randf() > mutation_chance:
			if not arrays_have_same_content(connections, init_connections):
	
	func mutate_weight(mutating_connection:Genome_Connection):
		var old_weight = mutating_connection.get_weight()
		mutating_connection.set_weight(old_weight + randf_range(-0.3, 0.3))


## Helfer-Klasse zur Abbildung von Connections
class Genome_Connection:
	var origin: int		# Nummer der Ausgangs-Node
	var target: int		# Nummer der Ziel-Node
	var weight: float	# Gewicht der Verbindung. Geht von 0.0 (ausgeschaltet) bis 1.0

	func _init(_origin: int, _target: int, _weight: float):
		origin = _origin
		target = _target
		weight = _weight
	
	func set_weight(new_weight: float) -> void:
		weight = new_weight
	
	func get_weight() -> float:
		return weight
	
	func set_origin(new_origin: int) -> void:
		origin = new_origin
	
	func get_origin() -> int:
		return origin
	
	func set_target(new_target: int) -> void:
		target = new_target
	
	func get_target() -> int:
		return target


## Helfer-Klasse zur Abbildung von Nodes
class Genome_Node:
	var number: int		# Nummer der Node. In einem Genom einzigartig.
	var bias: float		# Bias der Node.
	
	func _init(_number: int, _bias: float):
		number = _number
		bias = _bias

	func set_bias(new_bias: float) -> void:
		bias = new_bias
	
	func get_bias() -> float:
		return bias
	
	func set_number(new_number: int) -> void:
		number = new_number
	
	func get_number() -> int:
		return number
