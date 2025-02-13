extends Camera3D

@export var move_speed := 10.0
@export var look_sensitivity := 0.005

var is_right_clicking := false
var rotation_x := 0.0  # For vertical look

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)  # Keep mouse free initially

func _input(event):
	# Detect right-click press
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			is_right_clicking = event.pressed
			if is_right_clicking:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)  # Lock cursor
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)  # Unlock cursor

	# Handle mouse movement when right-clicking
	if is_right_clicking and event is InputEventMouseMotion:
		rotate_camera(event.relative)

func _process(delta):
	# Move camera when right-clicking
	if is_right_clicking:
		move_camera(delta)

func rotate_camera(mouse_movement: Vector2):
	rotation_x -= mouse_movement.y * look_sensitivity
	rotation_x = clamp(rotation_x, -1.5, 1.5)  # Limit vertical rotation

	rotate_y(-mouse_movement.x * look_sensitivity)
	$Camera3D.rotation.x = rotation_x

func move_camera(delta):
	var move_dir = Vector3.ZERO
	
	if Input.is_action_pressed("ui_up"):    move_dir += -transform.basis.z  # Forward
	if Input.is_action_pressed("ui_down"):  move_dir += transform.basis.z   # Backward
	if Input.is_action_pressed("ui_left"):  move_dir += -transform.basis.x  # Left
	if Input.is_action_pressed("ui_right"): move_dir += transform.basis.x   # Right
	
	move_dir = move_dir.normalized()
	position += move_dir * move_speed * delta
