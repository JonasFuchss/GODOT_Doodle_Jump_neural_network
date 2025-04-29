extends Node

var generation_count: int = 0
var pop_count: int = 1
var current_pops: int = 0
var spawn_coord: Array = []

var current_record_height: float = 1
var this_gen_record_height: float = 1

# Trackt innerhalb einer Generation den Score und das Genom aller gestorbenen
# Doodles. Wird beim Erstellen einer neuen Gen zurückgesetzt.
var dead_scores_and_genomes: Dictionary = {}

# Trackt die Zahl der Mutationen generationsübergreifend.
var innovation_counter: int = 0
# Trackt Mutationen für jede Generation einzeln. Mutationen, welche innerhalb
# einer Generation identisch sind (zB 02 -> 04 splittet in 02 -> 05 -> 04) wird
# dieser die selbe innovations-Nummer zugeordnet.
var mutation_tracker: Dictionary = {}
"""
Struktur: Im Key die Mutation, im Value die Innovationsnummer
	mutation_tracker = {
		occured_mutation{...}: 0,
		occured_mutation{...}: 2,
		occured_mutation{...}: 5,
		occured_mutation{...}: 12,
		...
	}
"""


var target_species_count = 1
var species_threshold = 3.0
var threshold_step = 0.05


var highscore_label: Label
var Doodle = preload("res://Scenes/doodle.tscn")


signal create_doodle(doodle, x, y, Genome)
signal need_new_level(generation)


func _ready() -> void:
	print("nn_trainer ready")
	highscore_label = get_node("/root/root/Camera2D/Header/Highscore")

func create_generation() -> void:
	print("nn_trainer creating new generation")
	# Zurücksetzen des generations-spezifischen mutations-trackers & Scores der letzten Runde
	mutation_tracker.clear()
	dead_scores_and_genomes.clear()
	
	for pop in pop_count:
		var gene: Gene_Stuff.Genome
		
		# Wenn Gen 0, erstelle Gene mit Initialwerten
		# Anfängliche Genom-Struktur, in der ersten Generation bei allen gleich.
		# Bei Erstellung der ersten Generation passieren erste Mutationen
		if generation_count == 0:
			var rand_weight_1 = randf()
			randomize()
			var rand_weight_2 = randf()
			gene = Gene_Stuff.Genome.new(
				{
					"input": [Gene_Stuff.Genome_Node.new(0, 0.0), Gene_Stuff.Genome_Node.new(1, 0.0)],
					"hidden": [],
					"output": [Gene_Stuff.Genome_Node.new(2, 0.0)]
				},
				{
					0: Gene_Stuff.Genome_Connection.new(0, 1, rand_weight_1),
					1: Gene_Stuff.Genome_Connection.new(1, 2, rand_weight_1)
				}
			)
			
			var occured_mutation = gene.mutate()
			if occured_mutation["type"] != "none":
				var this_innovation_number: int
				# Ist diese Mutation in dieser Generation so schon einmal vorgekommen?
				# Wenn ja, ordne ihr dieselbe innovationsnummer zu. Wenn nein, erhöhe die
				# Mutationsnummer, ordne die höhere zu und logge die Mutation für die
				# die jetzige Mutation.
				if mutation_tracker.has(occured_mutation):
					this_innovation_number = mutation_tracker[occured_mutation]
				else:
					innovation_counter += 1
					this_innovation_number = innovation_counter
					mutation_tracker[occured_mutation] = innovation_counter
				gene.add_mutation(this_innovation_number, occured_mutation)
			
			print("Mutation: " + str(occured_mutation))
		
		else:
			# TODO Bilde Spezies anhand von der Ähnlichkeit der Innovations-Folge der
			# Genome und lasse die stärksten Genome in jeder Spezies fortpflanzen.
			var key = dead_scores_and_genomes.keys()[0] # FÜR DEBUG MIT EINZELNER POP
			gene = Gene_Stuff.Genome.new(
				dead_scores_and_genomes[key].get_nodes(),
				dead_scores_and_genomes[key].get_connections()
			)
			
			var occured_mutation = gene.mutate()
			if occured_mutation["type"] != "none":
				var this_innovation_number: int
				if mutation_tracker.has(occured_mutation):
					this_innovation_number = mutation_tracker[occured_mutation]
				else:
					innovation_counter += 1
					this_innovation_number = innovation_counter
					mutation_tracker[occured_mutation] = innovation_counter
				gene.add_mutation(this_innovation_number, occured_mutation)
			
			print("Mutation: " + str(occured_mutation))
		
		current_pops += 1
		create_doodle.emit(Doodle, spawn_coord[0], spawn_coord[1], gene)


func _on_root_level_built(x_coord: float, y_coord: float) -> void:
	spawn_coord = [x_coord, y_coord]
	create_generation()


func _on_doodle_death_by_falling(genome: Gene_Stuff.Genome, score: float) -> void:
	current_pops -= 1
	
	print("doodle died")
	# runde den Score auf einen Integer. Verhindert Rundungsfehler.
	var rounded_score = roundf(score)
	
	# speichere das Gene des gestorbenen Doodles und den dazuhgehörigen Score
	dead_scores_and_genomes[rounded_score] = genome
	
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
