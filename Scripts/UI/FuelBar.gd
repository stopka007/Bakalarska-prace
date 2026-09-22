extends ProgressBar

## Ukazatel zbývajícího paliva lodi.
##
## Skript stav lodi pouze čte – spotřebu ani fyziku nijak neovlivňuje
## (vizuál je záměrně oddělen od simulace). Při docházejícím palivu
## se výplň přebarvuje do varovné barvy a pod kritickou hranicí bliká.


## Sledovaná loď.
@export var ship: Ship


@export_group("Barvy")

## Barva výplně při plné nádrži.
@export var color_full: Color = Color(0.29, 0.85, 0.45)

## Barva výplně při prázdné nádrži.
@export var color_low: Color = Color(0.9, 0.27, 0.22)

## Podíl paliva (0..1), od kterého se barva začne přelévat do varovné.
@export_range(0.0, 1.0, 0.05) var low_fuel_ratio: float = 0.35


@export_group("Varování")

## Podíl paliva (0..1), pod kterým ukazatel bliká.
@export_range(0.0, 1.0, 0.05) var critical_fuel_ratio: float = 0.12

## Vypnutím blikání zůstane jen změna barvy.
@export var blink_when_critical: bool = true

## Frekvence blikání [Hz].
@export_range(0.5, 10.0, 0.5) var blink_frequency: float = 2.0

# Vlastní kopie stylu výplně, aby přebarvování neovlivnilo jiné prvky UI.
var _fill_style: StyleBoxFlat = null

# Čas pro výpočet fáze blikání.
var _elapsed: float = 0.0


func _ready() -> void:
	# Když odkaz není nastaven v inspektoru, dohledáme loď podle skupiny.
	if ship == null:
		ship = get_tree().get_first_node_in_group(Ship.GROUP_NAME) as Ship

	# Ukazatel pracuje s podílem paliva v rozsahu 0..1.
	min_value = 0.0
	max_value = 1.0
	# Nulový krok vypne zaokrouhlování, jinak by hodnota skákala mezi 0 a 1.
	step = 0.0

	var style: StyleBoxFlat = get_theme_stylebox("fill") as StyleBoxFlat
	if style == null:
		style = StyleBoxFlat.new()
	_fill_style = style.duplicate() as StyleBoxFlat
	add_theme_stylebox_override("fill", _fill_style)

	if ship != null:
		value = ship.get_fuel_ratio()


func _process(delta: float) -> void:
	if ship == null:
		return

	_elapsed += delta
	var ratio: float = ship.get_fuel_ratio()
	value = ratio
	_update_color(ratio)
	_update_blink(ratio)


## Plynulý přechod barvy: nad `low_fuel_ratio` svítí `color_full`,
## pod ní se barva lineárně přelévá do `color_low`.
func _update_color(ratio: float) -> void:
	if _fill_style == null:
		return
	var weight: float = 1.0
	if low_fuel_ratio > 0.0:
		weight = clampf(ratio / low_fuel_ratio, 0.0, 1.0)
	_fill_style.bg_color = color_low.lerp(color_full, weight)


## Pod kritickou hranicí ukazatel pulzuje, aby si hráč nedostatku všiml.
func _update_blink(ratio: float) -> void:
	if not blink_when_critical or ratio > critical_fuel_ratio:
		modulate.a = 1.0
		return
	modulate.a = 0.35 + 0.65 * absf(sin(_elapsed * blink_frequency * PI))
