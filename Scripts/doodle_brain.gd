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
var highestJump: float = 999.0
var label: Label
var camera: Camera2D

signal new_highest_jump(height_y)


func _ready() -> void:
	label = $Label
	camera = get_parent().get_node("Camera2D")


func _physics_process(delta:float)->void:
	
	if is_on_floor():
		vel.y = -jumpImpulse
	else:
		vel.y += gravityImpulse * delta
		
	if highestJump > position.y:
		highestJump = position.y
		label.set_text(str(roundf(highestJump)))
		new_highest_jump.emit(highestJump)
		
	
	# DEBUG STEUERUNG MIT ARROWKEYS
	if Input.is_action_pressed("ui_left"):
		dir = -1.0
	if Input.is_action_pressed("ui_right"):
		dir = 1.0
	
	vel.x = dir * spd
	set_velocity(vel)
	set_up_direction(Vector2.UP)
	move_and_slide()
	dir = 0.0


func _on_nn_controller_send_direction(direction: float) -> void:
	dir = direction
