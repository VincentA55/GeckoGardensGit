extends Node

# Scene to instantiate when dropping food
@export var geck_scene: PackedScene
@export var food_scene: PackedScene  

@onready var food_manager = $FoodManager  # Reference to FoodManager
@onready var hud = $HUD  # Reference to HUD

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("spawn_food"):
		var food = food_scene.instantiate()
		get_parent().add_child(food)
		food.global_position = get_viewport().get_camera_3d().project_position(get_viewport().get_mouse_position(), 10)

		food_manager.add_food(food)  # Register food in FoodManager

		# 🔥 Connect the "eaten" signal to both FoodManager and HUD
		food.connect("eaten", Callable(food_manager, "_on_food_eaten").bind(food))
		food.connect("eaten", Callable(hud, "remove_food_ui").bind(food.get_instance_id()))

		print("Food spawned:", food.typeString)
