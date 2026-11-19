extends Node2D

## Cíl mise. Nemá gravitaci, jen oblast, do které loď musí doletět.
##
## Splnění hlásí stejnou cestou jako černá díra, takže se ukáže
## obrazovka s dalším kolem.


@export var radius: float = 80.0
@export var ring_color: Color = Color(0.45, 0.95, 0.75, 0.9)

## Když je vyplněné, cíl se otevře až po průletu tímto bodem.
@export var checkpoint_path: NodePath = NodePath("")

const TARGET_GROUP: StringName = &"mission_target"

var _done: bool = false
var _checkpoint: Node = null
var _was_locked: bool = false


func _ready() -> void:
	if not checkpoint_path.is_empty():
		_checkpoint = get_node_or_null(checkpoint_path)
	add_to_group(TARGET_GROUP)
	add_to_group(&"mission_goal")
	z_index = 4
	queue_redraw()


func _draw() -> void:
	var color: Color = ring_color
	if _is_locked():
		color.a = 0.35
	draw_circle(Vector2.ZERO, radius, Color(color.r, color.g, color.b, 0.12))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, color, 3.0, true)
	draw_circle(Vector2.ZERO, 8.0, color)


func _physics_process(_delta: float) -> void:
	if _done or LevelProgress.run_finished:
		return
	var locked: bool = _is_locked()
	if locked != _was_locked:
		_was_locked = locked
		queue_redraw()
	if locked:
		return
	var ship: Ship = get_tree().get_first_node_in_group(Ship.GROUP_NAME) as Ship
	if ship == null:
		return
	if global_position.distance_to(ship.global_position) > radius:
		return
	_done = true
	LevelProgress.complete_current_level()


func _is_locked() -> bool:
	return _checkpoint != null and not bool(_checkpoint.get("opened"))
