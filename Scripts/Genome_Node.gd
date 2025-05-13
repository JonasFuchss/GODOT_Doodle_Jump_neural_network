class_name Genome_Node extends Node

var number: int		# Nummer der Node. In einem Genom einzigartig.
var layer: int		# Layer auf welchem sich die Node befindet. Eine Node des Typs Input hat immer Layer 0, eine Node des Typs Output immer Layer N-1 (maximales Layer)
var bias: float		# Bias der Node.

func _init(_number: int, _layer: int, _bias: float):
	number = _number
	layer = _layer
	bias = _bias

func set_number(new_number: int) -> void:
	number = new_number

func get_number() -> int:
	return number

func set_bias(new_bias: float) -> void:
	bias = new_bias

func get_bias() -> float:
	return bias

func set_layer(new_layer: int) -> void:
	layer = new_layer

func get_layer() -> int:
	return layer
