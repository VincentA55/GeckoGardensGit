extends CharacterBody3D


@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D

enum States {
	Neutral,
	Walking,
	Pursuit,
	Hungry,
	Eating,
	Dead
}
var state : States = States.Neutral

@export var walkSpeed : float = 7.0
@export var runSpeed : float = 10.0

func _ready() -> void:	
	ChangeState(States.Neutral)
	get_random_position()

#Gives random target position everytime jump is pressed
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		var random_position := Vector3.ZERO
		random_position.x = randf_range(-9,15.0)
		random_position.z = randf_range(-9,15.0)
		navigation_agent.set_target_position(random_position)

func _physics_process(delta: float) -> void:
	if state == States.Walking:
		move_to_location(delta)


func _on_navigation_finished() -> void:
	velocity = Vector3.ZERO 
	ChangeState(States.Neutral)

#Moves geck to next path position while navigation is not finished
func move_to_location(delta:float)->void:
	if navigation_agent.is_navigation_finished():  
		velocity = Vector3.ZERO  
		return  
	var destination = navigation_agent.get_next_path_position()
	var local_destination = destination - global_position
	var direction = local_destination.normalized()
	
	# 🔄 Rotate only on the Y-axis (prevent flipping)
	if direction.length() > 0.01:
		var target_basis = Basis().looking_at(direction, Vector3.UP)  
		var target_rotation = target_basis.get_euler()  

		# Lock rotation to Y-axis only (ignore X and Z tilting)
		var flat_rotation = Vector3(0, target_rotation.y, 0)  

		rotation.y = lerp_angle(rotation.y, flat_rotation.y, delta * 10.0)
	
	velocity = direction * walkSpeed
	move_and_slide() 

#This is used the moment a state is changed to prevent the action happening every frame
func ChangeState(newState : States) -> void:
	state = newState
	match state:
		States.Neutral:
			$WanderTimer.start()
			
			
			return
		States.Walking: 
			pass


func _on_wander_timer_timeout() -> void:
	if state == States.Neutral:
		ChangeState(States.Walking)
		get_random_position()

func get_random_position()->void:
	var random_position := Vector3.ZERO
	random_position.x = randf_range(-9,15.0)
	random_position.z = randf_range(-9,15.0)
	navigation_agent.set_target_position(random_position)
