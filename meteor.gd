extends Area2D

@onready var sprite = $Sprite2D

var speed = 300
var rotation_speed = randf_range(-5.0, 5.0)

var meteor_textures = [
	preload("res://Sprites/Asteroid1.png"),
	preload("res://Sprites/Asteroid2.png"),
	preload("res://Sprites/Asteroid3.png"),
	preload("res://Sprites/Asteroid4.png")
]

func _ready():
	add_to_group("obstacle")
	rotation = randf_range(0, TAU)

	sprite.texture = meteor_textures[randi() % meteor_textures.size()]
	sprite.scale = Vector2(2, 2)

func _process(delta):
	position.y += speed * delta
	rotation += rotation_speed * delta

	if position.y > 800:
		queue_free()
