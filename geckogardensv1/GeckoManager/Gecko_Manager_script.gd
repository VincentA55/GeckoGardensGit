extends Node

# Load the scene file from the path and store it as a PackedScene blueprint.
const gecko_scene: PackedScene = preload("res://Characters/new_geck.tscn")
var current_geckos: Array[Node3D] = []

# This tracks the next visibility layer to assign.
var next_available_layer: int = 10
const MAX_LAYER: int = 20

# Optional spawn area or positions
@export var spawn_positions: Array[Node3D] = []  # Assign Position3D nodes in editor
signal geckoAdded(gecko)


func spawn_rand_gecko() -> void:
	if gecko_scene == null:
		print("Gecko scene not assigned!")
		return

	if next_available_layer > MAX_LAYER:
		printerr("Cannot spawn new gecko: Maximum render layer reached.")
	
	var gecko = gecko_scene.instantiate()
	
	#sets the geckos favfood and nature randomly
	gecko.favouriteFood = gecko.FavTypes.values()[randi() % gecko.FavTypes.size()]
	gecko.nature = gecko.Natures.values()[randi() % gecko.Natures.size()]
	gecko.randomize_Colour()
	gecko.set_layer(next_available_layer)
	#increment the layer for the next spawn.
	next_available_layer += 1
	
	add_child(gecko)
	#geckoAdded.emit(gecko)
	gecko.died.connect(Callable(self, "remove_gecko"))
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
		await get_tree().create_timer(0.5).timeout
		current_geckos.erase(gecko)
		gecko.queue_free()
		next_available_layer -= 1

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
