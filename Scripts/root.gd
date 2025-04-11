extends Node2D


var platform = preload("res://Scenes/Platform.tscn")
var platformCount = 5
var platforms = []
var scrollSpeed = 0.05
var camera: Camera2D

@onready var width := get_viewport_rect().size.x
@onready var height := get_viewport_rect().size.y
@onready var trainer: Node = $nn_trainer
@onready var platformParent: Node2D= $Platforms
@onready var threshold: float = 0.0
@onready var platformGap: float = height / (platformCount)
@onready var background: Sprite2D= $"Parallax2D/Sprite2D"

signal level_built(x_spawn, y_spawn)
signal set_weights_and_biases(values: Array, first_gen: bool)

func _ready()-> void:
	camera = $Camera2D
	
	var x_player_pos = rand_x()
	var y_player_pos = threshold
	
	for i in platformCount:
		createPlatform(rand_x(), -(platformGap * (i-1)))
		
	# Die unterste Plattform muss unter dem Spieler sein
	platforms.front().global_position.x = x_player_pos
	
	level_built.emit(x_player_pos, y_player_pos)
	
func rand_x()->float:
	return randf_range(28.0, width-28.0)


func createPlatform(x, y) -> void:
	var inst: CharacterBody2D = platform.instantiate()
	inst.global_position.y = y
	inst.global_position.x = x
	platformParent.add_child(inst)
	inst.connect("out_of_bounds", _on_platform_out_of_bounds)
	platforms.append(inst)


func move_background(move:float)-> void:
	var ratio: float = 0.75
	background.global_position.y=fmod((background.global_position.y+height+move*ratio), height)-height


func game_over()-> void:
	get_tree().reload_current_scene()


func _on_nn_trainer_create_doodle(Doodle: PackedScene, x: float, y: float, values: Array, first_gen: bool):
	var doodle: CharacterBody2D = Doodle.instantiate()
	trainer.add_child(doodle)
	doodle.translate(Vector2(x, y))
	doodle.add_to_group("doodles")
	doodle.connect("new_highest_jump", _on_doodle_highest_jump)
	
	# Verbinde auch das Death-Signal des Doodles mit dem Trainer:
	doodle.connect("death_by_falling", get_node("nn_trainer")._on_doodle_death_by_falling)
	
	# Verbindung der SETTER-Funktion für den individuellen Controller
	self.connect("set_weights_and_biases", doodle.get_node("nn_controller")._on_set_weights_and_biases)
	set_weights_and_biases.emit(values, first_gen)
	
	camera.position.y = doodle.position.y - 30


func _on_doodle_highest_jump(height_y):
	if camera.position.y > height_y:
		camera.position.y = height_y


func _on_platform_out_of_bounds(emitting_platform: CharacterBody2D):
	platforms.pop_front()
	emitting_platform.queue_free()
	print("platform out of bounds!")
	createPlatform(rand_x(), camera.position.y - get_viewport_rect().size.y / 2)


func _on_nn_trainer_need_new_level() -> void:
	# resette die Kamera auf 0,0
	camera.set_position(Vector2(width/2,0))
	
	# lösche alle platformen
	for p in platforms:
		p.queue_free()
	platforms.clear()

	var x_player_pos = rand_x()
	var y_player_pos = threshold
	
	# erstelle neue Platformen
	for i in platformCount:
		createPlatform(rand_x(), -(platformGap * (i-1)))
		
	# Die unterste Plattform muss unter dem Spieler sein
	platforms.front().global_position.x = x_player_pos
	
	level_built.emit(x_player_pos, y_player_pos)
