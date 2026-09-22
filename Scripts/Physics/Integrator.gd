class_name Integrator
extends RefCounted

## Sada numerických integrátorů pohybové rovnice.
##
## Řešíme soustavu obyčejných diferenciálních rovnic 1. řádu:
##     dx/dt = v
##     dv/dt = a(x, v)
## kde zrychlení a = F / m dodává volající přes parametr `acceleration`.
##
## Funkce zrychlení musí mít signaturu:
##     func(position: Vector2, velocity: Vector2) -> Vector2
##
## Všechny metody jsou statické a bezstavové – stav se předává v `MotionState`,
## který metody mění na místě. Díky tomu lze stejný kód použít jak pro pohyb
## lodi, tak pro dopřednou predikci trajektorie.


## Dostupné integrační metody. Pořadí hodnot musí odpovídat popiskům
## v `@export_enum` u lodi (viz Ship.gd).
enum Method {
	EULER_EXPLICIT = 0,      ## Explicitní (dopředný) Euler – 1. řád, chyba roste nejrychleji.
	EULER_SEMI_IMPLICIT = 1, ## Semi-implicitní (symplektický) Euler – 1. řád, dobře zachovává energii.
	VELOCITY_VERLET = 2,     ## Velocity Verlet – 2. řád, symplektický, standard pro N-těles.
	RK4 = 3,                 ## Runge–Kutta 4. řádu – 4. řád, nejpřesnější, 4 vyhodnocení síly.
}


## Provede jeden integrační krok zvolenou metodou.
## Stav `state` je změněn na místě.
## `method` je hodnota z výčtu `Method` (typ int, aby nebyl potřeba explicitní cast).
static func integrate(method: int, state: MotionState, acceleration: Callable, delta: float) -> void:
	match method:
		Method.EULER_EXPLICIT:
			_euler_explicit(state, acceleration, delta)
		Method.EULER_SEMI_IMPLICIT:
			_euler_semi_implicit(state, acceleration, delta)
		Method.VELOCITY_VERLET:
			_velocity_verlet(state, acceleration, delta)
		_:
			_rk4(state, acceleration, delta)


## Rozdělí jeden snímek na `substeps` dílčích kroků.
## Menší krok h = delta / substeps výrazně snižuje lokální chybu metody
## (u Eulera lineárně, u RK4 se čtvrtou mocninou).
static func integrate_substeps(method: int, state: MotionState, acceleration: Callable, delta: float, substeps: int) -> void:
	var step_count: int = maxi(substeps, 1)
	var h: float = delta / float(step_count)
	for _i in step_count:
		integrate(method, state, acceleration, h)


## Lidsky čitelný název metody – pro HUD a pro tabulky srovnání v práci.
static func method_name(method: int) -> String:
	match method:
		Method.EULER_EXPLICIT:
			return "Explicitní Euler"
		Method.EULER_SEMI_IMPLICIT:
			return "Semi-implicitní Euler"
		Method.VELOCITY_VERLET:
			return "Velocity Verlet"
		_:
			return "RK4"


# --- Jednotlivé metody -------------------------------------------------------


## Explicitní Euler (1. řád).
## x(t+h) = x(t) + h * v(t)
## v(t+h) = v(t) + h * a(t)
## Nová poloha se počítá ze STARÉ rychlosti – proto se rychlost aktualizuje až nakonec.
## Není symplektický: energie systému soustavně narůstá (spirálovitě rozpadlé orbity).
static func _euler_explicit(state: MotionState, acceleration: Callable, delta: float) -> void:
	var a: Vector2 = acceleration.call(state.position, state.velocity)
	state.position += state.velocity * delta
	state.velocity += a * delta


## Semi-implicitní (symplektický) Euler (1. řád).
## v(t+h) = v(t) + h * a(t)
## x(t+h) = x(t) + h * v(t+h)
## Oproti explicitnímu Euleru je stabilní a energii pouze osciluje, nenavyšuje.
static func _euler_semi_implicit(state: MotionState, acceleration: Callable, delta: float) -> void:
	var a: Vector2 = acceleration.call(state.position, state.velocity)
	state.velocity += a * delta
	state.position += state.velocity * delta


## Velocity Verlet (2. řád, symplektický).
## x(t+h) = x(t) + h * v(t) + 0.5 * h^2 * a(t)
## v(t+h) = v(t) + 0.5 * h * (a(t) + a(t+h))
## Vyžaduje dvě vyhodnocení zrychlení na krok. Protože naše zrychlení může
## teoreticky záviset i na rychlosti (atmosféra), použijeme pro druhé
## vyhodnocení predikovanou rychlost v(t) + h * a(t).
static func _velocity_verlet(state: MotionState, acceleration: Callable, delta: float) -> void:
	var a_start: Vector2 = acceleration.call(state.position, state.velocity)
	state.position += state.velocity * delta + 0.5 * a_start * delta * delta
	var predicted_velocity: Vector2 = state.velocity + a_start * delta
	var a_end: Vector2 = acceleration.call(state.position, predicted_velocity)
	state.velocity += 0.5 * (a_start + a_end) * delta


## Runge–Kutta 4. řádu.
## Klasické RK4 aplikované na stavový vektor y = (x, v), y' = (v, a(x, v)).
## Čtyři vyhodnocení zrychlení na krok, chyba metody O(h^5).
static func _rk4(state: MotionState, acceleration: Callable, delta: float) -> void:
	var x: Vector2 = state.position
	var v: Vector2 = state.velocity

	# k1 – derivace na začátku intervalu
	var k1_x: Vector2 = v
	var k1_v: Vector2 = acceleration.call(x, v)

	# k2 – derivace ve středu intervalu podle k1
	var k2_x: Vector2 = v + 0.5 * delta * k1_v
	var k2_v: Vector2 = acceleration.call(x + 0.5 * delta * k1_x, k2_x)

	# k3 – derivace ve středu intervalu podle k2
	var k3_x: Vector2 = v + 0.5 * delta * k2_v
	var k3_v: Vector2 = acceleration.call(x + 0.5 * delta * k2_x, k3_x)

	# k4 – derivace na konci intervalu podle k3
	var k4_x: Vector2 = v + delta * k3_v
	var k4_v: Vector2 = acceleration.call(x + delta * k3_x, k4_x)

	# Vážený průměr derivací (Simpsonovo pravidlo)
	state.position = x + (delta / 6.0) * (k1_x + 2.0 * k2_x + 2.0 * k3_x + k4_x)
	state.velocity = v + (delta / 6.0) * (k1_v + 2.0 * k2_v + 2.0 * k3_v + k4_v)
