class_name Genome extends Node

# Dictionary mit den Keys "input", "hidden" und "output": Die Values
# von denen sind Arrays mit den einzelnen Genome_Node-Klassen
var nodes: Dictionary
"""
Struktur des Nodes-Dictionary: Type im Key, Array mit Objekten als Value

	nodes = {
		"input":	[
			Genome_Node(number, bias),
			Genome_Node(number, bias),
			...
		],
		"hidden":[
			Genome_Node(number, bias),
			Genome_Node(number, bias),
			...
		],
		"output":[
			Genome_Node(number, bias),
			Genome_Node(number, bias),
			...
		]
	}
"""

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

# Zum durchgehenden Hochzählen der Connections / Nodes
var node_number: int = 0


func _init(_nodes: Dictionary, _connections: Dictionary, _enabled_connections: Array, _disabled_connections: Array):
	nodes		= _nodes
	node_number = _nodes["input"].size() + nodes["hidden"].size() + nodes["output"].size()
	
	connections	= _connections
	enabled_connections = _enabled_connections
	disabled_connections = _disabled_connections


func clone() -> Genome:
	"""Gibt eine Kopie des aktuellen Genoms zurück."""
	var new_genome = Genome.new(self.nodes, self.connections, self.enabled_connections, self.disabled_connections)
	return new_genome


func add_node(type: String, bias: float) -> int:
	"""Erstellt eine neue Node mit der fortlaufenden, neuen ID und gibt die ID zurück"""
	var node = Genome_Node.new(node_number, bias)
	nodes[type].append(node)
	node_number += 1
	return node_number - 1

func add_connection(origin_node_id: int, target_node_id: int, weight: float, innovation_number: int) -> void:
	"""Erstellt eine neue Verbindung mit der gegebenen Innovationnumber"""
	var connection = Genome_Connection.new(origin_node_id, target_node_id, weight)
	connections[innovation_number] = connection
	enable_connection(innovation_number)

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

func enable_connection(connection_id: int) -> void:
	"""(Re)aktiviere eine Verbindung anhand ihrer ID"""
	disabled_connections.erase(connection_id)
	enabled_connections.append(connection_id)

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

func mutate(current_innov_number: int, mutation_tracker: Dictionary):
	"""
	Mutiert anhand der Wahrscheinlichkeiten unten. Gibt danach eine erweiterte
	(oder gleichgebliebene, falls es diese Mutation schon mal gab oder sie
	nicht strukturell ist) Innovations-Nummer und Mutationstracker zurück.
	
	mögliche Mutationen:
		A: Connection-Weight-Änderung (80%)
			Das Gewicht einer Connection ändert sich. Nicht strukturell / tracked.
			A.1: Änderung im Intervall +-0.3 (90%)
			A.2: Änderung mit vollständig zufälligem Wert (10%)
		B: Connection-Hinzufügen-Änderung (3%)
			Die Erstellung einer noch nicht bestehenden Connection.
		C: Node-Hinzufügen-Änderung (5%)
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
			
	# Mutation B, Wahrscheinlichkeit 3%
	if randf() <= 0.03 and not missing_connections.is_empty():
		## TODO
	
	# Mutation C, Wahrscheinlichkeit 5%
	if randf() <= 0.05:
		



var _input_values: Dictionary = {} # node_id → input-Wert
var _output_cache: Dictionary = {} # node_id → bereits berechnete Ergebnisse

func activation(x: float) -> float:
	"""
	Gibt den tanh-Wert der gegebenen Float-Zahl zurück.
	Der resultierende Wert liegt zwischen -1.0 und 1.0
	Auch als "Squashing-Funktion" bezeichnet, da sie alle sehr großen (negativen
	oder positiven) Eingaben auf (fast) -1 oder 1 "zusammendrückt".
	"""
	return (exp(x) - exp(-x)) / (exp(x) + exp(-x))

func calc_node_output(node_id: int) -> float:
	# 1) Prüfen, ob das Ergebnis schon im Cache ist
	if _output_cache.has(node_id):
		return _output_cache[node_id]
	
	# 2) Ist es eine Input-Node? Dann einfach den vorgegebenen Wert nehmen
	if _input_values.has(node_id):
		var val = _input_values[node_id]
		_output_cache[node_id] = val
		return val
	
	# 3) Sonst: alle eingehenden Verbindungen aufsammeln
	var sum := 0.0
	for con_id in connections.keys():
		var con: Genome_Connection = connections[con_id]
		if con.get_target() == node_id:
			var origin_id = con.get_origin()
			var origin_out = calc_node_output(origin_id)
			sum += origin_out * con.get_weight()
	
	# 4) Bias der Node holen
	var node_obj: Genome_Node = get_node_by_id(node_id)
	sum += node_obj.get_bias()
	
	# 5) Aktivierung anwenden und ins Cache schreiben
	var out = activation(sum)
	_output_cache[node_id] = out
	return out

func feed_forward(input_dict: Dictionary) -> Array:
	"""
	input_dict: { input_node_id_1: wert1, input_node_id_2: wert2, ... }
	Gibt ein Array zurück mit den Outputs aller Output-Nodes
	"""
	# Reset Cache und Input-Werte
	_input_values = input_dict.duplicate()
	_output_cache.clear()
	
	var results := []
	for node in nodes["output"]:
		var id = node.get_number()
		results.append(calc_node_output(id))
	return results
