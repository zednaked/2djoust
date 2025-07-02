extends Node2D

@export var enemy_scene: PackedScene

#spawna um inimigo
func start_spawning():
	if not enemy_scene:
		printerr("Spawner: A cena do inimigo não foi definida!")
		return
	
	var new_enemy = enemy_scene.instantiate()
	get_parent().add_child(new_enemy)
	new_enemy.global_position = self.global_position
