extends Node2D


func _on_nn_controller_create_doodle(Doodle: PackedScene) -> void:
	var spawned_doodle = Doodle.instantiate()
	add_child(spawned_doodle)
	print("... spawned doodle")
	spawned_doodle.rotate()
	
	

func _ready() -> void:
	var preloadedDoodle = preload("res://Scenes/doodle.tscn")
	var doodle_instance = preloadedDoodle.instantiate()
	add_child(doodle_instance)
