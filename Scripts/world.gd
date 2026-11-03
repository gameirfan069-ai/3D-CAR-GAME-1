extends Node3D
## Street Legends 3D: open-city driving prototype (Godot 4.4).
## This script owns the world (city, roads, coins, camera) and the game state.
## hud.gd owns all UI.

const PlayerCar = preload("res://scripts/player_car.gd")
const Catalog = preload("res://scripts/car_catalog.gd")
const SaveData = preload("res://scripts/save_data.gd")
const Hud = preload("res://scripts/hud.gd")

const SPAWN := Vector3(0.0, 1.0, 12.0)
const COIN_RESPAWN_SECONDS := 20.0
const COIN_PICKUP_RADIUS := 2.2
const SAVE_EVERY_SECONDS := 10.0

var game: Dictionary = {}
var car: PlayerCar
var cam: Camera3D
var hud
var box_mesh: BoxMesh
var building_mats: Array = []
var coins: Array = []
var coin_mesh: CylinderMesh
var coin_mat: StandardMaterial3D
var dirty := false
var save_timer := 0.0


func _ready() -> void:
	randomize()
	game = SaveData.load_game()
	_setup_input_actions()
	_build_environment()
	_build_roads()
	_build_city()
	_build_props()
	_build_coins()
	_build_car()
	_build_camera()

	hud = Hud.new()
	add_child(hud)
	hud.play_pressed.connect(_on_play)
	hud.menu_pressed.connect(_on_menu)
	hud.buy_pressed.connect(_on_buy)
	hud.select_pressed.connect(_on_select)
	hud.paint_pressed.connect(_on_paint)
	hud.refresh(game)
	hud.show_menu()


func _process(delta: float) -> void:
	_update_coins(delta)
	_update_camera(delta)
	hud.update_speed(car.speed_kmh())
	save_timer -= delta
	if dirty and save_timer <= 0.0:
		_save()
		save_timer = SAVE_EVERY_SECONDS


func _notification(what: int) -> void:
	# Save when the app closes or goes to the background (phones)
	if what in [NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT]:
		if not game.is_empty():
			_save()


# ---------- Setup ----------

func _setup_input_actions() -> void:
	var bindings := {
		"accelerate": [KEY_W, KEY_UP],
		"brake": [KEY_S, KEY_DOWN],
		"steer_left": [KEY_A, KEY_LEFT],
		"steer_right": [KEY_D, KEY_RIGHT],
	}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in bindings[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)


func _build_environment() -> void:
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("#3b74c9")
	sky_material.sky_horizon_color = Color("#b9d7f2")
	sky_material.ground_horizon_color = Color("#b9d7f2")
	sky_material.ground_bottom_color = Color("#2b2f36")
	var sky := Sky.new()
	sky.sky_material = sky_material

	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color("#c4d6e6")
	env.fog_density = 0.0010
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.08
	env.adjustment_saturation = 1.12

	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52.0, -30.0, 0.0)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 160.0
	add_child(sun)


func _build_roads() -> void:
	_block(Vector3(0.0, -0.4, 0.0), Vector3(900.0, 0.5, 900.0), _solid(Color("#3f6e44"), 0.95))
	_block(Vector3(0.0, -0.08, 0.0), Vector3(18.0, 0.2, 650.0), _solid(Color("#2a2f36"), 0.85))
	# Same height as the main road. (The original file used -0.07, which left a 1 cm step that stopped the car.)
	_block(Vector3(0.0, -0.08, -35.0), Vector3(650.0, 0.2, 15.0), _solid(Color("#2a2f36"), 0.85))

	# Curbs with a gap where the cross road passes, so the intersection stays open
	var curb := _solid(Color("#9aa0a6"), 0.9)
	for sx in [-11.0, 11.0]:
		for seg in [[-325.0, -43.0], [-27.0, 325.0]]:
			var z0: float = seg[0]
			var z1: float = seg[1]
			_block(Vector3(sx, 0.07, (z0 + z1) * 0.5), Vector3(4.0, 0.3, z1 - z0), curb)

	var white := _solid(Color("#e8ecf0"), 0.6)
	for sx in [-8.5, 8.5]:
		_block(Vector3(sx, 0.04, 0.0), Vector3(0.25, 0.04, 650.0), white, false)
	var yellow := _solid(Color("#f3d879"), 0.6)
	for z in range(-315, 320, 20):
		_block(Vector3(0.0, 0.04, float(z)), Vector3(0.22, 0.04, 8.0), yellow, false)


func _build_city() -> void:
	box_mesh = BoxMesh.new()
	box_mesh.size = Vector3.ONE  # unit cube, scaled per building
	var window_tex := _make_window_texture()
	var palette := [Color("#8fa3b8"), Color("#c9b99a"), Color("#6f8396"), Color("#dfe5ea"), Color("#9a8fa6"), Color("#b8c4a8")]
	for c in palette:
		var m := StandardMaterial3D.new()
		m.albedo_color = c
		m.albedo_texture = window_tex
		m.roughness = 0.6
		m.uv1_triplanar = true
		m.uv1_world_triplanar = true
		m.uv1_scale = Vector3(0.09, 0.09, 0.09)
		building_mats.append(m)

	for gx in range(-6, 7):
		for gz in range(-15, 16):
			var px := float(gx) * 25.0
			var pz := float(gz) * 22.0
			if absf(px) < 16.0:
				continue  # keep the main road clear
			if absf(pz + 35.0) < 15.0:
				continue  # keep the cross road clear
			if randf() < 0.18:
				continue
			var h := randf_range(8.0, 36.0)
			var size := Vector3(randf_range(9.0, 15.0), h, randf_range(9.0, 14.0))
			_add_building(Vector3(px, h * 0.5, pz), size, building_mats.pick_random())


func _build_props() -> void:
	var trunk_mesh := BoxMesh.new()
	trunk_mesh.size = Vector3(0.6, 2.0, 0.6)
	var trunk_mat := _solid(Color("#62462f"), 0.9)
	var crown_mesh := SphereMesh.new()
	crown_mesh.radius = 2.1
	crown_mesh.height = 4.2
	var crown_mat := _solid(Color("#2f7042"), 0.85)
	var pole_mesh := BoxMesh.new()
	pole_mesh.size = Vector3(0.25, 6.0, 0.25)
	var pole_mat := _solid(Color("#333840"), 0.6)
	var head_mesh := BoxMesh.new()
	head_mesh.size = Vector3(0.9, 0.2, 0.4)
	var lamp_mat := StandardMaterial3D.new()
	lamp_mat.albedo_color = Color("#ffe6a8")
	lamp_mat.emission_enabled = true
	lamp_mat.emission = Color("#ffd27a")
	lamp_mat.emission_energy_multiplier = 1.5

	for z in range(-300, 301, 25):
		for sx in [-15.5, 15.5]:
			_prop(Vector3(sx, 1.0, float(z)), trunk_mesh, trunk_mat, Vector3(0.6, 2.0, 0.6))
			_prop(Vector3(sx, 3.2, float(z)), crown_mesh, crown_mat)
	for z in range(-300, 301, 50):
		for sx in [-10.5, 10.5]:
			_prop(Vector3(sx, 3.0, float(z)), pole_mesh, pole_mat, Vector3(0.25, 6.0, 0.25))
			var head_x: float = sx + (0.4 if sx < 0.0 else -0.4)
			_prop(Vector3(head_x, 5.9, float(z)), head_mesh, lamp_mat)


func _build_coins() -> void:
	coin_mesh = CylinderMesh.new()
	coin_mesh.top_radius = 0.55
	coin_mesh.bottom_radius = 0.55
	coin_mesh.height = 0.12
	coin_mat = StandardMaterial3D.new()
	coin_mat.albedo_color = Color("#ffcc33")
	coin_mat.metallic = 1.0
	coin_mat.roughness = 0.25
	coin_mat.emission_enabled = true
	coin_mat.emission = Color("#ffb300")
	coin_mat.emission_energy_multiplier = 0.35
	for z in range(-280, 281, 40):
		for i in 5:
			_spawn_coin(Vector3(randf_range(-2.5, 2.5), 0.9, float(z) + float(i) * 3.0))


func _build_car() -> void:
	car = PlayerCar.new()
	car.name = "PlayerCar"
	car.position = SPAWN
	car.respawn_position = SPAWN
	add_child(car)
	_apply_selected_car()


func _build_camera() -> void:
	cam = Camera3D.new()
	cam.fov = 68.0
	add_child(cam)
	cam.current = true
	cam.global_position = car.global_transform * Vector3(0.0, 3.0, 8.5)
	cam.look_at(car.global_position + Vector3(0.0, 1.0, 0.0), Vector3.UP)


# ---------- Helpers ----------

func _solid(color: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	return m


func _block(pos: Vector3, size: Vector3, mat: Material, collide := true) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	if collide:
		var body := StaticBody3D.new()
		body.position = pos
		body.add_child(mi)
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = size
		cs.shape = bs
		body.add_child(cs)
		add_child(body)
	else:
		mi.position = pos
		add_child(mi)


func _prop(pos: Vector3, mesh: Mesh, mat: Material, collide_size := Vector3.ZERO) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	if collide_size == Vector3.ZERO:
		mi.position = pos
		add_child(mi)
		return
	var body := StaticBody3D.new()
	body.position = pos
	body.add_child(mi)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = collide_size
	cs.shape = bs
	body.add_child(cs)
	add_child(body)


func _add_building(pos: Vector3, size: Vector3, mat: Material) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var mi := MeshInstance3D.new()
	mi.mesh = box_mesh
	mi.scale = size
	mi.material_override = mat
	body.add_child(mi)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	body.add_child(cs)
	add_child(body)


func _make_window_texture() -> Texture2D:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(1.0, 1.0, 1.0, 1.0))
	var glass := Color(0.16, 0.22, 0.30)
	for y in 64:
		for x in 64:
			var in_window := posmod(x, 16) >= 3 and posmod(x, 16) < 13 and posmod(y, 16) >= 4 and posmod(y, 16) < 13
			if in_window:
				img.set_pixel(x, y, glass)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


func _spawn_coin(pos: Vector3) -> void:
	var holder := Node3D.new()
	holder.position = pos
	var mi := MeshInstance3D.new()
	mi.mesh = coin_mesh
	mi.material_override = coin_mat
	mi.rotation_degrees.x = 90.0  # stand the coin upright, facing the road
	holder.add_child(mi)
	add_child(holder)
	coins.append({"node": holder, "base_y": pos.y, "timer": 0.0})


# ---------- Per-frame ----------

func _update_coins(delta: float) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	for c in coins:
		var holder: Node3D = c["node"]
		if c["timer"] > 0.0:
			c["timer"] -= delta
			if c["timer"] <= 0.0:
				holder.visible = true
			continue
		holder.rotation.y += delta * 2.5
		holder.position.y = float(c["base_y"]) + sin(now * 3.0 + holder.position.z) * 0.12
		if car.active and _near(holder.global_position, car.global_position):
			c["timer"] = COIN_RESPAWN_SECONDS
			holder.visible = false
			game["coins"] = int(game["coins"]) + Catalog.COIN_VALUE
			dirty = true
			hud.refresh(game)
			hud.show_toast("+%d" % Catalog.COIN_VALUE)


func _near(a: Vector3, b: Vector3) -> bool:
	return Vector2(a.x - b.x, a.z - b.z).length() < COIN_PICKUP_RADIUS and absf(a.y - b.y) < 2.5


func _update_camera(delta: float) -> void:
	var target := car.global_transform * Vector3(0.0, 3.0, 8.5)
	cam.global_position = cam.global_position.lerp(target, clampf(delta * 7.0, 0.0, 1.0))
	cam.look_at(car.global_position + Vector3(0.0, 1.0, 0.0), Vector3.UP)
	var speed_ratio := clampf(absf(car.forward_speed) / car.max_speed, 0.0, 1.0)
	cam.fov = lerpf(cam.fov, 66.0 + 12.0 * speed_ratio, clampf(delta * 3.0, 0.0, 1.0))


func _apply_selected_car() -> void:
	var spec := Catalog.by_id(str(game["selected"]))
	var paint: Dictionary = game["paint"]
	var hex: String = paint.get(spec["id"], spec["color"])
	car.set_spec(spec, hex)


func _save() -> void:
	SaveData.save_game(game)
	dirty = false


# ---------- Signals from hud.gd ----------

func _on_play() -> void:
	car.active = true


func _on_menu() -> void:
	car.active = false
	_save()


func _on_buy(id: String) -> void:
	var spec := Catalog.by_id(id)
	var owned: Array = game["owned"]
	if owned.has(id):
		return
	if int(game["coins"]) < int(spec["price"]):
		hud.show_toast("Not enough coins")
		return
	game["coins"] = int(game["coins"]) - int(spec["price"])
	owned.append(id)
	game["owned"] = owned
	game["selected"] = id
	_after_change()


func _on_select(id: String) -> void:
	var owned: Array = game["owned"]
	if owned.has(id):
		game["selected"] = id
		_after_change()


func _on_paint(hex: String) -> void:
	var paint: Dictionary = game["paint"]
	paint[str(game["selected"])] = hex
	_after_change()


func _after_change() -> void:
	_apply_selected_car()
	_save()
	hud.refresh(game)
