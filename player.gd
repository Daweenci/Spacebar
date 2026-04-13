extends CharacterBody2D

@onready var hp_label = get_node("/root/Node2D/UI/HP")
@onready var game_manager = get_node("/root/Node2D/GameManager")

@onready var sprite = $Sprite2D

var lane_count = 4
var lanes = []
var current_lane = 2
var target_x = 0

var switch_speed = 800

var health = 5
var is_invincible = false
var invincibility_time = 2

var is_blinking = false


func _ready():
	setup_lanes()
	target_x = lanes[current_lane]


func setup_lanes():
	var base_width = 1280 #projekt width
	var left_offset = 640 #verschiebung um die Hälfte
	var road_width = base_width * 0.5 - 128  #128 = 1280 * 0.1 weil die 5fte lane den Kunden gehört
	
	var lane_width = road_width / lane_count
	
	for i in range(lane_count):
		var x = left_offset + lane_width * (i + 0.5)
		lanes.append(x)
	

func _process(delta):
	if current_lane == lane_count - 1 and game_manager.state == game_manager.GameState.DELIVERY:
		game_manager.deliver()
	handle_input()
	position.x = move_toward(position.x, target_x, switch_speed * delta)


func handle_input():
	if Input.is_action_just_pressed("left"):
		current_lane = max(0, current_lane - 1)
		target_x = lanes[current_lane]
		
	if Input.is_action_just_pressed("right"):
		current_lane = min(lane_count - 1, current_lane + 1)
		target_x = lanes[current_lane]
	
	if current_lane == lane_count - 1 and game_manager.state == game_manager.GameState.CLIENT_WAITING:
		game_manager.accept_order()
		
		
func _physics_process(delta):
	move_and_slide()		

func take_damage():
	if is_invincible:
		return

	health -= 1
	print("Health:", health)
	update_hp_ui()

	if health <= 0:
		game_over()

	start_invincibility()

func start_invincibility():
	if is_invincible:
		return
		
	is_invincible = true
	
	if not is_blinking:
		blink()

	await get_tree().create_timer(invincibility_time).timeout
	
	is_invincible = false
	sprite.visible = true
		

func blink():
	is_blinking = true
	
	while is_invincible:
		sprite.visible = !sprite.visible
		await get_tree().create_timer(0.1).timeout
	
	sprite.visible = true
	is_blinking = false
		

func game_over():
	print("GAME OVER")
	get_tree().paused = true

func update_hp_ui():
	hp_label.text = "HP: " + str(health)

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("obstacle"):
		take_damage()
