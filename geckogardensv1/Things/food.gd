extends Node3D

signal eaten

@export var fill_amount: int = 40
@export var food_scene: PackedScene  

enum Types{
	Sweet,
	Salty,
	Spicy,
	Plain
}

var type : Types
var typeString : String 
var foodName : String = "TestFood"

func _ready():
	type = Types.values()[randi() % Types.size()]  # Pick a random type, for testing
	typeString = Types.keys()[type]#for debugging 

#checks if a CharacterBody3D has touched the food
#connected to the body_entered signal of the Area3D node
func _on_area_3d_body_entered(body):
	if body is CharacterBody3D:
		eaten.emit(fill_amount)
		$AnimationPlayer.play("eaten")
		await $AnimationPlayer.animation_finished
		

func get_fill_amount() -> int:
	return fill_amount


func on_eaten()-> void:
	eaten.emit(fill_amount)
	$AnimationPlayer.play("eaten")
	await $AnimationPlayer.animation_finished
	
