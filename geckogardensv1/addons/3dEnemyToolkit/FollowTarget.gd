extends NavigationAgent3D
class_name FollowTarget3D

signal ReachedTarget(target : Node3D)

enum States {
	Neutral,
	Walking,
	Pursuit,
	Hungry,
	Eating,
	Dead
}
@export var Speed : float = 5.0
@export var TurnSpeed : float = 0.3
@export var ReachTargetMinDistance : float = 2

@export var WanderRange : float = 10.0
@export var MinWanderWait : float = 1.0
@export var MaxWanderWait : float = 2

var startPosition : Vector3


var target : Node3D
var isTargetSet : bool = false
var targetPosition : Vector3 = Vector3.ZERO
var lastTargetPosition : Vector3 = Vector3.ZERO
var fixedTarget : bool = false
var isdead : bool = false
var canMove : bool = true

@onready var wanderTimer = Timer.new()
@onready var parent = get_parent() as CharacterBody3D

func _ready() -> void:
	velocity_computed.connect(_on_velocity_computed)

func _process(delta: float) -> void:
	var state = get_parent_state()
	if not isdead:
		match state:
			States.Neutral:
				avoidance_enabled = false
				handle_neutral_state()#HEREGERE---------------------------------------------------
			States.Walking:
				pass
			States.Hungry:
				handle_target_state()#HEREGERE-------------------
				pass
			States.Pursuit:
				avoidance_enabled = true
				pass
			States.Eating:
				velocity = Vector3(0,0,0)
				Speed = 0
			States.Dead:
				isdead = true
	if canMove:
		parent.move_and_slide()
		handle_target_state()
	
func SetFixedTarget(newTarget : Vector3) -> void:
	target = null
	targetPosition = newTarget
	fixedTarget = true
	isTargetSet = true

func SetTarget(newTarget : Node3D) -> void:
	target = newTarget
	targetPosition = Vector3.ZERO
	fixedTarget = false
	isTargetSet = true

func ClearTarget() -> void:
	target = null
	targetPosition = Vector3.ZERO
	isTargetSet = false
	
func go_to_location(targetPosition : Vector3):
	if not isTargetSet or lastTargetPosition != targetPosition:
		set_target_position(targetPosition)
		lastTargetPosition = targetPosition
		isTargetSet = true
		
	var lookDir = atan2(-parent.velocity.x, -parent.velocity.z)
	parent.rotation.y = lerp_angle(parent.rotation.y, lookDir, TurnSpeed)
	
	if is_navigation_finished():
		isTargetSet = false
		return
	
	var nextPathPosition = get_next_path_position()
	var currentTPosition = parent.global_position
	var newVelocity = (nextPathPosition - currentTPosition).normalized() * Speed
	
	if avoidance_enabled:
		set_velocity(newVelocity.move_toward(newVelocity, 0.25))
	else:
		parent.velocity = newVelocity.move_toward(newVelocity, 0.25)

func _on_velocity_computed(safe_velocity: Vector3) -> void:
	parent.velocity = parent.velocity.move_toward(safe_velocity, 0.25)

func _on_gecko_starved() -> void:
	isdead = true
	target = null
	isTargetSet = false
	canMove = false

func stopMoving(time : int)-> void:
	$StopMovingTimer.wait_time = time
	canMove = false
	$StopMovingTimer.start()

func _on_stop_moving_timer_timeout() -> void:
	canMove = true


#ALL BELOW IS NEW AND UNTESTED-------------------------------------------
func get_parent_state() -> int:
	if parent and "state" in parent:
		return parent.state
	return 0

#The idea is; this is for any state that has a target ie:pursuit, hungry, etc
func handle_target_state() -> void:
	if target != null:
		if fixedTarget:
			go_to_location(targetPosition)
		elif target:
			go_to_location(target.global_position)
			if target and parent.global_position.distance_to(target.global_position) <= ReachTargetMinDistance:
				emit_signal("ReachedTarget", target)
	else:
		start_wandering()

func handle_neutral_state() -> void:
	if not isTargetSet:
		start_wandering()

func start_wandering() -> void:
	SetFixedTarget($"../RandomTarget3D".GetNextPoint())
	

func _on_wander_timer_timeout() -> void:
	if get_parent_state() == States.Neutral:
		start_wandering()
