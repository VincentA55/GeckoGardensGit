extends CharacterBody3D


@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var food_manager = get_node("/root/Main/FoodManager")

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


enum States {
	Neutral,
	Walking,
	Pursuit,
	Hungry,
	Eating,
	Dead}
var state : States = States.Neutral
var stateString : String  #for the billboard
# Gecko's action weights
var Spin: int = 4
var Sit: int = 5
var Wander: int = 8

enum Natures {
	Neutral,
	Greedy,
	Picky
}
@export var nature : Natures

@export var walkSpeed : float = 9.0
@export var runSpeed : float = 12.0

enum FavTypes{
	Sweet,
	Salty,
	Spicy,
	Plain}
@export var favouriteFood : FavTypes
var favString : String 

@export var current_hunger : int #The size of the hungerbar, zero is empty
@export var hungerMax : int
@export var hungerGreed : int = 10#How much it decreases by
signal hunger_changed(current_hunger)

var isHungry : bool = false
var isdead : bool = false
var isStarving : bool = false
signal Starved
var invalid_targets: Array = []  # List of targets that should be ignored to prevent every frame interactions

var target : Node3D = null
var targetPosition : Vector3 = Vector3.ZERO
var lastTargetPosition : Vector3 = Vector3.ZERO

func _ready() -> void:	
	#hungerGreed = randi_range(5, 15)
	#favouriteFood = FavTypes.values()[randi() % FavTypes.size()]
	favString = FavTypes.keys()[favouriteFood]
	current_hunger = hungerMax
	ChangeState(States.Neutral)
	get_random_position()



func get_SubViewport()->SubViewport:
	return $SubViewport
func get_Sprite2D()->Sprite2D:
	return $Sprite2D
func get_Camera()->Camera3D:
	return $SubViewport/HeadCam




#Gives random target position everytime jump is pressed
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		var random_position := Vector3.ZERO
		random_position.x = randf_range(-9,15.0)
		random_position.z = randf_range(-9,15.0)
		navigation_agent.set_target_position(random_position)

func _physics_process(delta: float) -> void:
	#velocity.y -= gravity * delta thses 2 are to try and make it fall when spawned
	#move_and_slide()
	if not isdead:
		if state == States.Walking or state == States.Pursuit:
			print("Moving towards:", navigation_agent.get_target_position())
			move_to_location(delta)

		if state == States.Pursuit and (target == null or not is_instance_valid(target)):
			print("Lost food target, finding new food...")
			velocity = Vector3.ZERO
			move_and_slide()  # Apply the stop immediately
			navigation_agent.set_target_position(global_position)  # Cancel navigation
			find_food()
			
		stateString = States.keys()[state]#for debugging and billboard
		$Billboard._update()

func _process(_delta: float) -> void:
	if not isdead:
		if current_hunger <= 50 and not isHungry:
			ChangeState(States.Hungry)

func _on_navigation_finished() -> void:
	velocity = Vector3.ZERO 
	if state == States.Pursuit:
			if target != null and global_position.distance_to(target.global_position) < 2 and target.is_in_group("food"):
				_on_mouth_zone_entered(target)  # force interaction when close
	ChangeState(States.Neutral)

#Moves geck to next path position while navigation is not finished
func move_to_location(delta:float)->void:
	if target != null and lastTargetPosition != target.global_position:
		navigation_agent.set_target_position(target.global_position)
		lastTargetPosition = target.global_position
	if navigation_agent.is_navigation_finished():  
		print("nav_finished")
		velocity = Vector3.ZERO  
		return  
	var destination = navigation_agent.get_next_path_position()
	var local_destination = destination - global_position
	var direction = local_destination.normalized()
	
	# 🔄 Rotate only on the Y-axis (prevent flipping)--
	if direction.length() > 0.01:
		var target_basis = Basis().looking_at(direction, Vector3.UP)  
		var target_rotation = target_basis.get_euler()  

		# Lock rotation to Y-axis only (ignore X and Z tilting)--
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
	if not isdead:
		$AnimationPlayer.play("RESET")
		state = newState
		match state:
			States.Neutral:
				target = null
				$WanderTimer.start()
			
			States.Walking: 
				$AnimationPlayer.play("wander")
				
			States.Hungry:
				isHungry = true
				find_food()
				if target:
					ChangeState(States.Pursuit)
			States.Pursuit:
				$AnimationPlayer.play("wander")  # Change to walk animation
				lastTargetPosition = target.global_position
				navigation_agent.set_target_position(target.global_position)  # move to target
			States.Eating:
				$AnimationPlayer.play("eat")
				await $AnimationPlayer.animation_finished

				if nature == Natures.Greedy:
					if current_hunger < 200:
						ChangeState(States.Hungry)
					else:
						isHungry = false
						ChangeState(States.Neutral)
				else:
					if current_hunger <= 60:
						ChangeState(States.Hungry)
					else:
						isHungry = false
						ChangeState(States.Neutral)
			States.Dead:
				isdead = true
				print("dead")
				$AnimationPlayer.play("die")
				emit_signal("Starved")
	print("State:", stateString)

#This is when it makes the "decision" to do next
func _on_wander_timer_timeout() -> void:
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
	hunger_changed.emit(current_hunger)
	if not isdead and state != States.Eating:
		if current_hunger <= -40:
			die()
		if current_hunger >= -40:
			current_hunger -= hungerGreed
		if isHungry and target == null:
			find_food()


func die() -> void:
	ChangeState(States.Dead)

func _on_mouth_zone_entered(body: Node3D) -> void:
	if body not in invalid_targets:# initial check so the body doesnt interact every frame
		invalid_targets.append(body)  # Mark the food as already processed
		if body.is_in_group("food") and body == target:
			if body.has_method("get_fill_amount"):
				target = null 
				ChangeState(States.Eating)
				current_hunger += body.get_fill_amount()
				hunger_changed.emit(current_hunger)
				body.on_eaten() 
		invalid_targets.erase(body)


func find_food() -> void:
	var nearest_food = null
	if food_manager and state != States.Pursuit:
		if nature == Natures.Picky:
			nearest_food = food_manager.get_fav_only(global_position, favouriteFood)
		else:
			nearest_food = food_manager.get_nearest_food(global_position, favouriteFood)
				
		if nearest_food and nearest_food != target:
			target = nearest_food
			ChangeState(States.Pursuit)  #Switch to pursuit and move toward food
			print("Gecko is now pursuing food:", target)
