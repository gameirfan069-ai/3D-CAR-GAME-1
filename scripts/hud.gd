extends CanvasLayer
## All UI: main menu, showroom (dealership + garage), driving HUD and touch controls.

signal play_pressed
signal menu_pressed
signal buy_pressed(car_id: String)
signal select_pressed(car_id: String)
signal paint_pressed(paint_hex: String)

const Catalog = preload("res://scripts/car_catalog.gd")
const CarBuilder = preload("res://scripts/car_builder.gd")

var game: Dictionary = {}
var mode := "shop"           # "shop" or "garage"
var driving := false
var viewing_id := ""        # car shown on the turntable
var touch_zones := {}       # zone name -> Rect2 as screen fractions (x, y, w, h)
var zone_labels := {}
var touch_panels := {}
var touch_map := {}         # finger index -> zone name
var holds := {}             # action name -> fingers holding it
var toast_time := 0.0

var menu_root: Control
var coin_labels: Array = []
var showroom_root: Control
var showroom_title: Label
var showroom_list: VBoxContainer
var showroom_stats: Label
var paint_row: HBoxContainer
var preview_pivot: Node3D
var drive_root: Control
var touch_root: Control
var car_label: Label
var speed_label: Label
var toast: Label


func _ready() -> void:
	layer = 10
	touch_zones = {
		"steer_left": Rect2(0.02, 0.56, 0.16, 0.40),
		"steer_right": Rect2(0.20, 0.56, 0.16, 0.40),
		"brake": Rect2(0.64, 0.56, 0.16, 0.40),
		"accelerate": Rect2(0.82, 0.56, 0.16, 0.40),
	}
	zone_labels = {"steer_left": "LEFT", "steer_right": "RIGHT", "brake": "BRAKE", "accelerate": "GAS"}
	_build_menu()
	_build_showroom()
	_build_drive()
	_build_preview()


func _process(delta: float) -> void:
	if toast_time > 0.0:
		toast_time -= delta
		toast.modulate.a = clampf(toast_time * 2.0, 0.0, 1.0)
	if driving:
		for zone_name in touch_panels:
			touch_panels[zone_name].modulate.a = 1.0 if Input.is_action_pressed(zone_name) else 0.5
	if showroom_root.visible:
		preview_pivot.rotation.y += delta * 0.6


# ---------- Public API (called by world.gd) ----------

func refresh(data: Dictionary) -> void:
	game = data
	var text := "COINS  " + commas(int(game["coins"]))
	for label in coin_labels:
		label.text = text
	car_label.text = Catalog.by_id(str(game["selected"]))["name"]
	if showroom_root.visible:
		_refresh_showroom()


func update_speed(kmh: float) -> void:
	speed_label.text = "%d km/h" % roundi(kmh)


func show_toast(text: String) -> void:
	toast.text = text
	toast_time = 1.2


func show_menu() -> void:
	driving = false
	_release_all()
	menu_root.visible = true
	showroom_root.visible = false
	drive_root.visible = false


func show_showroom(new_mode: String) -> void:
	mode = new_mode
	driving = false
	_release_all()
	menu_root.visible = false
	drive_root.visible = false
	showroom_root.visible = true
	showroom_title.text = "DEALERSHIP" if mode == "shop" else "GARAGE"
	paint_row.visible = mode == "garage"
	viewing_id = str(game["selected"])
	_refresh_showroom()


# ---------- Menu ----------

func _build_menu() -> void:
	menu_root = Control.new()
	_full_rect(menu_root)
	add_child(menu_root)

	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.04, 0.06, 0.72)
	_full_rect(dim)
	menu_root.add_child(dim)

	var center := CenterContainer.new()
	_full_rect(center)
	menu_root.add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	center.add_child(box)

	var title := Label.new()
	title.text = "STREET LEGENDS 3D"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 46)
	title.add_theme_color_override("font_color", Color("#ffae2a"))
	box.add_child(title)

	var menu_coins := _label(24, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(menu_coins)
	coin_labels.append(menu_coins)

	var drive_btn := _button("DRIVE", Vector2(300, 58))
	drive_btn.pressed.connect(_on_drive_pressed)
	box.add_child(drive_btn)
	var shop_btn := _button("DEALERSHIP", Vector2(300, 58))
	shop_btn.pressed.connect(show_showroom.bind("shop"))
	box.add_child(shop_btn)
	var garage_btn := _button("GARAGE", Vector2(300, 58))
	garage_btn.pressed.connect(show_showroom.bind("garage"))
	box.add_child(garage_btn)


func _on_drive_pressed() -> void:
	driving = true
	menu_root.visible = false
	showroom_root.visible = false
	drive_root.visible = true
	play_pressed.emit()


func _on_menu_pressed() -> void:
	show_menu()
	menu_pressed.emit()


# ---------- Showroom (dealership + garage) ----------

func _build_showroom() -> void:
	showroom_root = Control.new()
	_full_rect(showroom_root)
	add_child(showroom_root)

	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.06, 0.08, 0.97)
	_full_rect(dim)
	showroom_root.add_child(dim)

	var margin := MarginContainer.new()
	_full_rect(margin)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 24)
	showroom_root.add_child(margin)

	var vbox := VBoxContainer.new()
	margin.add_child(vbox)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 20)
	vbox.add_child(top)
	var back := _button("BACK", Vector2(120, 44))
	back.pressed.connect(show_menu)
	top.add_child(back)
	showroom_title = _label(28, HORIZONTAL_ALIGNMENT_LEFT)
	top.add_child(showroom_title)
	var coins_here := _label(22, HORIZONTAL_ALIGNMENT_RIGHT)
	coins_here.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(coins_here)
	coin_labels.append(coins_here)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 20)
	vbox.add_child(body)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(580, 0)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(scroll)
	showroom_list = VBoxContainer.new()
	showroom_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	showroom_list.add_theme_constant_override("separation", 8)
	scroll.add_child(showroom_list)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(right)
	preview_container_slot = right  # filled by _build_preview()
	showroom_stats = _label(20, HORIZONTAL_ALIGNMENT_LEFT)
	right.add_child(showroom_stats)
	paint_row = HBoxContainer.new()
	paint_row.add_theme_constant_override("separation", 10)
	right.add_child(paint_row)

	showroom_root.visible = false


var preview_container_slot: Control


func _build_preview() -> void:
	var container := SubViewportContainer.new()
	container.stretch = true
	container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_container_slot.add_child(container)
	preview_container_slot.move_child(container, 0)

	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	viewport.size = Vector2i(900, 560)
	container.add_child(viewport)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#1b2029")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.65, 0.7)
	env.ambient_light_energy = 0.8
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	viewport.add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35.0, 35.0, 0.0)
	viewport.add_child(sun)

	var cam := Camera3D.new()
	cam.position = Vector3(2.6, 1.5, 4.2)
	viewport.add_child(cam)
	cam.current = true
	cam.look_at(Vector3(0.0, 0.6, 0.0), Vector3.UP)

	preview_pivot = Node3D.new()
	viewport.add_child(preview_pivot)


func _refresh_showroom() -> void:
	_clear(showroom_list)
	_clear(paint_row)
	var owned: Array = game["owned"]
	var selected := str(game["selected"])
	for car in Catalog.CARS:
		var id: String = car["id"]
		var is_owned: bool = owned.has(id)
		if mode == "garage" and not is_owned:
			continue
		showroom_list.add_child(_car_row(car, is_owned, id == selected))
	if mode == "garage":
		for hex in Catalog.PAINTS:
			var swatch := Button.new()
			swatch.custom_minimum_size = Vector2(54, 40)
			swatch.focus_mode = Control.FOCUS_NONE
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color(hex)
			sb.set_corner_radius_all(8)
			for st in ["normal", "hover", "pressed", "focus"]:
				swatch.add_theme_stylebox_override(st, sb)
			swatch.pressed.connect(_on_paint_button.bind(hex))
			paint_row.add_child(swatch)
	_show_turntable(viewing_id)


func _car_row(car: Dictionary, is_owned: bool, is_selected: bool) -> Control:
	var id: String = car["id"]
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var name_btn := _button("%s  -  %s" % [car["name"], _price_text(car, is_owned)], Vector2(0, 48))
	name_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_btn.pressed.connect(_show_turntable.bind(id))
	row.add_child(name_btn)

	var action := _button("", Vector2(150, 48))
	if mode == "shop" and not is_owned:
		action.text = "BUY"
		action.pressed.connect(_on_buy_button.bind(id))
	else:
		action.text = "SELECTED" if is_selected else "SELECT"
		action.disabled = is_selected
		action.pressed.connect(_on_select_button.bind(id))
	row.add_child(action)
	return row


func _price_text(car: Dictionary, is_owned: bool) -> String:
	if is_owned:
		return "OWNED"
	return "%s coins" % commas(int(car["price"]))


func _show_turntable(id: String) -> void:
	viewing_id = id
	var car := Catalog.by_id(id)
	var paint: Dictionary = game["paint"]
	var hex: String = paint.get(id, car["color"])
	_clear(preview_pivot)
	preview_pivot.add_child(CarBuilder.build(car, hex))
	showroom_stats.text = _stats_text(car)


func _stats_text(car: Dictionary) -> String:
	return "%s\n\nTop speed     %s  %d km/h\nAcceleration  %s\nHandling      %s" % [
		car["name"],
		_bar(float(car["top"]), 30.0, 50.0), roundi(float(car["top"]) * 3.6),
		_bar(float(car["accel"]), 20.0, 32.0),
		_bar(float(car["turn"]), 1.4, 2.0),
	]


func _bar(value: float, lo: float, hi: float) -> String:
	var n := clampi(roundi((value - lo) / (hi - lo) * 10.0), 1, 10)
	var s := ""
	for i in 10:
		s += "#" if i < n else "-"
	return "[" + s + "]"


func _on_buy_button(id: String) -> void:
	buy_pressed.emit(id)


func _on_select_button(id: String) -> void:
	select_pressed.emit(id)


func _on_paint_button(hex: String) -> void:
	paint_pressed.emit(hex)


# ---------- Driving HUD and touch controls ----------

func _build_drive() -> void:
	drive_root = Control.new()
	_full_rect(drive_root)
	drive_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(drive_root)

	var menu_btn := _button("MENU", Vector2(110, 40))
	menu_btn.position = Vector2(16, 16)
	menu_btn.pressed.connect(_on_menu_pressed)
	drive_root.add_child(menu_btn)

	car_label = _label(22, HORIZONTAL_ALIGNMENT_CENTER)
	_place(car_label, 0.0, 0.0, 1.0, 0.0, 0, 14, 0, 46)
	drive_root.add_child(car_label)

	var coins_hud := _label(22, HORIZONTAL_ALIGNMENT_RIGHT)
	_place(coins_hud, 1.0, 0.0, 1.0, 0.0, -340, 16, -16, 46)
	drive_root.add_child(coins_hud)
	coin_labels.append(coins_hud)

	speed_label = _label(38, HORIZONTAL_ALIGNMENT_CENTER)
	_place(speed_label, 0.5, 1.0, 0.5, 1.0, -160, -96, 160, -30)
	drive_root.add_child(speed_label)

	toast = _label(34, HORIZONTAL_ALIGNMENT_CENTER)
	toast.add_theme_color_override("font_color", Color("#ffcc33"))
	_place(toast, 0.5, 0.0, 0.5, 0.0, -200, 60, 200, 110)
	toast.modulate.a = 0.0
	drive_root.add_child(toast)

	# Touch overlay: only shown on touch screens
	touch_root = Control.new()
	_full_rect(touch_root)
	touch_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	touch_root.visible = DisplayServer.is_touchscreen_available()
	drive_root.add_child(touch_root)
	for zone_name in touch_zones:
		var r: Rect2 = touch_zones[zone_name]
		var panel := Panel.new()
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(1.0, 1.0, 1.0, 0.14)
		sb.border_color = Color(1.0, 1.0, 1.0, 0.5)
		sb.set_border_width_all(3)
		sb.set_corner_radius_all(18)
		panel.add_theme_stylebox_override("panel", sb)
		_place(panel, r.position.x, r.position.y, r.end.x, r.end.y, 0, 0, 0, 0)
		touch_root.add_child(panel)
		var text := _label(26, HORIZONTAL_ALIGNMENT_CENTER)
		text.text = zone_labels[zone_name]
		text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_full_rect(text)
		panel.add_child(text)
		touch_panels[zone_name] = panel


func _input(event: InputEvent) -> void:
	if not driving:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_down(event.index, _zone_at(event.position))
		else:
			_touch_up(event.index)
	elif event is InputEventScreenDrag:
		_touch_move(event.index, _zone_at(event.position))


func _zone_at(pos: Vector2) -> String:
	var view := get_viewport().get_visible_rect().size
	for zone_name in touch_zones:
		var r: Rect2 = touch_zones[zone_name]
		if Rect2(r.position * view, r.size * view).has_point(pos):
			return zone_name
	return ""


func _touch_down(index: int, zone_name: String) -> void:
	if zone_name == "":
		return
	_touch_up(index)
	touch_map[index] = zone_name
	_hold(zone_name, 1)


func _touch_up(index: int) -> void:
	if touch_map.has(index):
		var zone_name: String = touch_map[index]
		touch_map.erase(index)
		_hold(zone_name, -1)


func _touch_move(index: int, zone_name: String) -> void:
	if not touch_map.has(index) or touch_map[index] == zone_name:
		return
	_touch_up(index)
	_touch_down(index, zone_name)


func _hold(action: String, change: int) -> void:
	var count: int = holds.get(action, 0) + change
	if count > 0:
		holds[action] = count
		Input.action_press(action)
	else:
		holds.erase(action)
		Input.action_release(action)


func _release_all() -> void:
	for action in holds.keys():
		Input.action_release(action)
	holds.clear()
	touch_map.clear()


# ---------- Small helpers ----------

static func commas(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "," + out
	return ("-" if n < 0 else "") + out


func _full_rect(c: Control) -> void:
	c.set_anchors_preset(Control.PRESET_FULL_RECT)


func _place(c: Control, ax0: float, ay0: float, ax1: float, ay1: float, l: float, t: float, r: float, b: float) -> void:
	c.anchor_left = ax0
	c.anchor_top = ay0
	c.anchor_right = ax1
	c.anchor_bottom = ay1
	c.offset_left = l
	c.offset_top = t
	c.offset_right = r
	c.offset_bottom = b


func _label(font_size: int, align: HorizontalAlignment) -> Label:
	var l := Label.new()
	l.horizontal_alignment = align
	l.add_theme_font_size_override("font_size", font_size)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Dark outline keeps HUD text readable over bright buildings and sky
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 6)
	return l


func _button(text: String, min_size: Vector2) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 20)
	return b


func _clear(box: Node) -> void:
	for child in box.get_children():
		box.remove_child(child)
		child.queue_free()
