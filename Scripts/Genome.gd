class_name Genome extends Node


# Alle Mutationen, welche dieses Netz im Laufe seiner Lebenszeit bisher
# durchgemacht hat. Die Keys ist die eindeutige Innovationsnummer der Mutation,
# die Values der Inhalt der Mutation (wie zurückgegeben durch mutate())
var mutations: Dictionary = {}
"""
Struktur:
	mutations = {
		0: occured_mutation{...},
		2: occured_mutation{...},
		5: occured_mutation{...},
		12: occured_mutation{...},
		...
	}
"""

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
		]
		"hidden":[
			Genome_Node(number, bias),
			Genome_Node(number, bias),
			...
		]
		"output":[
			Genome_Node(number, bias),
			Genome_Node(number, bias),
			...
		]
	}
"""
# Keys: ID der jeweiligen Connection. Values: Genome_Connection Instanzen
var connections: Dictionary
"""
	Struktur des Connection-Dictionaries: ID im Key, Objekt als Value
	
		connections = {
			0:	Genome_Connection(Origin, Target, Weight),
			1:	Genome_Connection(Origin, Target, Weight),
			2:	Genome_Connection(Origin, Target, Weight),
			3:	Genome_Connection(Origin, Target, Weight),
			...
		}
"""
# Hier werden fehlende Verbindungen aufgelistet, welche bei add_node- und 
# remove_connection-Mutationen entstehen können.
var missing_connections: Array[Array] = []
"""
	Struktur von missing_connections:
		
		missing_connections = [
			[origin_id, target_id],
			[origin_id, target_id],
			[origin_id, target_id],
			...
		]
"""
# Zum durchgehenden Hochzählen der Connections / Nodes
var node_number: int = 0
var connection_number: int = 0


func _init(_nodes: Dictionary, _connections: Dictionary):
	nodes		= _nodes
	node_number = _nodes["input"].size() + nodes["hidden"].size() + nodes["output"].size()
	
	connections	= _connections
	connection_number = _connections.size()


func add_node(type: String, bias: float) -> int:
	"""Erstellt eine neue Node mit der fortlaufenden, neuen ID und gibt die ID zurück"""
	var node = Genome_Node.new(node_number, bias)
	nodes[type].append(node)
	node_number += 1
	return node_number - 1

func add_connection(origin_node_id: int, target_node_id: int, weight: float) -> void:
	"""Erstellt eine neue Verbindung mit der fortlaufenden, neuen ID"""
	var connection = Genome_Connection.new(origin_node_id, target_node_id, weight)
	connections[connection_number] = connection
	connection_number += 1

func get_connections_from_node(node_id: int) -> Array:
	"""Gibt für eine Node (per ID spezifiziert) die IDs aller damit
	verbundenen Connections zurück"""
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

func remove_node(node_id) -> void:
	"""Loope durch alle existierenden Nodes und lösche die Node mit der
	entsprechenden ID und alle damit verbundenen Connections"""
	for key in nodes.keys():
		var node_list: Array = nodes[key]
		for i in range(node_list.size()):
			var node: Genome_Node = node_list[i]
			var id = node.get_number()
			if id == node_id:
				node_list.pop_at(i)
				
				## Wenn eine Node gelöscht wird, müssen auch alle damit
				## Connections gelöscht werden, damit sie nicht ins nichts führen.
				var to_delete = get_connections_from_node(node_id)
				for con in to_delete:
					remove_connection(con)
				return

func remove_connection(connection_id: int) -> Array:
	"""Lösche eine Verbindung anhand ihrer ID und füge sie missing_connections hinzu"""
	var con: Genome_Connection = connections[connection_id]
	missing_connections.append([con.get_origin(), con.get_target()])
	connections.erase(connection_id)
	return [con.get_origin(), con.get_target()]
	

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

func get_nodes():
	return nodes

func get_connections():
	return connections

func randomize_weights_and_biases():
	for category in nodes.keys():
		for node: Genome_Node in nodes[category]:
			node.set_bias(randf())
	for id in connections.keys():
		connections[id].set_weight(randf())

func mutate() -> Dictionary:
	## geschehene Mutationen werden hier aufgelistet
	var occured_mutation: Dictionary = {"type": "none"}
	"""Struktur:
		{
			"type": "none" / "add_node" / "add_connection" / "delete_connection" / "delete_hidden_node",
			"origin_node": ...,
			"node_id": ...,
			"target_node": ...
		}
	"""
	
	# Base-Chance, dass etwas mutiert:
	var mutation_chance: float = 0.5
	if randf() > mutation_chance:
		
		print(missing_connections)
		
		var mutation_type = randf()
		
		# Mutation A: Veränderung des Gewichtes (+-0.3) einer zufälligen Verbindung (30%)
		# Diese Mutation wird NICHT getrackt, da sie häufig passiert
		# und nicht strukturell ist.
		if mutation_type < 0.3:
			var all_ids: Array = connections.keys()
			var chosen_id: int = all_ids.pick_random()
			var con: Genome_Connection = connections[chosen_id]
			con.set_weight(activation(con.get_weight() + randf_range(-0.3, 0.3)))
			print("Weight von Con " + str(chosen_id) + " verändert auf " + str(con.get_weight()))
		
		# Mutation B: Veränderung des Bias (+-0.3) einer zufälligen Node (30%)
		# Diese Mutation wird NICHT getrackt, da sie häufig passiert
		# und nicht strukturell ist.
		if mutation_type >= 0.3 and mutation_type < 0.6:
			var all_ids = get_node_ids()
			var chosen_id: int = all_ids.pick_random()
			var node: Genome_Node = get_node_by_id(chosen_id)
			node.set_bias(activation(node.get_bias() + randf_range(-0.3, 0.3)))
			print("Bias von Node " + str(chosen_id) + " verändert auf " + str(node.get_bias()))
		
		# Mutation C: Einfügen einer neuen Node anstelle einer bestehenden Verbindung (10%)
		# Dies kappt daher natürlich die bestehende Verbindung
		# zB 		A ------> B
		# wird zu
		# 	 		A -> C -> B
		if mutation_type >= 0.6 and mutation_type < 0.7:
			var all_ids: Array = connections.keys()
			var chosen_id: int = all_ids.pick_random()
			var removed_con: Genome_Connection = connections[chosen_id]
			var origin_node_id: int = removed_con.get_origin()
			var target_node_id: int = removed_con.get_target()
			remove_connection(chosen_id)
			var created_node_id: int = add_node("hidden", randf_range(-1.0, 1.0))
			add_connection(origin_node_id, created_node_id, randf())
			add_connection(created_node_id, target_node_id, randf())
			occured_mutation = {
				"type": "add_node",
				"origin_node": origin_node_id,
				"node_id": created_node_id,
				"target_node": target_node_id
			}
		
		# Mutation D: Hinzufügen einer neuen Connection zwischen zwei zufälligen nodes, die
		# noch keine bestehende Connection haben (15%)
		if mutation_type >= 0.7 and mutation_type < 0.85 and not missing_connections.is_empty():
			var pair: Array = missing_connections.pick_random()
			add_connection(pair[0], pair[1], randf())
			occured_mutation = {
				"type": "add_connection",
				"origin_node": pair[0],
				"target_node": pair[1]
			}
		
		# Mutation E: Entfernen einer bestehenden Connection (falls es eine gibt) (05%)
		if mutation_type >= 0.85 and mutation_type < 0.9 and connections.keys().size() > 0:
			var ids = connections.keys()
			var id_to_delete = ids.pick_random()
			var orig_and_target: Array = remove_connection(id_to_delete)
			occured_mutation = {
				"type": "delete_connection",
				"origin_node": orig_and_target[0],
				"target_node": orig_and_target[1]
			}
		
		# Mutation F: Entfernen einer hidden-Node und aller damit (10%) 
		# verbundenen Connections - nur möglich, falls mehr als 1 hidden vorhanden
		if mutation_type >= 0.9 and nodes["hidden"].size() > 1:
			var ids = get_node_ids("hidden", false)
			var id_to_delete = ids.pick_random()
			remove_node(id_to_delete)
			occured_mutation = {
				"type": "delete_hidden_node",
				"node_id": id_to_delete,
			}
		
	return occured_mutation


func get_mutations() -> Dictionary:
	return mutations

func get_innovation_numbers() -> Array:
	return mutations.keys()

func add_mutation(innovation_number: int, occured_mutation: Dictionary) -> void:
	mutations[innovation_number] = occured_mutation


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
