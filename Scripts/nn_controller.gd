extends Node2D

var platforms = null
var cam: Camera2D = null
var died = false
# Doodles Nummer. Gebraucht, damit set_gene nicht die Gene aller controller überschreibt
var number: int

# damit das Modell nach einem Sprung sofort die nächste Platform anvisiert, muss
# die vorherige geblacklisted werden.
var forbidden_platform: Object

# direction as given by the nn. shall be between -1.0 and 1.0
# Determines how much the nn "pushes" the joystick to left or right,
# to control the doodle left/right-movement.
var dir: float = 0.0

var genome: Genome

signal send_direction(direction: float)
signal send_genome(genome: Genome)


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
	
	return self.genome.feed_forward({0: distance_x, 1: distance_y})[0]



func _process(delta: float) -> void:
	dir = decide_dir(get_vector_to_next_platform())
	send_direction.emit(dir)
	
	# Check, ob der Doodle sich unterhalb des Viewports befindet.
	var cutoff: float = cam.position.y + get_viewport_rect().size.y / 2
	if get_parent().position.y > cutoff and not died:
		send_genome.emit(genome)
		died = true


func _on_doodle_touched_platform(platform: Object) -> void:
	forbidden_platform = platform
