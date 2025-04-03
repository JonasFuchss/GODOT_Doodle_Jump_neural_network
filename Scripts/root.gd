extends Node2D


var platform = preload("res://Scenes/Platform.tscn")
var platformCount = 5
var platforms = []
var scrollSpeed = 0.05

@onready var width := get_viewport_rect().size.x
@onready var height := get_viewport_rect().size.y
@onready var player: CharacterBody2D= $doodle
@onready var trainer: Node = $nn_trainer
@onready var platformParent: Node2D= $Platforms
@onready var threshold = height * 0.5
@onready var background: Sprite2D= $"Parallax2D/Sprite2D"


signal level_built(x_spawn, y_spawn)

func _ready()-> void:
	var x_player_pos = rand_x()
	var y_player_pos = threshold
	
	player.global_position.y = y_player_pos
	for i in platformCount:
		var inst = platform.instantiate()
		inst.global_position.y=height/platformCount*i
		inst.global_position.x=rand_x()
		platformParent.add_child(inst)
		platforms.append(inst)
	# Die unterste Plattform muss unter dem Spieler sein
	platforms.back().global_position.x = x_player_pos
	
	level_built.emit(x_player_pos, y_player_pos)
	
func rand_x()->float:
	return randf_range(28.0, width-28.0)
	
func _physics_process(delta:float)-> void:
	if player.global_position.y < threshold:
		var move: float = lerp(0.0, threshold - player.global_position.y, scrollSpeed)
		move_background(move)
		player.global_position.y+=move
		for plat in platforms:
			plat.global_position.y +=move
			if plat.global_position.y>height:
				plat.global_position.y -=height
				plat.global_position.x=rand_x()
				
	if player.global_position.y > height:
		game_over()

func move_background(move:float)-> void:
	var ratio :=0.75
	background.global_position.y=fmod((background.global_position.y+height+move*ratio), height)-height

func game_over()-> void:
	get_tree().reload_current_scene()

func _on_nn_trainer_create_doodle(Doodle: PackedScene, x: float, y: float) -> void:
	var doodle: CharacterBody2D = Doodle.instantiate()
	trainer.add_child(doodle)
	doodle.translate(Vector2(x, y))
