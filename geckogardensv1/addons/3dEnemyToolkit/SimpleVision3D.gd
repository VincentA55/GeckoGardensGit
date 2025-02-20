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
		# Make the mesh transparent
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1, 1, 1, 0.3)  # White color with 30% opacity
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA  # Enable transparency
	material.cull_mode = BaseMaterial3D.CULL_BACK  # Optional: Prevents weird rendering issues
	visible_vision_mesh.set_surface_override_material(0, material)
	
	#add_child(visible_vision_mesh)
	

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
	
	var radius = 30.0
	var height = 10.0
	var num_segments = 16  # The more segments, the smoother the cylinder
	
	# Generate bottom circle points
	for i in range(num_segments):
		var angle = i * TAU / num_segments
		points.append(Vector3(radius * cos(angle), 0, radius * sin(angle)))

	# Generate top circle points
	for i in range(num_segments):
		var angle = i * TAU / num_segments
		points.append(Vector3(radius * cos(angle), height, radius * sin(angle)))

	# Add the center points for the top and bottom circles to help define faces
	points.append(Vector3(0, 0, 0))       # Center of bottom circle
	points.append(Vector3(0, height, 0))  # Center of top circle

	result.points = points
	return result


func __BuildVisionMesh() -> CylinderMesh:
	var mesh = CylinderMesh.new()
	mesh.set_top_radius(30.0)   # Correct method to set radius
	mesh.set_bottom_radius(30.0)  # Both top and bottom should match for a cylinder
	mesh.set_height(10.0)       # Correct method to set height
	mesh.set_radial_segments(16) # Matches the convex shape
	
	
	return mesh


func _on_gecko_hungry() -> void:
	LookUpGroup = "food"
