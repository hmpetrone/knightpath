extends Area2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
var opened = false

func _on_area_entered(area: Area2D) -> void:
	if not opened:
		animated_sprite_2d.play("open")
		opened = true
