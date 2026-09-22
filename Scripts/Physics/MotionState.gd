class_name MotionState
extends RefCounted

## Stav pohybu jednoho tělesa v konfiguračním prostoru (poloha + rychlost).
##
## Integrátory tento objekt mutují na místě (in-place), takže při integraci
## nevznikají nové alokace. To je důležité pro predikci trajektorie,
## kde se integrační krok volá stokrát za jeden snímek.


## Poloha tělesa [px] ve světových souřadnicích.
var position: Vector2 = Vector2.ZERO

## Rychlost tělesa [px/s].
var velocity: Vector2 = Vector2.ZERO


func _init(start_position: Vector2 = Vector2.ZERO, start_velocity: Vector2 = Vector2.ZERO) -> void:
	position = start_position
	velocity = start_velocity


## Vrátí nezávislou kopii stavu (např. jako výchozí bod predikce trajektorie).
func duplicate_state() -> MotionState:
	return MotionState.new(position, velocity)


## Přepíše stav novými hodnotami bez alokace nového objektu.
func set_state(new_position: Vector2, new_velocity: Vector2) -> void:
	position = new_position
	velocity = new_velocity


## Kinetická energie na jednotku hmotnosti [px^2/s^2].
## Slouží k ověření zachování energie při srovnávání integrátorů v textu práce.
func specific_kinetic_energy() -> float:
	return 0.5 * velocity.length_squared()
