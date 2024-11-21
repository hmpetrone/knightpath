extends CharacterBody2D

@export var SPEED: float = 150
@export var JUMP_VELOCITY: float
@onready var knight_animations: AnimatedSprite2D = $"knight animations"
@onready var idle_shape: CollisionShape2D = $"idle shape"
@onready var attacks: Area2D = $attacks
@onready var hitbox_cs: CollisionShape2D = $hitbox/CollisionShape2D
@onready var hitbox: Area2D = $hitbox

var prop: CollisionShape2D

var speed = SPEED

# Status
var is_facing_right = true
var is_crouching = false
var attacking = false
var alive = true
var taking_damage = false
var died: bool = false
var praying: bool = false
var falling: bool = false
var rolling: bool = false

#player stats
var damage = 15
var health = 200
var max_health: float = 200
var min_health: float = 0

# collition shapes animations
var standing_cshape = preload("res://resources/knight/collision shapes/knight_standing.tres")
var crouch_cshape = preload("res://resources/knight/collision shapes/knight_crouching.tres")

# Extra shapes
@onready var attacks_area: Area2D = $attacks
@onready var attack_shape: CollisionShape2D = $"attacks/attack shape"
@onready var crouching_attack_shape: CollisionShape2D = $"attacks/crouching attack shape"

# SFX
@onready var sounds: Node2D = $sounds

func _physics_process(delta: float) -> void:
	if died: return
	move_x()
	if praying:
		knight_animations.play("pray")
		return
	jump(delta)
	flip()
	crouch()
	first_attack()
	roll()
	update_animations()
	move_and_slide()
	
func update_animations():
	#print(attacking)
	if not died:
		if velocity.x and not attacking and not taking_damage and not falling and not rolling:
			if is_crouching:
				knight_animations.play("crouch")
			else:
				knight_animations.play("run")
		elif not attacking and not taking_damage and not falling and not rolling:
			if is_crouching:
				knight_animations.play("crouch_stay")
			elif not attacking:
				knight_animations.play("idle")
		if not is_on_floor() and not attacking and not taking_damage and not rolling:
			if velocity.y < 0:
				knight_animations.play("jump")
			elif falling:
				knight_animations.play("fall")
		elif is_on_floor():
			falling = false

	if knight_animations.animation != "hurt":
		taking_damage = false
	if knight_animations.animation != "roll":
		rolling = false
		
		

func move_x():
	if died:
		velocity.x = 0
		return
		
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		praying = false
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed*0.1)

func flip():
	if (is_facing_right and velocity.x < 0) or (not is_facing_right and velocity.x > 0) and not died and not attacking:
		scale.x *= -1
		is_facing_right = not is_facing_right

func jump(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta
	if Input.is_action_just_pressed("jump") and is_on_floor() and not rolling:
		velocity.y = JUMP_VELOCITY
	if velocity.y > 0:
		falling= true
		
func crouch():
	if Input.is_action_just_pressed("down") and not rolling:
		is_crouching = true
		idle_shape.position.y = -12
		hitbox_cs.position.y = -12
		idle_shape.shape = crouch_cshape
		hitbox_cs.shape = crouch_cshape
		set_movement_speed('crouching')

	if Input.is_action_just_released("down"):
		is_crouching = false
		idle_shape.position.y = -18
		hitbox_cs.position.y = -18
		idle_shape.shape = standing_cshape
		hitbox_cs.shape = standing_cshape
		set_movement_speed('default')

func set_movement_speed(state: String):
	match state:
		"default":
			speed = SPEED
		"crouching":
			speed = SPEED * 0.3
		"rolling":
			speed = SPEED * 2

func first_attack():
	if Input.is_action_just_pressed("first_attack") and not rolling:
		attacking = true
		speed = speed * 0.2
		if is_crouching:
			prop = crouching_attack_shape
			knight_animations.play("crouching_first_attack")
		else:
			prop = attack_shape
			knight_animations.play("first_attack")
		prop.disabled = false

func roll():
	if Input.is_action_just_pressed("roll") and velocity.x != 0 and is_on_floor() and not attacking:
		rolling = true
		idle_shape.position.y = -12
		hitbox_cs.position.y = -12
		idle_shape.shape = crouch_cshape
		hitbox_cs.shape = crouch_cshape
		knight_animations.play("roll")
		set_movement_speed('rolling')
		
func death():
	health = min_health
	died = true;
	knight_animations.play("death")
	Engine.time_scale = 0.5
	

func take_damage(damage_received):
	health -= damage_received
	if health <= min_health:
		death()
	else:
		rolling = false
		idle_shape.position.y = -18
		hitbox_cs.position.y = -18
		idle_shape.shape = standing_cshape
		hitbox_cs.shape = standing_cshape
		set_movement_speed('default')
		taking_damage = true
		knight_animations.play("hurt")
		sounds.get_child(randi_range(0,2)).play()
		await get_tree().create_timer(0.2).timeout

func _on_hitbox_area_entered(area: Area2D) -> void:
	if not died: take_damage(area.damage)

func _on_knight_animations_animation_finished() -> void:
	if knight_animations.animation == "first_attack" or knight_animations.animation == "crouching_first_attack":
		attacking = false
		crouching_attack_shape.disabled = true
		attack_shape.disabled = true
		speed = SPEED
	if knight_animations.animation == "hurt":
		taking_damage = false
	if knight_animations.animation == "fall":
		knight_animations.frame = 1
	if knight_animations.animation == "roll":
		rolling = false
		idle_shape.position.y = -18
		hitbox_cs.position.y = -18
		idle_shape.shape = standing_cshape
		hitbox_cs.shape = standing_cshape
		set_movement_speed('default')
