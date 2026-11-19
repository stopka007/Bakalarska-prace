extends Node2D

## Průletový bod. Sám kolo nesplní, jen otevře vzdálenější cíl.
##
## Loď jím musí proletět dřív, než se počítá dolet ke konečnému kroužku.


@export var radius: float = 80.0
@export var ring_color: Color = Color(0.95, 0.85, 0.4, 0.95)

var opened: bool = false


func _ready() -> void:
	z_index = 4
	queue_redraw()


func _draw() -> void:
	var color: Color = ring_color
	if opened:
		color = Color(0.45, 0.95, 0.75, 0.95)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 36, color, 3.0, true)


func _physics_process(_delta: float) -> void:
	if opened or LevelProgress.run_finished:
		return
	var ship: Ship = get_tree().get_first_node_in_group(Ship.GROUP_NAME) as Ship
	if ship == null:
		return
	if global_position.distance_to(ship.global_position) > radius:
		return
	opened = true
	queue_redraw()
