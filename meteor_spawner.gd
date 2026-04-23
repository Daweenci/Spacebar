extends Node2D

@export var meteor_scene: PackedScene

var lane_count = 4
var lanes = []

var last_lane_index := -1

func _ready():
	randomize()
	setup_lanes()

func setup_lanes():
	var base_width = 1280
	var left_offset = 640 + 128
	var road_width = base_width * 0.5 - 128 - 128
	
	var lane_width = road_width / lane_count
	
	for i in range(lane_count):
		var x = left_offset + lane_width * (i + 0.5)
		lanes.append(x)

func spawn_meteor():
	var meteor = meteor_scene.instantiate()
	
	var lane_index = randi() % lane_count
	
	while lane_index == last_lane_index and lane_count > 1:
		lane_index = randi() % lane_count
	
	last_lane_index = lane_index
	
	meteor.position = Vector2(lanes[lane_index], -50)
	add_child(meteor)

var meteor_unlocked = false
var meteor_delay_done = false

func _on_meteor_timer_timeout():
	if not meteor_unlocked and Global.score >= 5:
		meteor_unlocked = true
		_start_meteor_delay()
		return
	
	if meteor_delay_done:
		spawn_meteor()

func _start_meteor_delay():
	await get_tree().create_timer(6.0, false).timeout
	meteor_delay_done = true
