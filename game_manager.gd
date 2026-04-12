extends Node

enum GameState {
	IDLE,
	CLIENT_WAITING,
	SHOW_RECIPE,
	MIXING,
	DELIVERY,
	RESULT
}

@onready var customer = get_node("/root/Node2D/Customer")
@onready var clock = get_node("/root/Node2D/UI/Clock")

var current_recipe = []
var player_input = []
var recipe_length = 3

var current_step = 0
var selecting = false

# config
var spawn_delay = 5.0
var cooldown_time = 5.0

var approach_time_max = 10.0
var mixing_time_max = 30.0

var enter_offset_y = 400
var exit_offset_y = -500

var enter_random_x = 120
var exit_random_x = 150

var tween_duration = 0.5

var customer_target_pos = Vector2(1200, 600)

var customer_start
var customer_exit

var state = GameState.IDLE

var approach_timer = 0.0
var approach_timer_running = false

var mixing_timer = 0.0
var mixing_timer_running = false


func _ready():
	await get_tree().create_timer(spawn_delay).timeout
	start_customer()


func _process(delta):
	if approach_timer_running:
		var progress = approach_timer / approach_time_max
		clock.value = progress * 100.0
	elif mixing_timer_running:
		var progress = mixing_timer / mixing_time_max
		clock.value = progress * 100.0
		
	if state == GameState.CLIENT_WAITING and approach_timer_running:
		approach_timer -= delta
		if approach_timer <= 0:
			fail_customer()

	if (state == GameState.SHOW_RECIPE or state == GameState.MIXING) and mixing_timer_running:
		mixing_timer -= delta
		if mixing_timer <= 0:
			fail_customer()


func start_customer():
	state = GameState.CLIENT_WAITING

	var random_x = randf_range(-enter_random_x, enter_random_x)
	customer_start = customer_target_pos + Vector2(random_x, enter_offset_y)

	customer.position = customer_start
	customer.visible = true

	await get_tree().process_frame

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(customer, "position", customer_target_pos, tween_duration)

	approach_timer = approach_time_max
	approach_timer_running = true
	show_clock()


func send_customer_away():
	var tween = create_tween()

	var random_x = randf_range(-exit_random_x, exit_random_x)
	customer_exit = customer_target_pos + Vector2(random_x, exit_offset_y)

	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(customer, "position", customer_exit, tween_duration)

	tween.finished.connect(func():
		customer.visible = false
	)


func fail_customer():
	approach_timer_running = false
	mixing_timer_running = false

	give_stars(1)

	send_customer_away()
	state = GameState.IDLE

	hide_clock()
	await get_tree().create_timer(cooldown_time).timeout
	start_customer()


func give_stars(amount):
	print(amount)


func accept_order():
	if state != GameState.CLIENT_WAITING:
		return

	approach_timer_running = false

	mixing_timer = mixing_time_max
	mixing_timer_running = true

	state = GameState.SHOW_RECIPE


func start_mixing():
	if state != GameState.SHOW_RECIPE:
		return

	state = GameState.MIXING


func deliver():
	if state != GameState.MIXING:
		return

	mixing_timer_running = false

	send_customer_away()
	state = GameState.RESULT
	
	hide_clock()
	await get_tree().create_timer(cooldown_time).timeout
	start_customer()
	
func show_clock():
	clock.visible = true
	clock.scale = Vector2.ZERO

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(clock, "scale", Vector2(1.2, 1.2), 0.2)
	tween.tween_property(clock, "scale", Vector2(1.0, 1.0), 0.1)

func hide_clock():
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_IN)

	tween.tween_property(clock, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(clock, "scale", Vector2.ZERO, 0.2)

	tween.finished.connect(func():
		clock.visible = false
	)
