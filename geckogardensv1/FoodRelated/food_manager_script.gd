extends Node

const food_scene: PackedScene = preload("res://FoodRelated/food.tscn") 
var food_items: Array[Node3D] = []  # Stores all food objects
const hud: PackedScene = preload("res://UserInterface/hud.tscn")  

# Add food to the list
func add_food(type: int) -> Node3D:
	var food = food_scene.instantiate().getSpecificType(type)
	get_parent().add_child(food)
	food_items.append(food)
	#print("Adding food: ", food)
	#print("Calling HUD: ", hud)

	food.connect("eaten", Callable(self, "_on_food_eaten").bind(food))  # Connect the "eaten" signal to the handler method "_on_food_eaten"
	#	# Update HUD UI
	if Hud:
		Hud.add_food_ui(food.foodName,food.typeString, food.get_instance_id())
	return food


func remove_food(food: Node3D) -> void:
	if food in food_items:
		Hud.remove_food_ui(food.get_instance_id())
		food_items.erase(food)
		if is_instance_valid(food):
			food.queue_free()
	#print("remove_food:", food)


func get_nearest_food(from_position: Vector3, fav_type: int) -> Node3D:
	var nearest_fav: Node3D = null
	var shortest_fav_distance := INF

	# First: Search ONLY for favourite type
	for food in food_items:
		if food == null or not is_instance_valid(food):
			continue
		if food.getType() == fav_type:
			var dist = from_position.distance_to(food.global_position)
			if dist < shortest_fav_distance:
				nearest_fav = food
				shortest_fav_distance = dist

	# If a favourite is found, return it
	if nearest_fav != null:
		return nearest_fav

	# Otherwise, search for any available food
	var nearest_any: Node3D = null
	var shortest_any_distance := INF

	for food in food_items:
		if food == null or not is_instance_valid(food):
			continue
		var dist = from_position.distance_to(food.global_position)
		if dist < shortest_any_distance:
			nearest_any = food
			shortest_any_distance = dist

	return nearest_any

#Find func for greedy
func get_fav_only(from_position: Vector3, fav_type: int) -> Node3D:
	var nearest_fav: Node3D = null
	var shortest_fav_distance := INF

	# First: Search ONLY for favourite type
	for food in food_items:
		if food == null or not is_instance_valid(food):
			continue
		if food.getType() == fav_type:
			var dist = from_position.distance_to(food.global_position)
			if dist < shortest_fav_distance:
				nearest_fav = food
				shortest_fav_distance = dist
	return nearest_fav


# Handle the signal when the food is eaten
func _on_food_eaten(food: Node3D) -> void:
		#print("_on_food_eaten: ", food)
	# Remove the food from the list
		if food in food_items:
			food_items.erase(food)
		# Remove from HUD UI
		if Hud:
			Hud.remove_food_ui(food.get_instance_id())
		food.queue_free()  # Free the food object
