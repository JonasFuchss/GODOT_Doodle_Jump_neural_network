extends Node

var graph_painter	= preload("res://Scenes/UI Prefabs/ui_graph.tscn")
var arrow_drawer	= preload("res://Scenes/UI Prefabs/arrow_drawer.tscn")
var graph_root: CanvasLayer

var generation_count: int = 0
var pop_count: int = 150
var current_pops: int = 0
var spawn_coord: Array = []

var current_record_height: float = 1
var this_gen_record_height: float = 1


# Trackt die Genome der bestperforming Genomen aus jeder Generation.
# Kann genutzt werden, um hinterher ein Training nachzuvollziehen und die
# besten Genome anzuzeigen. Index der Liste == Generation
var best_from_each_gen: Array = []
"""
Struktur: Array:
	best_from_each_gen = [
		0: Genome_with_highest_score,
		1: Genome_with_highest_score,
		...
	]
"""

# Trackt innerhalb einer Generation den Score und das Genom aller gestorbenen
# Doodles. Wird beim Erstellen einer neuen Gen zurückgesetzt.
# Kann kein Dict mit Score als Key sein, da Keys sich nicht doppeln dürfen (duh)
var dead_scores_and_genomes: Array[Dictionary] = []
"""
Struktur: Dictionary, welche Score und Genom beinhalten:
	dead_scores_and_genomes = [
		{"score": 244, "genome": >genome< },
		{"score": 41, "genome": >genome< },
		{...}
	]
"""

# Trackt die Zahl der Mutationen generationsübergreifend. Muss mit der anfänglichen 
# Zahl an Connections -1 beginnen, da die Connection-IDs daran gekoppelt sind
var innovation_counter: int = 3
# Trackt strukturelle Mutationen für jede Generation einzeln. Mutationen, welche innerhalb
# einer Generation identisch sind (zB 02 -> 04 splittet in 02 -> 05 -> 04) wird
# dieser die selbe innovations-Nummer zugeordnet.
var mutation_tracker: Dictionary = {}
"""
Struktur: Im Key die detailierte Mutation, im Value die Innovationsnummer(n)
Bei einer add_node-Mutation werden zwei Innovationsnummern gebraucht - eine für jede neue Connection!
	mutation_tracker = {
		"add_con_between_3_5": 12,
		"add_node_between_6_7": [13, 14],
		...
	}
"""

# Liste mit allen Spezies und ihren zugehörigen Genomen und fitnesswerten
var species: Array[Dictionary] = []
"""
species = [
	# Spezies 1
	{
		"representant": >random_genome<,
		"genomes": [
			>genome_1<,
			>genome_2<,
			...
		],
		"raw_scores": [
			>normaler_score_1<,
			>normaler_score_2<,
			...
		],
		"adjusted_scores": [
			>angepasster_score_1<,
			>angepasster_score_1<,
			...
		],
		"offspring_count": >wie_viele_nachkommen_gen_zeugen_darf<
	},
	# Spezies 2
	{
		
	},
	# Spezies ...
	...
]
"""

var highscore_label: Label
var Doodle = preload("res://Scenes/doodle.tscn")


signal create_doodle(doodle, x, y, gene: Genome, number: int)
signal need_new_level(generation)


func _ready() -> void:
	print("nn_trainer ready")
	highscore_label = get_node("/root/root/Camera2D/Header/Highscore")
	graph_root = get_node("/root/root/graph_root")

func create_generation() -> void:
	print("creating generation")
	# Zurücksetzen des generations-spezifischen mutations-trackers & Scores der letzten Runde
	mutation_tracker.clear()
	
	if generation_count > 0:
		spezify(dead_scores_and_genomes)
	
	for pop in pop_count:
		var gene: Genome
		
		# Wenn Gen 0, erstelle Gene mit Initialwerten
		# Anfängliche Genom-Struktur, in der ersten Generation bei allen gleich.
		# Bei Erstellung der ersten Generation passieren erste Mutationen
		if generation_count == 0:
			gene = Genome.new(
				{
					"input": [
						Genome_Node.new(0, 0, 0.0),
						Genome_Node.new(1, 0, 0.0),
						Genome_Node.new(2, 0, 0.0),
						Genome_Node.new(3, 0, 0.0)
					],
					"hidden": [],
					"output": [Genome_Node.new(4, 1, 0.0)]
				},
				{
					0: Genome_Connection.new(0, 4, 0.0),
					1: Genome_Connection.new(1, 4, 0.0),
					2: Genome_Connection.new(2, 4, 0.0),
					3: Genome_Connection.new(3, 4, 0.0)
				},
				[0,1],
				[],
				[]
			)
			
			var mutate_tuple = gene.mutate(innovation_counter, mutation_tracker)
			innovation_counter = mutate_tuple[0]
			mutation_tracker = mutate_tuple[1]
			
		else:
			
			# TODO Bilde Spezies anhand von der Ähnlichkeit der Innovations-Folge der
			# Genome und lasse die stärksten Genome in jeder Spezies fortpflanzen.
			var bestPerforming: Genome
			var highscore: float = 0.0
			for entry in dead_scores_and_genomes:
				if entry["score"] <= highscore:
					highscore = entry["score"]
					bestPerforming = entry["genome"]
			
			gene = bestPerforming.clone()
			
			var mutate_tuple = gene.mutate(innovation_counter, mutation_tracker)
			innovation_counter = mutate_tuple[0]
			mutation_tracker = mutate_tuple[1]
		
		current_pops += 1
		create_doodle.emit(Doodle, spawn_coord[0], spawn_coord[1], gene)
	dead_scores_and_genomes.clear()


func log_generations_best() -> void:
	"""Loggt die besten Genome aus jeder Generation und schreibt die weights, 
	connections und nodes in einen json file."""
	var highest_score: int = 0
	var best_genome: Genome
	for entry in dead_scores_and_genomes:
		if entry["score"] >= highest_score:
			highest_score = entry["score"]
			best_genome = entry["genome"]
	best_from_each_gen.append(best_genome.clone())
	## Schreiben in eine JSON zum permanenten Speichern funktioniert noch nicht :(
	#_write_json("res://highscores/best_per_generation.txt", best_from_each_gen)


func spezify(s_and_g) -> Array[Dictionary]:
	"""
	Teilt die übergebenen genome in Spezies auf.
	Allgemeine Formel:
		delta = (ExcessGenes / largestGenomeSize) + (DisjointGenes / largestGenomeSize) +
				0.3 * AverageWeightDifferenceOfMatchingGenes
	"""
	
	"""
	species = [
		# Spezies 1
		{
			"representant": >random_genome<,
			"genomes": [
				>genome_1<,
				>genome_2<,
				...
			],
			"raw_scores": [
				>normaler_score_1<,
				>normaler_score_2<,
				...
			],
			"adjusted_scores": [
				>angepasster_score_1<,
				>angepasster_score_1<,
				...
			],
			"offspring_count": >wie_viele_nachkommen_gen_zeugen_darf<
		},
		# Spezies 2
		{
			
		},
		# Spezies ...
		...
	]
	"""

	
	var calc_delta = func calc_compatibility(i: Genome, j: Genome) -> float:
		var delta: float
		var e: int = 0		# excess_count
		var d: int = 0		# disjoint_count
		var w: float = 0	# avg_weight_dif
		var n: int = 1		# size_of_largest_genome
		
		var con_keys_i: Array = i.connections.keys()
		var con_keys_j: Array = j.connections.keys()
		var size_i = con_keys_i.size()
		var size_j = con_keys_j.size()
		
		# Setze nur die Size, wenn Genome größer als 20 sind. Sonst bleib bei 1
		if size_i > size_j and size_i > 20:
			n = size_i
		elif size_j >= size_i and size_j > 20:
			n = size_j
		
		# i hat excess Genes über j
		if con_keys_i[-1] > con_keys_j[-1]:
			var last_j: int = con_keys_j[-1]
			for key in con_keys_i:
				if key > last_j:
					e += 1

		# j hat excess Genes über i
		elif con_keys_i[-1] < con_keys_j[-1]:
			var last_i: int = con_keys_i[-1]
			for key in con_keys_j:
				if key > last_i:
					e += 1
		
		var matching_gene_count = 0
		var acum_difs = 0.0
		
		# Zähle die disjoint Genes (alle einzelnen Genes minus den excess).
		# wenn es ein matching gene ist, errechne die Weight-Differenz
		for key in con_keys_i:
			if not con_keys_j.has(key):
				d += 1
			else:
				matching_gene_count += 1
				var w_i = i.connections[key].get_weight()
				var w_j = j.connections[key].get_weight()
				acum_difs = acum_difs + (max(w_i, w_j) - min(w_i, w_j))
		for key in con_keys_j:
			if not con_keys_i.has(key):
				d += 1
		d = d-e
		
		# avg Weight-Difference aller matching Genes:
		w = acum_difs / matching_gene_count
		
		delta = e/n+d/n+0.3*w
		
		return delta
	var species_threshold = 3.0
	var species_dup = species.duplicate(true)
	
	# Spezieszuordnung jedes Genoms anhand eines zufälligen Repräsentanten:
	for entry in s_and_g:
		var genome: Genome = entry["genome"]
		var fitness: int = entry["score"]
		var has_species: bool = false
		

		for sp: Dictionary in species_dup:
			var representant: Genome = sp["representant"]
			if calc_delta.call(genome, representant) < 3.0:
				sp["genomes"].append(genome)
				sp["raw_scores"].append(fitness)
				has_species = true
		
		# Wenn keine passende Spezies gefunden wurde (oder noch keine existieren),
		# erstelle eine neue
		if not has_species:
			species_dup.append({"representant": genome, "genomes":[genome], "raw_scores": fitness})
	
	# Errechne für jede Spezies einmal die angepassten scores ...
	var fitness_of_all_species = 0
	for sp in species_dup:
		var popcount = len(sp["genomes"])
		var gesamt_score_of_species = 0
		
		for index in range(len(sp["raw_scores"])):
			var adj_score = sp["raw_scores"][index] / popcount
			sp["adjusted_scores"][index] = adj_score
			gesamt_score_of_species += adj_score
		
		fitness_of_all_species += gesamt_score_of_species
	
	# ... und die Anzahl an Kindern, die die Spezies zeugen darf
	for sp in species_dup:
		var gesamt_score_of_species = 0
		for adj_score in sp["adjusted_scores"]:
			gesamt_score_of_species += adj_score
		sp["offspring_count"] = int(floor((gesamt_score_of_species / fitness_of_all_species)*pop_count))
	
	
	# "Töte" die schwächsten offspring_count gene in jeder Spezies, um Platz für
	# Nachkommen zu machen. 
	for sp in species_dup:
		# finde i mal das schwächste Genom und lösche alle dazugehörigen Daten
		for i in range(sp["offspring_count"]):
			var weakest_score: int = INF
			var weakest_index: int
			for adj_score_index in range(len(sp["adjusted_scores"])):
				if sp["adjusted_scores"][adj_score_index] < weakest_score:
					weakest_score = sp["adjusted_scores"][adj_score_index]
					weakest_index = adj_score_index
			sp["genomes"].pop_at(weakest_index)
			sp["raw_scores"].pop_at(weakest_index)
			sp["adjusted_scores"].pop_at(weakest_index)
	
	# Erstelle die Nachkommen in jeder Spezies:
	# 	Bei Speziesgröße > 5: Stärkstes Genom wird gecloned
	#	75% der restlichen Plätze: 2 zufällige Eltern -> Ein Kind durch Crossover
	#	verbleibende Plätze: Mutation ohne Crossover
	
	return []


func paint_nodes_and_arrows(gene: Genome):
	var graph_inst = graph_painter.instantiate()
	graph_root.add_child(graph_inst)
	var node_dictionary = graph_inst.build_graph(gene.nodes["output"][0].get_layer(), gene.nodes, gene.connections)
	graph_inst.set_connected_genome(gene)
	
	# Nachdem alle Layer gebaut sind, Verbinde die entsprechenden Nodes mit Pfeilen:
	for con_key in gene.connections.keys():
		if gene.disabled_connections.find(con_key) == -1:
			var orig_id: int		= gene.connections[con_key].get_origin()
			var targ_id: int		= gene.connections[con_key].get_target()
			var orig_node: Control 	= node_dictionary[orig_id]
			var targ_node: Control 	= node_dictionary[targ_id]
			var weight: float		= gene.connections[con_key].get_weight()
			var arrow_inst = arrow_drawer.instantiate()
			graph_root.add_child(arrow_inst)
			arrow_inst.set_draw_params(orig_node, targ_node, weight)

func clear_nodes_and_arrows() -> void:
	# Lösche alle vorherigen Graphen und Pfeile
	var childs = graph_root.get_children()
	for child: Node in childs:
		child.free()

func _on_root_level_built(x_coord: float, y_coord: float) -> void:
	spawn_coord = [x_coord, y_coord]
	create_generation()


func _on_doodle_death_by_falling(genome: Genome, score: float) -> void:
	current_pops -= 1
	
	# runde den Score auf einen Integer. Verhindert Rundungsfehler.
	var rounded_score = roundf(score)
	
	# speichere das Gene des gestorbenen Doodles und den dazuhgehörigen Score
	dead_scores_and_genomes.append({"score": rounded_score, "genome": genome})
	
	if rounded_score < this_gen_record_height:
		this_gen_record_height = rounded_score
	
	# Hat der doodle einen neuen Highscore aufgestellt? Wenn ja, speichere den Rekord!
	if this_gen_record_height < current_record_height:
		print("-----------\nnew record: ", round(this_gen_record_height), "\n-----------")
		current_record_height = this_gen_record_height
		# und male das aktuell beste Genom
		clear_nodes_and_arrows()
		paint_nodes_and_arrows(genome)
		
	
	# Generation gestorben. Alle runtergefallen.
	if current_pops == 0:
		log_generations_best()
		generation_count += 1
		# setze Rekord zurück
		this_gen_record_height = 1
		
		need_new_level.emit(generation_count)







#####################
#####################
###### Helper- ######
##### Functions #####
#####################
#####################

func _write_json(path, data):
	"""erstellt / überschreibt eine (existierende) Datei mit einem JSON String"""
	# Convert the data to a JSON string
	var json_string = JSON.stringify(data, "\t", true, true)
	
	# Open the file for writing
	var file = FileAccess.open(path, FileAccess.WRITE_READ)
	
	# Write the JSON string to the file
	file.store_string(json_string)
	
	# Close the file
	file.close()

func _read_json(path) -> String:
	return FileAccess.get_file_as_string(path)
