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
var stateString : String 
# Gecko's action weights
var Spin: int = 4
var Sit: int = 5
var Wander: int = 8

#The size of the hungerbar, zero is empty
@export var hungerBar : int = 1000
#How much it decreases by
@export var hungerGreed : int = 10

var isHungry : bool = false
var isdead : bool = false
var isStarving : bool = false
signal Starved
var invalid_targets: Array = []  # List of targets that should be ignored to prevent every frame interactions


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
		
	stateString = States.keys()[state]#for debugging and billboard
	$Billboard._update()

func _process(delta: float) -> void:
	if not isdead:
		if hungerBar <= 50:
			ChangeState(States.Hungry)
			
		if hungerBar < 10 and not isStarving:
			isStarving = true
			$GraceTimer.start()#So the Gecko doesnt die immediatly when hunger hits zero

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

func get_random_position()->void:
	var random_position := Vector3.ZERO
	random_position.x = randf_range(-9,15.0)
	random_position.z = randf_range(-9,15.0)
	navigation_agent.set_target_position(random_position)
	
#This is used the moment a state is changed to prevent the action happening every frame
func ChangeState(newState : States) -> void:
	$AnimationPlayer.play("RESET")
	state = newState
	match state:
		States.Neutral:
			$WanderTimer.start()
		
		States.Walking: 
			$AnimationPlayer.play("wander")
			
		States.Hungry:
			isHungry = true
			
		States.Dead:
			$AnimationPlayer.play("die")
			isdead = true
			emit_signal("Starved")

#This is when it makes the "decision" to do next
func _on_wander_timer_timeout() -> void:
	$AnimationPlayer.play("RESET")
	if state == States.Neutral:
		perform_wander_action()

#Recieves the choice as a string and does it
func perform_wander_action():
	var action = choose_wander_action()
	$AnimationPlayer.play("RESET")
	print("Gecko chose: ", action)  # Debugging

	if action == "spin":
		$AnimationPlayer.play("spin")
		$WanderTimer.start()
	elif action == "sit":
		$AnimationPlayer.play("sit")
		$WanderTimer.start()
	elif action == "wander":
		ChangeState(States.Walking)
		get_random_position()
	else:
		$AnimationPlayer.play("idle")  
		pass
		
#using math and numbers to choose return an actions string
func choose_wander_action() -> String:
	var total = Spin + Sit + Wander  # Get total weight 
	if total == 0:
		return "idle"  # No valid actions  

	var r = randi_range(1, total)  # Pick random number between 1 and total 

	if r <= Spin:
		return "spin"  
	elif r <= Spin + Sit:
		return "sit"  
	else:
		return "wander" 

#The rate at which the hunger goes down
func _on_hunger_timer_timeout() -> void:
	if not isdead or state != States.Eating:
		if hungerBar >= 0:
			hungerBar -= hungerGreed
			print("NewGeck:")
			print(hungerBar)

#So the geck doesnt die immediatly after hitting zero
func _on_grace_timer_timeout() -> void:
	if hungerBar <= 0:
		die()
	elif isStarving:
		isStarving = false

func die() -> void:
	ChangeState(States.Dead)
