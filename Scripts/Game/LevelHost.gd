extends Node2D

## Společná herní scéna načte rozložení levelu podle `LevelProgress`.
##
## Loď, HUD a pauza zůstávají tady. Meteory a černá díra jsou v samostatné
## scéně levelu, aby šel seznam kol rozšiřovat bez kopírování celé hry.


func _ready() -> void:
	var path: String = LevelProgress.current_scene_path()
	if path.is_empty():
		push_error("LevelHost: není vybraný žádný level.")
		return

	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		push_error("LevelHost: scénu '%s' se nepodařilo načíst." % path)
		return

	var level: Node = packed.instantiate()
	level.name = "Level"
	add_child(level)

	var spawn: Node2D = level.get_node_or_null("Spawn") as Node2D
	var ship: Ship = get_node_or_null("Ship") as Ship
	if spawn == null or ship == null:
		push_warning("LevelHost: level nemá Spawn, nebo ve scéně chybí loď.")
		return

	# Mise může na značce Start nést počáteční rychlost a menší nádrž.
	var velocity: Vector2 = Vector2.ZERO
	var velocity_value: Variant = spawn.get("initial_velocity")
	if velocity_value is Vector2:
		velocity = velocity_value
	ship.reset_motion(spawn.global_position, velocity, rad_to_deg(spawn.rotation))

	var fuel_capacity: Variant = spawn.get("fuel_capacity")
	if fuel_capacity is float and fuel_capacity >= 0.0:
		ship.max_fuel = fuel_capacity
		ship.current_fuel = fuel_capacity

	var card: Node = level.get_node_or_null("MissionCard")
	_apply_mission_camera(card)

	var intro: Node = get_node_or_null("MissionIntro")
	if intro != null and card != null:
		intro.call("open_for", card)


## Výukové mise mají vlastní odstup kamery, ať je vidět cíl i planeta.
## Ostatní kola zůstanou na zoomu 1.
func _apply_mission_camera(card: Node) -> void:
	var camera: Camera2D = get_node_or_null("Ship/Camera2D") as Camera2D
	if camera == null:
		return
	var zoom_value: float = 1.0
	if card != null:
		var custom: Variant = card.get("camera_zoom")
		if custom is float and custom > 0.0:
			zoom_value = custom
	camera.zoom = Vector2(zoom_value, zoom_value)
