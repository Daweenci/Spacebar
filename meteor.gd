extends Area2D

var speed = 300

func _ready():
	add_to_group("obstacle")

func _process(delta):
	position.y += speed * delta

	if position.y > 800:
		queue_free()
