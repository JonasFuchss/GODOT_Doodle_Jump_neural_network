extends Node2D


#func _on_nn_controller_create_doodle(Doodle: PackedScene) -> void:
	#var spawned_doodle: CharacterBody2D = Doodle.instantiate()
	#add_child(spawned_doodle)
	#print("... spawned doodle")

var gen_count = 3
var pop_count = 10

signal create_doodle(doodle)

var Doodle = preload("res://Scenes/doodle.tscn")

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# create first generation & let it run
			for p in pop_count:
				print("emitting signal...")
				create_doodle.emit(Doodle)


@onready var width := get_viewport_rect().size.x
@onready var height := get_viewport_rect().size.y

var platform = preload("res://Scenes/Platform.tscn")

var platformCount:=5
@onready var player:= $doodle
@onready var platformParent:= $Platforms
var platforms:=[]
@onready var treshold=height*0.5
var scrollSpeed=0.05
@onready var background:Sprite2D= $"Parallax2D/Sprite2D"

func _ready()-> void:
	player.global_position.y=treshold
	for i in platformCount:
		var inst:= platform.instantiate()
		inst.global_position.y=height/platformCount*i
		inst.global_position.x=rand_x()
		platformParent.add_child(inst)
		platforms.append(inst)
	player.global_position.x=rand_x()
	platforms.back().global_position.x=player.global_position.x
	
func rand_x()->float:
	return randf_range(28.0, width-28.0)
	
func _physics_process(delta:float)-> void:
	if player.global_position.y <treshold:
		var move:float =lerp(0.0, treshold-player.global_position.y, scrollSpeed)
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
