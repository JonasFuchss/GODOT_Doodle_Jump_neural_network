extends CharacterBody2D

# --- doodles neuronen ---
# Inputneuronen: eigene Position, Position der nächsten Plattform
# Outputneuronen: left_force, right_force

# in jedem Frame errechnet doodle den left_force/right_force, welcher besagt,
# mit welcher force doodle sich nach rechts- oder links bewegt.

@export var jumpImpulse= 6.5 * 60
@export var gravityImpulse = 8.0 * 60
@export var spd = 3.0 * 60
var dir: float = 0.0
var vel = Vector2.ZERO
var highestJump: float = INF
var label: Label
var camera: Camera2D

signal new_highest_jump(height_y)
signal death_by_falling(weights_in: Array, biases_in: Array, weights_out: Array, biases_out: float, score: float)
signal touched_platform(platform: Object)


func _ready() -> void:
	print("doodle brain ready")
	label = $Label
	camera = get_parent().get_node("/root/root/Camera2D")


func _physics_process(delta:float)->void:
	
	# Wenn der Doodle eine Platform berührt, springe automatisch
	if is_on_floor():
		vel.y = -jumpImpulse
		var collisionObjId = get_last_slide_collision().get_collider_id()
		var platform_instance = instance_from_id(collisionObjId)
		touched_platform.emit(platform_instance)
	else:
		vel.y += gravityImpulse * delta
	
	if highestJump > position.y:
		highestJump = position.y
		label.set_text(str(abs(roundf(highestJump))))
		new_highest_jump.emit(highestJump)
	
	# Wenn der Doodle out of bounds geht, tp auf die andere Seite
	if position.x < 0:
		position.x = get_viewport_rect().size.x
	if position.x > get_viewport_rect().size.x:
		position.x = 0
	
	# DEBUG STEUERUNG MIT ARROWKEYS
	if Input.is_action_pressed("ui_left"):
		dir = -1.0
	if Input.is_action_pressed("ui_right"):
		dir = 1.0
	
	vel.x = dir * spd
	set_velocity(vel)
	set_up_direction(Vector2.UP)
	move_and_slide()
	
	# flip den doodle-sprite, wenn direction negativ (nach links) ist
	if dir < 0.0:
		$Sprite2D.set_flip_h(true)
	elif dir > 0.0:
		$Sprite2D.set_flip_h(false)
	
	dir = 0.0


func _on_nn_controller_send_direction(direction: float) -> void:
	dir = direction


func _on_nn_controller_send_genome(genome: Gene_Stuff.Genome) -> void:
	# wenn der controller seine Daten sendet, bedeutet das, dass der Doodle
	# aus der Map gefallen ("gestorben") ist. Also Daten und Highscore an den
	# Trainer weitergeben und Doodle-Instanz für's löschen queuen.
	death_by_falling.emit(genome, highestJump)
	queue_free()
