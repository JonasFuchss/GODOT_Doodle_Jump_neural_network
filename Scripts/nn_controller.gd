extends Node2D

signal send_direction(direction)



## vector as given by the nn. shall be between -1.0 and 1.0
## Determines how much the nn "pushes" the joystick to left or right,
## to control the doodle left/right-movement.
var v: float = 0.0

## number of input-layers (x_diff & y_diff), output-layers (v) and hidden-
## layers with neurons for calculations via sigmoid.
const INPUTS = 2
const HIDDEN_LAYERS = 2
const OUTPUTS = 1
const LEARNING_RATE = 0.1

## weights and biases for input -> hidden (initially small random values)
var weights_in = 	[
						[randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)],
						[randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)]
					]
var biases_in = 	[
						randf_range(-1.0, 1.0),
						randf_range(-1.0, 1.0)
					]

## weights and biases for hidden -> output
var weights_out = 	[
						randf_range(-1.0, 1.0),
						randf_range(-1.0, 1.0)
					]
var biases_out =	randf_range(-1.0, 1.0)



func sigmoid(x) -> float:
	"""
	Returns the sigmoid-value of the given float.
	Resulting value is between 0.0 and 1.0
	Also called "Squashing function", as it "squashes" all huge (negative
	or positive) inputs to (almost) 0 or 1.
	"""
	return 1 / (1+exp(-x))


func sigmoid_deriv(x) -> float:
	"""
	Returns the derivative (dt. Ableitung) of sigmoid on the given float.
	Resulting value is between 0.0 and 0.25
	"""
	return sigmoid(x) * (1-sigmoid(x))






func _physics_process(delta: float) -> void:
	send_direction.emit(v)
