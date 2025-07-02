extends GPUParticles2D

func _ready():
	# Start emitting
	emitting = true
	# Stop emitting after a short time
	await get_tree().create_timer(0.2).timeout
	emitting = false
	# Wait for the remaining particles to die, then free the node
	await get_tree().create_timer(lifetime).timeout
	queue_free()
