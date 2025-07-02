extends CharacterBody2D

signal died

@export var max_health = 100
var health

const SPEED = 120.0
const ATTACK_DAMAGE = 10
const KNOCKBACK_DISTANCE = 160.0
const KNOCKBACK_DURATION = 0.2
var attack_range = 120.0


var hit_effect_scene = preload("res://scenes/effects/hit_effect.tscn")
var death_effect_scene = preload("res://scenes/effects/death_effect.tscn")


@onready var animated_sprite = $Orc
@onready var hitbox_area = $Hitbox # Referência para a Area2D
@onready var hitbox_shape = $Hitbox/CollisionShape2D # Referência para a CollisionShape2D
@onready var health_bar = $EnemyHealthBar

var player = null
var hit_targets_in_swing = []

enum State { IDLE, CHASING, ATTACKING, HURT, DEATH }
var current_state = State.CHASING
var is_attacking = false
var can_attack = true


func _ready():
	health = max_health
	health_bar.max_value = max_health
	health_bar.value = health
	health_bar.visible = false
	hitbox_shape.disabled = true # Começa com a forma desabilitada
	
	animated_sprite.connect("animation_finished", Callable(self, "_on_animation_finished"))
	$Hurtbox.connect("area_entered", Callable(self, "_on_Hurtbox_area_entered"))
	
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	if is_instance_valid(player):
		current_state = State.CHASING
	else:
		printerr("Inimigo spawnado não conseguiu encontrar o jogador.")

func _physics_process(delta):
	if not is_instance_valid(player) or current_state == State.HURT or current_state == State.DEATH:
		if current_state != State.HURT:
			velocity = velocity.move_toward(Vector2.ZERO, SPEED * delta * 2)
		move_and_slide()
		return

	match current_state:
		State.IDLE:
			velocity = velocity.move_toward(Vector2.ZERO, SPEED * delta * 2)
			animated_sprite.play("idle")
		State.CHASING:
			chase_state(delta)
		State.ATTACKING:
			attack_state(delta)
	
	if is_instance_valid(player):
		animated_sprite.flip_h = player.global_position.x < global_position.x
	
	move_and_slide()

func chase_state(delta):
	var distance_to_player = global_position.distance_to(player.global_position)
	if distance_to_player <= attack_range:
		current_state = State.ATTACKING
		velocity = Vector2.ZERO
		return
	var direction = global_position.direction_to(player.global_position)
	velocity = direction * SPEED
	animated_sprite.play("walk")

func attack_state(delta):
	velocity = velocity.move_toward(Vector2.ZERO, SPEED * delta * 2)
	if is_attacking or not can_attack: return

	is_attacking = true
	can_attack = false
	animated_sprite.play("attack01")
	
	hit_targets_in_swing.clear()
	
	await get_tree().create_timer(0.3).timeout
	if current_state == State.ATTACKING:
		hitbox_shape.disabled = false
		await get_tree().create_timer(0.2).timeout
		perform_attack_check()
		hitbox_shape.disabled = true

func perform_attack_check():
	var overlapping_areas = hitbox_area.get_overlapping_areas()
	for area in overlapping_areas:
		if area.get_parent().is_in_group("player") and not hit_targets_in_swing.has(area.get_parent()):
			var target_player = area.get_parent()
			target_player.take_damage(ATTACK_DAMAGE)
			hit_targets_in_swing.append(target_player)

func decide_next_action():
	if current_state == State.DEATH: return
	if not is_instance_valid(player):
		current_state = State.IDLE
		return
	if global_position.distance_to(player.global_position) < attack_range:
		current_state = State.ATTACKING
	else:
		current_state = State.CHASING

func _on_animation_finished():
	if animated_sprite.animation == "Death":
		queue_free()
	elif animated_sprite.animation == "hurt":
		decide_next_action()
	elif animated_sprite.animation == "attack01":
		is_attacking = false
		await get_tree().create_timer(0.5).timeout # Cooldown de 0.5s
		can_attack = true
		decide_next_action()
	elif animated_sprite.animation == "idle":
		animated_sprite.play("idle")

func take_damage(amount):
	if current_state == State.DEATH or current_state == State.HURT: return
	
	health -= amount
	health_bar.value = health
	if not health_bar.visible:
		health_bar.visible = true
	
	var effect = hit_effect_scene.instantiate()
	get_parent().add_child(effect)
	effect.global_position = global_position
	
	if health <= 0:
		died.emit()
		var death_effect = death_effect_scene.instantiate()
		get_parent().add_child(death_effect)
		death_effect.global_position = global_position
		
		current_state = State.DEATH
		animated_sprite.play("Death")
		health_bar.visible = false
		$CollisionShape2D.disabled = true
		$Hurtbox/CollisionShape2D.disabled = true
		hitbox_shape.disabled = true
	else:
		current_state = State.HURT
		animated_sprite.play("hurt")
		if is_instance_valid(player):
			var knockback_direction = player.global_position.direction_to(global_position)
			apply_knockback(knockback_direction)

func apply_knockback(direction: Vector2):
	velocity = Vector2.ZERO
	var tween = get_tree().create_tween().bind_node(self)
	var target_position = global_position + direction * KNOCKBACK_DISTANCE
	tween.tween_property(self, "global_position", target_position, KNOCKBACK_DURATION).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)

func _on_Hurtbox_area_entered(area):
	if area.is_in_group("player_attack"):
		take_damage(55)
