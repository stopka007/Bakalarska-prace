extends VBoxContainer

## Ukazatel rychlosti. Simulaci jen čte.
##
## Kromě čísla hlásí, jestli loď zrychluje, zpomaluje, nebo rychlost drží.
## To je vidět na setrvačnosti (číslo stojí) a na pádu k planetě (číslo roste).


## Sledovaná loď.
@export var ship: Ship

## Rychlost [px/s], při které je proužek plný. Číslo nad ní dál roste.
@export var max_speed: float = 400.0

## Pod touto změnou rychlosti [px/s²] se hlásí, že rychlost drží.
@export var hold_threshold: float = 12.0

@onready var _value: Label = $Value
@onready var _state: Label = $State
@onready var _bar: ProgressBar = $Bar

var _previous_speed: float = 0.0
var _smoothed_accel: float = 0.0
var _has_sample: bool = false


func _ready() -> void:
	if ship == null:
		ship = get_tree().get_first_node_in_group(Ship.GROUP_NAME) as Ship
	_bar.min_value = 0.0
	_bar.max_value = 1.0
	_bar.step = 0.0
	_bar.show_percentage = false


func _process(delta: float) -> void:
	if ship == null:
		_value.text = "—"
		_state.text = ""
		_bar.value = 0.0
		return

	var speed: float = ship.get_speed()
	var accel: float = 0.0
	if _has_sample and delta > 0.0:
		accel = (speed - _previous_speed) / delta
	_previous_speed = speed
	_has_sample = true

	# Krátké vyhlazení, aby nápis neblikal na každém snímku.
	var blend: float = 1.0 - exp(-5.0 * delta)
	_smoothed_accel = lerpf(_smoothed_accel, accel, blend)

	_value.text = "%d px/s" % roundi(speed)
	if max_speed <= 0.0:
		_bar.value = 0.0
	else:
		_bar.value = clampf(speed / max_speed, 0.0, 1.0)
	_show_trend()


func _show_trend() -> void:
	if absf(_smoothed_accel) < hold_threshold:
		_state.text = "rychlost drží"
		_state.modulate = Color(0.75, 0.86, 1.0)
		return
	if _smoothed_accel > 0.0:
		_state.text = "zrychluje"
		_state.modulate = Color(0.45, 0.95, 0.55)
		return
	_state.text = "zpomaluje"
	_state.modulate = Color(1.0, 0.72, 0.4)
