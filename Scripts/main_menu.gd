extends Control

var level: PackedScene = preload("res://Scenes/root.tscn")

func _ready() -> void:
	# Setze den Seed des globalen Randomizers fest, um Replizierbarkeit zu gewähren
	seed(12)

func _on_train_button_pressed() -> void:
	var inst = level.instantiate()
	add_child(inst)


func _on_train_button_toggled(toggled_on: bool) -> void:
	pass # Replace with function body.
