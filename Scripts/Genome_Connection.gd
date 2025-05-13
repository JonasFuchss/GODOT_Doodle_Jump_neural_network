class_name Genome_Connection extends Node


var origin: int		# ID der Ausgangs-Node
var target: int		# ID der Ziel-Node
var weight: float	# Gewicht der Verbindung. Geht von -1.0 bis 1.0

func _init(_origin: int, _target: int, _weight: float):
	origin = _origin
	target = _target
	weight = _weight

func clone() -> Genome_Connection:
	return Genome_Connection.new(origin, target, weight)

func set_weight(new_weight: float) -> void:
	weight = new_weight

func get_weight() -> float:
	return weight

func set_origin(new_origin: int) -> void:
	origin = new_origin

func get_origin() -> int:
	return origin

func set_target(new_target: int) -> void:
	target = new_target

func get_target() -> int:
	return target
