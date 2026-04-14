extends Node

enum GameState {
	IDLE,
	CLIENT_WAITING,
	SHOW_RECIPE,
	MIXING,
	DELIVERY,
	RESULT
}

var ingredient_textures = {
	"space_fruit_1": preload("res://Sprites/SpaceFruit1.png"),
	"space_fruit_2": preload("res://Sprites/SpaceFruit2.png"),
	"space_fruit_3": preload("res://Sprites/SpaceFruit3.png"),
	"space_fruit_4": preload("res://Sprites/SpaceFruit4.png"),
	"space_fruit_5": preload("res://Sprites/SpaceFruit5.png"),
	"space_fruit_6": preload("res://Sprites/SpaceFruit6.png"),
	"space_fruit_7": preload("res://Sprites/SpaceFruit7.png")
}

@onready var customer = get_node("/root/Node2D/Customer")
@onready var clock = get_node("/root/Node2D/UI/Clock")
@onready var recipe_container = get_node("/root/Node2D/UI/RecipePanel/HFlowContainer")
@onready var recipe_panel = get_node("/root/Node2D/UI/RecipePanel")
@onready var ingredients_panel = get_node("/root/Node2D/UI/IngredientsContainer")

@onready var slot_w = get_node("/root/Node2D/UI/IngredientsContainer/CenterContainer/VBoxContainer/IngredientSlotW")
@onready var slot_a = get_node("/root/Node2D/UI/IngredientsContainer/CenterContainer/VBoxContainer/HBoxContainer/IngredientSlotA")
@onready var slot_s = get_node("/root/Node2D/UI/IngredientsContainer/CenterContainer/VBoxContainer/IngredientSlotS")
@onready var slot_d = get_node("/root/Node2D/UI/IngredientsContainer/CenterContainer/VBoxContainer/HBoxContainer/IngredientSlotD")
@onready var score_label = get_node("/root/Node2D/UI/ScoreLabel")
@onready var reputation_bar = get_node("/root/Node2D/UI/ReputationBar")

var slot_scene = preload("res://ingredient_slot.tscn")

var possible_ingredients = ["space_fruit_1", "space_fruit_2", "space_fruit_3", 
"space_fruit_4", "space_fruit_5", "space_fruit_6", "space_fruit_7"]

var fly_sound = "res://Sprites/fly.wav"
var fly_away_sound = "res://Sprites/fly_away.wav"
@onready var warning_player = AudioStreamPlayer.new()
var warning_playing = false
var warning_threshold = 5.0

var current_recipe = []
var player_input = []
var recipe_length_start = 3
var recipe_length = recipe_length_start

var current_step = 0 #beim Mixing
var current_choices = []
var selecting = false

# config
var spawn_delay = 5.0
var cooldown_time = 5.0

var approach_time_max = 6.0
var mixing_time_max = 20.0

var enter_offset_y = 400
var exit_offset_y = -1000

var enter_random_x = 120
var exit_random_x = 150

var tween_duration = 1 #wie lange der customer zum Ziel fliegt

var customer_target_pos = Vector2(1200, 600)

var customer_start
var customer_exit

var state = GameState.IDLE

var approach_timer = 0.0
var approach_timer_running = false

var mixing_timer = 0.0
var mixing_timer_running = false

var pending_stars = 0
var score = 0
var reputation = 5
var max_recipe_length = 10

var input_locked = false


func _ready():
	add_child(warning_player)
	warning_player.stream = load("res://Sprites/clock.wav")
	warning_player.volume_db = -5
	update_score_ui()
	update_reputation_ui()
	await get_tree().create_timer(spawn_delay).timeout
	start_customer()


func _process(delta):
	if approach_timer_running:
		var progress = approach_timer / approach_time_max
		clock.value = progress * 100.0

	if mixing_timer_running:
		var progress = mixing_timer / mixing_time_max
		clock.value = progress * 100.0
		
	if state == GameState.CLIENT_WAITING and approach_timer_running:
		approach_timer -= delta
		
		if approach_timer <= warning_threshold and not warning_playing:
			warning_player.play()
			warning_playing = true
		
		if approach_timer <= 0:
			fail_customer()


	if (state == GameState.SHOW_RECIPE 
	or state == GameState.MIXING 
	or state == GameState.DELIVERY) and mixing_timer_running:
		mixing_timer -= delta
		if mixing_timer <= warning_threshold and not warning_playing:
			warning_player.play()
			warning_playing = true
		if mixing_timer <= 0:
			fail_customer()


func start_customer():
	play_sound(fly_sound)
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
	play_sound(fly_away_sound)
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
	warning_player.stop()
	warning_playing = false
	approach_timer_running = false
	mixing_timer_running = false
	
	recipe_panel.visible = false
	ingredients_panel.visible = false
	selecting = false

	apply_result(1)

	send_customer_away()
	state = GameState.IDLE

	hide_clock()
	await get_tree().create_timer(cooldown_time).timeout
	start_customer()


func accept_order():
	if state != GameState.CLIENT_WAITING:
		return

	warning_player.stop()
	warning_playing = false
	approach_timer_running = false

	mixing_timer = mixing_time_max
	mixing_timer_running = true

	generate_recipe()
	show_recipe_ui()
	
	recipe_panel.visible = true
	
	state = GameState.SHOW_RECIPE


func start_mixing():
	if state != GameState.SHOW_RECIPE:
		return
		
	recipe_panel.visible = false
	ingredients_panel.visible = true
	player_input.clear()
	current_step = 0
	selecting = true

	show_next_choices()

	state = GameState.MIXING


func deliver():
	if state != GameState.DELIVERY:
		return
		
	warning_player.stop()
	warning_playing = false
	mixing_timer_running = false
	
	apply_result(pending_stars)

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
	warning_player.stop()
	warning_playing = false
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_IN)

	tween.tween_property(clock, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(clock, "scale", Vector2.ZERO, 0.2)

	tween.finished.connect(func():
		clock.visible = false
	)


func generate_recipe():
	current_recipe.clear()

	for i in range(recipe_length):
		var ingredient = possible_ingredients[randi() % possible_ingredients.size()]
		current_recipe.append(ingredient)

	print("Recipe:", current_recipe)


func _input(event):

	if state == GameState.SHOW_RECIPE:
		if event.is_action_pressed("w") or event.is_action_pressed("a") or event.is_action_pressed("s") or event.is_action_pressed("d"):
			start_mixing()

	elif state == GameState.MIXING and selecting:
		handle_selection(event)


func show_next_choices():
	current_choices.clear()

	var correct = current_recipe[current_step]

	var pool = possible_ingredients.duplicate()
	pool.erase(correct)

	pool.shuffle()

	var wrong_choices = pool.slice(0, 3)

	current_choices = wrong_choices
	current_choices.append(correct)

	current_choices.shuffle()

	print("Choices:", current_choices)

	var slots = [slot_w, slot_a, slot_s, slot_d]

	for i in range(4):
		var texture_rect = slots[i].get_node("TextureRect")
		texture_rect.texture = ingredient_textures[current_choices[i]]


func handle_selection(event):
	if input_locked:
		return
		
	if event.is_action_pressed("w"):
		select_ingredient(0)

	elif event.is_action_pressed("a"):
		select_ingredient(1)

	elif event.is_action_pressed("s"):
		select_ingredient(2)

	elif event.is_action_pressed("d"):
		select_ingredient(3)


func select_ingredient(index):
	if input_locked:
		return

	input_locked = true
	
	if index >= current_choices.size():
		return
		
	highlight_slot(index)
	await get_tree().create_timer(0.15).timeout
	
	var chosen = current_choices[index]
	player_input.append(chosen)

	print("Selected:", chosen)

	current_step += 1

	if current_step >= recipe_length:
		finish_mixing()
	else:
		show_next_choices()

	input_locked = false


func show_recipe_ui():
	for child in recipe_container.get_children():
		child.queue_free()

	for ingredient in current_recipe:
		var slot = slot_scene.instantiate()
		var texture_rect = slot.get_node("TextureRect")
		texture_rect.texture = ingredient_textures[ingredient]

		recipe_container.add_child(slot)


func finish_mixing():
	selecting = false
	ingredients_panel.visible = false

	pending_stars = calculate_score()

	state = GameState.DELIVERY

	
func highlight_slot(index):
	var slots = [slot_w, slot_a, slot_s, slot_d]

	for i in range(4):
		slots[i].modulate = Color(1, 1, 1)

	slots[index].modulate = Color(1.5, 1.5, 1.5)
	
	
func calculate_score():
	var correct = 0

	for i in range(recipe_length):
		if player_input[i] == current_recipe[i]:
			correct += 1

	var percentage = (correct / float(recipe_length)) * 100

	var stars = 1

	if percentage >= 100:
		stars = 5
	elif percentage >= 80:
		stars = 4
	elif percentage >= 60:
		stars = 3
	elif percentage >= 40:
		stars = 2
	else:
		stars = 1

	return stars


func apply_result(stars):
	score += stars
	update_score_ui()
	
	update_difficulty()
	
	if stars == 5:
		reputation += 2
	elif stars == 4:
		reputation += 1
	elif stars == 3:
		pass
	elif stars == 2:
		reputation -= 1
	elif stars == 1:
		reputation -= 2

	reputation = clamp(reputation, 0, 10)
	update_reputation_ui()

	print("Stars:", stars)
	print("Score:", score)
	print("Reputation:", reputation)

	if reputation <= 0:
		game_over()
		
		
func game_over():
	print("GAME OVER")

	get_tree().paused = true
	
	
func update_score_ui():
	score_label.text = "Score:" + str(score)


func update_reputation_ui():
	reputation_bar.value = reputation
	

func update_difficulty():
	var new_length = recipe_length_start + int(score / 10)

	if new_length > max_recipe_length:
		new_length = max_recipe_length

	recipe_length = new_length


func play_sound(path):
	var player = AudioStreamPlayer.new()
	player.volume_db = -10
	add_child(player)
	player.stream = load(path)
	player.play()
	player.finished.connect(player.queue_free)
