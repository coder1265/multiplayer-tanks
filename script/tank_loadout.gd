class_name Tankloadout
extends Resource

enum TankColour { RED, BLUE, GRAY, SAND }
enum ExtraType { NONE, MINES, ROCKETS, SMOKE }

const COLOUR_NAMES := {
	TankColour.RED: "red",
	TankColour.BLUE: "blue",
	TankColour.GRAY: "dark",
	TankColour.SAND: "sand",
}
const EXTRA_NAMES := {
	ExtraType.NONE: "none",
	ExtraType.MINES: "mines",
	ExtraType.ROCKETS: "rockets",
	ExtraType.SMOKE: "smoke",
}
const TANK_ASSET_DIR := "res://Assets/Default size/"
const HULL_PATH_FMT := TANK_ASSET_DIR + "tankBody_%s.png"
const BARREL_PATH_FMT := TANK_ASSET_DIR + "tank%s_barrel%d.png"
const BULLET_PATH_FMT := TANK_ASSET_DIR + "bullet%s%d.png"
const HULL_TYPE_COUNT := 1 #change as game develops
const BARREL_TYPE_COUNT := 3  #change as game develops

@export var colour: TankColour = TankColour.BLUE
@export_range(0,0) var hull_type: int = 0
@export_range(0,2) var barrel_type: int = 0
@export var extra_type: ExtraType = ExtraType.NONE

func get_colour_name() -> String:
	return COLOUR_NAMES[colour]

func get_hull_texture_path() -> String:
	return HULL_PATH_FMT % [get_colour_name()]

func get_barrel_texture_path() -> String:
	return BARREL_PATH_FMT % [get_colour_name_capitalized(), barrel_type + 1]

func get_bullet_texture_path() -> String:
	return BULLET_PATH_FMT % [get_colour_name_capitalized(), barrel_type + 1]

func get_colour_name_capitalized() -> String:
	return get_colour_name().capitalize()

func get_stats() -> Dictionary:
	return TankStatsTable.get_combined_stats(hull_type,barrel_type)

func to_dict() -> Dictionary:
	return {
		"colour": colour,
		"hull_type": hull_type,
		"barrel_type": barrel_type,
		"extra_type": extra_type,
	}

static func from_dict(data: Dictionary) -> Tankloadout:
	var loadout := Tankloadout.new()
	loadout.colour = data.get("color", TankColour.RED)
	loadout.hull_type = data.get("hull_type", 0)
	loadout.barrel_type = data.get("barrel_type", 0)
	loadout.extra_type = data.get("extra_type", ExtraType.NONE)
	return loadout
