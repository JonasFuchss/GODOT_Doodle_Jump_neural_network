extends HBoxContainer
class_name ui_graph

const GRAPH_LEVEL 	= preload("res://Scenes/UI Prefabs/graph_level.tscn")
const GRAPH_NODE 	= preload("res://Scenes/UI Prefabs/node.tscn")

var connected_genome: Genome

func build_graph(layers: int, nodes: Dictionary, connections: Dictionary) -> Dictionary:
	var node_dictionary = {}
	var layercount = range(layers)
	layercount.append(layers)
	for layer in layercount:
		if layer == 0:
			var node_list = nodes["input"]
			node_dictionary.merge(_build_layer(node_list))
			# Adde ein leeres Layer nach jedem Layer, AUßER es ist das letzte
			_build_layer([])
		elif layer > 0 and layer < layers:
			var node_list = []
			for node: Genome_Node in nodes["hidden"]:
				var tmp = node.get_layer()
				if tmp == layer:
					node_list.append(node)
			node_dictionary.merge(_build_layer(node_list))
			# Adde ein leeres Layer nach jedem Layer, AUßER es ist das letzte
			_build_layer([])
		else:
			var node_list = nodes["output"]
			node_dictionary.merge(_build_layer(node_list))
	return node_dictionary
			

func _build_layer(node_list: Array) -> Dictionary:
	var node_dictionary = {}
	var layer_inst: VBoxContainer = GRAPH_LEVEL.instantiate()
	add_child(layer_inst)
	if not node_list.is_empty():
		for node: Genome_Node in node_list:
			var new_node_inst = GRAPH_NODE.instantiate()
			layer_inst.add_child(new_node_inst)
			new_node_inst.set_tooltip_text(\
				"Node ID: " + str(node.number)\
			 + 	"\nBias: " + str(node.bias)\
			 + 	"\nLayer: " + str(node.layer)\
			)
			node_dictionary[node.number] = new_node_inst
	return node_dictionary

func get_connected_genome() -> Genome:
	return connected_genome

func set_connected_genome(_connected_genome: Genome) -> void:
	connected_genome = _connected_genome
