extends Node2D

var platforms = null
var cam: Camera2D = null
var died = false

# damit das Modell nach einem Sprung sofort die nächste Platform anvisiert, muss
# die vorherige geblacklisted werden.
var forbidden_platform: Object

# direction as given by the nn. shall be between -1.0 and 1.0
# Determines how much the nn "pushes" the joystick to left or right,
# to control the doodle left/right-movement.
var dir: float = 0.0

var nodes: Array		## Liste mit allen Genome-Nodes (Neuronen) dieses Genoms
var connections: Array	## Liste mit allen Genome-Connections zwischen den obengenannten Neuronen

## Helfer-Klasse zur Abbildung von Nodes
class Genome_Node:
	var type: String	# Typ der Node. Darf nur 'input', 'hidden' oder 'output' sein.
	var number: int		# Nummer der Node. In einem Genom einzigartig.
	var bias: float		# Bias der Node.
	
	func _init(_type: String, _number: int, _bias: float):
		type = _type
		number = _number
		bias = _bias

	func set_bias(new_bias: float) -> void:
		bias = new_bias
	
	func get_bias() -> float:
		return bias
	
	func set_type(new_type: String) -> void:
		type = new_type
	
	func get_type() -> String:
		return type
	
	func set_number(new_number: int) -> void:
		number = new_number
	
	func get_number() -> int:
		return number

## Helfer-Klasse zur Abbildung von Connections
class Genome_Connection:
	var origin: int		# Nummer der Ausgangs-Node
	var target: int		# Nummer der Ziel-Node
	var weight: float	# Gewicht der Verbindung. Geht von 0.0 (ausgeschaltet) bis 1.0

	func _init(_origin: int, _target: int, _weight: float):
		origin = _origin
		target = _target
		weight = _weight
	
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

signal send_direction(direction)
signal send_genome(nodes, connections)


func _ready() -> void:
	platforms = get_node("/root/root/Platforms")
	cam = get_node("/root/root/Camera2D")


func get_vector_to_next_platform() -> Vector2:
	var to_next: Vector2
	var stack: Array = platforms.get_children()
	
	if stack[1] != forbidden_platform:
		# zweites Element ist immer die Platform, auf die der Doodle springen muss,
		# wenn die erste PLatform nicht mehr existiert (also wenn der Doodle
		# im Apex seinen Sprungs ist und die erste Platform out of bounds geht
		to_next = stack[1].global_position - self.global_position
	else:
		to_next = stack[2].global_position - self.global_position
	return to_next


func tanh(x) -> float:
	"""
	Gibt den tanh-Wert der gegebenen Float-Zahl zurück.
	Der resultierende Wert liegt zwischen -1.0 und 1.0
	Auch als "Squashing-Funktion" bezeichnet, da sie alle sehr großen (negativen
	oder positiven) Eingaben auf (fast) -1 oder 1 "zusammendrückt".
	"""
	return (exp(x) - exp(-x)) / (exp(x) + exp(-x))


func decide_dir(vector_to_next_platform: Vector2) -> float:
	"""
	Entscheidet, in welche Richtung das neuronale Netz den Doodle
	als nächstes steuern wird. Dies geschieht anhand der übergebenen x-
	und y-Werte der nächsten Platform, und den vorher festgelegten weights
	und biases der Hidden- / Output-Layers.
	Die Ausgabe ist ein Float zwischen -1 und +1;
	-1 = voll nach links, 
	+1 = voll nach rechts,
	 0 = keine Richtungssteuerung des Netzes.
	"""
	
	var distance_x = vector_to_next_platform.x
	var distance_y = vector_to_next_platform.y
	
	return output_neuron_out


func _on_root_set_weights_and_biases(nodes, connections) -> void:
	self.nodes = nodes
	self.connections = connections


func _process(delta: float) -> void:
	dir = decide_dir(get_vector_to_next_platform())
	send_direction.emit(dir)
	
	# Check, ob der Doodle sich unterhalb des Viewports befindet.
	var cutoff: float = cam.position.y + get_viewport_rect().size.y / 2
	if get_parent().position.y > cutoff and not died:
		send_genome.emit(nodes, connections)
		died = true


func _on_doodle_touched_platform(platform: Object) -> void:
	forbidden_platform = platform
