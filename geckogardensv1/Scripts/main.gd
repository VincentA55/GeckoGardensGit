extends Node

# Scene to instantiate when dropping food
@export var geck_scene: PackedScene
@export var food_scene: PackedScene  

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed:
		var food = food_scene.instantiate()
		get_parent().add_child(food)
		food.global_transform.origin = get_viewport().get_camera_3d().project_position(event.position, 10)
		
