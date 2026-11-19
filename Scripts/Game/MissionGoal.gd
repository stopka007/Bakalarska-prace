extends Node2D

## Cíl mise. Nemá gravitaci, jen oblast, do které loď musí doletět.
##
## Splnění hlásí stejnou cestou jako černá díra, takže se ukáže
## obrazovka s dalším kolem.


@export var radius: float = 80.0
@export var ring_color: Color = Color(0.45, 0.95, 0.75, 0.9)

var _done: bool = false


func _ready() -> void:
	z_index = 4
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(ring_color.r, ring_color.g, ring_color.b, 0.12))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, ring_color, 3.0, true)
	draw_circle(Vector2.ZERO, 8.0, ring_color)


func _physics_process(_delta: float) -> void:
	if _done or LevelProgress.run_finished:
		return
	var ship: Ship = get_tree().get_first_node_in_group(Ship.GROUP_NAME) as Ship
	if ship == null:
		return
	if global_position.distance_to(ship.global_position) > radius:
		return
	_done = true
	LevelProgress.complete_current_level()
