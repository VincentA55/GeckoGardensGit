extends Node

# Scene to instantiate when dropping food
@export var geck_scene: PackedScene
@export var food_scene: PackedScene  


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("spawn_food"):
		var food = food_scene.instantiate()
		get_parent().add_child(food)
		food.global_position = get_viewport().get_camera_3d().project_position(get_viewport().get_mouse_position(), 10)
		$FoodManager.add_food(food)  # Register the food in FoodManager
		print(food.typeString)
