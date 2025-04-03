extends Node2D

signal send_direction(direction)

var v: float = 0.0



func _physics_process(delta: float) -> void:
	send_direction.emit(v)
