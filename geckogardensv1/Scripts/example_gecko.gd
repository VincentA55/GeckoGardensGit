extends CharacterBody3D

enum States {
	Walking,
	Pursuit,
	Hungry,
	Eating,
	Dead
}

@export var hunger : int = 1000
var isdead : bool = false
signal Starved
var invalid_targets: Array = []  # List of targets that should be ignored to prevent every frame interactions


@export var walkSpeed : float = 2.0
@export var runSpeed : float = 5.0

@onready var follow_target_3d: FollowTarget3D = $FollowTarget3D
@onready var random_target_3d: RandomTarget3D = $RandomTarget3D

var state : States = States.Walking
var target : Node3D

func _ready() -> void:	
	ChangeState(States.Walking)

func _process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

func ChangeState(newState : States) -> void:
	state = newState
	match state:
		States.Walking:
			$AnimationPlayer.play("wander2")
			$AnimationPlayer.speed_scale = 3
			follow_target_3d.ClearTarget()
			follow_target_3d.Speed = walkSpeed
			follow_target_3d.SetFixedTarget(random_target_3d.GetNextPoint())
			target = null
		States.Pursuit:
			$AnimationPlayer.play("walk")
			$AnimationPlayer.speed_scale = 1
			follow_target_3d.Speed = runSpeed
			follow_target_3d.SetTarget(target)
		States.Eating:
			$AnimationPlayer.play("eating")
			$AnimationPlayer.speed_scale = 0.2
			await $AnimationPlayer.animation_finished
			follow_target_3d.ClearTarget()
			target = null
		States.Dead:
			$SimpleVision3D.Enabled = false
			follow_target_3d.ClearTarget()
			return

func _on_follow_target_3d_navigation_finished() -> void:
		follow_target_3d.SetFixedTarget(random_target_3d.GetNextPoint())

func _on_simple_vision_3d_get_sight(body: Node3D) -> void:
	target = body
	ChangeState(States.Pursuit)

func _on_simple_vision_3d_lost_sight() -> void:
	ChangeState(States.Walking)

func _on_hunger_timer_timeout() -> void:
	if hunger >= 10:
		hunger -= 10
		print(hunger)
	elif hunger < 10 and not isdead:
		die()
		isdead = true
		emit_signal("Starved")


func die() -> void:
	ChangeState(States.Dead)
	$AnimationPlayer.play("die")


func _on_mouth_zone_entered(body: Node3D) -> void:
	if body not in invalid_targets:# initial check so the body doesnt interact every frame
		invalid_targets.append(body)  # Mark the food as already processed
		
		if body.is_in_group("food"):
			if body.has_method("get_fill_amount"):
				$AnimationPlayer.play("eating")
				$AnimationPlayer.speed_scale = 1
				await $AnimationPlayer.animation_finished  # Ensure it has a fill value method
				ChangeState(States.Eating)
				hunger += body.get_fill_amount() 
				body.on_eaten()
