extends CanvasLayer

## Pauzovací překryv herní scény.
##
## Klávesa Escape (akce `ui_cancel`) zmrazí strom scény přes `SceneTree.paused`,
## takže se zastaví i vlastní integrační smyčka lodi – simulace se nikam
## neposune a po návratu pokračuje přesně tam, kde skončila.


## Scéna menu, na kterou přepíná tlačítko „Quit to menu".
@export_file("*.tscn") var menu_scene_path: String = "res://MainScenes/main_menu.tscn"

## Vstupní akce pro pauzu. `ui_cancel` je ve výchozím stavu Escape.
@export var pause_action: StringName = &"ui_cancel"

## Tlačítko, které po zapauzování dostane klávesový fokus.
@export var default_focus_button: Button = null


func _ready() -> void:
	# Překryv musí běžet i během pauzy, jinak by hru nešlo znovu rozjet.
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	# Po dokončení kola má přednost obrazovka s Continue / Quit.
	if LevelProgress.run_finished:
		return
	if not event.is_action_pressed(pause_action):
		return

	# Událost označíme za zpracovanou, aby na Escape nereagoval nikdo další.
	get_viewport().set_input_as_handled()
	toggle_pause()


## Přepne mezi pauzou a během hry podle aktuálního stavu.
func toggle_pause() -> void:
	if visible:
		resume()
	else:
		pause_game()


## Zastaví simulaci a zobrazí překryv.
func pause_game() -> void:
	get_tree().paused = true
	visible = true
	if default_focus_button != null:
		default_focus_button.grab_focus()


## Skryje překryv a nechá simulaci pokračovat z místa, kde byla zmrazena.
func resume() -> void:
	get_tree().paused = false
	visible = false


## Opustí rozehranou hru a vrátí se do hlavního menu.
func quit_to_menu() -> void:
	if menu_scene_path.is_empty():
		push_warning("PauseMenu: není nastavena cesta ke scéně menu.")
		return

	# Pauzu je nutné zrušit, jinak by menu naběhlo zamrzlé.
	get_tree().paused = false

	var error: Error = get_tree().change_scene_to_file(menu_scene_path)
	if error != OK:
		push_error("PauseMenu: scénu '%s' se nepodařilo načíst (chyba %d)." % [menu_scene_path, error])
