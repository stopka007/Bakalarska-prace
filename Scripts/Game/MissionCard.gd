extends Node

## Krátký text mise pro děti. HUD si ho najde podle skupiny.


const GROUP_NAME: StringName = &"mission_card"

@export var mission_title: String = ""

## Krátká připomínka, která zůstane na obrazovce během letu.
@export_multiline var mission_text: String = ""

## Text do okna před startem. Když zůstane prázdný, použije se `mission_text`.
@export_multiline var lesson_text: String = ""

## Přiblížení kamery. 1 = jako v ostatních kolech, menší číslo = větší odstup.
@export var camera_zoom: float = 0.5


func _ready() -> void:
	add_to_group(GROUP_NAME)
