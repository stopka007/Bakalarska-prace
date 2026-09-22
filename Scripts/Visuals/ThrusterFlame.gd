extends Polygon2D

## Vizualizace plamene motoru. Pouze čte stav lodi, nijak nezasahuje
## do fyzikálního výpočtu – vizuál je záměrně oddělen od simulace.


## Loď, jejíž motor sledujeme. Když zůstane prázdné, použije se rodič.
@export var ship: Ship

## Mez, od které se plamen zobrazí.
@export var visibility_threshold: float = 0.01

## Rozsah náhodného kmitání délky plamene (efekt hoření).
@export var flicker_amount: float = 0.15

var _ship: Ship = null


func _ready() -> void:
	_ship = ship if ship != null else get_parent() as Ship
	visible = false


func _process(_delta: float) -> void:
	if _ship == null:
		return

	var level: float = _ship.thrust_level
	visible = level > visibility_threshold
	if not visible:
		return

	# Délka plamene odpovídá míře tahu, drobné kmitání dodává život.
	var flicker: float = 1.0 + randf_range(-flicker_amount, flicker_amount)
	scale = Vector2(1.0, level * flicker)
