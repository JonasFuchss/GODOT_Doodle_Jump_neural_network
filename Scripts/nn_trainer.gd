extends Node

var generation_count = 0
var pop_count = 200
var current_pops = 0
var spawn_coord = []

var current_record_height: float = 1
var this_gen_record_height: float = 1
var current_record_seed: Array

var highscore_label: Label


signal create_doodle(doodle, x, y, values, gencount)
signal need_new_level(generation)

var Doodle = preload("res://Scenes/doodle.tscn")


func _ready() -> void:
	highscore_label = get_node("/root/root/Camera2D/Header/Highscore")


func create_generation() -> void:
	if generation_count != 0:
		print("Abweichung: ", str(0.5 / generation_count))
	for pop in pop_count:
		current_pops += 1
		create_doodle.emit(Doodle, spawn_coord[0], spawn_coord[1], current_record_seed, generation_count)
	
	if generation_count == 0:
		print("Gen 0 - nutze zufällige Werte.")
		# Erste Gen? Dann werden komplett zufällige generiert.


func _on_root_level_built(x_coord: float, y_coord: float) -> void:
	spawn_coord = [x_coord, y_coord]
	create_generation()


func _on_doodle_death_by_falling(weights_in: Array, biases_in: Array, weights_out: Array, biases_out: float, score: float) -> void:
	current_pops -= 1
	
	# runde den Score auf einen Integer. Verhindert Rundungsfehler.
	var rounded_score = roundf(score)
	
	if rounded_score < this_gen_record_height:
		this_gen_record_height = rounded_score
	
	# Hat der doodle einen neuen Highscore aufgestellt? Wenn ja, speichere seinen Seed und den Rekord!
	if this_gen_record_height < current_record_height:
		print("-----------\nnew record: ", round(this_gen_record_height), "\n-----------")
		current_record_seed = [weights_in, biases_in, weights_out, biases_out]
		current_record_height = this_gen_record_height
		
	
	# Generation gestorben. Alle runtergefallen.
	if current_pops == 0:
		generation_count += 1
		# um dem entgegenzuwirken, dass Doodles "lernen" auf der Stelle zu springen,
		# da sie dann die letzten Überlebenden sind, wird, falls der Rekord der
		# aktuellen Generation GERINGER als der der vorherigen ist,
		# die nächste Generation auf Stufe 0 zurückgestuft. Fresh start quasi.
		# Die Doodles müssen sich also stetig verbessern um nicht lobotomisiert
		# zu werden.
		if this_gen_record_height > current_record_height and generation_count > 0:
			generation_count = 0
			current_record_height = 1
			highscore_label.set_text(str(0))
			print("Schlechter Seed. Setze auf Null zurück.")

		# setze Rekord zurück
		this_gen_record_height = 1
		
		print("Aktuell bester Seed:\n", current_record_seed)
		
		need_new_level.emit(generation_count)
