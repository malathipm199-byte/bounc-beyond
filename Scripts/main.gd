extends Node2D

enum GameState { MENU, CONFIRM, PLAYING, PAUSED, GAME_OVER, VICTORY }

@onready var player: CharacterBody2D = $Player
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var abyss: Area2D = $Abyss
@onready var finish_portal: Area2D = $FinishPortal
@onready var coins_container: Node2D = $World/Coins
@onready var obstacles_container: Node2D = $World/Obstacles

# HUD & Screens (CanvasLayer)
@onready var hud_bar: PanelContainer = $UI/HUD
@onready var score_label: Label = $UI/HUD/Margin/HBox/ScoreLabel
@onready var coins_label: Label = $UI/HUD/Margin/HBox/CoinsLabel
@onready var best_label: Label = $UI/HUD/Margin/HBox/BestLabel
@onready var pause_btn: Button = $UI/HUD/Margin/HBox/PauseButton

@onready var menu_screen: Control = $UI/MenuScreen
@onready var menu_best_label: Label = $UI/MenuScreen/Center/Panel/VBox/BestScoreLabel
@onready var instructions_popup: PanelContainer = $UI/MenuScreen/InstructionsPopup

@onready var confirm_screen: Control = $UI/ConfirmScreen
@onready var pause_screen: Control = $UI/PauseScreen

@onready var game_over_screen: Control = $UI/GameOverScreen
@onready var go_score_label: Label = $UI/GameOverScreen/Center/Panel/VBox/ScoreResultLabel
@onready var go_best_label: Label = $UI/GameOverScreen/Center/Panel/VBox/BestResultLabel

@onready var victory_screen: Control = $UI/VictoryScreen
@onready var vic_score_label: Label = $UI/VictoryScreen/Center/Panel/VBox/FinalScoreLabel
@onready var vic_coins_label: Label = $UI/VictoryScreen/Center/Panel/VBox/FinalCoinsLabel
@onready var vic_best_label: Label = $UI/VictoryScreen/Center/Panel/VBox/BestResultLabel

var state: GameState = GameState.MENU
var score: int = 0
var coins: int = 0
var best_score: int = 0

# Obstacle section checkpoints (X coordinates) -> +20 pts each when crossed
var section_checkpoints: Array[float] = [680.0, 1280.0, 1950.0, 2600.0]
var cleared_sections: Array[bool] = [false, false, false, false]

# Procedural Sound Effect Generator
var sfx_player: AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	player.add_to_group("player")
	
	# Setup procedural audio player
	sfx_player = AudioStreamPlayer.new()
	add_child(sfx_player)
	
	# Connect world triggers
	abyss.body_entered.connect(_on_hazard_triggered)
	finish_portal.body_entered.connect(_on_finish_reached)
	
	# Connect all coins
	for coin in coins_container.get_children():
		if coin.has_signal("collected"):
			coin.collected.connect(_on_coin_collected)
	
	# Connect all hazards & bounce pads inside World/Obstacles
	for node in obstacles_container.get_children():
		if node.is_in_group("hazard") and node is Area2D:
			node.body_entered.connect(_on_hazard_triggered)
		elif node.is_in_group("bounce_pad") and node is Area2D:
			node.body_entered.connect(_on_bounce_pad_entered)
		# Also check children of moving obstacle containers
		for child in node.get_children():
			if child.is_in_group("hazard") and child is Area2D:
				child.body_entered.connect(_on_hazard_triggered)
	
	# Connect UI Buttons
	$UI/MenuScreen/Center/Panel/VBox/StartButton.pressed.connect(_on_start_pressed)
	$UI/MenuScreen/Center/Panel/VBox/InstructionsButton.pressed.connect(_on_instructions_pressed)
	$UI/MenuScreen/Center/Panel/VBox/QuitButton.pressed.connect(_on_quit_pressed)
	$UI/MenuScreen/InstructionsPopup/VBox/CloseInstrButton.pressed.connect(_on_close_instructions_pressed)
	
	$UI/ConfirmScreen/Center/Panel/VBox/YesPlayButton.pressed.connect(_on_confirm_yes_pressed)
	$UI/ConfirmScreen/Center/Panel/VBox/BackMenuButton.pressed.connect(_on_back_to_menu_pressed)
	
	pause_btn.pressed.connect(_toggle_pause)
	$UI/PauseScreen/Center/Panel/VBox/ResumeButton.pressed.connect(_toggle_pause)
	$UI/PauseScreen/Center/Panel/VBox/RestartPauseButton.pressed.connect(_start_new_run)
	$UI/PauseScreen/Center/Panel/VBox/MenuPauseButton.pressed.connect(_on_back_to_menu_pressed)
	
	$UI/GameOverScreen/Center/Panel/VBox/RetryButton.pressed.connect(_start_new_run)
	$UI/GameOverScreen/Center/Panel/VBox/MenuButton.pressed.connect(_on_back_to_menu_pressed)
	
	$UI/VictoryScreen/Center/Panel/VBox/PlayAgainButton.pressed.connect(_start_new_run)
	$UI/VictoryScreen/Center/Panel/VBox/MenuButton.pressed.connect(_on_back_to_menu_pressed)
	
	_switch_state(GameState.MENU)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		if state == GameState.PLAYING or state == GameState.PAUSED:
			_toggle_pause()
	
	if state == GameState.PLAYING:
		# Check obstacle sections crossed (+20 points per section)
		for i in range(section_checkpoints.size()):
			if not cleared_sections[i] and player.global_position.x >= section_checkpoints[i]:
				cleared_sections[i] = true
				_add_score(20)
				_play_tone(520.0, 0.12)

func _switch_state(new_state: GameState) -> void:
	state = new_state
	get_tree().paused = (state == GameState.PAUSED)
	
	menu_screen.visible = (state == GameState.MENU)
	instructions_popup.visible = false
	confirm_screen.visible = (state == GameState.CONFIRM)
	hud_bar.visible = (state == GameState.PLAYING or state == GameState.PAUSED)
	pause_screen.visible = (state == GameState.PAUSED)
	game_over_screen.visible = (state == GameState.GAME_OVER)
	victory_screen.visible = (state == GameState.VICTORY)
	
	player.can_control = (state == GameState.PLAYING)
	
	if state == GameState.MENU:
		menu_best_label.text = "SESSION BEST SCORE: %d" % best_score
		_reset_world_objects()

func _start_new_run() -> void:
	score = 0
	coins = 0
	for i in range(cleared_sections.size()):
		cleared_sections[i] = false
	_reset_world_objects()
	_update_hud()
	_switch_state(GameState.PLAYING)
	_play_tone(440.0, 0.15)

func _reset_world_objects() -> void:
	player.global_position = spawn_point.global_position
	player.velocity = Vector2.ZERO
	for coin in coins_container.get_children():
		coin.is_collected = false
		coin.visible = true
		coin.set_deferred("monitoring", true)

func _add_score(points: int) -> void:
	score += points
	if score > best_score:
		best_score = score
	_update_hud()

func _update_hud() -> void:
	score_label.text = "SCORE: %d" % score
	coins_label.text = "COINS: %d" % coins
	best_label.text = "BEST: %d" % best_score

# --- Gameplay Callbacks ---

func _on_coin_collected(_coin_node: Area2D) -> void:
	if state != GameState.PLAYING:
		return
	coins += 1
	_add_score(10)
	_play_tone(880.0, 0.10)

func _on_bounce_pad_entered(body: Node2D) -> void:
	if state != GameState.PLAYING:
		return
	if body == player:
		player.bounce(-780.0)
		_play_tone(660.0, 0.18)

func _on_hazard_triggered(body: Node2D) -> void:
	if state != GameState.PLAYING:
		return
	if body == player:
		_play_tone(160.0, 0.35)
		go_score_label.text = "Score: %d  |  Coins: %d" % [score, coins]
		go_best_label.text = "Session Best: %d" % best_score
		_switch_state(GameState.GAME_OVER)

func _on_finish_reached(body: Node2D) -> void:
	if state != GameState.PLAYING:
		return
	if body == player:
		# +100 bonus points for reaching the finish
		_add_score(100)
		_play_tone(1046.5, 0.40)
		vic_score_label.text = "Final Score: %d (+100 Finish Bonus)" % score
		vic_coins_label.text = "Coins Collected: %d / %d" % [coins, coins_container.get_child_count()]
		vic_best_label.text = "Session Best Score: %d" % best_score
		_switch_state(GameState.VICTORY)

# --- UI Button Handlers ---

func _on_start_pressed() -> void:
	_play_tone(500.0, 0.08)
	_switch_state(GameState.CONFIRM)

func _on_instructions_pressed() -> void:
	_play_tone(500.0, 0.08)
	instructions_popup.visible = true

func _on_close_instructions_pressed() -> void:
	_play_tone(400.0, 0.08)
	instructions_popup.visible = false

func _on_confirm_yes_pressed() -> void:
	_start_new_run()

func _on_back_to_menu_pressed() -> void:
	_play_tone(400.0, 0.08)
	_switch_state(GameState.MENU)

func _toggle_pause() -> void:
	if state == GameState.PLAYING:
		_switch_state(GameState.PAUSED)
	elif state == GameState.PAUSED:
		_switch_state(GameState.PLAYING)

func _on_quit_pressed() -> void:
	get_tree().quit()

# --- Procedural Retro Beep Synthesizer (No external audio files needed) ---
func _play_tone(freq: float, duration: float) -> void:
	var sample_rate := 22050
	var num_samples := int(sample_rate * duration)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	var data := PackedByteArray()
	data.resize(num_samples)
	for i in range(num_samples):
		var t := float(i) / float(sample_rate)
		var env := 1.0 - (float(i) / float(num_samples))
		var wave := sin(TAU * freq * t) * env * 0.4
		data[i] = int(clamp((wave + 1.0) * 127.5, 0, 255))
	stream.data = data
	sfx_player.stream = stream
	sfx_player.play()
