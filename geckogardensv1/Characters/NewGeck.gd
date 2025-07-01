extends CharacterBody3D


@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D

var gravity = 150
# This variable will hold the "safe" velocity calculated by the agent.
var safe_velocity = Vector3.ZERO

@export var gecko_mesh : MeshInstance3D
@export var selfie_cam : Camera3D

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
signal died
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
	navigation_agent.velocity_computed.connect(_on_navigation_agent_velocity_computed)

#Set the layers for the selfie cam ui
func set_layer(layer_number: int)->void:
	var unique_layer_bitmask = 1 << (layer_number - 1)
	gecko_mesh.layers = 1 | unique_layer_bitmask
	selfie_cam.cull_mask = unique_layer_bitmask
	pass

func get_SubViewport()->SubViewport:
	return $HeadViewport
func get_Mesh()->MeshInstance3D:
	return $Pivot/Gecko11/Armature/Skeleton3D/Sphere

func randomize_Colour():
	var mesh = get_Mesh()
	if not mesh:
		return
	# This is often needed to make sure the surface override is not blocked.
	mesh.material_override = null
	var mat := StandardMaterial3D.new()
	# Set the albedo to a completely random color.
	mat.albedo_color = Color(randf(), randf(), randf())
	mesh.set_surface_override_material(0, mat)

#Gives random target position everytime jump is pressed
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		var random_position := Vector3.ZERO
		random_position.x = randf_range(-9,15.0)
		random_position.z = randf_range(-9,15.0)
		navigation_agent.set_target_position(random_position)

#receives the safe velocity from the agent.
func _on_navigation_agent_velocity_computed(new_safe_velocity: Vector3):
	safe_velocity = new_safe_velocity
	
# Your current _physics_process, modified to use avoidance.

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	var desired_velocity = Vector3.ZERO

	if not isdead:
		if state == States.Walking or state == States.Pursuit:
			# Get the IDEAL movement velocity from our helper function.
			desired_velocity = update_movement_and_rotation(delta)
			
		navigation_agent.set_velocity(desired_velocity)

		# The agent processes our desired_velocity, adds avoidance, and emits the
		# `velocity_computed` signal, which updates our `safe_velocity` variable.
		velocity.x = safe_velocity.x
		velocity.z = safe_velocity.z
		
		# Logic for when a target is lost 
		if state == States.Pursuit and not is_instance_valid(target):
			navigation_agent.set_target_position(global_position)
			find_food()

		# Update Billboard/Debug info
		stateString = States.keys()[state]
		$Billboard._update()
	else:
		# If dead, ensure the character stops moving
		navigation_agent.set_velocity(Vector3.ZERO)
		velocity.x = 0
		velocity.z = 0
		
	#uses the velocity that has been corrected for avoidance.
	move_and_slide()

func _process(_delta: float) -> void:
	if not isdead:
		if current_hunger <= 50 and not isHungry:
			ChangeState(States.Hungry)
			
	hunger_changed.emit(current_hunger, hungerMax)

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
		#print("nav_finished")
		velocity = Vector3.ZERO  
		return  
	var destination = navigation_agent.get_next_path_position()
	var local_destination = destination - global_position
	var direction = local_destination.normalized()
	
	#Rotate only on the Y-axis (prevent flipping)--
	if direction.length() > 0.01:
		var target_basis = Basis().looking_at(direction, Vector3.UP)  
		var target_rotation = target_basis.get_euler()  

		#Lock rotation to Y-axis only (ignore X and Z tilting)--
		var flat_rotation = Vector3(0, target_rotation.y, 0)  

		rotation.y = lerp_angle(rotation.y, flat_rotation.y, delta * 10.0)
	
	velocity = direction * walkSpeed
	move_and_slide() 

#calculates rotation and returns the desired horizontal velocity.
func update_movement_and_rotation(delta: float) -> Vector3:
	if target != null and lastTargetPosition != target.global_position:
		navigation_agent.set_target_position(target.global_position)
		lastTargetPosition = target.global_position

	if navigation_agent.is_navigation_finished():
		return Vector3.ZERO

	var destination = navigation_agent.get_next_path_position()
	var direction = (destination - global_position).normalized()


	#Create a flattened copy of the direction vector for rotation.
	var flat_direction = direction
	flat_direction.y = 0

	#Only perform the look_at if there is a horizontal direction.
	#This prevents a "zero-vector" error if the next point is directly above or below.
	if flat_direction.length() > 0:
		#Use the FLATTENED vector for rotation.
		#This ensures the gecko only ever turns left or right, never tilts.
		look_at(global_position + flat_direction, Vector3.UP)


	#Return the ORIGINAL direction vector for movement.
	#This is important so the gecko can walk up and down slopes correctly.
	return direction * walkSpeed

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
				hunger_changed.emit(current_hunger)
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
				$AnimationPlayer.play("die")
				await $AnimationPlayer.animation_finished
				died.emit(self)
	#print("State:", stateString)

#This is when it makes the "decision" to do next
func _on_wander_timer_timeout() -> void:
	if state == States.Neutral:
		perform_wander_action()

#Recieves the choice as a string and does it
func perform_wander_action():
	var action = choose_wander_action()
	$AnimationPlayer.play("RESET")
	#print("Gecko chose: ", action)  # Debugging

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
	if not isdead and state != States.Eating:
		hunger_changed.emit(current_hunger)
		#print(name, " TIMOUT hunger is now ", current_hunger) # <-- DEBUG
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
				
				body.on_eaten() 
		invalid_targets.erase(body)


func find_food() -> void:
	var nearest_food = null
	if FoodManagerScript and state != States.Pursuit:
		if nature == Natures.Picky:
			nearest_food = FoodManagerScript.get_fav_only(global_position, favouriteFood)
		else:
			nearest_food = FoodManagerScript.get_nearest_food(global_position, favouriteFood)
				
		if nearest_food and nearest_food != target:
			target = nearest_food
			ChangeState(States.Pursuit)  #Switch to pursuit and move toward food
			#print("Gecko is now pursuing food:", target)

# --- 1. ADD THIS TO YOUR STATES ENUM ---
# enum States { Walking, Pursuit, Following, ... } # Add "Following"


# --- 2. ADD THESE VARIABLES AT THE TOP OF YOUR SCRIPT ---
# This will hold a reference to the gecko we are following.
var following_target: CharacterBody3D = null

# Add a Timer node named "FollowTimer" to your gecko scene in the editor.
# Make sure its "One Shot" property is checked ON.
@onready var follow_timer = $FollowTimer


# --- 3. ADD THIS PUBLIC FUNCTION TO START FOLLOWING ---
# Call this function from another script to make this gecko follow another one.
func follow_gecko(gecko_to_follow: CharacterBody3D, duration: float):
	# Don't try to follow nothing or yourself.
	if not is_instance_valid(gecko_to_follow) or gecko_to_follow == self:
		return

	print(self.name + " is now following " + gecko_to_follow.name)
	state = States.Following
	following_target = gecko_to_follow
	
	# Set the timer and start it.
	follow_timer.wait_time = duration
	follow_timer.start()


# --- 4. ADD THIS FUNCTION TO HANDLE THE TIMER'S TIMEOUT ---
# Connect the "timeout()" signal from your FollowTimer node to this function
# in the editor (Node tab -> Signals).
func _on_follow_timer_timeout():
	# The timer has finished, so we stop following.
	if state == States.Following:
		print(self.name + " stopped following.")
		following_target = null
		
		# Give the gecko a new purpose.
		# This will automatically switch its state to Pursuit.
		find_food()
