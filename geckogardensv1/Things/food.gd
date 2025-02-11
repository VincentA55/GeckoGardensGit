extends Node3D

signal eaten

@export var fill_amount: int = 40
@export var food_scene: PackedScene  
 
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
	queue_free()
