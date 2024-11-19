extends Area2D
@onready var campfire: AnimatedSprite2D = $AnimatedSprite2D


func _on_body_entered(body: Node2D) -> void:
	print('Player entered');
	campfire.play("picked")
