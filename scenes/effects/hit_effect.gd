extends GPUParticles2D

func _ready():
	# Start emitting particles immediately
	emitting = true
	# Wait for the lifetime of the particles to finish, then free the node
	await get_tree().create_timer(lifetime).timeout
	queue_free()
