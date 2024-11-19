extends Node2D

@onready var knight: CharacterBody2D = %knight
@onready var camera: Camera2D = $knight/camera
@onready var skeleton_spawn: Marker2D = $"skeleton spawn"
@onready var surprise_area: Area2D = $surprise_area

var enemy_skeleton = load("res://scenes/enemies/enemy_skeleton.tscn")
var skeleton
var skeletons: Array = []

var wave_count: int = 2
var wave_active: bool = false
# Called when the node enters the scene tree for the first time.

func _ready() -> void:
	knight.praying = true
	
func _process(delta: float) -> void:
	if wave_active:
		skeletons = skeletons.filter(func(s): return s != null)
		if skeletons.size() == 0:
			wave_count -= 1
			if wave_count > 0:
				spawn_wave()
			else:
				wave_active = false


func _on_surprise_area_body_entered(body: Node2D) -> void:
	if body == knight:
		wave_active = true
		call_deferred("spawn_wave")
		surprise_area.queue_free()

func spawn_wave():
	var rng = RandomNumberGenerator.new()
	skeleton_spawn.position.y = -15
	#var array = [0.1, 0.2, 0.5]
	for i in range(1, 4):
		#await get_tree().create_timer(array.pick_random()).timeout
		skeleton_spawn.position.x = rng.randf_range(-30, 380)
		skeleton = enemy_skeleton.instantiate()
		skeleton.global_position = skeleton_spawn.global_position
		skeleton.player = knight
		skeleton.visible = false
		add_child(skeleton)
		skeletons.append(skeleton)
