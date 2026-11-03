extends RefCounted
## Saves coins, owned cars, selected car and paint colours to user://street_legends.cfg

const Catalog = preload("res://scripts/car_catalog.gd")
const PATH := "user://street_legends.cfg"


static func load_game() -> Dictionary:
	var data := {
		"coins": Catalog.START_COINS,
		"owned": [Catalog.FREE_START_CAR],
		"selected": Catalog.FREE_START_CAR,
		"paint": {},
	}
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return data
	data["coins"] = int(cfg.get_value("player", "coins", data["coins"]))
	data["owned"] = cfg.get_value("player", "owned", data["owned"])
	data["selected"] = cfg.get_value("player", "selected", data["selected"])
	data["paint"] = cfg.get_value("player", "paint", data["paint"])
	return data


static func save_game(data: Dictionary) -> int:
	var cfg := ConfigFile.new()
	cfg.set_value("player", "coins", data["coins"])
	cfg.set_value("player", "owned", data["owned"])
	cfg.set_value("player", "selected", data["selected"])
	cfg.set_value("player", "paint", data["paint"])
	return cfg.save(PATH)
