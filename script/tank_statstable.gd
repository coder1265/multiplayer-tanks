class_name TankStatsTable
extends RefCounted

## Hull contributes: health, armour, movement_speed, rotation_speed.
## Barrel contributes: fire_rate, damage, range.

const HULL_STATS := [
	{
		"health": 100,
		"armour": 10,
		"movement_speed": 120,
		"rotation_speed": 90
	}
]

const BARREL_STATS := [
	{ "fire_rate": 1.0, "damage": 25, "range": 400 },  # barrel_1 - balanced
	{ "fire_rate": 0.6, "damage": 45, "range": 550 },  # barrel_2 - heavy, slow-firing, long range
	{ "fire_rate": 1.6, "damage": 12, "range": 300 },  # barrel_3 - rapid-fire, short range
]

static func get_hull_stats(hull_type: int) -> Dictionary:
	return HULL_STATS[hull_type]

static func get_barrel_stats(barrel_type: int) -> Dictionary:
	return BARREL_STATS[barrel_type]

static func get_combined_stats(hull_type: int, barrel_type: int) -> Dictionary:
	var stats := get_hull_stats(hull_type).duplicate()
	stats.merge(get_barrel_stats(barrel_type))
	return stats
