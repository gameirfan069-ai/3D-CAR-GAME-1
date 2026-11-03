extends RefCounted
## Car data. Prices are in game coins.
## top = max speed (m/s, 34 m/s is about 122 km/h), accel = acceleration,
## turn = steering power, length/width/height/cabin_* = body proportions in metres.
## Car names are brand names taken from the brief. Rename or license them before
## publishing anywhere (see README).

const FREE_START_CAR := "street_coupe"
const START_COINS := 20000
const COIN_VALUE := 250

const PAINTS := ["#1f5fbf", "#b71c1c", "#ffd600", "#f2f2f2", "#0b0b0d", "#c0c4c8", "#2e7d32", "#ff6f00"]

const CARS := [
	{"id": "street_coupe", "name": "Street Coupe", "price": 0, "color": "#e34f36",
		"top": 34.0, "accel": 24.0, "turn": 1.55,
		"length": 4.2, "width": 1.9, "height": 1.3, "cabin_len": 2.0, "cabin_h": 0.55, "cabin_z": 0.1, "spoiler": false},
	{"id": "m4", "name": "BMW M4", "price": 45000, "color": "#1f5fbf",
		"top": 38.0, "accel": 26.0, "turn": 1.7,
		"length": 4.7, "width": 1.9, "height": 1.35, "cabin_len": 2.1, "cabin_h": 0.6, "cabin_z": 0.25, "spoiler": true},
	{"id": "amg_gt", "name": "Mercedes-AMG GT", "price": 60000, "color": "#c0c4c8",
		"top": 40.0, "accel": 27.0, "turn": 1.6,
		"length": 4.55, "width": 1.95, "height": 1.28, "cabin_len": 2.0, "cabin_h": 0.55, "cabin_z": 0.2, "spoiler": false},
	{"id": "911", "name": "Porsche 911", "price": 75000, "color": "#b71c1c",
		"top": 42.0, "accel": 28.0, "turn": 1.8,
		"length": 4.5, "width": 1.85, "height": 1.3, "cabin_len": 2.0, "cabin_h": 0.55, "cabin_z": 0.3, "spoiler": true},
	{"id": "m1", "name": "BMW M1", "price": 90000, "color": "#f2f2f2",
		"top": 41.0, "accel": 26.0, "turn": 1.75,
		"length": 4.3, "width": 1.9, "height": 1.14, "cabin_len": 1.9, "cabin_h": 0.45, "cabin_z": 0.1, "spoiler": false},
	{"id": "r8", "name": "Audi R8", "price": 90000, "color": "#0b0b0d",
		"top": 44.0, "accel": 29.0, "turn": 1.75,
		"length": 4.45, "width": 1.95, "height": 1.24, "cabin_len": 1.9, "cabin_h": 0.5, "cabin_z": 0.3, "spoiler": false},
	{"id": "huracan", "name": "Lamborghini Huracan", "price": 150000, "color": "#ffd600",
		"top": 48.0, "accel": 31.0, "turn": 1.9,
		"length": 4.5, "width": 2.0, "height": 1.2, "cabin_len": 1.8, "cabin_h": 0.45, "cabin_z": 0.35, "spoiler": true},
]


static func by_id(id: String) -> Dictionary:
	for car in CARS:
		if car["id"] == id:
			return car
	return CARS[0]
