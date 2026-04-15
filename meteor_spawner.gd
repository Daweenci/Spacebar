extends Node2D

@export var meteor_scene: PackedScene

var lane_count = 4
var lanes = []

func _ready():
	setup_lanes()

func setup_lanes():
	var base_width = 1280
	var left_offset = 640 + 128
	var road_width = base_width * 0.5 - 128 -128
	
	var lane_width = road_width / lane_count
	
	for i in range(lane_count):
		var x = left_offset + lane_width * (i + 0.5)
		lanes.append(x)

func spawn_meteor():
	var meteor = meteor_scene.instantiate()
	
	var lane_index = randi() % lane_count
	meteor.position = Vector2(lanes[lane_index], -50)
	add_child(meteor)

func _on_meteor_timer_timeout():
	spawn_meteor()
