extends Node3D

signal eaten

@export var fill_amount: int = 40
@export var food_scene: PackedScene  
@onready var food_manager = get_node("/root/Main/FoodManager")


enum Types{
	Sweet,
	Salty,
	Spicy,
	Plain
}

var type : Types
var typeString : String 
var foodName : String = "TestFood"


func _ready() -> void:
	#getRandomType()
	pass

func getRandomType():
	type = Types.values()[randi() % Types.size()]
	typeString = Types.keys()[type]

	var mesh = $character  # Change to your actual mesh path
	if mesh == null:
		print("Mesh not found")
		return

	var mat := StandardMaterial3D.new()

	match type:
		Types.Sweet:
			mat.albedo_color = Color(1.0, 0.4, 0.7)
		Types.Salty:
			mat.albedo_color = Color(0.4, 0.6, 1.0)
		Types.Spicy:
			mat.albedo_color = Color(1.0, 0.3, 0.0)
		Types.Plain:
			mat.albedo_color = Color(0.8, 0.8, 0.8)

	mesh.set_surface_override_material(0, mat)
	return self

func getSpecificType(type: int):
	type = type
	typeString = Types.keys()[type]

	var mesh = $character  # Change to your actual mesh path
	if mesh == null:
		print("Mesh not found")
		return

	var mat := StandardMaterial3D.new()

	match type:
		Types.Sweet:
			mat.albedo_color = Color(1.0, 0.4, 0.7)
		Types.Salty:
			mat.albedo_color = Color(0.4, 0.6, 1.0)
		Types.Spicy:
			mat.albedo_color = Color(1.0, 0.3, 0.0)
		Types.Plain:
			mat.albedo_color = Color(0.8, 0.8, 0.8)

	mesh.set_surface_override_material(0, mat)
	return self



func _process(delta: float) -> void:
	if global_position.y < -10: 
		food_manager.remove_food(self)

func get_fill_amount() -> int:
	return fill_amount

func on_eaten()-> void:
	$AnimationPlayer.play("eaten")
	await $AnimationPlayer.animation_finished
	eaten.emit(fill_amount)
	food_manager._on_food_eaten(self)
	
