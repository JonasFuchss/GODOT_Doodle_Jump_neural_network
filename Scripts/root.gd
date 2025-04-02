extends Node2D


func _on_nn_controller_create_doodle(Doodle: Variant, direction, location) -> void:
	var spawned_doodle = Doodle.instantiate()
	add_child(spawned_doodle)
	print("... spawned doodle")
	
