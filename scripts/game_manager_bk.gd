extends Node

signal wave_cleared
signal game_won
signal died

var wave_config = [3, 5, 8, 12, 15]
var current_wave = 0
var enemies_alive = 0
var game_over = false

var next_wave_timer: Timer

var spawners
var ui
var player
@onready var spawner_container = get_node ("/Main/spawners")

func _ready():
	# Wait for the scene to be fully loaded before we do anything.
	await get_tree().process_frame
	
	# Now, setup all connections and start the game.
	player = get_tree().get_root().find_child("Player", true, false)
	ui = get_node("../../UI") # Use a direct node path
	
	# Get spawners directly from the scene tree to avoid race conditions
	#spawners = spawner_container.get_children()
	

	# Setup timer
	next_wave_timer = Timer.new()
	next_wave_timer.wait_time = 5.0
	next_wave_timer.one_shot = true
	next_wave_timer.start()
	next_wave_timer.connect("timeout", Callable(self, "start_next_wave"))
	add_child(next_wave_timer)
	print("GameManager: Timer created.")

	# Connect signals
	if player:
		player.player_died.connect(_on_player_died)
		print("GameManager: Connected to player_died signal.")
	else:
		print("GameManager ERROR: Player not found!")
		
	game_won.connect(_on_game_won)
	
	# Start the game
	start_next_wave()

func start_next_wave():
	if game_over: 
		print("GameManager: Tried to start next wave, but game is over.")
		return
	
	if current_wave >= wave_config.size():
		game_won.emit()
		return

	current_wave += 1
	enemies_alive = wave_config[current_wave - 1]
	
	if ui:
		ui.update_wave_info(current_wave, enemies_alive)

	print("GameManager: Starting Wave " + str(current_wave) + " with " + str(enemies_alive) + " enemies.")
	
	if spawners.is_empty():
		print("GameManager ERROR: No spawners found in the 'spawners' group.")
		return
		
	for i in range(enemies_alive):
		var random_spawner = spawners.pick_random()
		var new_enemy = random_spawner.spawn_enemy()
		if new_enemy:
			# Use get_parent() to get the Main node and add the enemy as a child.
			get_parent().add_child(new_enemy)
			new_enemy.global_position = random_spawner.global_position
			
			new_enemy.activate(player)
			new_enemy.died.connect(_on_enemy_died)
			print("GameManager: Connected signal for new enemy.")

func _on_enemy_died():
	print("GameManager: Detected an enemy death.")
	if game_over: return
	
	enemies_alive -= 1
	print("GameManager: Enemies left: " + str(enemies_alive))
	if ui:
		ui.update_wave_info(current_wave, enemies_alive)
		
	if enemies_alive <= 0:
		wave_cleared.emit()
		print("GameManager: Wave " + str(current_wave) + " cleared!")
		next_wave_timer.start()
		print("GameManager: Next wave timer started.")

func _on_player_died():
	game_over = true
	if ui:
		ui.show_game_over("Game Over")
	print("GAME OVER")

func _on_game_won():
	game_over = true
	if ui:
		ui.show_game_over("You Win!")
	print("YOU WIN!")
