extends Control

signal loadout_confirmed(loadout: Tankloadout)

@onready var hull_preview = %Hullpreview
@onready var barrel_preview = %Barrelpreview
@onready var bullet_preview = %Bulletpreview
@onready var stats_label = %Statslabel
@onready var color_option = %Colour_option
@onready var hull_option = %Hull_option
@onready var barrel_option = %Barrel_option
@onready var extra_option = %Extra_option

var loadout := Tankloadout.new()



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_populate_option_buttons()
	color_option.item_selected.connect(_on_color_selected)
	hull_option.item_selected.connect(_on_hull_selected)
	barrel_option.item_selected.connect(_on_barrel_selected)
	extra_option.item_selected.connect(_on_extra_selected)
	%Confirm.pressed.connect(_on_confirm_pressed)
	_update_preview()

func _populate_option_buttons() -> void:
	color_option.clear()
	for color_key in Tankloadout.COLOUR_NAMES.keys():
		color_option.add_item(Tankloadout.COLOUR_NAMES[color_key].capitalize())
 
	hull_option.clear()
	for i in Tankloadout.HULL_TYPE_COUNT:
		hull_option.add_item("Hull %d" % (i + 1))
 
	barrel_option.clear()
	for i in Tankloadout.BARREL_TYPE_COUNT:
		barrel_option.add_item("Barrel %d" % (i + 1))
 
	extra_option.clear()
	for extra_key in Tankloadout.EXTRA_NAMES.keys():
		extra_option.add_item(Tankloadout.EXTRA_NAMES[extra_key])

func _on_color_selected(index: int) -> void:
	loadout.colour = index as Tankloadout.TankColour
	_update_preview()
 
 
func _on_hull_selected(index: int) -> void:
	loadout.hull_type = index
	_update_preview()
 
 
func _on_barrel_selected(index: int) -> void:
	loadout.barrel_type = index
	_update_preview()
 
 
func _on_extra_selected(index: int) -> void:
	loadout.extra_type = index as Tankloadout.ExtraType
	_update_preview()
 
 
func _update_preview() -> void:
	hull_preview.texture = load(loadout.get_hull_texture_path())
	barrel_preview.texture = load(loadout.get_barrel_texture_path())
	bullet_preview.texture = load(loadout.get_bullet_texture_path())
	stats_label.text = _format_stats_bbcode(loadout.get_stats())
 
 
func _format_stats_bbcode(stats: Dictionary) -> String:
	return "[b]Stats[/b]\n" \
		+ "Health: %d\n" % stats.health \
		+ "Armour: %d\n" % stats.armour \
		+ "Movement Speed: %d\n" % stats.movement_speed \
		+ "Rotation Speed: %d°/s\n" % stats.rotation_speed \
		+ "Fire Rate: %.1f/s\n" % stats.fire_rate \
		+ "Damage: %d\n" % stats.damage \
		+ "Range: %d\n" % stats.range
 
 
func _on_confirm_pressed() -> void:
	loadout_confirmed.emit(loadout)
	# Wire this to the same RPC pattern as the lobby's host-only settings,
	# sending loadout.to_dict() to the host.
