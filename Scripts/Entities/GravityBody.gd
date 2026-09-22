class_name GravityBody
extends Node2D

## Zdroj gravitace (planeta, měsíc, hvězda, černá díra).
##
## Těleso se samo registruje do skupiny `gravitational_bodies`, odkud si ho
## vyzvedne `GravityField` při výpočtu zrychlení. Samo se nehýbe – pohyb
## (orbita) se dá doplnit později bez zásahu do výpočtu gravitace.
##
## Skript neřeší vizuál ani kolize, jen fyzikální parametry.


## Název skupiny, ve které jsou registrovány všechny zdroje gravitace.
## Konstanta je zde (a ne v GravityField), aby mezi skripty nevznikla
## cyklická závislost.
const GROUP_NAME: StringName = &"gravitational_bodies"


## Hmotnost tělesa [kg] v herních jednotkách. Vstupuje do F = G * m1 * m2 / r^2.
@export var body_mass: float = 5000.0

## Vypnutím lze těleso dočasně vyřadit z výpočtu (užitečné při ladění).
@export var gravity_enabled: bool = true

## Fyzický poloměr povrchu [px] – pro budoucí přistávání a detekci dopadu.
@export var surface_radius: float = 64.0

## Poloměr, za kterým gravitaci tělesa zanedbáváme [px].
## Hodnota <= 0 znamená nekonečný dosah (plné N-těles řešení).
@export var influence_radius: float = 0.0


func _ready() -> void:
	add_to_group(GROUP_NAME)


## Gravitační parametr mu = G * M pro zadanou gravitační konstantu.
func gravitational_parameter(gravitational_constant: float) -> float:
	return gravitational_constant * body_mass


## Rychlost potřebná pro kruhovou orbitu ve vzdálenosti `orbit_radius` od středu.
## Plyne z rovnosti gravitační a dostředivé síly (v^2 / r = a):
##     v = sqrt(r * a(r)),  kde a(r) = G * M / (r^2 + eps^2)^(3/2) * r
## Parametr `softening` musí odpovídat hodnotě použité v `GravityField`,
## jinak by orbita nebyla přesně kruhová.
func circular_orbit_speed(orbit_radius: float, gravitational_constant: float, softening: float = 0.0) -> float:
	if orbit_radius <= 0.0:
		return 0.0
	var base: float = orbit_radius * orbit_radius + softening * softening
	return sqrt(gravitational_parameter(gravitational_constant) * orbit_radius * orbit_radius / (base * sqrt(base)))
