extends Area2D

var speed = 300
var rotation_speed = randf_range(-5.0, 5.0)

func _ready():
	add_to_group("obstacle")
	rotation = randf_range(0, TAU)

func _process(delta):
	position.y += speed * delta
	rotation += rotation_speed * delta

	if position.y > 800:
		queue_free()
