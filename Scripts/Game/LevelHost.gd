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

	ship.reset_motion(spawn.global_position, Vector2.ZERO, rad_to_deg(spawn.rotation))
