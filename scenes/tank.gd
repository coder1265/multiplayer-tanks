class_name Tank
extends CharacterBody2D

@export var hull: TankPart
@export var turret: TankPart
@export var extra_part: TankPart

@onready var turret_pivot: Node2D = $TurretPivot
@onready var vision_area: Area2D = $VisionArea
@onready var sync: MultiplayerSynchronizer = $MultiplayerSynchronizer

var stats: Dictionary = {}
var health: float
var max_health: float
var current_extra: Extra

@export var peer_id: int = 1:
	set(value):
		peer_id = value
		set_multiplayer_authority(value)

func _ready() -> void:
	_apply_loadout()
	health = max_health

	if not is_multiplayer_authority():
		return

	# Only the controlling client runs its own camera/input
	$Camera2D.enabled = true
	_spawn_extra()

func _apply_loadout() -> void:
	stats = {}
	for part in [hull, turret, extra_part]:
		if part == null:
			continue
		for key in part.stat_mods:
			stats[key] = stats.get(key, 0.0) + part.stat_mods[key]
	max_health = stats.get("health", 100.0)

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return

	_handle_movement(delta)
	_handle_turret_aim()

	if Input.is_action_just_pressed("use_extra"):
		_request_use_extra()

func _handle_movement(delta: float) -> void:
	var input_dir := Input.get_axis("move_left", "move_right")
	var turn_speed: float = stats.get("turn_rate", 2.0)
	rotation += input_dir * turn_speed * delta

	var forward := Input.get_axis("move_back", "move_forward")
	var speed: float = stats.get("speed", 120.0)
	velocity = Vector2.UP.rotated(rotation) * forward * speed
	move_and_slide()

func _handle_turret_aim() -> void:
	# Rotates toward the mouse locally; only meaningful for the authority's own tank
	turret_pivot.global_rotation = turret_pivot.global_position.angle_to_point(get_global_mouse_position()) + PI / 2

func _spawn_extra() -> void:
	if extra_part == null or extra_part.extra_scene == null:
		return
	current_extra = extra_part.extra_scene.instantiate()
	$ExtraMount.add_child(current_extra)

func _request_use_extra() -> void:
	rpc_id(1, "server_use_extra")

@rpc("any_peer", "call_local", "reliable")
func server_use_extra() -> void:
	if not multiplayer.is_server():
		return
	if get_multiplayer_authority() != multiplayer.get_remote_sender_id() and multiplayer.get_remote_sender_id() != 0:
		return  # ignore spoofed calls from someone else's tank
	if current_extra:
		current_extra.on_pressed(self)

# Called by repair zones, host-side only
func heal(amount: float) -> void:
	health = minf(health + amount, max_health)

func take_damage(amount: float) -> void:
	if not multiplayer.is_server():
		return
	var armour: float = stats.get("armour", 0.0)
	var mitigated: float = maxf(amount - armour, amount * 0.1)
	health -= mitigated
	if health <= 0.0:
		queue_free()  # or a respawn routine, given your respawn-timing host setting
