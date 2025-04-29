extends CharacterBody2D

signal out_of_bounds(platform)


func _process(delta: float) -> void:
	# Check, ob die Plattform sich unterhalb des Viewports befindet.
	var cam: Camera2D = get_parent().get_parent().get_node("Camera2D")
	var cutoff: float = cam.position.y + get_viewport_rect().size.y / 2
	if position.y > cutoff:
		out_of_bounds.emit(self)
