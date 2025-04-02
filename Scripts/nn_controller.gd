extends Node2D

var gen_count = 3
var pop_count = 10

signal create_doodle(doodle)

var Doodle = preload("res://Scenes/doodle.tscn")

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# create first generation & let it run
			for p in pop_count:
				print("emitting signal...")
				create_doodle.emit(Doodle)
