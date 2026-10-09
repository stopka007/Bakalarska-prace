class_name BlackHole
extends GravityBody

## Cíl kola. Mimo fialový kruh nepůsobí žádnou gravitací.
## Uvnitř něj loď vtahuje a po překročení horizontu kolo dokončí.
##
## Vizuál se kreslí kódem, takže uzel nepotřebuje texturu.


## Vzdálenost od středu [px], pod kterou díra loď spolkne.
@export var horizon_radius: float = 64.0

## Poloměr fialového kruhu vůči horizontu. Mimo něj je gravitace nulová.
@export var pull_radius_scale: float = 1.55

## Délka vtažení lodi do středu [s].
@export var capture_time: float = 0.4

var _capturing: bool = false


func _ready() -> void:
	super._ready()
	# `GravityField` těleso mimo `influence_radius` úplně přeskočí.
	influence_radius = _pull_radius()
	z_index = 10
	queue_redraw()


func _draw() -> void:
	var pull: float = _pull_radius()
	draw_circle(Vector2.ZERO, pull, Color(0.35, 0.12, 0.55, 0.22))
	draw_arc(Vector2.ZERO, horizon_radius * 1.05, 0.0, TAU, 48, Color(0.9, 0.48, 0.22, 0.9), 3.0, true)
	draw_circle(Vector2.ZERO, horizon_radius * 0.62, Color(0.01, 0.01, 0.02, 1.0))


## Poloměr fialové zóny, ve které díra začne táhnout.
func _pull_radius() -> float:
	return horizon_radius * pull_radius_scale


func _physics_process(_delta: float) -> void:
	if _capturing or LevelProgress.run_finished:
		return

	var ship: Ship = get_tree().get_first_node_in_group(Ship.GROUP_NAME) as Ship
	if ship == null or ship.controls_locked:
		return
	if global_position.distance_to(ship.global_position) > horizon_radius:
		return

	_capture(ship)


func _capture(ship: Ship) -> void:
	_capturing = true
	ship.lock_controls()

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(ship, "global_position", global_position, capture_time)
	tween.tween_property(ship, "scale", Vector2(0.06, 0.06), capture_time)
	tween.chain().tween_callback(LevelProgress.complete_current_level)
