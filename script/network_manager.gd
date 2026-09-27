extends Node

const PORT = 8888
const DISCOVERY_PORT = 8889
const DISCOVERY_TIMEOUT = 1.5 # seconds to wait for a host to respond

var peer = ENetMultiplayerPeer.new()
var players := {}
signal player_list_changed
enum State { OFFLINE, HOSTING, CONNECTED }
var state: State
signal state_changed
signal connection_error(message: String)
signal chat_message_recieved(id: int, text: String)

var discovery_listener := PacketPeerUDP.new() # host uses this to answer discovery pings

func _ready():
	state = State.OFFLINE

func _process(_delta):
	# host: answer any discovery pings that come in
	if state == State.HOSTING and discovery_listener.get_available_packet_count() > 0:
		var data = discovery_listener.get_packet().get_string_from_utf8()
		var sender_ip = discovery_listener.get_packet_ip()
		var sender_port = discovery_listener.get_packet_port()
		if data == "TANKS_DISCOVER":
			discovery_listener.set_dest_address(sender_ip, sender_port)
			discovery_listener.put_packet("TANKS_HOST".to_utf8_buffer())

func play(player_name: String) -> void:
	if state != State.OFFLINE:
		return

	var host_ip = await _discover_host()
	if host_ip != "":
		_join(host_ip, player_name)
	else:
		_host(player_name)

func _discover_host() -> String:
	var probe := PacketPeerUDP.new()
	probe.set_broadcast_enabled(true)
	probe.bind(0) # bind to a free local port so we can receive a reply
	probe.set_dest_address("255.255.255.255", DISCOVERY_PORT)
	probe.put_packet("TANKS_DISCOVER".to_utf8_buffer())

	var elapsed := 0.0
	while elapsed < DISCOVERY_TIMEOUT:
		if probe.get_available_packet_count() > 0:
			var data = probe.get_packet().get_string_from_utf8()
			var sender_ip = probe.get_packet_ip()
			if data == "TANKS_HOST":
				probe.close()
				return sender_ip
		await get_tree().create_timer(0.1).timeout
		elapsed += 0.1

	probe.close()
	return "" # nobody responded — we should host

func _host(player_name: String):
	peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(PORT, 8)
	if err != OK:
		connection_error.emit("Failed to host: error %d" % err)
		return
	multiplayer.multiplayer_peer = peer
	players[1] = player_name
	state = State.HOSTING
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	discovery_listener.bind(DISCOVERY_PORT) # start answering future discovery pings

	player_list_changed.emit()
	state_changed.emit()
	print("hosting, state is ", state)

func _join(ip: String, player_name: String):
	peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(ip, PORT)
	if err != OK:
		connection_error.emit("Failed to create client: error %d" % err)
		return
	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(func():
		state = State.CONNECTED
		state_changed.emit()
		print("joined, state is ", state)
		_register_self(player_name)
	)
	multiplayer.connection_failed.connect(func():
		connection_error.emit("Connection failed — server unreachable")
	)

func _register_self(player_name: String):
	rpc_id(1, "register_player", player_name)

@rpc("any_peer", "reliable")
func register_player(player_name: String):
	var id = multiplayer.get_remote_sender_id()
	players[id] = player_name
	_sync_players.rpc(players)

@rpc("authority", "reliable", "call_local")
func _sync_players(new_players: Dictionary):
	players = new_players
	player_list_changed.emit()

func _on_peer_connected(id: int):
	print("Peer connected: ", id)

func _on_peer_disconnected(id: int):
	players.erase(id)
	_sync_players.rpc(players)
	print("Peer disconnected: ", id)

@rpc("any_peer","reliable")
func send_chat(text:String):
	var id = multiplayer.get_remote_sender_id()
	_broadcast_chat.rpc(id,text)

@rpc("authority","reliable","call_local")
func _broadcast_chat(id: int, text: String):
	chat_message_recieved.emit(id,text)

func send_own_chat(text:String):
	if multiplayer.is_server():
		_broadcast_chat.rpc(1,text)
	else:
		send_chat.rpc_id(1,text)
