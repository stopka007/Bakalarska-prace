class_name Ship
extends Area2D

## Hráčova vesmírná loď s vlastní numerickou integrací pohybu.
##
## Zásadní vlastnosti:
##  - Vestavěná gravitace ani pohybové funkce fyzikálního serveru se NEPOUŽÍVAJÍ.
##    Poloha a rychlost se počítají ručně v `_physics_process` (viz `Integrator`).
##    Area2D je zde pouze kvůli detekci kolizí (asteroidy, horizont událostí).
##  - Ve vakuu není žádné umělé tření: bez tahu si loď zachovává rychlost
##    (setrvačnost), s tahem plynule zrychluje – zrychlení a = F / m.
##  - Loď stojí na místě, dokud hráč nezapne motor. Při nulovém počtu zdrojů
##    gravitace ve scéně je celkové zrychlení dáno jen tahem motoru.
##
## Ovládání: W / Nahoru = tah motoru, A / D (Vlevo / Vpravo) = rotace.


## Skupina, do které se loď registruje, aby si ji uměly dohledat prvky UI.
const GROUP_NAME: StringName = &"player_ship"

## Vstupní akce (definované v project.godot -> Input Map).
const ACTION_THRUST: StringName = &"thrust"
const ACTION_ROTATE_LEFT: StringName = &"rotate_left"
const ACTION_ROTATE_RIGHT: StringName = &"rotate_right"

## Směr "dopředu" v lokálních souřadnicích lodi.
## V Godotu je -Y nahoru, takže loď s rotací 0° míří vzhůru.
const LOCAL_FORWARD: Vector2 = Vector2.UP


@export_group("Pohon")

## Hmotnost lodi [kg]. Spolu s tahem určuje zrychlení: a = thrust_force / ship_mass.
@export_range(0.1, 100.0, 0.1, "or_greater") var ship_mass: float = 1.0

## Tah motoru [N]. Působí ve směru, kam loď míří.
@export_range(0.0, 2000.0, 1.0, "or_greater") var thrust_force: float = 300.0

## Úhlová rychlost otáčení lodi [°/s].
@export_range(0.0, 720.0, 5.0) var rotation_speed: float = 160.0


@export_group("Palivo")

## Kapacita nádrže [jednotky paliva].
@export var max_fuel: float = 100.0

## Spotřeba při plném tahu [jednotky/s]. Nutí hráče využívat gravitační prak.
@export var fuel_consumption: float = 8.0

## Vypnutím se palivo neomezuje (vhodné při ladění fyziky).
@export var fuel_enabled: bool = true


@export_group("Gravitace")

## Gravitační konstanta G v herních jednotkách (nejde o reálných 6.674e-11,
## protože pracujeme s pixely a herními hmotnostmi).
@export var gravitational_constant: float = 1000.0

## Změkčovací parametr epsilon [px] – zamezuje singularitě při r -> 0.
@export_range(0.0, 200.0, 1.0, "or_greater") var softening: float = 20.0

## Vypnutím zůstane působit pouze tah motoru.
@export var gravity_enabled: bool = true


@export_group("Numerická integrace")

## Volba integrační metody. Pořadí musí odpovídat výčtu `Integrator.Method`.
@export_enum("Explicitní Euler:0", "Semi-implicitní Euler:1", "Velocity Verlet:2", "RK4:3") var integration_method: int = Integrator.Method.RK4

## Počet dílčích integračních kroků na jeden snímek.
## Vyšší hodnota = menší krok h = delta / substeps = menší numerická chyba.
@export_range(1, 32, 1) var substeps: int = 1

## Počáteční rychlost [px/s]. Ponech nulovou, má-li loď startovat v klidu.
@export var initial_velocity: Vector2 = Vector2.ZERO


## Aktuální rychlost lodi [px/s]. Čtení zvenčí (HUD, predikce trajektorie).
var velocity: Vector2 = Vector2.ZERO

## Zbývající palivo [jednotky].
var current_fuel: float = 0.0

## Poslední spočtené celkové zrychlení [px/s^2] – pouze pro diagnostiku a HUD.
var last_acceleration: Vector2 = Vector2.ZERO

## Aktuální míra tahu 0..1 (analogové ovladače umí i mezihodnoty).
var thrust_level: float = 0.0

# Vnitřní stav integrace – jeden znovupoužívaný objekt, bez alokací za snímek.
var _state: MotionState = MotionState.new()

# Zdroje gravitace načtené jednou za snímek (integrátor je volá vícekrát).
var _gravity_bodies: Array[GravityBody] = []

# Zrychlení jako Callable předávané integrátoru (uloženo, aby se nevytvářelo znovu).
var _acceleration_func: Callable = Callable()

# Jsou k dispozici všechny vstupní akce?
var _input_available: bool = false


func _ready() -> void:
	add_to_group(GROUP_NAME)
	current_fuel = max_fuel
	velocity = initial_velocity
	_state.set_state(global_position, velocity)
	_acceleration_func = _compute_acceleration
	_input_available = _check_input_actions()


func _physics_process(delta: float) -> void:
	_handle_rotation(delta)
	_handle_thrust(delta)
	_integrate_motion(delta)


# --- Vstup -------------------------------------------------------------------


## Rotace se řeší kinematicky (přímo úhlovou rychlostí), protože moment
## setrvačnosti lodi pro účely hratelnosti nemodelujeme.
func _handle_rotation(delta: float) -> void:
	if not _input_available:
		return
	var direction: float = Input.get_axis(ACTION_ROTATE_LEFT, ACTION_ROTATE_RIGHT)
	if direction != 0.0:
		rotation += deg_to_rad(rotation_speed) * direction * delta


## Zjistí míru tahu a odečte palivo. Bez paliva motor nepracuje.
func _handle_thrust(delta: float) -> void:
	var requested: float = 0.0
	if _input_available:
		requested = clampf(Input.get_action_strength(ACTION_THRUST), 0.0, 1.0)

	if fuel_enabled and requested > 0.0:
		if current_fuel <= 0.0:
			requested = 0.0
		else:
			var needed: float = fuel_consumption * requested * delta
			if needed > current_fuel:
				# Na konci nádrže hoří motor jen po část snímku -> zkrácený tah.
				requested *= current_fuel / needed
				current_fuel = 0.0
			else:
				current_fuel -= needed

	thrust_level = requested


# --- Fyzika ------------------------------------------------------------------


## Jeden krok vlastní integrační smyčky.
func _integrate_motion(delta: float) -> void:
	# Zdroje gravitace stačí načíst jednou za snímek.
	_gravity_bodies = GravityField.gather_bodies(get_tree())

	# Synchronizace ze scény (poloha mohla být změněna zvenčí, např. při restartu).
	_state.set_state(global_position, velocity)

	Integrator.integrate_substeps(
		integration_method,
		_state,
		_acceleration_func,
		delta,
		substeps
	)

	# Zápis výsledku do scény – jediné místo, kde se fyzika propisuje do vizuálu.
	velocity = _state.velocity
	global_position = _state.position


## Celkové zrychlení působící na loď: gravitace okolních těles + tah motoru.
## Parametr rychlosti zatím nevyužíváme (ve vakuu nepůsobí odpor prostředí),
## ale je součástí signatury kvůli metodám vyššího řádu a budoucí atmosféře.
func _compute_acceleration(position_now: Vector2, _velocity_now: Vector2) -> Vector2:
	var total: Vector2 = Vector2.ZERO

	if gravity_enabled:
		total += GravityField.acceleration_at(
			_gravity_bodies,
			position_now,
			gravitational_constant,
			softening
		)

	total += _thrust_acceleration()

	last_acceleration = total
	return total


## Zrychlení od motoru: a = F / m ve směru, kam loď míří.
## Rotace je v rámci jednoho snímku konstantní, takže směr tahu je uvnitř
## integračního kroku pevný.
func _thrust_acceleration() -> Vector2:
	if thrust_level <= 0.0 or ship_mass <= 0.0:
		return Vector2.ZERO
	var magnitude: float = (thrust_force / ship_mass) * thrust_level
	return LOCAL_FORWARD.rotated(rotation) * magnitude


# --- Veřejné API -------------------------------------------------------------


## Vrátí loď do klidu na zadanou pozici (restart pokusu).
func reset_motion(new_position: Vector2, new_velocity: Vector2 = Vector2.ZERO, new_rotation_degrees: float = 0.0) -> void:
	global_position = new_position
	rotation = deg_to_rad(new_rotation_degrees)
	velocity = new_velocity
	thrust_level = 0.0
	last_acceleration = Vector2.ZERO
	current_fuel = max_fuel
	_state.set_state(new_position, new_velocity)


## Aktuální velikost rychlosti [px/s].
func get_speed() -> float:
	return velocity.length()


## Podíl zbývajícího paliva v rozsahu 0..1.
func get_fuel_ratio() -> float:
	if max_fuel <= 0.0:
		return 0.0
	return clampf(current_fuel / max_fuel, 0.0, 1.0)


## Celková mechanická energie na jednotku hmotnosti (kinetická + potenciální).
## Ideální integrátor ji při vypnutém motoru udrží konstantní – slouží jako
## měřítko kvality metody při srovnání v bakalářské práci.
func get_specific_energy() -> float:
	var kinetic: float = 0.5 * velocity.length_squared()
	var potential: float = GravityField.specific_potential_at(
		_gravity_bodies,
		global_position,
		gravitational_constant,
		softening
	)
	return kinetic + potential


## Název aktuálně použité integrační metody.
func get_integration_method_name() -> String:
	return Integrator.method_name(integration_method)


# --- Pomocné -----------------------------------------------------------------


func _check_input_actions() -> bool:
	var required: Array[StringName] = [ACTION_THRUST, ACTION_ROTATE_LEFT, ACTION_ROTATE_RIGHT]
	for action in required:
		if not InputMap.has_action(action):
			push_warning(
				"Ship: chybí vstupní akce '%s'. Doplň ji v Project Settings -> Input Map." % action
			)
			return false
	return true
