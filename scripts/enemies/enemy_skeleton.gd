extends CharacterBody2D

@onready var enemy_skeleton: CharacterBody2D = $"."

@onready var player
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var direction_timer: Timer = $"direction timer"

@onready var hitbox_shape: CollisionShape2D = $"hitbox/hitbox shape"
@onready var hitbox: Area2D = $hitbox
@onready var dirt: Sprite2D = $dirt
@onready var emerging_sound: AudioStreamPlayer2D = $"emerging sound"
@onready var collision_shape_2d: CollisionShape2D = $"first attack area/CollisionShape2D"

@export var SPEED: int = 30
var speed = SPEED
var chasing: bool = false
var is_facing_right = true

var health = 120
var max_health: float = 60
var min_health: float = 0
var taking_damage: bool = false
var dealing_damage: bool = false
var dead: bool = false
var attacking = false

var damage: float = 15

var dir: int = 1
var kb_force = 15
var roaming: bool = true 

var player_in_area = false
var flip_threshold = 50
var emerging = true
var has_started_emerging = false

func _process(delta: float) -> void:
	if emerging:
		if not has_started_emerging: 
			emerge()
		return
		
	if not player.alive:
		if chasing:
			chasing = false

	if not is_on_floor():
		velocity += get_gravity() * delta
		
	handle_animation()
	move()
	move_and_slide()
	
func emerge():
	enemy_skeleton.visible = true
	has_started_emerging = true
	dirt.visible = true
	animated_sprite_2d.play("emerge")
	emerging_sound.play()
	await get_tree().create_timer(1).timeout
	dirt.visible = false
	await get_tree().create_timer(0.5).timeout
	emerging = false
	chasing = true
	
func handle_animation():
	if emerging: return
	if !dead and !taking_damage and ! dealing_damage:
		if velocity.x < 0:
			animated_sprite_2d.play("walk")
			flip()
		elif velocity.x > 0:
			animated_sprite_2d.play("walk")
			flip()
		else:
			animated_sprite_2d.play("idle")
	elif !dead and taking_damage and !dealing_damage:
		animated_sprite_2d.play("hurt")
		await get_tree().create_timer(0.6).timeout
		taking_damage = false
	elif dead and roaming:
		roaming = false
		animated_sprite_2d.play("death")
		await get_tree().create_timer(3).timeout
		handle_death()

func flip():
	if (is_facing_right and velocity.x < 0) or (not is_facing_right and velocity.x > 0):
		scale.x *= -1
		is_facing_right = not is_facing_right

func move():
	if emerging: return
	if !dead:
		var to_player = position.direction_to(player.position)
		if !chasing:
			speed = SPEED
			velocity.x = dir * speed
		elif chasing and !taking_damage:
			speed = SPEED * 3
			var distance_to_player = position.distance_to(player.position)
			if distance_to_player > flip_threshold:
				velocity.x = to_player.x * speed
			else:
				velocity.x = 0
				if (is_facing_right and to_player.x < 0) or (not is_facing_right and to_player.x > 0):
					scale.x *= -1
					is_facing_right = not is_facing_right
				if not dealing_damage:
					first_attack()
		elif taking_damage:
			var kb_dir = to_player * kb_force * -1
			velocity.x = kb_dir.x
		roaming = true
	else:
		velocity.x = 0

func choose(array: Array):
	return array.pick_random()

func handle_death():
	self.queue_free()

func _on_direction_timer_timeout() -> void:
	direction_timer.wait_time = choose([1.5, 2, 2.5, 3])
	if not chasing:
		dir = choose([1, -1])
		velocity.x = 0


func _on_hitbox_area_entered(area: Area2D) -> void:
	if area == player.attacks_area:
		take_damage()
		
func take_damage():
	var player_damage = player.damage
	health -= player_damage
	taking_damage = true
	if health <= min_health:
		health = min_health
		dead = true

func first_attack():
	speed = SPEED * 0.5
	dealing_damage = true
	animated_sprite_2d.play("attack")
	await get_tree().create_timer(0.4).timeout
	collision_shape_2d.disabled = false
	await get_tree().create_timer(0.7).timeout
	collision_shape_2d.disabled = true
	speed = SPEED
	
func _on_first_attack_area_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_hitbox_area"):
		dealing_damage = true
		await get_tree().create_timer(0.7).timeout
		dealing_damage = false

func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite_2d.animation == "attack":
		await get_tree().create_timer(2).timeout
		dealing_damage = false

func _on_first_attack_area_body_entered(body: Node2D) -> void:
	if body == player:
		if body.die:
			chasing = false
