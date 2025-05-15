extends Control

var origin: Control
var target: Control
var arrow_color: Color = Color.RED
var arrow_thickness: float = 3.0
var arrow_head_size: float = 15.0


func set_draw_params(_origin: Control, _target: Control, _weight: float):
	origin = _origin
	target = _target
	if _weight > 0.1:
		arrow_thickness = arrow_thickness * _weight
		arrow_head_size = arrow_head_size * _weight
	elif -0.1 < _weight and _weight <= 0.1:
		## Damit die Arrows bei zu geringem Gewicht nicht "unsichtbar" werden, wird
		## bei einem weight von -0.1 -> 0.1 eine Standarddicke genommen
		arrow_thickness = 0.4
		arrow_head_size = 4.0
		if _weight < 0.0:
			## Negative Weights haben eine Blaue Farbe
			arrow_color = Color.BLUE
	else:
		arrow_color = Color.BLUE
		arrow_thickness = arrow_thickness * abs(_weight)
		arrow_head_size = arrow_head_size * abs(_weight)

func _draw():
	if not origin or not target:
		return

	# Rechte Mitte von origin
	var from_rect = origin.get_global_rect()
	var from_pos: Vector2
	if from_rect.size.x > from_rect.size.y:
		from_pos = Vector2(from_rect.position.x + from_rect.size.x / 2 + from_rect.size.y / 2, from_rect.position.y + from_rect.size.y / 2)
	elif from_rect.size.x < from_rect.size.y:
		from_pos = Vector2(from_rect.position.x + from_rect.size.x, from_rect.position.y + from_rect.size.y / 2)
	else:
		from_pos = Vector2(from_rect.position.x + from_rect.size.x, from_rect.position.y + from_rect.size.y / 2)


	# Linke Mitte von target
	var to_rect = target.get_global_rect()
	var to_pos: Vector2
	if to_rect.size.x > to_rect.size.y:
		to_pos = Vector2(to_rect.position.x + to_rect.size.x / 2 - to_rect.size.y / 2, to_rect.position.y + to_rect.size.y / 2)
	elif to_rect.size.x < to_rect.size.y:
		to_pos = Vector2(to_rect.position.x, to_rect.position.y + to_rect.size.y / 2)
	else:
		to_pos = Vector2(to_rect.position.x, to_rect.position.y + to_rect.size.y / 2)
	
	# Zeichne Linie
	draw_line(from_pos, to_pos, arrow_color, arrow_thickness, true)

	# Zeichne Pfeilspitze
	var dir = (to_pos - from_pos).normalized()
	var ortho = Vector2(-dir.y, dir.x) * 0.5
	var p1 = to_pos
	var p2 = to_pos - dir * arrow_head_size + ortho * arrow_head_size
	var p3 = to_pos - dir * arrow_head_size - ortho * arrow_head_size

	draw_polygon([p1, p2, p3], [arrow_color])
