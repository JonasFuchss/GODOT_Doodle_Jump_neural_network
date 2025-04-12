extends Node2D

var platforms = null
var cam: Camera2D = null
var died = false

signal send_direction(direction)
signal send_seed(weights_in, biases_in, weights_out, biases_out)


func _ready() -> void:
	platforms = get_node("/root/root/Platforms")
	cam = get_node("/root/root/Camera2D")


func get_vector_to_next_platform() -> Vector2:
	var to_next: Vector2
	var stack: Array = platforms.get_children()
	
	# zweites Element ist immer die Platform, auf die der Doodle springen muss
	to_next = stack[1].global_position - self.global_position
	return to_next


## vector as given by the nn. shall be between -1.0 and 1.0
## Determines how much the nn "pushes" the joystick to left or right,
## to control the doodle left/right-movement.
var v: float = 0.0

## number of input-layers (x_diff & y_diff), output-layers (v) and hidden-
## layers with neurons for calculations via tanh.
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


func tanh(x) -> float:
	"""
	Returns the tanh-value of the given float.
	Resulting value is between -1.0 and 1.0
	Also called "Squashing function", as it "squashes" all huge (negative
	or positive) inputs to (almost) -1 or 1.
	"""
	return (exp(x) - exp(-x)) / (exp(x) + exp(-x))


func tanh_deriv(x) -> float:
	"""
	Returns the derivative (dt. Ableitung) of tanh on the given float.
	Resulting value is between 0.0 and 0.25
	"""
	return 1 - (x ** 2)


func decide_v(vector_to_next_platform: Vector2) -> float:
	var distance_x = vector_to_next_platform.x
	var distance_y = vector_to_next_platform.y
	
	# Hidden neuron 0:
	var hidden_input_0 = (distance_x * weights_in[0][0]) + (distance_y * weights_in[1][0]) + biases_in[0]
	
	# Hidden neuron 1:
	var hidden_input_1 = (distance_x * weights_in[0][1]) + (distance_y * weights_in[1][1]) + biases_in[1]
	
	# convert to 0-1 range:
	var hidden_output_0 = tanh(hidden_input_0)
	var hidden_output_1 = tanh(hidden_input_1)
	
	# output neuron:
	var output_neuron_in = (hidden_output_0 * weights_out[0]) + (hidden_output_1 * weights_out[1]) + biases_out
	var output_neuron_out = tanh(output_neuron_in)
	
	return output_neuron_out


func _on_set_weights_and_biases(values, first_gen) -> void:
	var seed_variation = 0.3
	
	# Lasse die neuen Weights & Biases von dem vorherigen besten etwas abweichen,
	# wenn es bereits eine Generation gab (Faktor 0.75).
	if not first_gen:
		values = [
			[
				[randf_range(
					-values[0][0][0] * (1 - seed_variation),
					 values[0][0][0] * (1 + seed_variation)
				),
				randf_range(
					-values[0][0][1] * (1 - seed_variation),
					 values[0][0][1] * (1 + seed_variation)
				)],
				[randf_range(
					-values[0][1][0] * (1 - seed_variation),
					 values[0][0][0] * (1 + seed_variation)
				),
				randf_range(
					-values[0][1][1] * (1 - seed_variation),
					 values[0][1][1] * (1 + seed_variation)
				)]
			],
			[
				randf_range(
					-values[1][0] * (1 - seed_variation),
					 values[1][0] * (1 + seed_variation)
				),
				randf_range(
					-values[1][1] * (1 - seed_variation),
					 values[1][1] * (1 + seed_variation)
				)
			],
			[
				randf_range(
					-values[2][0] * (1 - seed_variation),
					 values[2][0] * (1 + seed_variation)
				),
				randf_range(
					-values[2][1] * (1 - seed_variation),
					 values[2][1] * (1 + seed_variation)
				)
			],
			randf_range(
					-values[3] * (1 - seed_variation),
					 values[3] * (1 + seed_variation)
			)
		]
	else:
		# Ist dies die erste Generation, verwende komplett zufällige Werte.
		values = [
			[
				[randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)],
				[randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)]
			],
			[
				randf_range(-1.0, 1.0),
				randf_range(-1.0, 1.0)
			],
			[
				randf_range(-1.0, 1.0),
				randf_range(-1.0, 1.0)
			],
			randf_range(-1.0, 1.0)
		]
	
	weights_in	= values[0]
	biases_in 	= values[1]
	weights_out = values[2]
	biases_out 	= values[3]


func _process(delta: float) -> void:
	v = decide_v(get_vector_to_next_platform())
	send_direction.emit(v)
	
	# Check, ob der Doodle sich unterhalb des Viewports befindet.
	var cutoff: float = cam.position.y + get_viewport_rect().size.y / 2
	if get_parent().position.y > cutoff and not died:
		send_seed.emit(weights_in, biases_in, weights_out, biases_out)
		died = true
