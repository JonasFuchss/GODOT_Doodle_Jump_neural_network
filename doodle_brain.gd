extends Area2D

# --- doodles neuronen ---
# Inputneuronen: eigene Position, Position der nächsten Plattform
# Outputneuronen: left_force, right_force

# in jedem Frame errechnet doodle den left_force/right_force, welcher besagt,
# mit welcher force doodle sich nach rechts- oder links bewegt.

# GLOBAL VARS
var left_force = 0.0
var right_force = 0.0



func _process(delta: float) -> void:
	left = 0.4

func _physics_process(delta: float) -> void:
