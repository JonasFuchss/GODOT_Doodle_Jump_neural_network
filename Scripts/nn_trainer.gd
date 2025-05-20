extends Node

var graph_painter	= preload("res://Scenes/UI Prefabs/ui_graph.tscn")
var arrow_drawer	= preload("res://Scenes/UI Prefabs/arrow_drawer.tscn")
var graph_root: CanvasLayer

var generation_count: int = 0
var pop_count: int = 150
var current_pops: int = 0
var spawn_coord: Array = []
var species_threshold = 3.0
var target_species_count = 5

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
	
	if generation_count > 0:
		species = spezify(dead_scores_and_genomes)
		for sp in species:
			for genome in sp["genomes"]:
				create_doodle.emit(Doodle, spawn_coord[0], spawn_coord[1], genome)
				current_pops += 1
	
	# falls es die erste Generation ist, erstell mit Default Werten
	else:
		for pop in range(pop_count):
			var gene: Genome
			
			# Wenn Gen 0, erstelle Gene mit Initialwerten
			# Anfängliche Genom-Struktur, in der ersten Generation bei allen gleich.
			# Bei Erstellung der ersten Generation passieren erste Mutationen
			gene = Genome.new(
				{ ## Nodes
					"input": [
						Genome_Node.new(0, 0, 0.0),
						Genome_Node.new(1, 0, 0.0),
						Genome_Node.new(2, 0, 0.0),
						Genome_Node.new(3, 0, 0.0)
					],
					"hidden": [],
					"output": [Genome_Node.new(4, 1, 0.0)]
				},
				{ ## Connections
					0: Genome_Connection.new(0, 4, 0.0),
					1: Genome_Connection.new(1, 4, 0.0),
					2: Genome_Connection.new(2, 4, 0.0),
					3: Genome_Connection.new(3, 4, 0.0)
				},
				[0,1,2,3], ## angeschaltete Connections
				[], ## Abgeschaltete Connections (Gegenstück von angeschaltet)
				[] ## Fehlende Connections
			)
			
			var mutate_tuple = gene.mutate(innovation_counter, mutation_tracker)
			innovation_counter = mutate_tuple[0]
			mutation_tracker = mutate_tuple[1]
			current_pops += 1
			create_doodle.emit(Doodle, spawn_coord[0], spawn_coord[1], gene)
	# Zurücksetzen des generations-spezifischen mutations-trackers & Scores der letzten Runde
	mutation_tracker.clear()
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


func spezify(s_and_g: Array[Dictionary]) -> Array[Dictionary]:
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
		var e: float = 0		# excess_count
		var d: float = 0		# disjoint_count
		var w: float = 0		# avg_weight_dif
		var n: float = 1		# size_of_largest_genome
		
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
		if matching_gene_count > 0:
			w = acum_difs / matching_gene_count
		else:
			w = 0
		
		delta = e/n+d/n+0.3*w
		
		return delta

	var species_dup = species.duplicate(true)
	
	# Damit nicht die alten & neuen Genome gleichzeitig in der Spezies
	# sind, werden die alten gelöscht. Der Representant bleiben vor-
	# handen, da er ein Klon ist.
	for sp: Dictionary in species_dup:
		sp["genomes"].clear()
	
	# Spezieszuordnung jedes Genoms anhand eines zufälligen Repräsentanten:
	for entry in s_and_g:
		var genome: Genome = entry["genome"]
		var fitness: int = entry["score"]
		var has_species: bool = false
		
		for sp: Dictionary in species_dup:
			var representant: Genome = sp["representant"]
			
			if calc_delta.call(genome, representant) < species_threshold:
				sp["genomes"].append(genome)
				sp["raw_scores"].append(fitness)
				has_species = true
				break
			
		if has_species:
			continue
		
		# Wenn keine passende Spezies gefunden wurde (oder noch keine existieren),
		# erstelle eine neue
		species_dup.append({
			"representant": genome, 
			"genomes":[genome], 
			"raw_scores": [fitness],
			"highscore": -1,
			"gens_since_improvement": 0
		})
	
	# Lösche alle Spezies, die keine Population haben:
	# Iteriere rückwärts über alle einträge, damit kein Keyerror vorkommt
	for sp_index in range(len(species_dup) - 1, -1, -1):
		if species_dup[sp_index]["genomes"].is_empty():
			species_dup.remove_at(sp_index)
	
	# Suche für jede Spezies den Highscore und setze gens_since_improvement auf
	# 0, falls sie einen neuen Highscore aufgestellt haben, sonst +=1
	for sp in species_dup:
		# Suche den höchsten raw_score in der Spezies:
		var new_best: bool = false
		for score in sp["raw_scores"]:
			if score > sp["highscore"]:
				sp["highscore"] = score
				new_best = true
		
		if new_best:
			sp["gens_since_improvement"] = 0
		else:
			sp["gens_since_improvement"] += 1
	
	# Errechne für jede Spezies einmal die angepassten scores ...
	var fitness_of_all_species = 0
	for sp in species_dup:
		sp["adjusted_scores"] = []
		var popcount = len(sp["genomes"])
		var gesamt_score_of_species = 0
		
		for index in range(len(sp["raw_scores"])):
			var adj_score = float(sp["raw_scores"][index]) / float(popcount)
			sp["adjusted_scores"].append(adj_score)
			gesamt_score_of_species += adj_score
		
		fitness_of_all_species += gesamt_score_of_species
	
	# Wenn die Spezies sich über 5 Generationen nicht verbessert hat, darf
	# sie keine Kinder zeugen und wird komplett abgetötet:
	for sp in species_dup:
		if sp["gens_since_improvement"] >= 5:
			var index = species_dup.find(sp)
			print("\n----- Lösche Spezies " + str(index) + ", da sie 5x in Folge schlecht performt hat.\n")
			species_dup.remove_at(index)
			
			# Falls der seltene Fall eintritt, dass hierdurch die einzige Spezies abgetötet
			# wurde, erstell eine komplett neue Spezies mit dem Initalblueprint:
			if species_dup.is_empty():
				var tmp_species_dict = {
					"representant": null,
					"genomes": [],
					"raw_scores": [],
					"adjusted_scores": [],
					"offspring_count": 150,
					"highscore": 0.0,
					"gens_since_improvement": 0
				}
				print("Keine Spezies zum fortpflanzen mehr vorhanden, initiere daher eine komplett neue.")
				for pop in pop_count:
					var gene = Genome.new(
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
						[0,1,2,3],
						[],
						[]
					)
					gene.mutate(innovation_counter, mutation_tracker)
					tmp_species_dict["genomes"].append(gene)
					tmp_species_dict["raw_scores"].append(0.0)
					tmp_species_dict["adjusted_scores"].append(0.0)
				
				species_dup.append(tmp_species_dict)

	# ... und errechne die Anzahl an Kindern, die die Spezies zeugen darf
	for sp in species_dup:
		var gesamt_score_of_species = 0
		for adj_score in sp["adjusted_scores"]:
			gesamt_score_of_species += adj_score
		var ct = int((float(gesamt_score_of_species) / float(fitness_of_all_species))*float(pop_count))
		sp["offspring_count"] = ct
	
	# Stelle sicher, dass die Gesamtzahl an offspring exakt pop_count ist
	var total_assigned = 0
	for sp in species_dup:
		total_assigned += sp["offspring_count"]

	var diff = pop_count - total_assigned
	# Korrigiere die Differenz, indem sie auf die insgesamt stärkste
	# Spezies verteilt wird
	while diff != 0:
		var best_index = 0
		var max_score = -INF
		for i in range(species_dup.size()):
			var sp = species_dup[i]
			var score_sum = 0
			for s in sp["adjusted_scores"]:
				score_sum += s
			if score_sum > max_score:
				max_score = score_sum
				best_index = i
		
		# Wende Korrektur an
		species_dup[best_index]["offspring_count"] += sign(diff)
		diff -= sign(diff)
	
	# "Töte" die schwächsten i gene in jeder Spezies, um Platz für
	# Nachkommen zu machen. (i = offspring_count)
	for sp in species_dup:
		# Um zu verhindern, dass kleine, vielversprechende Spezies voll abgetö-
		# tet werden, weil ihnen mehr Kinder als ihre eigene Pop zugewiesen werden,
		# bekommt jede Spezies maximal so viele abgetötet, dass 
		# noch die Hälfte der kleinen Population am Leben bleibt (aufgerundet).
		var survival_threshold_count = 5
		var elim_count = 0
		if sp["genomes"].size() > survival_threshold_count:
			elim_count = floor(sp["genomes"].size() * 0.5)
		# finde i mal das schwächste Genom und lösche alle dazugehörigen Daten
		for i in range(elim_count):
			var weakest_score = INF
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
	for sp in species_dup:
		
		# überspringe, falls offspring == 0:
		if sp["offspring_count"] == 0:
			continue
		
		# Temporäres Spezies-Dict für die Genome der neuen Generation
		var new_gen_species: Dictionary = {
			"representant": null,
			"genomes": [],
			"raw_scores": [],
			"adjusted_scores": [],
			"offspring_count": -1, # Damit sie hinterher nicht gelöscht werden
			"highscore": sp["highscore"],
			"gens_since_improvement": sp["gens_since_improvement"]
		}
		
		var champion_index: int
		# Klone das Champion-Genom in die neue Generation, 1 zu 1 ohne Mutation
		# Tue dies nur falls die Spezies über 5 pops hat
		if len(sp["genomes"]) > 5 and sp["offspring_count"] > 0:
			var best_score = -INF
			var best_index: int
			for adj_score_index in range(len(sp["adjusted_scores"])):
				if sp["adjusted_scores"][adj_score_index] > best_score:
					best_score = sp["adjusted_scores"][adj_score_index]
					best_index = adj_score_index
			new_gen_species["genomes"].append(sp["genomes"][best_index].clone())
			champion_index = best_index
			sp["offspring_count"] -= 1
		else:
			champion_index = -1
		
		# Fülle 75% (abgerundet) der verbleibenden Plätze mit Kindern per Crossover
		# zweier zufälliger Eltern:
		# 	für Gene, welche in beiden Eltern existieren, wird ein zufälliges übernommen
		#	disjointe und excess Gene werden vom fitteren Elternteil übernommen
		var crossover_count: int = floor(sp["offspring_count"]*3/4)
		if sp["genomes"].size() < 2:
			crossover_count = 0
		sp["offspring_count"] -= crossover_count
		for i in range(crossover_count):
			# Suche zwei zufällige Genome raus
			var genome_index_1: int = randi_range(0,len(sp["genomes"])-1)
			var genome_index_2: int = randi_range(0,len(sp["genomes"])-1)
			var fitter_genome: int = 0
			
			# schaue welches Genom das fittere ist (bei gleich fitten Genomen
			# nimm ein zufälliges) und baue entsprechend das neue
			# Genom aus den Alten anhand der obigen Regeln zusammen:
			if sp["adjusted_scores"][genome_index_1] > sp["adjusted_scores"][genome_index_2]:
				fitter_genome = 1
			elif sp["adjusted_scores"][genome_index_1] < sp["adjusted_scores"][genome_index_2]:
				fitter_genome = 2
			else:
				fitter_genome = randi_range(1,2)
				
			var new_nodes: Dictionary = {}
			var new_connections: Dictionary = {}
			var new_enabled_connections: Array = []
			var new_disabled_connections: Array = []
			var new_missing_connections: Array[Array] = []
			var genome_1: Genome = sp["genomes"][genome_index_1]
			var genome_2: Genome = sp["genomes"][genome_index_2]
			if fitter_genome == 1:
				new_missing_connections = genome_1.get_missing_connections()
				new_nodes = genome_1.get_nodes()
				for con in genome_1.connections.keys():
					# Beide haben die Connection: Wähle zufällig
					if genome_2.connections.has(con):
						if randi_range(1,2) == 1:
							new_connections[con] = genome_1.connections[con].clone()
							# Wenn ein Gen im Elternteil Disabled ist, hat es 25% Chance auch 
							# im Kind disabled zu sein.
							if genome_1.enabled_connections.find(con) == -1 and randf() < 0.25:
								new_disabled_connections.append(con)
							else:
								new_enabled_connections.append(con)
						else:
							new_connections[con] = genome_2.connections[con].clone()
							if genome_2.enabled_connections.find(con) == -1 and randf() < 0.25:
								new_disabled_connections.append(con)
							else:
								new_enabled_connections.append(con)
					else:
						new_connections[con] = genome_1.connections[con].clone()
						if genome_1.enabled_connections.find(con) == -1 and randf() < 0.25:
							new_disabled_connections.append(con)
						else:
							new_enabled_connections.append(con)
			else:
				new_nodes = genome_2.get_nodes()
				for con in genome_2.connections.keys():
					# Beide haben die Connection: Wähle zufällig
					if genome_1.connections.has(con):
						if randi_range(1,2) == 1:
							new_connections[con] = genome_1.connections[con].clone()
							if genome_1.enabled_connections.find(con) == -1 and randf() < 0.25:
								new_disabled_connections.append(con)
							else:
								new_enabled_connections.append(con)
						else:
							new_connections[con] = genome_2.connections[con].clone()
							if genome_2.enabled_connections.find(con) == -1 and randf() < 0.25:
								new_disabled_connections.append(con)
							else:
								new_enabled_connections.append(con)
					else:
						new_connections[con] = genome_2.connections[con].clone()
						if genome_2.enabled_connections.find(con) == -1 and randf() < 0.25:
							new_disabled_connections.append(con)
						else:
							new_enabled_connections.append(con)
			new_gen_species["genomes"].append(Genome.new(
				new_nodes,
				new_connections,
				new_enabled_connections,
				new_disabled_connections,
				new_missing_connections
			))
		
		# Fülle die restlichen Plätze mit mutierten Klonen
		for i in range(sp["offspring_count"]):
			# suche ein random Genom zu klonen raus (darf NICHT der champion
			# sein) und mutiere es:
			var index = randi_range(0, len(sp["genomes"])-1)
			while index == champion_index:
				index = randi_range(0, len(sp["genomes"])-1)
			var cloning_genome: Genome = sp["genomes"][index]
			var new_clone: Genome = cloning_genome.clone()
			
			var mutate_tuple = new_clone.mutate(innovation_counter, mutation_tracker)
			innovation_counter = mutate_tuple[0]
			mutation_tracker = mutate_tuple[1]
			
			new_gen_species["genomes"].append(new_clone)
			
		# suche zufällig einen neuen Repräsentanten aus
		new_gen_species["representant"] = new_gen_species["genomes"].pick_random().clone()
		
		# ... und ersetze die alte Spezies durch die neue
		var index = species_dup.find(sp)
		species_dup[index] = new_gen_species
		
	# Lösche alle Spezies, welche keine Nachkommen gezeugt haben und noch übrig sind
	for sp in species_dup:
		if sp["offspring_count"] == 0:
			var index = species_dup.find(sp)
			species_dup.remove_at(index)
			continue
	
	# Wenn die Anzahl an verbleibenden Spezies signifikant GERINGER (-10%)
	# ist als die Zielanzahl an Spezies, verringere den spezies-bildungs-
	# threshold um 0.5. Genauso, wenn die Anzahl höher ist.
	var spez_count = len(species_dup)
	if spez_count < int(target_species_count * 0.9):
		species_threshold -= 0.2
		print("Anzahl an Spezies: " + str(spez_count) + ", daher neues Threshold: " + str(species_threshold))
	elif spez_count > int(target_species_count * 1.1):
		species_threshold += 0.2
		print("Anzahl an Spezies: " + str(spez_count) + ", daher neues Threshold: " + str(species_threshold))
	
	var doodles: int = 0
	for sp in species_dup:
		for g in range(len(sp["genomes"])):
			doodles += 1
	
	print("habe " + str(doodles) + " neu doodles erstellt, in " + str(spez_count) + " Spezies.")
	
	return species_dup


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
	dead_scores_and_genomes.append({"score": abs(rounded_score), "genome": genome})
	
	if rounded_score < this_gen_record_height:
		this_gen_record_height = rounded_score
	
	# Hat der doodle einen neuen Highscore aufgestellt? Wenn ja, speichere den Rekord!
	if this_gen_record_height < current_record_height:
		print("-----------\nnew record: ", round(this_gen_record_height), "\n-----------")
		current_record_height = this_gen_record_height
		
	
	# Generation gestorben. Alle runtergefallen.
	if current_pops == 0:
		#log_generations_best()
		generation_count += 1
		# setze Rekord zurück
		this_gen_record_height = 1
		
		need_new_level.emit(generation_count)


func _on_button_draw_genome(genome: Genome) -> void:
	print("drawing Genome")
	clear_nodes_and_arrows()
	paint_nodes_and_arrows(genome)





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
