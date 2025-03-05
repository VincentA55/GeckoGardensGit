extends CharacterBody3D

enum States {
	Neutral,
	Walking,
	Pursuit,
	Hungry,
	Eating,
	Dead
}

@export var hunger : int = 100
var isHungry : bool = false
signal Hungry
var isdead : bool = false
var isStarving : bool = false
signal Starved
var invalid_targets: Array = []  # List of targets that should be ignored to prevent every frame interactions


@export var walkSpeed : float = 2.0
@export var runSpeed : float = 5.0

@onready var follow_target_3d: FollowTarget3D = $FollowTarget3D
@onready var random_target_3d: RandomTarget3D = $RandomTarget3D

var state : States = States.Walking
var stateString : String
var target : Node3D

func _ready() -> void:	
	ChangeState(States.Neutral)#Just changed this was orignally Walking

func _process(delta: float) -> void:
	if not isdead:
		if not is_on_floor():
			velocity += get_gravity() * delta
		
		if hunger > 50:
			isHungry = false
			ChangeState(States.Neutral)
		elif hunger <= 50:
			isHungry = true
			ChangeState(States.Hungry)
			
		if hunger < 10 and not isStarving:
			isStarving = true
			$GraceTimer.start()#So the Gecko doesnt die immediatly when hunger hits zero
			
			
	stateString = States.keys()[state]#for debugging and billboard
	$Billboard._update()


#This is used the moment a state is changed to prevent the action happening every frame
func ChangeState(newState : States) -> void:
	state = newState
	match state:
		States.Neutral:
			return
		States.Walking:
			$AnimationPlayer.play("wander2")
			$AnimationPlayer.speed_scale = 3
			follow_target_3d.Speed = walkSpeed
			follow_target_3d.SetFixedTarget(random_target_3d.GetNextPoint())
			target = null
		States.Hungry:
			$SimpleVision3D.LookUpGroup = "food"
			find_food()#HERE NOW EATS EVEN WHEN NOT HUNGRY---------------
			if not isHungry:
				$SimpleVision3D.LookUpGroup = "player"
		States.Pursuit:
			$AnimationPlayer.play("walk")
			$AnimationPlayer.speed_scale = 1
			follow_target_3d.Speed = runSpeed
			follow_target_3d.SetTarget(target)
		States.Eating:
			$FollowTarget3D.canMove = false
			$AnimationPlayer.play("eating")
			$AnimationPlayer.speed_scale = 1
			await $AnimationPlayer.animation_finished
			target = null
			follow_target_3d.SetFixedTarget(random_target_3d.GetNextPoint())
			ChangeState(States.Walking)
		States.Dead:
			$SimpleVision3D.Enabled = false
			follow_target_3d.ClearTarget()
	return

#ReachedTarget signal from FollowTarget3D
func _on_follow_target_3d_navigation_finished() -> void:
		follow_target_3d.SetFixedTarget(random_target_3d.GetNextPoint())

#when it sees somthing
func _on_simple_vision_3d_get_sight(body: Node3D) -> void:
	target = body
	ChangeState(States.Pursuit)

func _on_simple_vision_3d_lost_sight() -> void:
	if not isdead:
		ChangeState(States.Walking)

func _on_hunger_timer_timeout() -> void:
	if not isdead:
		if hunger >= 0:
			hunger -= 10
			print(hunger)

func _on_grace_timer_timeout() -> void:
	if hunger <= 0:
		die()
	elif isStarving:
		isStarving = false

func die() -> void:
	ChangeState(States.Dead)
	$AnimationPlayer.play("die")
	isdead = true
	emit_signal("Starved")

func _on_mouth_zone_entered(body: Node3D) -> void:
	if body not in invalid_targets:# initial check so the body doesnt interact every frame
		invalid_targets.append(body)  # Mark the food as already processed
		if body.is_in_group("food") and body == target:
			if body.has_method("get_fill_amount"):
				ChangeState(States.Eating)
				hunger += body.get_fill_amount() 
				$FollowTarget3D.canMove = true
				body.on_eaten()

#changes its target from null or something else to "food"
func find_food()->void:
	if target == null or not target.is_in_group("food") :
		follow_target_3d.SetFixedTarget(random_target_3d.GetNextPoint())
	
	
	
#------------------------------------WORKINGON EHEHERERERE---------------------
