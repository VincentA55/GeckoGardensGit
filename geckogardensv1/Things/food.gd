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



func get_fill_amount() -> int:
	return fill_amount


func on_eaten()-> void:
	#$AnimationPlayer.play("eaten")
	eaten.emit(fill_amount)
	
