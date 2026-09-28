extends Polygon2D

## Vizualizace plamene motoru. Pouze čte stav lodi, nijak nezasahuje
## do fyzikálního výpočtu – vizuál je záměrně oddělen od simulace.


## Který motor plamen zobrazuje. Pořadí musí odpovídat výčtu níže.
@export_enum("Hlavní:0", "Zpětný:1", "Doleva:2", "Doprava:3") var channel: int = 0

## Loď, jejíž motor sledujeme. Když zůstane prázdné, použije se rodič.
@export var ship: Ship

## Základní velikost vůči polygonu. Manévrovací plameny jsou menší.
@export_range(0.05, 2.0, 0.05) var size_scale: float = 1.0

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

	var level: float = _read_level()
	visible = level > visibility_threshold
	if not visible:
		return

	# Délka plamene odpovídá míře tahu, drobné kmitání dodává život.
	# Škáluje se jen lokální Y – uzel je natočený tak, aby Y mířilo ve směru výfuku.
	var flicker: float = 1.0 + randf_range(-flicker_amount, flicker_amount)
	scale = Vector2(size_scale, size_scale * level * flicker)


## Míra tahu motoru, který tento plamen zobrazuje.
func _read_level() -> float:
	match channel:
		1:
			return _ship.reverse_thrust_level
		2:
			return _ship.strafe_left_level
		3:
			return _ship.strafe_right_level
		_:
			return _ship.thrust_level
