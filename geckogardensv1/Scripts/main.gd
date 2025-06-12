extends Node






func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("click"):
		#var food = food_manager.add_food(2)  # Register food in FoodManager
		#food.global_position = get_viewport().get_camera_3d().project_position(get_viewport().get_mouse_position(), 10)
#
		##Connect the "eaten" signal to both FoodManager and HUD
		#food.connect("eaten", Callable(food_manager, "_on_food_eaten").bind(food))
		#food.connect("eaten", Callable(hud, "remove_food_ui").bind(food.get_instance_id()))
#
		#print("Food spawned:", food.typeString)
		
		GeckoManagerScript.spawn_rand_gecko()
		if GeckoManagerScript.current_geckos.size() > 0:
			GeckoManagerScript.current_geckos[-1].global_position = get_viewport().get_camera_3d().project_position(get_viewport().get_mouse_position(), 10)
