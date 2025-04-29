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

var init_weights: float = randf()

var highscore_label: Label
var Doodle = preload("res://Scenes/doodle.tscn")


signal create_doodle(doodle, x, y, Genome)
signal need_new_level(generation)


func _ready() -> void:
	highscore_label = get_node("/root/root/Camera2D/Header/Highscore")

func create_generation() -> void:
	# Zurücksetzen des generations-spezifischen mutations-trackers
	mutation_tracker.clear()
	
	for pop in pop_count:
		var gene: Gene_Stuff.Genome
		
		# Wenn Gen 0, erstelle Gene mit Initialwerten
		# Anfängliche Genom-Struktur, in der ersten Generation bei allen gleich.
		# Bei Erstellung der ersten Generation passieren erste Mutationen
		if generation_count == 0:
			print("erste Generation, erstelle frische Gene")
			gene = Gene_Stuff.Genome.new(
				{
					"input": [Gene_Stuff.Genome_Node.new(0, 0.0), Gene_Stuff.Genome_Node.new(1, 0.0)],
					"hidden": [],
					"output": [Gene_Stuff.Genome_Node.new(2, 0.0)]
				},
				{
					0: Gene_Stuff.Genome_Connection.new(0, 1, init_weights),
					1: Gene_Stuff.Genome_Connection.new(1, 2, init_weights)
				}
			)
			gene.mutate()
			
		
		# Errechne die Nodes & Connections leicht abweichend der vorherigen, besten Generation
		## TODO
		
		current_pops += 1
		create_doodle.emit(Doodle, spawn_coord[0], spawn_coord[1], gene)


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
