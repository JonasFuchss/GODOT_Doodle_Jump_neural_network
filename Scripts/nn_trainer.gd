extends Node

var generation_count: int = 0
var pop_count: int = 150
var current_pops: int = 0
var spawn_coord: Array = []

var current_record_height: float = 1
var this_gen_record_height: float = 1

# Trackt innerhalb einer Generation den Score und das Genom aller gestorbenen
# Doodles. Wird beim Erstellen einer neuen Gen zurückgesetzt.
var dead_scores_and_genomes: Array[Dictionary] = []
"""
Struktur: Dictionary, welche Score und Genom beinhalten:
	dead_scores_and_genomes = [
		{"score": 244, "genome": >genome< },
		{"score": 41, "genome": >genome< },
		{...}
	]
"""

# Trackt die Zahl der Mutationen generationsübergreifend.
var innovation_counter: int = 0
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


var species_threshold = 3.0


var highscore_label: Label
var Doodle = preload("res://Scenes/doodle.tscn")


signal create_doodle(doodle, x, y, gene: Genome, number: int)
signal need_new_level(generation)


func _ready() -> void:
	print("nn_trainer ready")
	highscore_label = get_node("/root/root/Camera2D/Header/Highscore")

func create_generation() -> void:
	print("creating generation")
	# Zurücksetzen des generations-spezifischen mutations-trackers & Scores der letzten Runde
	mutation_tracker.clear()
	
	for pop in pop_count:
		var gene: Genome
		
		# Wenn Gen 0, erstelle Gene mit Initialwerten
		# Anfängliche Genom-Struktur, in der ersten Generation bei allen gleich.
		# Bei Erstellung der ersten Generation passieren erste Mutationen
		if generation_count == 0:
			gene = Genome.new(
				{
					"input": [Genome_Node.new(0, 0, 0.0), Genome_Node.new(1, 0, 0.0)],
					"hidden": [],
					"output": [Genome_Node.new(2, 1, 0.0)]
				},
				{
					0: Genome_Connection.new(0, 2, 1.0),
					1: Genome_Connection.new(1, 2, 1.0),
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
				if entry["score"] >= highscore:
					highscore = entry["score"]
					bestPerforming = entry["genome"]
			
			gene = bestPerforming.clone()
			
			var mutate_tuple = gene.mutate(innovation_counter, mutation_tracker)
			innovation_counter = mutate_tuple[0]
			mutation_tracker = mutate_tuple[1]
			
		current_pops += 1
		create_doodle.emit(Doodle, spawn_coord[0], spawn_coord[1], gene)
	print(str(mutation_tracker))
	dead_scores_and_genomes.clear()


func spezify(s_and_g) -> Array:
	"""
	Teilt die übergebenen genome in Spezies auf.
	Allgemeine Formel:
		delta = (ExcessGenes / largestGenomeSize) + (DisjointGenes / largestGenomeSize) +
				0.3 * AverageWeightDifferenceOfMatchingGenes
	"""
	return []


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
		
	
	# Generation gestorben. Alle runtergefallen.
	if current_pops == 0:
		generation_count += 1
		# setze Rekord zurück
		this_gen_record_height = 1
		
		need_new_level.emit(generation_count)
