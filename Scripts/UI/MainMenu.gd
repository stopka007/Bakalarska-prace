extends Control

## Hlavní menu hry.
##
## Skript sám nic nepropojuje – signály `pressed` jednotlivých tlačítek
## si napojíš v editoru na veřejné metody níže. Cílová scéna se nastavuje
## přes inspektor, aby menu nebylo svázané s konkrétním souborem.


## Scéna, která se spustí po stisknutí tlačítka Play.
@export_file("*.tscn") var gameplay_scene_path: String = "res://MainScenes/gameplay.tscn"

## Tlačítko, které po otevření menu dostane klávesový fokus.
@export var default_focus_button: Button = null


func _ready() -> void:
	if default_focus_button != null:
		default_focus_button.grab_focus()


## Přepne hru do herní scény.
func on_play_pressed() -> void:
	if gameplay_scene_path.is_empty():
		push_warning("MainMenu: není nastavena cesta ke gameplay scéně.")
		return

	var error: Error = get_tree().change_scene_to_file(gameplay_scene_path)
	if error != OK:
		push_error("MainMenu: scénu '%s' se nepodařilo načíst (chyba %d)." % [gameplay_scene_path, error])


## Ukončí aplikaci. V editoru tím skončí i spuštěná hra.
func on_quit_pressed() -> void:
	get_tree().quit()
