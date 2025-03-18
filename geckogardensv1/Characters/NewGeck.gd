extends CharacterBody3D


@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		var random_position := Vector3.ZERO
		random_position.x = randf_range(-10.0,10.0)
		random_position.y = randf_range(-10.0,10.0)
		navigation_agent.set_target_position(random_position)

func _physics_process(delta: float) -> void:
	var destination = navigation_agent.get_next_path_position()
	var local_destination = destination - global_position
	var direction = local_destination.normalized()
	
	#WORKINGHERERE-----------------ROTATION GECK NO ROTATE
	velocity = direction * 5.0
	move_and_slide() 
