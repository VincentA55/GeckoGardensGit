extends Node3D
class_name SimpleVision3D

signal GetSight(body : Node3D)
signal LostSight

@export var Enabled : bool = true
@export var LookUpGroup : String = "food"

@export_category("Vision Area")
@export var Distance : float = 50.0
@export var BaseWidth : float = 10.0
@export var EndWidth : float = 30.0
@export var BaseHeight : float = 5.0
@export var EndHeight : float = 5.0
@export var BaseConeSize : float = 1.0
@export var VisionArea : CollisionShape3D

var vision : Area3D
var target : Node3D

var visible_vision_mesh: MeshInstance3D  # The visual representation of the vision area

func _ready() -> void:
	vision = Area3D.new()
	if not VisionArea:
		VisionArea = CollisionShape3D.new()
		VisionArea.shape = __BuildVisionShape()	
	vision.add_child(VisionArea)
	add_child(vision)
	
		# Create a visible mesh instance--------MAYBENOTNEDDED
	visible_vision_mesh = MeshInstance3D.new()
	visible_vision_mesh.mesh = __BuildVisionMesh()
	visible_vision_mesh.global_position = global_position  # Align with node
	add_child(visible_vision_mesh)
	
	var test_cube = MeshInstance3D.new()
	test_cube.mesh = BoxMesh.new()
	test_cube.global_position = global_position
	add_child(test_cube)

	print("Vision Mesh Added:", visible_vision_mesh.mesh)  # Debug log
	if visible_vision_mesh.mesh == null:
		print("⚠️ Vision Mesh NOT created!")
	else:
		print("✅ Vision Mesh successfully created!")

func _process(delta: float) -> void:
	if not Enabled:
		return
		
	if target:
		if not CheckSight(target):
			target = null
			emit_signal("LostSight")
	else:
		CheckOverlaping()

func CheckSight(sightTarget : Node3D) -> bool:
	var space = get_world_3d().direct_space_state
	var ignore : Array[RID] = []	
	var query = PhysicsRayQueryParameters3D.create(global_position, sightTarget.global_position)
	var collision = space.intersect_ray(query)
	if collision:
		if collision.collider == sightTarget:
			return true
	return false

func CheckOverlaping():
	var overlapingBodies = vision.get_overlapping_bodies()
	var targetOverlap = overlapingBodies.filter(func(item : Node3D) : return item.is_in_group(LookUpGroup))
	if len(targetOverlap) > 0:
		if CheckSight(targetOverlap[0]):
			target = targetOverlap[0]
			emit_signal("GetSight", target)

func __BuildVisionShape() -> ConvexPolygonShape3D:
	var result = ConvexPolygonShape3D.new()
	var points = PackedVector3Array()
	points.append(Vector3(0, 0, 0))
	points.append(Vector3(BaseHeight/2, 0, -BaseConeSize))
	points.append(Vector3(EndWidth/2, 0, -Distance))
	points.append(Vector3(-(BaseHeight/2), 0, -BaseConeSize))
	points.append(Vector3(-(EndWidth/2), 0, -Distance))
	points.append(Vector3(0, BaseHeight, 0))	
	points.append(Vector3(BaseHeight/2, BaseHeight, -BaseConeSize))
	points.append(Vector3(EndWidth/2, BaseHeight, -Distance))
	points.append(Vector3(-(BaseHeight/2), BaseHeight, -BaseConeSize))
	points.append(Vector3(-(EndWidth/2), BaseHeight, -Distance))	    
	result.points = points
	return result

#notworking ------------------------------MAYBENEOTNEEDED
func __BuildVisionMesh() -> ArrayMesh:
	var mesh = ArrayMesh.new()
	var surface_array = []
	for i in range(Mesh.ARRAY_MAX):
		surface_array.append([])

	# Use the same points as the vision shape
	var points = PackedVector3Array([
		Vector3(0, 0, 0),
		Vector3(BaseHeight / 2, 0, -BaseConeSize),
		Vector3(EndWidth / 2, 0, -Distance),
		Vector3(-(BaseHeight / 2), 0, -BaseConeSize),
		Vector3(-(EndWidth / 2), 0, -Distance),
		Vector3(0, BaseHeight, 0),
		Vector3(BaseHeight / 2, BaseHeight, -BaseConeSize),
		Vector3(EndWidth / 2, BaseHeight, -Distance),
		Vector3(-(BaseHeight / 2), BaseHeight, -BaseConeSize),
		Vector3(-(EndWidth / 2), BaseHeight, -Distance)
	])

	surface_array[Mesh.ARRAY_VERTEX] = points

	# Define the triangle faces for the mesh
	surface_array[Mesh.ARRAY_INDEX] = PackedInt32Array([
		0, 1, 2,  # Bottom triangle 1
		0, 2, 3,  # Bottom triangle 2
		0, 3, 4,  # Bottom triangle 3
		0, 4, 1,  # Bottom triangle 4
		5, 6, 7,  # Top triangle 1
		5, 7, 8,  # Top triangle 2
		5, 8, 9,  # Top triangle 3
		5, 9, 6,  # Top triangle 4
		1, 6, 7,  # Side 1
		1, 7, 2,  # Side 2
		2, 7, 8,  # Side 3
		2, 8, 3,  # Side 4
		3, 8, 9,  # Side 5
		3, 9, 4,  # Side 6
		4, 9, 6,  # Side 7
		4, 6, 1   # Side 8
	])

	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)

	# Apply a transparent material for visibility
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0, 1, 0, 0.3)  # Green, semi-transparent
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.surface_set_material(0, material)

	return mesh

func _on_gecko_hungry() -> void:
	LookUpGroup = "food"
