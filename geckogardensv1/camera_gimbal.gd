extends Node3D

@export var target: NodePath

@export_range(0.0, 2.0, 0.01) var rotation_speed: float = PI / 2

# Mouse properties
@export var mouse_control: bool = true
@export_range(0.001, 0.1, 0.001) var mouse_sensitivity: float = 0.005
@export var invert_y: bool = false
@export var invert_x: bool = false

# Zoom settings
@export var max_zoom: float = 3.0
@export var min_zoom: float = 0.4
@export_range(0.05, 1.0, 0.01) var zoom_speed: float = 0.09

var zoom = 1.5

func _process(delta):
	$InnerGimbal.rotation.x = clamp($InnerGimbal.rotation.x, -1.4, -0.01)
	scale = lerp(scale, Vector3.ONE * zoom, zoom_speed)
	if target:
		global_transform.origin = get_node(target).global_transform.origin

func _unhandled_input(event):
	if event.is_action_pressed("move_cam"):#Moves the camera when the right click is held
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			mouse_control = true
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if event.is_action_released("move_cam"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			mouse_control = false
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		

	if event.is_action_pressed("cam_zoom_in"):
		zoom -= zoom_speed
	if event.is_action_pressed("cam_zoom_out"):
		zoom += zoom_speed
	zoom = clamp(zoom, min_zoom, max_zoom)
	if mouse_control and event is InputEventMouseMotion:
		if event.relative.x != 0:
			var dir = 1 if invert_x else -1
			rotate_object_local(Vector3.UP, dir * event.relative.x * mouse_sensitivity)
		if event.relative.y != 0:
			var dir = 1 if invert_y else -1
			var y_rotation = clamp(event.relative.y, -30, 30)
			$InnerGimbal.rotate_object_local(Vector3.RIGHT, dir * y_rotation * mouse_sensitivity)
