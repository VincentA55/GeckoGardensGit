extends Node

# Load the scene file from the path and store it as a PackedScene blueprint.
const gecko_scene: PackedScene = preload("res://Characters/new_geck.tscn")
var current_geckos: Array[Node3D] = []

# Optional spawn area or positions
@export var spawn_positions: Array[Node3D] = []  # Assign Position3D nodes in editor
signal geckoAdded(gecko)


func spawn_rand_gecko() -> void:
	if gecko_scene == null:
		print("Gecko scene not assigned!")
		return

	var gecko = gecko_scene.instantiate()
	
	#sets the geckos favfood and nature randomly
	gecko.favouriteFood = gecko.FavTypes.values()[randi() % gecko.FavTypes.size()]
	gecko.nature = gecko.Natures.values()[randi() % gecko.Natures.size()]
	gecko.randomize_Colour()
	
	add_child(gecko)
	#geckoAdded.emit(gecko)
	Hud._on_gecko_added(gecko)
	
	# Set random spawn position by adding markers to the geckomanager in main
	if spawn_positions.size() > 0:
		var spawn_point = spawn_positions[randi() % spawn_positions.size()]
		gecko.global_transform.origin = spawn_point.global_transform.origin
	else:
		gecko.global_position = Vector3(randf() * 10, 0, randf() * 10)  # fallback

	current_geckos.append(gecko)



func remove_gecko(gecko: Node3D) -> void:
	if gecko in current_geckos:
		current_geckos.erase(gecko)
		gecko.queue_free()

#this is for spawning specific geckos 
func spawn_specific_gecko(fav: int, nature :int)-> void: 
	var gecko = gecko_scene.instantiate()
	
	#sets the geckos favfood and nature randomly
	gecko.favouriteFood = fav
	gecko.nature = nature
	
	add_child(gecko)
	

	# Set random spawn position by adding markers to the geckomanager in main
	if spawn_positions.size() > 0:
		var spawn_point = spawn_positions[randi() % spawn_positions.size()]
		gecko.global_transform.origin = spawn_point.global_transform.origin
	else:
		gecko.global_position = Vector3(randf() * 10, 0, randf() * 10)  # fallback

	current_geckos.append(gecko)
	
	
	pass
