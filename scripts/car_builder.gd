extends RefCounted
## Builds a stylised car from primitives. Local space: ground at y = 0, nose toward -Z.
## Placeholder look only. Replace with original optimised .glb models later (see README).

const CLEARANCE := 0.12


static func build(spec: Dictionary, paint_hex: String) -> Node3D:
	var root := Node3D.new()
	root.name = "Visual"
	var length: float = spec["length"]
	var width: float = spec["width"]
	var height: float = spec["height"]
	var cab_len: float = spec["cabin_len"]
	var cab_h: float = spec["cabin_h"]
	var cab_z: float = spec["cabin_z"]

	var paint := _mat(Color(paint_hex), 0.18, 0.7)
	var glass := _mat(Color("#0b1520"), 0.05, 0.9)
	var trim := _mat(Color("#16181d"), 0.7, 0.0)
	var tire := _mat(Color("#101113"), 0.95, 0.0)
	var rim := _mat(Color("#9aa3ad"), 0.3, 0.9)
	var head := _lamp(Color("#fff1c2"), 2.2)
	var tail := _lamp(Color("#ff2a2a"), 1.8)

	var body_h := height * 0.42
	var body_top := CLEARANCE + body_h

	# Main body, cabin and a paint-coloured roof panel
	_box(root, Vector3(width, body_h, length), Vector3(0.0, CLEARANCE + body_h * 0.5, 0.0), paint)
	_box(root, Vector3(width * 0.82, cab_h, cab_len), Vector3(0.0, body_top + cab_h * 0.5, cab_z), glass)
	_box(root, Vector3(width * 0.74, 0.05, cab_len * 0.85), Vector3(0.0, body_top + cab_h + 0.025, cab_z), paint)

	# Front splitter, grille, side skirts, headlights and taillights
	_box(root, Vector3(width * 0.9, 0.06, 0.2), Vector3(0.0, CLEARANCE * 0.6, -length * 0.5), trim)
	_box(root, Vector3(width * 0.5, body_h * 0.4, 0.05), Vector3(0.0, CLEARANCE + body_h * 0.4, -length * 0.5 - 0.01), trim)
	for sx in [-1.0, 1.0]:
		_box(root, Vector3(0.06, 0.14, length * 0.6), Vector3(sx * (width * 0.5 + 0.02), CLEARANCE * 0.6, 0.0), trim)
		_box(root, Vector3(width * 0.26, 0.1, 0.06), Vector3(sx * width * 0.3, CLEARANCE + body_h * 0.55, -length * 0.5 - 0.01), head)
		_box(root, Vector3(width * 0.26, 0.1, 0.06), Vector3(sx * width * 0.3, CLEARANCE + body_h * 0.55, length * 0.5 + 0.01), tail)

	# Rear spoiler on sporty models
	if spec["spoiler"]:
		_box(root, Vector3(width * 0.9, 0.05, 0.28), Vector3(0.0, body_top + 0.12, length * 0.5 - 0.2), trim)
		for sx in [-1.0, 1.0]:
			_box(root, Vector3(0.05, 0.12, 0.05), Vector3(sx * width * 0.35, body_top + 0.06, length * 0.5 - 0.2), trim)

	# Four wheels touching the ground at y = 0
	var radius := height * 0.27
	for sx in [-1.0, 1.0]:
		for zf in [-1.0, 1.0]:
			_wheel(root, Vector3(sx * (width * 0.5 - 0.02), radius, zf * length * 0.31), radius, 0.3, tire, rim)
	return root


static func _mat(color: Color, rough: float, metal: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.metallic = metal
	return m


static func _lamp(color: Color, energy: float) -> StandardMaterial3D:
	var m := _mat(color, 0.2, 0.0)
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	return m


static func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)


static func _wheel(parent: Node3D, pos: Vector3, radius: float, width: float, tire: Material, rim: Material) -> void:
	var hub := Node3D.new()
	hub.position = pos
	parent.add_child(hub)

	var tire_mesh := CylinderMesh.new()
	tire_mesh.top_radius = radius
	tire_mesh.bottom_radius = radius
	tire_mesh.height = width
	var tire_node := MeshInstance3D.new()
	tire_node.mesh = tire_mesh
	tire_node.material_override = tire
	tire_node.rotation_degrees.z = 90.0
	hub.add_child(tire_node)

	var rim_mesh := CylinderMesh.new()
	rim_mesh.top_radius = radius * 0.6
	rim_mesh.bottom_radius = radius * 0.6
	rim_mesh.height = width + 0.02
	var rim_node := MeshInstance3D.new()
	rim_node.mesh = rim_mesh
	rim_node.material_override = rim
	rim_node.rotation_degrees.z = 90.0
	hub.add_child(rim_node)
