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




func _ready():
	type = Types.values()[randi() % Types.size()]  # Pick a random type, for testing
	typeString = Types.keys()[type]#for debugging 

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
	
