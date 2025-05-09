class_name Genome extends Node

# Dictionary mit den Keys "input", "hidden" und "output": Die Values
# von denen sind Arrays mit den einzelnen Genome_Node-Klassen
var nodes: Dictionary
"""
Struktur des Nodes-Dictionary: Type im Key, Array mit Objekten als Value

	nodes = {
		"input":	[
			Genome_Node(number, layer, bias),
			Genome_Node(number, layer, bias),
			...
		],
		"hidden":[
			Genome_Node(number, layer, bias),
			Genome_Node(number, layer, bias),
			...
		],
		"output":[
			Genome_Node(number, layer, bias),
			Genome_Node(number, layer, bias),
			...
		]
	}
"""

# Zum durchgehenden Hochzählen der Connections / Nodes
var node_number: int = 0

var connections: Dictionary
"""
	Struktur des Connection-Dictionaries: Innovationsnummer (ID) im Key,
	Objekt als Value
	
		connections = {
			1:	Genome_Connection(Origin, Target, Weight),
			2:	Genome_Connection(Origin, Target, Weight),
			4:	Genome_Connection(Origin, Target, Weight),
			5:	Genome_Connection(Origin, Target, Weight),
			11:	Genome_Connection(Origin, Target, Weight),
			...
		}
"""

var disabled_connections: Array
"""
	listet alle INAKTIVEN Connection-IDs auf, welche durch die disable_connection- und add_node-
	Mutations abgeschaltet wurden.
	
		disabled_connections = [2,4,...]
"""

var enabled_connections: Array
"""
	listet alle AKTIVEN connection-IDs auf. Gegenstück zu disabled_connections.
	
		enabled_connections = [1,5,11,...]
"""

var missing_connections: Array[Array]
"""
	listet alle connections auf, welche noch NICHT existieren - welche also durch
	das Hinzufügen einer neuen Node potentiell erstellt werden könnten.
	Aufgelistete Connections sind lediglich [origin_node_id, target_node_id]
	
		missing_connections = [
			[origin_node_id, target_node_id],
			[origin_node_id, target_node_id],
			[origin_node_id, target_node_id],
			...
		]
"""

var incoming_connections: Dictionary = {}
"""
Für eine performantere Feed-Forward-Funktion.
	node_id → Array[Tuple(origin_id, weight_ref)]
"""


func _init(_nodes: Dictionary, _connections: Dictionary, _enabled_connections: Array, _disabled_connections: Array, _missing_connections: Array[Array]):
	nodes		= _nodes
	node_number = nodes["input"].size() + nodes["hidden"].size() + nodes["output"].size()
	connections	= _connections
	incoming_connections.clear()
	for innov_id in connections.keys():
		var con: Genome_Connection = connections[innov_id]
		var tgt = con.get_target()
		if not incoming_connections.has(tgt):
			incoming_connections[tgt] = []
		incoming_connections[tgt].append([ con.get_origin(), con ])
	enabled_connections = _enabled_connections
	disabled_connections = _disabled_connections
	missing_connections = _missing_connections


func clone() -> Genome:
	"""Gibt eine tiefe Kopie des aktuellen Genoms zurück."""
	var new_genome = Genome.new(self.nodes.duplicate(true), self.connections.duplicate(true), self.enabled_connections.duplicate(true), self.disabled_connections.duplicate(true), self.missing_connections.duplicate(true))
	new_genome.incoming_connections = self.incoming_connections.duplicate(true)
	return new_genome

func get_innovation_numbers() -> Array:
	"""Gibt ein (sortiertes) Array mit allen Innovationsnummern der Connections zurück."""
	var inno_nums: Array = connections.keys()
	inno_nums.sort()
	return inno_nums

func add_node(type: String, layer: int, bias: float) -> int:
	"""Erstellt eine neue Node mit der fortlaufenden, neuen ID und gibt die ID zurück"""
	var node = Genome_Node.new(node_number, layer, bias)
	nodes[type].append(node)
	node_number += 1
	return node_number - 1

func add_connection(origin_node_id: int, target_node_id: int, weight: float, innovation_number: int) -> void:
	"""Erstellt eine neue Verbindung mit der gegebenen Innovationnumber"""
	var connection = Genome_Connection.new(origin_node_id, target_node_id, weight)
	connections[innovation_number] = connection
	enable_connection(innovation_number)
	if not incoming_connections.has(target_node_id):
		incoming_connections[target_node_id] = []
	incoming_connections[target_node_id].append([origin_node_id, connection])

func get_connections_from_node(node_id: int) -> Array:
	"""Gibt für eine Node (per ID spezifiziert) die IDs aller damit
	verbundenen Connections zurück (aktive und inaktive)"""
	var list_of_connection_ids = []
	# iteriere über alle Connections und schaue, ob sie in Origin oder 
	# Target mit der Node_id verbunden sind.
	for key in connections.keys():
		var con: Genome_Connection = connections[key]
		var orig: int = con.get_origin()
		var targ: int = con.get_target()
		if orig == node_id or targ == node_id:
			list_of_connection_ids.append(key)
	return list_of_connection_ids

func disable_connection(connection_id: int) -> void:
	"""Deaktiviere eine Verbindung anhand ihrer ID und füge sie disabled_connections hinzu"""
	enabled_connections.erase(connection_id)
	disabled_connections.append(connection_id)
	
	var con: Genome_Connection = connections[connection_id]
	var tgt: int = con.get_target()
	if incoming_connections.has(tgt):
		# filtert alle Paare heraus, deren conn_ref == diese Connection
		var cleaned: Array = []
		for pair in incoming_connections[tgt]:
			if pair[1] != con:
				cleaned.append(pair)
		incoming_connections[tgt] = cleaned

func enable_connection(connection_id: int) -> void:
	"""(Re)aktiviere eine Verbindung anhand ihrer ID"""
	disabled_connections.erase(connection_id)
	enabled_connections.append(connection_id)
	var con: Genome_Connection = connections[connection_id]
	var tgt: int = con.get_target()
	if not incoming_connections.has(tgt):
		incoming_connections[tgt] = []
	incoming_connections[tgt].append([ con.get_origin(), con ])

func get_node_ids(type: String = "", all: bool = true) -> Array:
	"""gibt ein Array mit allen Node-IDs des gegebenen Typs zurück.
	Falls all = True ist, gibt es die IDs aller Typen zurück"""
	var id_array = []
	if all:
		for key in nodes.keys():
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

func change_node_bias_by_id(node_id, new_bias) -> void:
	"""Ändert den Bias einer Node anhand der ID. ID muss existieren!"""
	for key in nodes.keys():
		var node_list: Array = nodes[key]
		for node: Genome_Node in node_list:
			if node.get_number() == node_id:
				node.set_bias(new_bias)

func get_node_by_id(node_id):
	"""Gibt eine Node anhand ihrer ID zurück"""
	for key in nodes.keys():
		var node_list: Array = nodes[key]
		for i in range(node_list.size()):
			var node: Genome_Node = node_list[i]
			if node.get_number() == node_id:
				return node

func get_nodes() -> Dictionary:
	return nodes

func get_connections() -> Dictionary:
	return connections

func get_disabled_connections() -> Array:
	return disabled_connections

func get_enabled_connections() -> Array:
	return enabled_connections

func get_missing_connections() -> Array:
	return missing_connections

func add_layer_and_shift_right(new_layer_number) -> void:
	"""
	Fügt ein Layer an Index new_layer_number zwischen zwei bestehenden Layern ein.
	Dies "bewegt" logischerweise alle Nodes mit einem Layer >= eine Stufe weiter nach rechts.
	"""
	for node_type in nodes.keys():
		# Input hat immer Layer 0, kann daher beim Verschieben geskippt werden.
		if node_type == "input":
			continue
		for node: Genome_Node in nodes[node_type]:
			var i = node.get_layer()
			if i >= new_layer_number:
				node.set_layer(i + 1)
	

func mutate(current_max_innov_number: int, mutation_tracker: Dictionary) -> Array:
	"""
	Mutiert anhand der Wahrscheinlichkeiten unten. Gibt danach eine erweiterte
	(oder gleichgebliebene, falls es diese Mutation schon mal gab oder sie
	nicht strukturell ist) Innovations-Nummer und Mutationstracker zurück.
	
	mögliche Mutationen:
		A: Connection-Weight-Änderung (80%)
			Das Gewicht einer Connection ändert sich. Nicht strukturell / tracked.
			A.1: Änderung im Intervall +-0.3 (90%)
			A.2: Änderung mit vollständig zufälligem Wert (10%)
		B: Connection-Hinzufügen (3%)
			Die Erstellung einer noch nicht bestehenden Connection.
		C: Node-Hinzufügen (5%)
			Die Erstellung einer neuen Node anstelle einer bereits aktiven
			Connection. Resultiert in der Deaktivierung der alten Connection und
			der Erstellung von zwei neuen Connections mit der neuen Node (in-
			coming Weight: 1, outgoing Weight: wie die alte Connection).
	"""
	
	# Mutation A, Wahrscheinlichkeit 80%
	if randf() <= 0.8:
		# Mutation A.1, Wahrscheinlichkeit 90%
		if randf() <= 0.9:
			var con_id = connections.keys().pick_random()
			var old_weight = connections[con_id].get_weight()
			var new_weight = old_weight + randf_range(-0.3, 0.3)
			if new_weight < 0.0:
				connections[con_id].set_weight(0.0)
				disable_connection(con_id)
			else:
				connections[con_id].set_weight(new_weight)
		# Mutation A.2, Wahrscheinlichkeit 10%
		else:
			var con_id = connections.keys().pick_random()
			var new_weight = randf()
			connections[con_id].set_weight(new_weight)
			
	# Mutation B, Wahrscheinlichkeit 3% & nur falls es nicht-existierende Connections gibt
	if randf() <= 0.03 and not missing_connections.is_empty():
		var innov_num = current_max_innov_number + 1
		var added_con_nodes = missing_connections.pick_random()
		var mutation_key = "add_con_between_%d_%d" % [added_con_nodes[0], added_con_nodes[1]]
		# lösche die hinzuzufügende Verbindung aus missing_connections
		missing_connections.erase(added_con_nodes) 
		# Gab es diese Mutation in der Generation schon? Wenn ja nutze ihre
		# Innovationsnummer, wenn nein logge sie und nehm die nächste.
		if mutation_tracker.has(mutation_key):
			innov_num = mutation_tracker[mutation_key]
		else:
			current_max_innov_number = innov_num
			mutation_tracker[mutation_key] = current_max_innov_number
		# Erstelle neue Verbindung zwischen den Node-IDs von missing_connections
		add_connection(added_con_nodes[0], added_con_nodes[1], randf(), innov_num)
		
	
	# Mutation C, Wahrscheinlichkeit 5%
	if randf() <= 0.05:
		var innov_num_1 = current_max_innov_number + 1
		var innov_num_2 = current_max_innov_number + 2
		var replaced_connection_id = enabled_connections.pick_random()
		var old_con_origin = connections[replaced_connection_id].get_origin()
		var old_con_target = connections[replaced_connection_id].get_target()
		var old_con_weight = connections[replaced_connection_id].get_weight()
		var origin_node_layer = get_node_by_id(old_con_origin).get_layer()
		var target_node_layer = get_node_by_id(old_con_target).get_layer()
		var mutation_key = "add_node_between_%d_%d" % [old_con_origin, old_con_target]
		# Deaktivieren der ersetzten Verbindung
		disable_connection(replaced_connection_id)
		# erstelle eine neue hidden Node mit dem Layer hinter der Original-Node:
		var new_node_layer = origin_node_layer + 1
		# Wenn zwischen beiden Original-Nodes noch kein Layer existiert (1 Differenz),
		# lege ein neues an und ändere alle Nodes mit layer >= targetlayer um +1  
		if target_node_layer - origin_node_layer == 1:
			add_layer_and_shift_right(new_node_layer)
		var new_node_id = add_node("hidden", new_node_layer, randf_range(-1.0, 1.0))
		# Gab es diese Mutation in der Generation schon? Wenn ja nutze ihre
		# Innovationsnummern, wenn nein logge sie und nehm die nächsten zwei.
		if mutation_tracker.has(mutation_key):
			innov_num_1 = mutation_tracker[mutation_key][0]
			innov_num_2 = mutation_tracker[mutation_key][1]
		else:
			current_max_innov_number += 2
			mutation_tracker[mutation_key] = [current_max_innov_number - 1, current_max_innov_number]
		add_connection(old_con_origin, new_node_id, 1.0, innov_num_1)
		add_connection(new_node_id, old_con_target, old_con_weight, innov_num_2)
		# Füge alle neuen, potentiellen Connections missing_connections hinzu:
		for type_key in nodes.keys():
			for node: Genome_Node in nodes[type_key]:
				var num = node.get_number()
				var layer = node.get_layer()
				if num != old_con_origin and num != old_con_target and num != new_node_id:
					if layer < new_node_layer:
						missing_connections.append([num, new_node_id])
					elif layer > new_node_layer:
						missing_connections.append([new_node_id, num])
	
	return [current_max_innov_number, mutation_tracker]



var _input_values: Dictionary = {} # node_id → input-Wert
var _output_cache: Dictionary = {} # node_id → bereits berechnete Ergebnisse

func calc_node_output(node_id: int) -> float:
	if _output_cache.has(node_id):
		return _output_cache[node_id]

	var sum := 0.0
	if incoming_connections.has(node_id):
		for pair in incoming_connections[node_id]:
			var origin_id: int = pair[0]
			var connection: Genome_Connection = pair[1]
			sum += calc_node_output(origin_id) * connection.get_weight()

	var node_obj: Genome_Node = get_node_by_id(node_id)
	sum += node_obj.get_bias()

	var out = tanh(sum)
	_output_cache[node_id] = out
	return out


func feed_forward(input_dict: Dictionary) -> Array:
	"""
	input_dict: { input_node_id_1: wert1, input_node_id_2: wert2, ... }
	Gibt ein Array zurück mit den Outputs aller Output-Nodes
	"""
	# Reset Cache und Input-Werte
	_output_cache.clear()
	_input_values = input_dict.duplicate()
	for node_id in input_dict.keys():
		_output_cache[node_id] = input_dict[node_id]
	
	var results := []
	for node in nodes["output"]:
		var id = node.get_number()
		results.append(calc_node_output(id))
	return results
