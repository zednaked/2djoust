extends CanvasLayer

enum GameState { START_MENU, PLAYING, GAME_OVER }
var current_state = GameState.START_MENU

@onready var health_bar = $HealthBar
@onready var score_label = $ScoreLabel
@onready var game_over_label = $GameOverLabel
@onready var restart_button = $RestartButton
@onready var title_label = $TitleLabel
@onready var start_button = $StartButton

var score = 0
var player = null

func _ready():
	# Conecta os botões às suas funções
	start_button.connect("pressed", _on_StartButton_pressed)
	restart_button.connect("pressed", _on_RestartButton_pressed)
	
	# Conecta-se à árvore para detectar nós adicionados
	get_tree().node_added.connect(_on_node_added)
	
	# Procura por nós que já existem
	for node in get_tree().get_nodes_in_group("player"):
		_on_node_added(node)
	for node in get_tree().get_nodes_in_group("enemy"):
		_on_node_added(node)
		
	update_ui_for_state()

func change_state(new_state):
	current_state = new_state
	update_ui_for_state()

func update_ui_for_state():
	# Visibilidade dos elementos da UI
	title_label.visible = (current_state == GameState.START_MENU)
	start_button.visible = (current_state == GameState.START_MENU)
	game_over_label.visible = (current_state == GameState.GAME_OVER)
	restart_button.visible = (current_state == GameState.GAME_OVER)
	health_bar.visible = (current_state == GameState.PLAYING)
	score_label.visible = (current_state == GameState.PLAYING)
	
	# Visibilidade dos elementos do jogo
	if is_instance_valid(player):
		player.visible = (current_state == GameState.PLAYING)
		# Impede o jogador de se mover e ser atingido fora do estado de jogo
		player.set_process(current_state == GameState.PLAYING)
		player.set_physics_process(current_state == GameState.PLAYING)
		if player.get_node_or_null("CollisionShape2D"):
			player.get_node("CollisionShape2D").disabled = (current_state != GameState.PLAYING)

	# Ativa/desativa os spawners
	for spawner in get_tree().get_nodes_in_group("spawners"):
		spawner.visible = (current_state == GameState.PLAYING)
		if current_state == GameState.PLAYING:
			spawner.start_spawning()

func _on_StartButton_pressed():
	change_state(GameState.PLAYING)

func _on_RestartButton_pressed():
	get_tree().reload_current_scene()

func _on_node_added(node):
	if node.is_in_group("player"):
		player = node
		player.health_updated.connect(_on_player_health_updated)
		player.player_died.connect(_on_player_died)
		if player.has_method("get_current_health") and player.has_method("get_max_health"):
			_on_player_health_updated(player.get_current_health(), player.get_max_health())
		update_ui_for_state() # Garante que o jogador comece invisível

	if node.is_in_group("enemy"):
		node.died.connect(Callable(self, "_on_enemy_died"))
		# Garante que os inimigos comecem invisíveis
		node.visible = (current_state == GameState.PLAYING)

func _on_enemy_died():
	if current_state != GameState.PLAYING: return
	score += 100
	score_label.text = "Score: " + str(score)

func _on_player_health_updated(current_health, max_health):
	health_bar.max_value = max_health
	health_bar.value = current_health

func _on_player_died():
	change_state(GameState.GAME_OVER)
