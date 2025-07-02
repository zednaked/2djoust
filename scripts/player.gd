extends CharacterBody2D

signal health_updated(current_health, max_health)
signal player_died

const SPEED = 280.0
const DASH_SPEED = 700.0
const DASH_DURATION = 0.40
const ATTACK_DAMAGE = 50
const HEAL_AMOUNT = 25
const DOUBLE_TAP_DELAY = 0.2
var dash_timer = 0.0
var combo_counter = 0

@export var max_health = 100
var health

@onready var animated_sprite = $Soldier
@onready var hitbox = $Hitbox/CollisionShape2D

enum State { IDLE, WALK, DASH, ATTACK, HURT, DEATH }
var current_state = State.IDLE

var dash_direction = Vector2.ZERO

var last_tap_time = {"left": 0.0, "right": 0.0, "up": 0.0, "down": 0.0}
var actions = {"left": "ui_left", "right": "ui_right", "up": "ui_up", "down": "ui_down"}
var directions = {"left": Vector2.LEFT, "right": Vector2.RIGHT, "up": Vector2.UP, "down": Vector2.DOWN}


var can_combo = false
var combo_reset_timer = null

func _ready():
	
	health = max_health
	$Hurtbox.connect("area_entered", Callable(self, "_on_Hurtbox_area_entered"))
	animated_sprite.connect("animation_finished", Callable(self, "_on_animation_finished"))

func _physics_process(delta):
	if current_state == State.DEATH:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	match current_state:
		State.HURT:
			velocity = Vector2.ZERO
		
		State.IDLE, State.WALK:
			handle_movement_input()
			handle_dash_input()
			if Input.is_action_just_pressed("ui_select"):
				start_attack()
		
		State.DASH:
			handle_dashing(delta)
			if Input.is_action_just_pressed("ui_select"):
				start_attack()

		State.ATTACK:
			velocity = velocity.move_toward(Vector2.ZERO, SPEED * delta * 5)
			if Input.is_action_just_pressed("ui_select") and can_combo:
				start_attack()

	move_and_slide()
	
#arrasta a rapaise
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision and collision.get_collider().is_in_group("enemy"):
			var enemy = collision.get_collider()
			enemy.velocity = self.velocity

func handle_movement_input():
	var direction_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direction_vector != Vector2.ZERO:
		current_state = State.WALK
		velocity = direction_vector * SPEED
		animated_sprite.play("Walk")
		animated_sprite.flip_h = direction_vector.x < 0
	else:
		current_state = State.IDLE
		velocity = Vector2.ZERO
		animated_sprite.play("Idle")

func handle_dash_input():
	var current_time = Time.get_ticks_msec() / 1000.0
	for dir_name in actions.keys():
		var action = actions[dir_name]
		if Input.is_action_just_pressed(action):
			if current_time - last_tap_time[dir_name] < DOUBLE_TAP_DELAY:
				current_state = State.DASH
				dash_timer = DASH_DURATION
				dash_direction = directions[dir_name]
				animated_sprite.play("Walk")
			last_tap_time[dir_name] = current_time

func handle_dashing(delta):
	velocity = dash_direction * DASH_SPEED
	dash_timer -= delta
	if dash_timer <= 0:
		current_state = State.IDLE

func start_attack():
	current_state = State.ATTACK
	can_combo = false
	if combo_reset_timer != null and combo_reset_timer.time_left > 0:
		combo_reset_timer.disconnect("timeout", Callable(self, "reset_combo"))
		combo_reset_timer = null

	combo_counter += 1
	if combo_counter > 3:
		combo_counter = 1
	
	var attack_animation = "Attack0" + str(combo_counter)
	animated_sprite.play(attack_animation)
	
	var damage_delay = 0.3
	await get_tree().create_timer(damage_delay).timeout
	hitbox.set_deferred("disabled", false)
	await get_tree().create_timer(0.2).timeout
	hitbox.set_deferred("disabled", true)

func _on_animation_finished():
	if animated_sprite.animation.begins_with("Attack"):
		can_combo = true
		combo_reset_timer = get_tree().create_timer(0.5)
		combo_reset_timer.connect("timeout", Callable(self, "reset_combo"))
		if current_state == State.ATTACK:
			current_state = State.IDLE
	elif animated_sprite.animation == "Hurt":
		current_state = State.IDLE
	elif animated_sprite.animation == "Death":
		pass

func reset_combo():
	combo_counter = 0
	can_combo = false

func take_damage(amount):
	if current_state == State.DEATH: return

	health -= amount
	health_updated.emit(health, max_health)
	
	if health <= 0:
		current_state = State.DEATH
		animated_sprite.play("Death")
		player_died.emit()
		$CollisionShape2D.set_deferred("disabled", true)
		$Hurtbox.set_deferred("monitoring", false)
	else:
		current_state = State.HURT
		animated_sprite.play("Hurt")
		var invincibility_duration = 0.3
		var tween = create_tween()
		tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1, 0.5), 0.1).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1, 1), 0.1).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN_OUT).set_delay(0.1)
		tween.set_loops(int(invincibility_duration / 0.2))

func heal(amount):
	health = min(health + amount, max_health)
	health_updated.emit(health, max_health)

func _on_Hurtbox_area_entered(area):
	if area.is_in_group("pickup"):
		
		if area.name == "HealthPack":
			print_debug("pickup")
			heal(HEAL_AMOUNT)
			area.queue_free()

func get_max_health():
	return max_health

func get_current_health():
	return health
