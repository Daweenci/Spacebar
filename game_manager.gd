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
	"space_fruit_7": preload("res://Sprites/SpaceFruit7.png"),
	"space_fruit_8": preload("res://Sprites/SpaceFruit8.png"),
	"space_fruit_9": preload("res://Sprites/SpaceFruit9.png"),
	"space_fruit_10": preload("res://Sprites/SpaceFruit10.png"),
	"space_fruit_11": preload("res://Sprites/SpaceFruit11.png"),
	"space_fruit_12": preload("res://Sprites/SpaceFruit12.png")
}

var rep_textures = [
	preload("res://Sprites/bad_rep.png"),        # 0
	preload("res://Sprites/mid_bad_rep.png"),    # 1
	preload("res://Sprites/mid_rep.png"),        # 2
	preload("res://Sprites/mid_good_rep.png"),   # 3
	preload("res://Sprites/good_rep.png")        # 4
]

@onready var customer = get_node("/root/Node2D/Customer")
@onready var clock = get_node("/root/Node2D/UI/Clock")
@onready var recipe_container = get_node("/root/Node2D/UI/RecipePanelWrapper/RecipePanel/GridContainer")
@onready var recipe_panel = get_node("/root/Node2D/UI/RecipePanelWrapper")
@onready var ingredients_panel = get_node("/root/Node2D/UI/IngredientsContainer")

@onready var slot_w = get_node("/root/Node2D/UI/IngredientsContainer/CenterContainer/VBoxContainer/IngredientSlotW")
@onready var slot_a = get_node("/root/Node2D/UI/IngredientsContainer/CenterContainer/VBoxContainer/HBoxContainer/IngredientSlotA")
@onready var slot_s = get_node("/root/Node2D/UI/IngredientsContainer/CenterContainer/VBoxContainer/IngredientSlotS")
@onready var slot_d = get_node("/root/Node2D/UI/IngredientsContainer/CenterContainer/VBoxContainer/HBoxContainer/IngredientSlotD")
@onready var score_label = get_node("/root/Node2D/UI/ScoreLabel")
@onready var reputation_bar = get_node("/root/Node2D/UI/ReputationBar")
@onready var reputation_sprite = get_node("/root/Node2D/UI/ReputationSprite")
@onready var cauldron = get_node("/root/Node2D/CauldronWrapper")
@onready var glass = get_node("/root/Node2D/BeerWrapper")
@onready var glass_full = get_node("/root/Node2D/BeerWrapper/Full")
@onready var glass_empty = get_node("/root/Node2D/BeerWrapper/Empty")
@onready var glass_anim = get_node("/root/Node2D/BeerWrapper/Animation")
@onready var cauldron_anim = get_node("/root/Node2D/CauldronWrapper/BrewAnim")
@onready var cauldron_front = get_node("/root/Node2D/CauldronWrapper/CauldronFront")
@onready var drop_point = get_node("/root/Node2D/CauldronWrapper/IngredientDropPoint")
@onready var result_panel = get_node("/root/Node2D/UI/ResultPanel")
@onready var stars_container = result_panel.get_node("Stars")
@onready var correct_container = result_panel.get_node("VBoxContainer/CorrectRecipe")
@onready var player_container = result_panel.get_node("VBoxContainer/PlayerRecipe")
@onready var game_over_panel = get_node("/root/Node2D/GameOver/GameOverPanel")
@onready var player = get_node("/root/Node2D/Player")
@onready var arrows = get_node("/root/Node2D/Arrows")

var brew_animating = false

var slot_scene = preload("res://ingredient_slot.tscn")

var possible_ingredients = ["space_fruit_1", "space_fruit_2", "space_fruit_3", 
"space_fruit_4", "space_fruit_5", "space_fruit_6", "space_fruit_7", "space_fruit_8",
"space_fruit_9", "space_fruit_10", "space_fruit_11", "space_fruit_12"]

var fly_sound = "res://Sprites/fly.wav"
var fly_away_sound = "res://Sprites/fly_away.wav"
@onready var warning_player = AudioStreamPlayer.new()
var warning_playing = false
var warning_threshold = 5.0

var current_recipe = []
var player_input = []
var recipe_length_start = 3
var recipe_length = recipe_length_start
var round_recipe_length = 3

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

var tween_duration = 1

var customer_target_pos = Vector2(1200, 600)

var customer_start
var customer_exit

var state = GameState.IDLE

var approach_timer = 0.0
var approach_timer_running = false

var mixing_timer = 0.0
var mixing_timer_running = false

var pending_stars = 0
var reputation = 5
var max_recipe_length = 12

var input_locked = false
var reputation_tween
var current_rep_state = 2

var customer_animations = ["customer1", "customer2", "customer3", "customer4", "customer5"]
var current_customer_index = 0

var recipe_target_pos
var recipe_start_offset = -720
var recipe_base_y
var recipe_visible_y = 720

var paper_texture = preload("res://Sprites/Schriftrolle.png")
var glass_is_full = false
var glass_animating = false

var result_base_y
var result_visible_y = 360

var dark_overlay: ColorRect

var approaching_customer_first_time = true

func _ready():
	dark_overlay = ColorRect.new()
	dark_overlay.color = Color(0, 0, 0, 0.6)
	dark_overlay.visible = false

	dark_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)

	var ui_root = get_node("/root/Node2D/UI")
	ui_root.add_child(dark_overlay)

	dark_overlay.z_index = 100
	game_over_panel.z_index = 101
	player.died.connect(game_over)
	await get_tree().process_frame
	result_base_y = result_panel.position.y
	cauldron_anim.animation_finished.connect(_on_brew_finished)
	glass_empty.visible = true
	glass_full.visible = false
	glass_anim.visible = false
	await get_tree().process_frame
	recipe_base_y = recipe_panel.position.y
	customer.scale = Vector2(2, 2)
	reputation_sprite.texture = rep_textures[current_rep_state]
	await get_tree().process_frame
	reputation_sprite.pivot_offset = Vector2(0, reputation_sprite.size.y)
	add_child(warning_player)
	warning_player.stream = load("res://Sprites/clock.wav")
	warning_player.volume_db = -20
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
	if (approaching_customer_first_time):
		arrows.visible = true
	var anim = customer_animations[current_customer_index]
	customer.play(anim)

	current_customer_index += 1
	if current_customer_index >= customer_animations.size():
		current_customer_index = 0
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
	
	if (approaching_customer_first_time):
		approaching_customer_first_time = false
		arrows.visible = false
	warning_player.stop()
	warning_playing = false
	approach_timer_running = false

	mixing_timer = mixing_time_max
	mixing_timer_running = true

	generate_recipe()
	show_recipe_ui()

	recipe_panel.position.y = recipe_base_y
	recipe_panel.visible = true

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(recipe_panel, "position:y", recipe_visible_y, 0.5)

	state = GameState.SHOW_RECIPE


func start_mixing():
	if state != GameState.SHOW_RECIPE:
		return

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN)

	tween.tween_property(recipe_panel, "position:y", recipe_base_y, 0.4)

	tween.finished.connect(func():
		recipe_panel.visible = false
	)

	ingredients_panel.visible = true
	show_cauldron()
	show_glass()
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
	hide_clock()

	if glass_animating:
		glass_anim.stop()
		glass_anim.visible = false
		glass_full.visible = true
		glass_is_full = true
		glass_animating = false
	
	if brew_animating:
		stop_brew_animation()
	
	hide_cauldron()
	hide_glass()

	apply_result(pending_stars)

	send_customer_away()
	state = GameState.RESULT
	selecting = false
	
	await get_tree().create_timer(0.5).timeout

	show_result_panel()

	var result_duration = max(cooldown_time - 1.0, 0.5)
	await get_tree().create_timer(result_duration).timeout

	hide_result_panel()

	await get_tree().create_timer(1.0).timeout

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

	var pool = possible_ingredients.duplicate()
	pool.shuffle()

	round_recipe_length = recipe_length

	for i in range(round_recipe_length):
		current_recipe.append(pool[i])

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

	var scale_factor = 2

	var base_paper_half = 32
	var base_icon_half = 16

	var paper_half = int(base_paper_half * scale_factor)
	var icon_half = int(base_icon_half * scale_factor)

	for i in range(4):
		var slot = slots[i]

		if not slot.has_node("Paper"):
			var paper = TextureRect.new()
			paper.name = "Paper"
			paper.texture = paper_texture

			paper.anchor_left = 0.5
			paper.anchor_top = 0.5
			paper.anchor_right = 0.5
			paper.anchor_bottom = 0.5

			paper.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

			slot.add_child(paper)
			slot.move_child(paper, 0)

		var paper = slot.get_node("Paper")

		paper.offset_left = -paper_half
		paper.offset_top = -paper_half
		paper.offset_right = paper_half
		paper.offset_bottom = paper_half

		var texture_rect = slot.get_node("TextureRect")
		texture_rect.texture = ingredient_textures[current_choices[i]]

		texture_rect.anchor_left = 0.5
		texture_rect.anchor_top = 0.5
		texture_rect.anchor_right = 0.5
		texture_rect.anchor_bottom = 0.5

		texture_rect.offset_left = -icon_half
		texture_rect.offset_top = -icon_half
		texture_rect.offset_right = icon_half
		texture_rect.offset_bottom = icon_half

		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

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
	var slot = [slot_w, slot_a, slot_s, slot_d][index]
	var texture = ingredient_textures[chosen]
	drop_ingredient(texture)

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

		slot.custom_minimum_size = Vector2(104, 104)

		var texture_rect = slot.get_node("TextureRect")
		texture_rect.texture = ingredient_textures[ingredient]

		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_rect.anchor_left = 0
		texture_rect.anchor_top = 0
		texture_rect.anchor_right = 1
		texture_rect.anchor_bottom = 1
		texture_rect.offset_left = 0
		texture_rect.offset_top = 0
		texture_rect.offset_right = 0
		texture_rect.offset_bottom = 0

		recipe_container.add_child(slot)


func finish_mixing():
	selecting = false
	ingredients_panel.visible = false

	pending_stars = calculate_score()
	fill_glass()
	play_brew_animation()
	state = GameState.DELIVERY

	
func highlight_slot(index):
	var slots = [slot_w, slot_a, slot_s, slot_d]

	for i in range(4):
		slots[i].modulate = Color(1, 1, 1)

	slots[index].modulate = Color(1.5, 1.5, 1.5)
	
	
func calculate_score():
	var correct = 0

	for i in range(round_recipe_length):
		if player_input[i] == current_recipe[i]:
			correct += 1

	var percentage = (correct / float(round_recipe_length)) * 100

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
	Global.score += stars
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
	print("Score:", Global.score)
	print("Reputation:", reputation)

	if reputation <= 0:
		game_over()
		
		
func game_over():
	dark_overlay.visible = true
	print("GAME OVER CALLED")

	if Global.score > Global.highscore:
		Global.highscore = Global.score

	var score_label = game_over_panel.get_node("ScoreLabel")
	var highscore_label = game_over_panel.get_node("HighscoreLabel")

	score_label.text = "Score: " + str(Global.score)
	highscore_label.text = "Highscore: " + str(Global.highscore)

	game_over_panel.visible = true

	await get_tree().process_frame

	get_tree().paused = true
	
	
func _on_retry_button_pressed():
	Global.score = 0
	dark_overlay.visible = false
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_exit_button_pressed():
	Global.score = 0
	dark_overlay.visible = false
	get_tree().paused = false
	get_tree().quit()
	
	
func update_score_ui():
	score_label.text = "Score:" + str(Global.score)


func update_reputation_ui():
	if reputation_tween:
		reputation_tween.kill()

	reputation_tween = create_tween()
	reputation_tween.set_trans(Tween.TRANS_SINE)
	reputation_tween.set_ease(Tween.EASE_IN_OUT)

	reputation_tween.tween_property(reputation_bar, "value", reputation, 1.5)

	var t = reputation / 10.0

	var color: Color
	if t < 0.5:
		color = Color.RED.lerp(Color(1.0, 0.8, 0.2), t * 2.0)
	else:
		color = Color(1.0, 0.8, 0.2).lerp(Color.GREEN, (t - 0.5) * 2.0)

	reputation_bar.tint_progress = color
	update_reputation_sprite()


func update_difficulty():
	var new_length = recipe_length_start + int(Global.score / 10)

	if new_length > max_recipe_length:
		new_length = max_recipe_length

	recipe_length = new_length


func play_sound(path):
	var player = AudioStreamPlayer.new()
	player.volume_db = -28
	add_child(player)
	player.stream = load(path)
	player.play()
	player.finished.connect(player.queue_free)
	

func get_rep_state(rep):
	if rep <= 2:
		return 0
	elif rep <= 4:
		return 1
	elif rep <= 6:
		return 2
	elif rep <= 8:
		return 3
	else:
		return 4
		
func update_reputation_sprite():
	var new_state = get_rep_state(reputation)

	if new_state == current_rep_state:
		return

	current_rep_state = new_state
	play_rep_transition(new_state)


func play_rep_transition(new_state):
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(reputation_sprite, "scale", Vector2(1.3, 1.3), 0.4)

	tween.tween_callback(func():
		reputation_sprite.texture = rep_textures[new_state]
	)

	tween.tween_property(reputation_sprite, "scale", Vector2(1, 1), 0.4)


func show_cauldron():
	var target_x = 116
	var start_x = 0

	cauldron.position.x = start_x
	cauldron.visible = true

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(cauldron, "position:x", target_x, 0.6)

func show_glass():
	var target_x = 220  
	var start_x = 700   

	glass.position.x = start_x
	glass.visible = true

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(glass, "position:x", target_x, 0.6)


func fill_glass():
	glass_animating = true

	glass_empty.visible = true
	glass_full.visible = false
	glass_anim.visible = true

	glass_anim.play("fill")

	await glass_anim.animation_finished

	glass_anim.visible = false
	glass_empty.visible = false
	glass_full.visible = true

	glass_is_full = true
	glass_animating = false

func hide_cauldron():
	var target_x = -300

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN)

	tween.tween_property(cauldron, "position:x", target_x, 0.5)
	
func hide_glass():
	var target_x = 700

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN)

	tween.tween_property(glass, "position:x", target_x, 0.5)

	tween.finished.connect(func():
		reset_glass()
	)
	
func reset_glass():
	glass_anim.stop()
	glass_anim.visible = false

	glass_empty.visible = true
	glass_full.visible = false

	glass_is_full = false
	glass.visible = false


func play_brew_animation():
	brew_animating = true
	
	cauldron_anim.visible = true
	cauldron_anim.play("brew")
	
	cauldron_front.visible = false


func stop_brew_animation():
	brew_animating = false
	
	cauldron_anim.stop()
	cauldron_anim.visible = false
	
	cauldron_front.visible = true

func _on_brew_finished():
	if brew_animating:
		stop_brew_animation()

func drop_ingredient(texture):
	var sprite = Sprite2D.new()
	sprite.texture = texture
	
	sprite.scale = Vector2(0.5, 0.5)
	
	var front_index = cauldron.get_node("CauldronFront").get_index()

	cauldron.add_child(sprite)
	cauldron.move_child(sprite, front_index)
	sprite.global_position = Vector2(100,380)

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN)

	tween.tween_property(sprite, "global_position", drop_point.global_position, 0.6)

	tween.parallel().tween_property(sprite, "rotation", randf_range(-2, 2), 0.6)
	tween.parallel().tween_property(sprite, "scale", Vector2(0.5, 0.5), 0.6)

	tween.finished.connect(func():
		sprite.queue_free()
	)


func show_result_panel():
	result_panel.visible = true
	
	result_panel.position.y = result_base_y

	result_panel.scale = Vector2(0.8, 0.8)
	result_panel.modulate.a = 0.0

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	show_recipe_comparison()
	tween.tween_property(result_panel, "position:y", result_visible_y, 0.8)

	tween.parallel().tween_property(result_panel, "scale", Vector2(1, 1), 0.8)
	tween.parallel().tween_property(result_panel, "modulate:a", 1.0, 0.8)

	var stars = stars_container.get_children()
	for star in stars:
		var empty = star.get_node("Empty")
		var full = star.get_node("Full")

		full.stop()
		full.frame = 0

		empty.visible = true
		full.visible = false

	await tween.finished
	await get_tree().create_timer(0.3).timeout

	await animate_stars(pending_stars)


func animate_stars(amount):
	var stars = stars_container.get_children()

	for i in range(amount):
		var star = stars[i]
		var empty = star.get_node("Empty")
		var full = star.get_node("Full")

		empty.visible = false
		full.visible = true

		full.scale = Vector2(0, 0)

		full.play("default")

		var tween = create_tween()
		tween.set_trans(Tween.TRANS_BACK)
		tween.set_ease(Tween.EASE_OUT)

		tween.tween_property(full, "scale", Vector2(1.2, 1.2), 0.2)
		tween.tween_property(full, "scale", Vector2(1, 1), 0.2)

		await tween.finished

func hide_result_panel():
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN)

	tween.tween_property(result_panel, "position:y", result_base_y, 0.4)

	await tween.finished
	result_panel.visible = false


func show_recipe_comparison():
	for c in correct_container.get_children():
		c.queue_free()
	for c in player_container.get_children():
		c.queue_free()

	for i in range(round_recipe_length):
		var correct = current_recipe[i]
		var player = player_input[i]

		var correct_slot = slot_scene.instantiate()
		correct_slot.custom_minimum_size = Vector2(48, 48)
		correct_slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

		var tex2 = correct_slot.get_node("TextureRect")
		tex2.texture = ingredient_textures[correct]

		tex2.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex2.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex2.anchor_left = 0
		tex2.anchor_top = 0
		tex2.anchor_right = 1
		tex2.anchor_bottom = 1
		tex2.offset_left = 0
		tex2.offset_top = 0
		tex2.offset_right = 0
		tex2.offset_bottom = 0

		correct_container.add_child(correct_slot)

		var player_slot = slot_scene.instantiate()
		player_slot.custom_minimum_size = Vector2(48, 48)
		player_slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

		var tex = player_slot.get_node("TextureRect")
		tex.texture = ingredient_textures[player]

		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.anchor_left = 0
		tex.anchor_top = 0
		tex.anchor_right = 1
		tex.anchor_bottom = 1
		tex.offset_left = 0
		tex.offset_top = 0
		tex.offset_right = 0
		tex.offset_bottom = 0

		if player != correct:
			var cross = Label.new()
			cross.text = "✖"
			cross.scale = Vector2(1.2, 1.2)
			cross.modulate = Color(1, 0, 0)
			cross.position = Vector2(2, 2)

			player_slot.add_child(cross)

		player_container.add_child(player_slot)


func _on_exit_pressed() -> void:
	pass # Replace with function body.
